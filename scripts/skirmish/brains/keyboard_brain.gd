class_name KeyboardBrain
extends Brain

func get_intent(_delta: float) -> Intent:
	if Input.is_action_just_pressed("attack"):
		var punch := Intent.new()
		punch.move = _first_offensive_move()
		return punch

	var movement := Intent.new()
	movement.direction = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	movement.jump = Input.is_action_just_pressed("jump")
	return movement

func _first_offensive_move() -> Move:
	if entity != null and entity.entity_config != null:
		for move in entity.entity_config.moveset:
			if move != null and move.category == Move.Category.OFFENSIVE:
				return move
	return null
