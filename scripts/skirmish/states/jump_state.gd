class_name JumpState
extends SkirmishState

const JUMP_VELOCITY = 500

@export var fall_state: FallState

func enter(_msg := {}) -> void:
	e.z_velocity = - JUMP_VELOCITY

func physics_update(delta: float) -> void:
	e.absolute_velocity = movement_direction() * e.move_speed

	e.z += e.z_velocity * delta
	e.z_velocity += SkirmishEntity.GRAVITY * delta

	if e.z_velocity >= 0:
		state_machine.transition_to(fall_state)
