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

@export_group("Physics")
# Ragdolls fall faster than the entity gravity, so hangtime doesn't drag
@export var gravity_scale := 1.0
# Fraction of altitude speed kept per floor bounce
@export var floor_restitution := 0.45
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

const SPIN_SPEED := TAU * 2

var phase: Phase
var spin := 0.0
var downed_timer := 0.0

func enter(msg := {}) -> void:
	relaunch(msg.get("impulse", Vector2.ZERO), msg.get("launch", 0.0))

# Applied on a fresh knockdown, and again on every hit that lands mid-ragdoll
func relaunch(impulse: Vector2, launch: float) -> void:
	e.absolute_velocity = impulse
	e.z_velocity = launch
	spin = SPIN_SPEED * (1.0 if impulse.x >= 0.0 else -1.0)
	# Reset hurtbox if previously lying down
	if not e.is_dead:
		e.hurtbox.set_deferred("monitorable", true)
	_enter_phase(Phase.AIRBORNE)

func physics_update(delta: float) -> void:
	match phase:
		Phase.AIRBORNE:
			e.z_velocity += SkirmishEntity.GRAVITY * gravity_scale * delta
			e.z += e.z_velocity * delta
			e.absolute_velocity = e.absolute_velocity.move_toward(Vector2.ZERO, air_drag * delta)
			e.sprite.rotation += spin * delta
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
		Phase.SLIDING:
			e.sprite.rotation = 0.0
		Phase.DOWNED:
			downed_timer = downed_seconds
			# Downed entities are safe until they're back in play
			e.hurtbox.set_deferred("monitorable", false)
			if e.is_dead:
				e.despawn()

func _land() -> void:
	e.z = 0.0

	if e.z_velocity >= min_bounce_speed:
		e.z_velocity *= -floor_restitution
		e.absolute_velocity *= floor_skid_retention
		Hitstop.freeze([e], 0.04)
		return

	e.z_velocity = 0.0
	_enter_phase(Phase.SLIDING)

func exit() -> void:
	e.absolute_velocity = Vector2.ZERO
	e.z = 0.0
	e.z_velocity = 0.0
	e.sprite.rotation = 0.0
	e.hurtbox.set_deferred("monitorable", true)
