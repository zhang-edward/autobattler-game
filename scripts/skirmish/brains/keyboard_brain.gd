class_name KeyboardBrain
extends Brain

func get_intent(_delta: float) -> Intent:
	if Input.is_action_just_pressed("attack"):
		var punch := Intent.new()
		punch.ability = _first_offensive_ability()
		return punch

	var movement := Intent.new()
	movement.direction = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	movement.jump = Input.is_action_just_pressed("jump")
	return movement

func _first_offensive_ability() -> Ability:
	if entity != null and entity.entity_config != null:
		for ability in entity.entity_config.abilities:
			if ability != null and ability.category == Ability.Category.OFFENSIVE:
				return ability
	return null
