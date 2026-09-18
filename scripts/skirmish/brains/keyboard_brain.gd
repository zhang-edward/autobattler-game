class_name KeyboardBrain
extends Brain

func get_intent(_delta: float) -> Intent:
	if Input.is_action_just_pressed("attack"):
		return ActionIntent.new()

	var movement := MovementIntent.new()
	movement.direction = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	movement.jump = Input.is_action_just_pressed("jump")
	return movement
