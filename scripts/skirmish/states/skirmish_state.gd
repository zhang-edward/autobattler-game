class_name SkirmishState
extends State

@onready var e: SkirmishEntity = entity as SkirmishEntity

func movement_direction() -> Vector2:
	return e.intent.direction if e.intent != null else Vector2.ZERO
