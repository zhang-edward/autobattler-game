class_name SkirmishEntity
extends CharacterBody2D

# 2.5D beat-em-up entity. Screen Y is a depth axis (squashed by IsometryUtils.DEPTH_SCALE)
# and altitude is faked in `z`, so gravity is integrated by the states, not the physics engine.

const GRAVITY := 980.0

# Hits with no launch of their own still pop the target up by this much when it
# has to be knocked down anyway (a killing blow, or a re-hit while ragdolling)
const DEATH_LAUNCH := -260.0
const JUGGLE_LAUNCH := -300.0
const DEATH_KNOCKBACK_MIN := 260.0

@export var entity_type: EntityConfig.EntityType
@export var move_speed := 100.0
@export var sprite: Sprite2D
@export var shadow: Sprite2D
@export var healthbar: ProgressBar
@export var hurtbox: Hurtbox
@export var state_machine: StateMachine
@export var hurt_state: HurtState
@export var ragdoll_state: RagdollState

var entity_config: EntityConfig

# Floor-plane velocity in absolute (pre-depth-scale) units. States write this;
# _physics_process scales it into `velocity` for move_and_slide().
var absolute_velocity := Vector2.ZERO

# Altitude: negative is up, 0 is the floor. Rendered by offsetting the sprite,
# which carries the hurtbox up with it.
var z := 0.0
var z_velocity := 0.0
var is_dead := false

var _shadow_base_scale: Vector2
var _sprite_pivot: Vector2

func _ready() -> void:
	healthbar.value = healthbar.max_value
	_shadow_base_scale = shadow.scale
	# The sprite's origin sits at the bottom, so rotating the node alone would swing the body around
	# the bottom - define a pivot where the sprite's centre actually sits
	_sprite_pivot = sprite.offset * sprite.scale

func configure_from_entity_config(ec: EntityConfig) -> void:
	entity_config = ec
	entity_type = ec.entity_type
	move_speed = ec.ground_speed
	healthbar.max_value = ec.max_health
	healthbar.value = healthbar.max_value

func _physics_process(_delta: float) -> void:
	velocity = IsometryUtils.scale_velocity(absolute_velocity)
	move_and_slide()

func _process(_delta: float) -> void:
	# Altitude plus shift that keeps the sprite's centre planted when it spins
	sprite.position = Vector2(0.0, z) + _sprite_pivot - _sprite_pivot.rotated(sprite.rotation)
	shadow.scale = _shadow_base_scale * IsometryUtils.scale_shadow_from(z)
	if absolute_velocity.x != 0.0:
		sprite.flip_h = absolute_velocity.x < 0.0

func take_hit(hit: HitConfig, source: SkirmishEntity) -> void:
	if is_dead:
		return

	healthbar.value -= hit.damage
	var dir := Vector2(signf(position.x - source.position.x), 0.0)
	if dir.x == 0.0: # Directly on top of us; shove them the way the attacker faces
		dir.x = -1.0 if source.sprite.flip_h else 1.0

	if healthbar.value <= 0:
		is_dead = true
		healthbar.hide()
		# Corpses still fly. They despawn once the ragdoll settles.
		knock_down(
			dir * maxf(hit.knockback, DEATH_KNOCKBACK_MIN),
			hit.launch if hit.launch != 0.0 else DEATH_LAUNCH
		)
		return

	# A ragdolling entity can't drop back into ordinary hitstun mid-air, so any
	# hit that connects while it's down there keeps it airborne instead
	if hit.knockdown or state_machine.state == ragdoll_state:
		knock_down(dir * hit.knockback, hit.launch if hit.launch != 0.0 else JUGGLE_LAUNCH)
	else:
		state_machine.transition_to(hurt_state, {"dir": dir})

func knock_down(impulse: Vector2, launch: float) -> void:
	if state_machine.state == ragdoll_state:
		# Already ragdolling: relaunch in place rather than re-entering the state,
		# which would reset the altitude we're trying to add to
		ragdoll_state.relaunch(impulse, launch)
	else:
		state_machine.transition_to(ragdoll_state, {"impulse": impulse, "launch": launch})

func despawn() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
	tween.parallel().tween_property(shadow, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

func get_sprite_size() -> Vector2:
	return sprite.texture.get_size() * sprite.scale
