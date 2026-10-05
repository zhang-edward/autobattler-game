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
@export var punch_state: PunchState
@export var grab_state: GrabState
@export var ragdoll_state: RagdollState
@export var is_grabbed_state: IsGrabbedState
@export var block_state: BlockState
@export var brain: Brain:
	set(value):
		brain = value
		brain.entity = self

var entity_config: EntityConfig
var intent: Intent
var is_active := true
var skirmish: Skirmish

# Scales everything that advances time for this entity. 0 holds it still while leaving
# its nodes and collision shapes live, so a frozen fighter can still be hit.
var hitstop_scale := 1.0:
	set(value):
		hitstop_scale = value
		if state_machine != null:
			state_machine.time_scale = value

# Floor-plane velocity in absolute (pre-depth-scale) units. States write this;
# _physics_process scales it into `velocity` for move_and_slide().
var absolute_velocity := Vector2.ZERO

# Altitude: negative is up, 0 is the floor. Rendered by offsetting the sprite,
# which carries the hurtbox up with it.
var z := 0.0
var z_velocity := 0.0
var is_dead := false

var grabbed_entity

var _shadow_base_scale: Vector2

func _ready() -> void:
	if entity_config != null:
		healthbar.max_value = entity_config.max_health
		healthbar.value = entity_config.curr_health
	else:
		healthbar.value = healthbar.max_value
	_shadow_base_scale = shadow.scale
	rig.on_emit_hitbox_enable.connect(handle_hitbox_enable)
	
func handle_hitbox_enable():
	if state_machine.state == punch_state:
		var hit_config = punch_state.hits[punch_state.combo_index]
		match rig.anim_player.current_animation:
			"male-rig/frontarm_jab":
				var hitbox = hitbox_scene.instantiate() as Hitbox
				rig.front_fist.add_child(hitbox)
				hitbox.init(Vector2(0, 0), Vector2(40, 40), 0.2, self, hit_config)
			"male-rig/backarm_jab":
				var hitbox = hitbox_scene.instantiate() as Hitbox
				rig.back_fist.add_child(hitbox)
				hitbox.init(Vector2(0, 0), Vector2(40, 40), 0.3, self, hit_config)
			"male-rig/backarm_uppercut":
				var hitbox = hitbox_scene.instantiate() as Hitbox
				add_child(hitbox)
				hitbox.init(Vector2(0, 0), Vector2(40, 80), 0.3, self, hit_config)
				hitbox.global_position = rig.back_fist.global_position
	elif state_machine.state == grab_state:
		var hit_config = grab_state.hit
		if rig.anim_player.current_animation == "male-rig/grab":
			var hitbox = hitbox_scene.instantiate() as Hitbox
			rig.back_fist.add_child(hitbox)
			hitbox.init(Vector2(0, 0), Vector2(40, 40), 0.2, self, hit_config)
			hitbox.global_position = rig.back_fist.global_position

func configure_from_entity_config(ec: EntityConfig) -> void:
	entity_config = ec
	entity_type = ec.entity_type
	move_speed = ec.ground_speed
	healthbar.max_value = ec.max_health
	healthbar.value = ec.curr_health
	var layer_index = HERO_LAYER_INDEX if entity_type == EntityConfig.EntityType.HERO else VILLAIN_LAYER_INDEX
	set_collision_layer_value(layer_index, true)
	debug_name_label.text = entity_config.entity_name

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

func take_hit(hit: HitConfig, source: SkirmishEntity) -> void:
	if is_dead or not is_active:
		return

	var dir := Vector2(signf(position.x - source.position.x), 0.0)
	var blocking := state_machine.state == block_state

	# A grab only catches a guarding target; anyone else shrugs it off
	if hit.kind == HitConfig.Kind.GRAB and not blocking:
		return

	# A guard stops strikes, but a grab goes straight through it
	if blocking:
		if hit.kind == HitConfig.Kind.STRIKE:
			absolute_velocity = dir * BLOCK_PUSHBACK
			Hitstop.freeze([source, self], hit.hitstop)
			return
		elif hit.kind == HitConfig.Kind.GRAB:
			state_machine.transition_to(is_grabbed_state, {"grabber": source})
			source.grabbed_entity = self

	var damage = HitConfig.calculate_damage(hit.damage, source.entity_config.attack, entity_config.defense)
	source.entity_config.damage_dealt += hit.damage
	healthbar.value -= hit.damage
	if entity_config != null:
		entity_config.curr_health = int(healthbar.value)

	if healthbar.value <= 0:
		# deal the killing blow, so source entity gets a villain-defeated credit
		source.entity_config.defeated_villain_names.append(entity_config.entity_name)
		is_dead = true
		healthbar.hide()
		died.emit()
		state_machine.transition_to(death_state)
	# A ragdolling entity can't drop back into ordinary hitstun mid-air, so any
	# hit that connects while it's down there keeps it airborne instead
	elif hit.knockdown or state_machine.state == ragdoll_state:
		knock_down(dir * hit.knockback, hit.launch if hit.launch != 0.0 else JUGGLE_LAUNCH)
	else:
		state_machine.transition_to(hurt_state, {"dir": dir})

	Hitstop.freeze([source, self], hit.hitstop)
	if hit.knockdown:
		ScreenShake.shake_horizontal(12, 0.1, 12)

func knock_down(impulse: Vector2, launch: float) -> void:
	impulse.y += impulse.length() * randf_range(-KNOCKDOWN_Y_SPREAD, KNOCKDOWN_Y_SPREAD)

func despawn() -> void:
	var tween := create_tween()
	tween.tween_property(rig, "modulate:a", 0.0, 0.4)
	tween.parallel().tween_property(shadow, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
