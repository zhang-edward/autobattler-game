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
const BLOCK_PUSHBACK := 140.0
# Max depth-axis spread on a knockdown
const KNOCKDOWN_Y_SPREAD := 0.35

const HERO_LAYER_INDEX = 9
const VILLAIN_LAYER_INDEX = 10

@onready var rig_wrapper: Sprite2D = $RigWrapper
@onready var debug_name_label: Label = $DebugNameLabel

@export var hitbox_scene: PackedScene
@export var entity_type: EntityConfig.EntityType
@export var move_speed := 100.0
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
@export var brain: Brain:
	set(value):
		brain = value
		brain.entity = self

var entity_config: EntityConfig
var intent: Intent
var is_active := true
var skirmish: Skirmish
var ability_to_state: Dictionary = {}

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
	rig.on_emit_hitbox_enable.connect(handle_hitbox_enable)
	
func handle_hitbox_enable():
	if state_machine.state is PunchState:
		var punch := state_machine.state as PunchState
		var hit_config: HitConfig = punch.hits[punch.combo_index]
		match rig.anim_player.current_animation:
			"male-rig/frontarm_jab", "male-rig/frontarm_jab_instant":
				var hitbox = hitbox_scene.instantiate() as Hitbox
				rig.front_fist.add_child(hitbox)
				hitbox.init(Vector2(0, 0), Vector2(40, 40), 0.2, self, hit_config)
			"male-rig/backarm_jab", "male-rig/backarm_jab_instant":
				var hitbox = hitbox_scene.instantiate() as Hitbox
				rig.back_fist.add_child(hitbox)
				hitbox.init(Vector2(0, 0), Vector2(40, 40), 0.3, self, hit_config)
			"male-rig/backarm_uppercut", "male-rig/backarm_uppercut_instant":
				var hitbox = hitbox_scene.instantiate() as Hitbox
				add_child(hitbox)
				hitbox.init(Vector2(0, 0), Vector2(80, 100), 0.3, self, hit_config)
				hitbox.global_position = rig.back_fist.global_position
	elif state_machine.state is GrabState:
		var hit_config: HitConfig = (state_machine.state as GrabState).hit
		if rig.anim_player.current_animation == "male-rig/grab":
			var hitbox = hitbox_scene.instantiate() as Hitbox
			rig.back_fist.add_child(hitbox)
			hitbox.init(Vector2(0, 0), Vector2(40, 40), 0.2, self, hit_config)
			hitbox.global_position = rig.back_fist.global_position

func configure_from_entity_config(ec: EntityConfig) -> void:
	entity_config = ec
	entity_type = ec.entity_type
	move_speed = ec.agility
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
		intent = null

func _physics_process(delta: float) -> void:
	if not is_active or brain == null:
		return
	intent = brain.get_intent(delta * hitstop_scale)
	velocity = IsometryUtils.scale_velocity(absolute_velocity) * hitstop_scale
	move_and_slide()

func _process(_delta: float) -> void:
	# Altitude plus shift that keeps the sprite's center planted when it spins
	rig_wrapper.position.y = z
	shadow.scale = _shadow_base_scale * IsometryUtils.scale_shadow_from(z)
	if intent != null and intent.facing != 0.0:
		rig_wrapper.scale.x = -1.0 if intent.facing < 0.0 else 1.0
	elif absolute_velocity.x != 0.0:
		rig_wrapper.scale.x = -1.0 if absolute_velocity.x < 0.0 else 1.0

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

func _defensive_ability() -> Ability:
	if entity_config == null:
		return null
	for ability in entity_config.abilities:
		if ability.category == Ability.Category.DEFENSIVE:
			return ability
	return null

func _defensive_state() -> State:
	var ability := _defensive_ability()
	if ability != null and ability_to_state.has(ability):
		return ability_to_state[ability]
	return null

func _can_block() -> bool:
	var state := state_machine.state
	return not (
		state == death_state
		or state == tag_in_state
		or state == tag_out_state
		or state == is_grabbed_state
		or state == ragdoll_state
	)

func take_hit(hit: HitConfig, source: SkirmishEntity) -> void:
	if is_dead or not is_active:
		return
	# If hitbox owner somehow transitioned into a state which invalidates its hitbox, we don't need to process this hit anymore
	if source == null or not is_instance_valid(source) or source.is_dead or not source.is_active:
		return
	if source.state_machine != null:
		var source_state: State = source.state_machine.state
		if source_state == source.is_grabbed_state or source_state == source.ragdoll_state or source_state == source.death_state:
			return

	var dir := Vector2(signf(position.x - source.position.x), 0.0)

	if hit.kind == HitConfig.Kind.GRAB:
		state_machine.transition_to(is_grabbed_state, {"grabber": source})
		source.grabbed_entity = self
		return

	if hit.kind == HitConfig.Kind.STRIKE and _can_block():
		# Check block success with a "skill" stat check (d100 < 5 * skill)
		var skill: int = entity_config.skill if entity_config != null else 0
		if randf() * 100.0 < float(skill) * 5.0:
			print("Defending!")
			var defensive_state := _defensive_state()
			if defensive_state != null:
				state_machine.transition_to(defensive_state)
				Hitstop.freeze([source, self], hit.hitstop)
				return

	var damage = HitConfig.calculate_damage(hit.damage, source.entity_config.strength, entity_config.defense)
	source.entity_config.damage_dealt += hit.damage
	healthbar.value -= hit.damage
	if entity_config != null:
		entity_config.curr_health = int(healthbar.value)

	if healthbar.value <= 0:
		is_dead = true
		healthbar.hide()
		died.emit()
		state_machine.transition_to(death_state)

	# A ragdolling entity can't drop back into ordinary hitstun mid-air, so any
	# hit that connects while it's down there keeps it airborne instead
	elif hit.knockdown or state_machine.state == ragdoll_state:
		knock_down(dir * hit.knockback, hit.launch if hit.launch != 0.0 else JUGGLE_LAUNCH, source)
	else:
		state_machine.transition_to(hurt_state, {"dir": dir})

	Hitstop.freeze([source, self], hit.hitstop)
	if hit.knockdown:
		ScreenShake.shake_horizontal(12, 0.1, 12)

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
