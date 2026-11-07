class_name SkirmishEntity
extends CharacterBody2D

# 2.5D beat-em-up entity. Screen Y is a depth axis (squashed by IsometryUtils.DEPTH_SCALE)
# and altitude is faked in `z`, so gravity is integrated by the states, not the physics engine.

signal died

const GRAVITY := 980.0

# Hits with no launch of their own still pop the target up by this much when it
# has to be knocked down anyway (a killing blow, or a re-hit while ragdolling)
const DEATH_LAUNCH := -260.0
const JUGGLE_LAUNCH := -300.0
const DEATH_KNOCKBACK_MIN := 260.0
const DASH_COOLDOWN := 5.0
const BLOCK_DEFENSE_SCALE := 10.0
const BLOCK_CHIP_FRACTION := 0.1
const DODGE_CHANCE := 0.09
# Max depth-axis spread on a knockdown
const KNOCKDOWN_Y_SPREAD := 0.35

const HERO_LAYER_INDEX = 9
const VILLAIN_LAYER_INDEX = 10

@onready var rig_wrapper: Sprite2D = $RigWrapper
@onready var debug_name_label: Label = $DebugNameLabel

@export var hitbox_scene: PackedScene
@export var entity_type: EntityConfig.EntityType
@export var move_speed := 125.0
@export var rig: SkirmishEntityRig
@export var shadow: Sprite2D
@export var healthbar: ProgressBar
@export var hurtbox: Hurtbox
@export var state_machine: StateMachine
@export var hurt_state: HurtState
@export var death_state: DeathState
@export var move_state: MoveState
@export var ragdoll_state: RagdollState
@export var is_grabbed_state: IsGrabbedState
@export var tag_out_state: TagOutState
@export var tag_in_state: TagInState
@export var block_state: BlockState
@export var dodge_state: DodgeState
@export var dash_state: DashState
@export var brain: Brain:
	set(value):
		brain = value
		brain.entity = self

var entity_config: EntityConfig
var is_active := true
var skirmish: Skirmish
var ability_to_state: Dictionary = {}
var ability_cooldowns: Dictionary = {}
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

var grabbed_entity

var _shadow_base_scale: Vector2

func facing() -> float:
	var f := signf(rig_wrapper.scale.x)
	return f if f != 0.0 else 1.0

func _ready() -> void:
	if entity_config != null:
		healthbar.max_value = entity_config.vitality
		healthbar.value = entity_config.curr_health
	else:
		healthbar.value = healthbar.max_value
	_shadow_base_scale = shadow.scale

func spawn_hitbox(config: HitboxConfig) -> Hitbox:
	var hitbox = hitbox_scene.instantiate() as Hitbox
	rig_wrapper.add_child(hitbox)
	hitbox.init(config.offset, config.size, config.lifetime, self, config.hit)
	return hitbox

func configure_from_entity_config(ec: EntityConfig) -> void:
	entity_config = ec
	entity_type = ec.entity_type
	healthbar.max_value = ec.vitality
	healthbar.value = ec.curr_health
	var layer_index = HERO_LAYER_INDEX if entity_type == EntityConfig.EntityType.HERO else VILLAIN_LAYER_INDEX
	set_collision_layer_value(layer_index, true)
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
	for ability in ability_cooldowns:
		ability_cooldowns[ability] = maxf(ability_cooldowns[ability] - delta * hitstop_scale, 0.0)
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
		if ability == null or ability.state_scene == null:
			continue
		var instance := ability.state_scene.instantiate() as AbilityState
		if instance == null:
			continue
		state_machine.add_child(instance)
		# StateMachine._ready already ran, so wire manually.
		instance.state_machine = state_machine
		instance.init(ability)
		ability_to_state[ability] = instance
		if ability is GrabAbility:
			_init_throw(ability, instance as GrabState)

func _init_throw(grab_ability: GrabAbility, grab_state: GrabState) -> void:
	if grab_ability.throw_state_scene == null or grab_state == null:
		return
	var throw_instance := grab_ability.throw_state_scene.instantiate() as ThrowState
	if throw_instance == null:
		return
	state_machine.add_child(throw_instance)
	throw_instance.state_machine = state_machine
	throw_instance.init(grab_ability)
	grab_state.throw_state = throw_instance
	ragdoll_state.bounce_base_damage = grab_ability.hit.damage

func _can_defend() -> bool:
	var state := state_machine.state
	return not (
		state == death_state
		or state == tag_in_state
		or state == tag_out_state
		or state == is_grabbed_state
		or state == ragdoll_state
		or state == hurt_state
		or state is AbilityState
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
		if source_state == source.is_grabbed_state or source_state == source.ragdoll_state or source_state == source.death_state:
			return false

	var dir := Vector2(signf(position.x - source.position.x), 0.0)

	## Grab logic TODO: Maybe get rid of this
	if hit.kind == HitConfig.Kind.GRAB:
		state_machine.transition_to(is_grabbed_state, {"grabber": source})
		source.grabbed_entity = self
		return false

	## Defensive options logic
	var blocked := state_machine.state == block_state
	if not blocked and _can_defend():
		# Dodge success roll calculation
		if randf() < DODGE_CHANCE:
			state_machine.transition_to(dodge_state, {"dir": dir})
			return false
		# Block success roll calculation
		var defense: int = entity_config.defense if entity_config != null else 0
		blocked = randf() < float(defense) / (defense + BLOCK_DEFENSE_SCALE)

	var damage := HitConfig.calculate_damage(hit.damage, entity_config.defense)
	# Take chip damage if blocked
	if blocked:
		damage = maxi(roundi(damage * BLOCK_CHIP_FRACTION), 1)
	source.entity_config.damage_dealt += damage
	healthbar.value -= damage
	if entity_config != null:
		entity_config.curr_health = int(healthbar.value)

	var hitstun := HurtState.hitstun_for(hit.base_hitstun, source.entity_config.strength)
	var hit_connected := false
	if healthbar.value <= 0:
		is_dead = true
		healthbar.hide()
		died.emit()
		state_machine.transition_to(death_state)
	elif blocked:
		state_machine.transition_to(block_state, {"dir": dir, "hitstun": hitstun})
		hit_connected = true
	elif hit.knockdown or state_machine.state == ragdoll_state:
		knock_down(dir * hit.knockback, hit.launch if hit.launch != 0.0 else JUGGLE_LAUNCH, source)
		hit_connected = true
	else:
		state_machine.transition_to(hurt_state, {"dir": dir, "hitstun": hitstun})
		hit_connected = true

	var frozen: Array = [self] if hit.kind == HitConfig.Kind.PROJECTILE else [source, self]
	Hitstop.freeze(frozen, hit.hitstop)

	if hit.knockdown and not blocked:
		ScreenShake.shake_horizontal(12, 0.1, 12)

	return hit_connected

func knock_down(impulse: Vector2, launch: float, thrower: SkirmishEntity) -> void:
	impulse.y += impulse.length() * randf_range(-KNOCKDOWN_Y_SPREAD, KNOCKDOWN_Y_SPREAD)

	if state_machine.state == ragdoll_state:
		# Already ragdolling: relaunch in place rather than re-entering the state,
		# which would reset the altitude we're trying to add to
		ragdoll_state.relaunch(impulse, launch)
		ragdoll_state.thrower_entity = thrower
	else:
		state_machine.transition_to(ragdoll_state, {"impulse": impulse, "launch": launch, "thrower": thrower})

func despawn() -> void:
	var tween := create_tween()
	tween.tween_property(rig, "modulate:a", 0.0, 0.4)
	tween.parallel().tween_property(shadow, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
