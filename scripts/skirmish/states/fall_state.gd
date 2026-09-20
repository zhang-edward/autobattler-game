class_name FallState
extends SkirmishState

@export var move_state: MoveState

func physics_update(delta: float) -> void:
	e.absolute_velocity = movement_direction() * e.move_speed

	e.z += e.z_velocity * delta
	e.z_velocity += SkirmishEntity.GRAVITY * delta

	if e.z >= 0:
		e.z = 0
		e.z_velocity = 0
		state_machine.transition_to(move_state)
