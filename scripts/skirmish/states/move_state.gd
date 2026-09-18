class_name MoveState
extends SkirmishState

@export var jump_state: JumpState
@export var punch_state: PunchState

func physics_update(_delta: float) -> void:
	if e.intent is ActionIntent:
		state_machine.transition_to(punch_state)
		return

	e.absolute_velocity = movement_direction() * e.move_speed

	var movement := e.intent as MovementIntent
	if e.z == 0 and movement != null and movement.jump:
		state_machine.transition_to(jump_state)
