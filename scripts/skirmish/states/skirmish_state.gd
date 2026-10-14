class_name SkirmishState
extends State

@onready var e: SkirmishEntity = entity as SkirmishEntity

func movement_direction() -> Vector2:
	var movement := e.intent as MovementIntent
	return movement.direction if movement != null else Vector2.ZERO
