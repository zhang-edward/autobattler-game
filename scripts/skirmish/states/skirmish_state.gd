class_name SkirmishState
extends State

@onready var e: SkirmishEntity = entity as SkirmishEntity

func movement_direction(delta: float) -> Vector2:
	var intent := e.brain.get_intent(delta)
	return intent.direction if intent != null else Vector2.ZERO
