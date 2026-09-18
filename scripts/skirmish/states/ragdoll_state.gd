class_name RagdollState
extends SkirmishState

"""
Knocked-down entity: a physics object that tumbles across the floor plane and
bowls over other entities.

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

@export_group("Chaining")
# A ragdoll has to be moving at least this fast to knock over an entity it slams into
@export var chain_min_speed := 220.0
# Fraction of its speed handed to that entity
@export var chain_transfer := 0.6
@export var chain_launch := -220.0

const SPIN_SPEED := TAU * 2

var phase: Phase
var spin := 0.0
var downed_timer := 0.0
# Entities already bowled over by the current launch, so two ragdolls touching can't relaunch each other
var _chained := {}

func enter(msg := {}) -> void:
	relaunch(msg.get("impulse", Vector2.ZERO), msg.get("launch", 0.0))

# Applied on a fresh knockdown, and again on every hit that lands mid-ragdoll
func relaunch(impulse: Vector2, launch: float) -> void:
	fighter.absolute_velocity = impulse
	fighter.z_velocity = launch
	_chained.clear()
	spin = SPIN_SPEED * (1.0 if impulse.x >= 0.0 else -1.0)
	# Reset hurtbox if previously lying down
	if not fighter.is_dead:
		fighter.hurtbox.set_deferred("monitorable", true)
	_enter_phase(Phase.AIRBORNE)

func physics_update(delta: float) -> void:
	match phase:
		Phase.AIRBORNE:
			fighter.z_velocity += SkirmishEntity.GRAVITY * gravity_scale * delta
			fighter.z += fighter.z_velocity * delta
			fighter.absolute_velocity = fighter.absolute_velocity.move_toward(Vector2.ZERO, air_drag * delta)
			fighter.sprite.rotation += spin * delta
			if fighter.z >= 0.0 and fighter.z_velocity > 0.0:
				_land()
		Phase.SLIDING:
			fighter.absolute_velocity = fighter.absolute_velocity.move_toward(Vector2.ZERO, ground_friction * delta)
			if fighter.absolute_velocity.length() <= settle_speed:
				fighter.absolute_velocity = Vector2.ZERO
				_enter_phase(Phase.DOWNED)
		_:
			fighter.absolute_velocity = Vector2.ZERO

	if phase == Phase.AIRBORNE or phase == Phase.SLIDING:
		_bowl_over_others()

func update(delta: float) -> void:
	if phase == Phase.DOWNED:
		downed_timer -= delta
		if downed_timer <= 0.0:
			state_machine.transition_to(move_state)

func _enter_phase(next_phase: Phase) -> void:
	phase = next_phase
	match phase:
		Phase.SLIDING:
			fighter.sprite.rotation = 0.0
		Phase.DOWNED:
			downed_timer = downed_seconds
			# Downed entities are safe until they're back in play
			fighter.hurtbox.set_deferred("monitorable", false)
			if fighter.is_dead:
				fighter.despawn()

func _land() -> void:
	fighter.z = 0.0

	if fighter.z_velocity >= min_bounce_speed:
		fighter.z_velocity *= -floor_restitution
		fighter.absolute_velocity *= floor_skid_retention
		Hitstop.freeze([fighter], 0.04)
		return

	fighter.z_velocity = 0.0
	_enter_phase(Phase.SLIDING)

func _bowl_over_others() -> void:
	var speed := fighter.absolute_velocity.length()
	if speed < chain_min_speed:
		return

	for i in fighter.get_slide_collision_count():
		var other := fighter.get_slide_collision(i).get_collider()
		if other is not SkirmishEntity or _chained.has(other):
			continue

		_chained[other] = true
		var offset: Vector2 = other.global_position - fighter.global_position
		var dir := Vector2(offset.x, offset.y / IsometryUtils.DEPTH_SCALE).normalized()
		if dir == Vector2.ZERO:
			dir = fighter.absolute_velocity.normalized()

		other.knock_down(dir * speed * chain_transfer, chain_launch)
		fighter.absolute_velocity *= 1.0 - (chain_transfer / 2.0)
		Hitstop.freeze([fighter, other], 0.06)

func exit() -> void:
	fighter.absolute_velocity = Vector2.ZERO
	fighter.z = 0.0
	fighter.z_velocity = 0.0
	fighter.sprite.rotation = 0.0
	fighter.hurtbox.set_deferred("monitorable", true)
