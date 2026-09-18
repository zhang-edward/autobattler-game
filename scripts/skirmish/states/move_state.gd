class_name MoveState
extends SkirmishState

@export var jump_state: JumpState
@export var punch_state: PunchState

func physics_update(_delta: float) -> void:
	var direction_x = Input.get_axis("move_left", "move_right")
	var direction_y = Input.get_axis("move_up", "move_down")
	fighter.absolute_velocity = Vector2(direction_x, direction_y) * fighter.move_speed

	if fighter.z == 0 and Input.is_action_just_pressed("jump"):
		state_machine.transition_to(jump_state)

func update(_delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		state_machine.transition_to(punch_state)
