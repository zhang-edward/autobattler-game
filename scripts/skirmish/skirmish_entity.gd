class_name SkirmishEntity
extends CharacterBody2D

# 2.5D beat-em-up entity. Screen Y is a depth axis (squashed by IsometryUtils.DEPTH_SCALE)
# and altitude is faked in `z`, so gravity is integrated by the states, not the physics engine.

signal died
signal took_hit(combo_hits: int, is_punish: bool)
signal combo_ended
signal character_moment_rolled

const GRAVITY := 980.0

# Hits with no launch of their own still pop the target up by this much when it
# has to be knocked down anyway (a killing blow, or a re-hit while ragdolling)
const DEATH_LAUNCH := -260.0
const JUGGLE_LAUNCH := -300.0
const DEATH_KNOCKBACK_MIN := 260.0
const DASH_COOLDOWN := 5.0
const STAMINA_MAX := 100.0
const STAMINA_REGEN := 10.0
const CHARACTER_MOMENT_ON_ZERO_HEALTH_CHANCE := 0.0
# const CHARACTER_MOMENT_ON_ZERO_HEALTH_CHANCE := 0.5
const ZERO_HEALTH_SPEED_SCALE := 0.7
# Max depth-axis spread on a knockdown
const LAUNCH_Y_SPREAD := 0.25
const DAMAGE_NUMBER_OFFSET := Vector2(0.0, -160.0)

const HERO_LAYER_INDEX = 9
const VILLAIN_LAYER_INDEX = 10
const SIDE_WALL_LAYER_INDEX = 12
const VILLAIN_TINT := Color(1.0, 0.45, 0.45)

@onready var rig_wrapper: Sprite2D = $RigWrapper
@onready var debug_name_label: Label = $DebugNameLabel

@export var hitbox_scene: PackedScene
@export var entity_type: EntityConfig.EntityType
@export var move_speed := 125.0
@export var rig: SkirmishEntityRig
@export var shadow: Sprite2D
@export var healthbar: ProgressBar
@export var wounds_bar: ProgressBar
@export var hurtbox: Hurtbox
@export var state_machine: StateMachine
@export var hurt_state: HurtState
@export var death_state: DeathState
@export var downed_state: DownedState
@export var move_state: MoveState
@export var ragdoll_state: RagdollState
@export var tag_out_state: TagOutState
@export var tag_in_state: TagInState
@export var block_state: BlockState
@export var dodge_state: DodgeState
@export var dash_state: DashState
@export var character_moment_state: CharacterMomentState
@export var brain: Brain:
	set(value):
		brain = value
		brain.entity = self

var entity_config: EntityConfig
var is_active := true
var skirmish: Skirmish
var ability_to_state: Dictionary = {}
var chains: Array[AbilityChain] = []
var dash_cooldowns: Array[float] = [0.0, 0.0]

var hitstop_scale := 1.0:
	set(value):
		hitstop_scale = value
		if state_machine != null:
			state_machine.time_scale = value

var absolute_velocity := Vector2.ZERO

# Altitude: negative is up, 0 is the floor. Rendered by offsetting the sprite.
var z := 0.0
var z_velocity := 0.0
var is_dead := false
var combo_hits := 0
var defensive_status: DefensiveAbility
var block := 0
var stamina := STAMINA_MAX


var _shadow_base_scale: Vector2

func facing() -> float:
	var f := signf(rig_wrapper.scale.x)
	return f if f != 0.0 else 1.0

func _ready() -> void:
	if entity_config != null:
		healthbar.max_value = entity_config.get_max_health()
		healthbar.value = entity_config.curr_health
		wounds_bar.max_value = entity_config.get_max_health()
		wounds_bar.value = entity_config.curr_wounds
		wounds_bar.visible = healthbar.value <= 0
	else:
		healthbar.value = healthbar.max_value
	_shadow_base_scale = shadow.scale
	state_machine.transitioned.connect(_on_state_transitioned, CONNECT_DEFERRED)

func _on_state_transitioned(_state_name: String) -> void:
	if combo_hits == 0 or state_machine.state == hurt_state or state_machine.state == ragdoll_state:
		return
	combo_hits = 0
	combo_ended.emit()

func spawn_hitbox(config: HitboxConfig) -> Hitbox:
	var hitbox = hitbox_scene.instantiate() as Hitbox
	rig_wrapper.add_child(hitbox)
	hitbox.init(config.offset, config.size, config.lifetime, self, config.hit)
	return hitbox

func configure_from_entity_config(ec: EntityConfig) -> void:
	entity_config = ec
	entity_type = ec.entity_type
	healthbar.max_value = ec.get_max_health()
	healthbar.value = ec.curr_health
	wounds_bar.max_value = ec.get_max_health()
	wounds_bar.value = ec.curr_wounds
	wounds_bar.visible = healthbar.value <= 0
	var layer_index = HERO_LAYER_INDEX if entity_type == EntityConfig.EntityType.HERO else VILLAIN_LAYER_INDEX
	set_collision_layer_value(layer_index, true)
	if entity_type == EntityConfig.EntityType.VILLAIN:
		rig.modulate = VILLAIN_TINT
	debug_name_label.text = entity_config.entity_name
	_build_move_map()

# Tag entrance setup: visible and ticking so TagInState runs, but the hurtbox
# stays dark until TagInState completes into set_active(true).
func begin_tag_in(destination: Vector2, entry_side := 0.0) -> void:
	is_active = true
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	state_machine.transition_to(tag_in_state, {"destination": destination, "entry_side": entry_side})

func begin_tag_out() -> void:
	state_machine.transition_to(tag_out_state)

func set_active(value: bool) -> void:
	is_active = value
	visible = value
	# DISABLED freezes the whole subtree (entity, state machine, brain, rig anims)
	process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED
	if hurtbox != null:
		hurtbox.set_deferred("monitorable", value)
		hurtbox.set_deferred("monitoring", value)
	if not value:
		absolute_velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not is_active or brain == null:
		return
	stamina = minf(stamina + STAMINA_REGEN * delta * hitstop_scale, STAMINA_MAX)
	for i in dash_cooldowns.size():
		dash_cooldowns[i] = maxf(dash_cooldowns[i] - delta * hitstop_scale, 0.0)
	velocity = IsometryUtils.scale_velocity(absolute_velocity) * hitstop_scale
	move_and_slide()

func _process(_delta: float) -> void:
	# Altitude plus shift that keeps the sprite's center planted when it spins
	rig_wrapper.position.y = z
	shadow.scale = _shadow_base_scale * IsometryUtils.scale_shadow_from(z)

func _build_move_map() -> void:
	ability_to_state.clear()
	if entity_config == null:
		return
	for ability in entity_config.abilities:
		var offensive_ability := ability as OffensiveAbility
		if offensive_ability == null or offensive_ability.state_scene == null:
			continue
		var instance := offensive_ability.state_scene.instantiate() as AbilityState
		if instance == null:
			continue
		state_machine.add_child(instance)
		# StateMachine._ready already ran, so wire manually.
		instance.state_machine = state_machine
		instance.init(offensive_ability)
		ability_to_state[offensive_ability] = instance
	chains = entity_config.chains.duplicate()
	if chains.is_empty():
		for ability in entity_config.abilities:
			if ability is OffensiveAbility:
				var chain := AbilityChain.new()
				chain.abilities.append(ability)
				chains.append(chain)

func _can_block() -> bool:
	var state := state_machine.state
	return not (
		state == death_state
		or state == tag_in_state
		or state == tag_out_state
		or state == ragdoll_state
		or state == hurt_state
		# or state is AbilityState
	)

func _can_dodge() -> bool:
	var state := state_machine.state
	return not (
		state == death_state
		or state == tag_in_state
		or state == tag_out_state
		or state == ragdoll_state
		or state == hurt_state
	)

# Returns whether or not the hit connected
func take_hit(hit: HitConfig, source: SkirmishEntity) -> bool:
	if is_dead or not is_active:
		return false
	# If hitbox owner somehow transitioned into a state which invalidates its hitbox, we don't need to process this hit anymore
	if source == null or not is_instance_valid(source) or source.is_dead or not source.is_active:
		return false
	if source.state_machine != null and hit.kind != HitConfig.Kind.PROJECTILE:
		var source_state: State = source.state_machine.state
		if source_state == source.ragdoll_state or source_state == source.death_state:
			return false

	var dir := Vector2(signf(position.x - source.position.x), 0.0)
	var in_combo := state_machine.state == hurt_state or state_machine.state == ragdoll_state
	var is_punish := state_machine.state is AbilityState \
		and (state_machine.state as AbilityState).phase == AbilityState.Phase.RECOVERY

	## Defensive options logic
	if defensive_status is DodgeAbility and _can_dodge():
		defensive_status = null
		state_machine.transition_to(dodge_state, {"dir": dir})
		return false
	var damage := hit.damage
	var blocked := false
	if defensive_status is BlockAbility and _can_block():
		var absorbed := mini(block, damage)
		block -= absorbed
		damage -= absorbed
		blocked = damage == 0
		if block == 0:
			defensive_status = null
	var was_at_zero_health := healthbar.value <= 0
	source.entity_config.damage_dealt += damage
	var wound_damage := maxi(damage - int(healthbar.value), 0)
	healthbar.value -= damage
	entity_config.curr_health = int(healthbar.value)
	entity_config.curr_wounds = mini(entity_config.curr_wounds + wound_damage, entity_config.get_max_health())
	wounds_bar.value = entity_config.curr_wounds
	wounds_bar.visible = healthbar.value <= 0
	if healthbar.value <= 0 and not was_at_zero_health:
		move_speed *= ZERO_HEALTH_SPEED_SCALE
	if not blocked:
		combo_hits = combo_hits + 1 if in_combo else 1
		EffectManager.spawn_damage_number(global_position + Vector2(0.0, z) + DAMAGE_NUMBER_OFFSET, damage)
	var wound_fraction := float(entity_config.curr_wounds) / entity_config.get_max_health()
	var downed := not blocked and (wound_fraction >= 1.0 or (was_at_zero_health and randf() < wound_fraction))

	var hitstun := hit.base_hitstun
	var pushback := hit.pushback
	var hit_connected := false
	if downed and state_machine.state != ragdoll_state:
		state_machine.transition_to(downed_state)
		hit_connected = true
	elif blocked:
		state_machine.transition_to(block_state, {"dir": dir, "hitstun": hitstun, "pushback": pushback})
		hit_connected = true
	elif hit.is_launcher or state_machine.state == ragdoll_state:
		launch_entity(dir * hit.launch.x, hit.launch.y if hit.launch.y != 0.0 else JUGGLE_LAUNCH, source)
		ragdoll_state.add_ragdoll_damage(damage)
		if downed:
			ragdoll_state.is_downed = true
		hit_connected = true
	else:
		state_machine.transition_to(hurt_state, {"dir": dir, "hitstun": hitstun, "pushback": pushback})
		hit_connected = true

	if entity_type == EntityConfig.EntityType.HERO and healthbar.value <= 0 and not was_at_zero_health \
		and not character_moment_state.has_played and state_machine.state != downed_state \
		and randf() < CHARACTER_MOMENT_ON_ZERO_HEALTH_CHANCE:
		if state_machine.state == ragdoll_state:
			ragdoll_state.character_moment_on_land = true
		else:
			character_moment_rolled.emit()

	var frozen: Array = [self] if hit.kind == HitConfig.Kind.PROJECTILE else [source, self]
	Hitstop.freeze(frozen, hit.hitstop)

	if hit.is_launcher and not blocked:
		ScreenShake.shake_horizontal(12, 0.1, 12)

	if hit_connected:
		took_hit.emit(combo_hits, is_punish and not blocked)
	return hit_connected

func launch_entity(impulse: Vector2, launch: float, launched_by: SkirmishEntity) -> void:
	impulse.y += impulse.length() * randf_range(-LAUNCH_Y_SPREAD, LAUNCH_Y_SPREAD)

	if state_machine.state == ragdoll_state:
		# Already ragdolling: relaunch in place rather than re-entering the state,
		# which would reset the altitude we're trying to add to
		ragdoll_state.relaunch(impulse, launch)
		ragdoll_state.launched_by = launched_by
	else:
		state_machine.transition_to(ragdoll_state, {"impulse": impulse, "launch": launch, "launched_by": launched_by})

func despawn() -> void:
	var tween := create_tween()
	tween.tween_property(rig, "modulate:a", 0.0, 0.4)
	tween.parallel().tween_property(shadow, "modulate:a", 0.0, 0.4)
	tween.tween_callback(set_active.bind(false))
