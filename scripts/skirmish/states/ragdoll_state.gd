class_name RagdollState
extends SkirmishState

"""
Knocked-down entity: a physics object that tumbles across the floor plane.

Not a RigidBody2D on purpose. Screen-Y is a depth axis here (squashed by
IsometryUtils.DEPTH_SCALE) and altitude is faked in SkirmishEntity.z, so Godot's 2D
gravity would pull bodies toward the front of the screen instead of down. We integrate
the three axes ourselves and let move_and_slide() handle only the floor-plane collisions.
"""

enum Phase {AIRBORNE, SLIDING, DOWNED}

@export var move_state: MoveState
@export var grab_state: GrabState

@export_group("Physics")
# Ragdolls fall faster than the entity gravity, so hangtime doesn't drag
@export var gravity_scale := 1.0
# Fraction of altitude speed kept per floor bounce
@export var floor_restitution := 0.65
# Fraction of floor-plane speed kept when hitting the floor
@export var floor_skid_retention := 0.8
@export var air_drag := 40.0
@export var ground_friction := 400.0
# Below this altitude speed, stop bouncing and start sliding
@export var min_bounce_speed := 300.0
# Below this floor speed, stop sliding and lie down
@export var settle_speed := 40.0

@export_group("Timing")
@export var downed_seconds := 0.5

const ANIM_THROWN := "male-rig/is_thrown"
const ANIM_SLAM := "male-rig/ground_slam1"
const ANIM_BOUNCE := "male-rig/bounce"
const ANIM_CRUMPLE := "male-rig/ground_crumple"
# How long the slam pose shows after an impact that bounces, before switching to ANIM_BOUNCE
const BOUNCE_ANIM_DELAY := 0.12

var phase: Phase
var downed_timer := 0.0
# > 0 while a bounce animation is pending. Driven by the state, not the animation player,
# so a long or looping slam animation can't hold it up.
var _bounce_anim_timer := 0.0
var thrower_entity: SkirmishEntity

func enter(msg := {}) -> void:
	relaunch(msg.get("impulse", Vector2.ZERO), msg.get("launch", 0.0))
	thrower_entity = msg["thrower"]

# Applied on a fresh knockdown, and again on every hit that lands mid-ragdoll
func relaunch(impulse: Vector2, launch: float) -> void:
	e.absolute_velocity = impulse
	e.z_velocity = launch
	# Reset hurtbox if previously lying down
	if not e.is_dead:
		e.hurtbox.set_deferred("monitorable", true)
	_enter_phase(Phase.AIRBORNE)
	_bounce_anim_timer = 0.0
	e.rig.play_animation(ANIM_THROWN)

func physics_update(delta: float) -> void:
	match phase:
		Phase.AIRBORNE:
			if _bounce_anim_timer > 0.0:
				_bounce_anim_timer -= delta
				if _bounce_anim_timer <= 0.0:
					e.rig.play_animation(ANIM_BOUNCE)
			e.z_velocity += SkirmishEntity.GRAVITY * gravity_scale * delta
			e.z += e.z_velocity * delta
			e.absolute_velocity = e.absolute_velocity.move_toward(Vector2.ZERO, air_drag * delta)
			if e.z >= 0.0 and e.z_velocity > 0.0:
				_land()
		Phase.SLIDING:
			e.absolute_velocity = e.absolute_velocity.move_toward(Vector2.ZERO, ground_friction * delta)
			if e.absolute_velocity.length() <= settle_speed:
				e.absolute_velocity = Vector2.ZERO
				_enter_phase(Phase.DOWNED)
		_:
			e.absolute_velocity = Vector2.ZERO

func update(delta: float) -> void:
	if phase == Phase.DOWNED:
		downed_timer -= delta
		if downed_timer <= 0.0:
			state_machine.transition_to(move_state)

func _enter_phase(next_phase: Phase) -> void:
	phase = next_phase
	match phase:
		Phase.DOWNED:
			downed_timer = downed_seconds
			# Downed entities are safe until they're back in play
			e.hurtbox.set_deferred("monitorable", false)
			if e.is_dead:
				e.despawn()

func _land() -> void:
	e.z = 0.0

	if e.z_velocity >= min_bounce_speed:
		e.rig.play_animation(ANIM_SLAM)
		e.healthbar.value -= HitConfig.calculate_damage(grab_state.hit.damage, thrower_entity.entity_config.attack, e.entity_config.defense)
		e.z_velocity *= -floor_restitution
		e.absolute_velocity *= floor_skid_retention
		# The bounce launch happens this same frame, so show the slam for a beat
		# before physics_update switches to the bounce animation
		_bounce_anim_timer = BOUNCE_ANIM_DELAY
		Hitstop.freeze([e], 0.04)
		return

	# Final impact: nothing left to bounce, so the body crumples instead of slamming
	e.rig.play_animation(ANIM_CRUMPLE)
	_bounce_anim_timer = 0.0
	e.z_velocity = 0.0
	_enter_phase(Phase.SLIDING)

func exit() -> void:
	_bounce_anim_timer = 0.0
	e.absolute_velocity = Vector2.ZERO
	e.z = 0.0
	e.z_velocity = 0.0
	e.hurtbox.set_deferred("monitorable", true)
