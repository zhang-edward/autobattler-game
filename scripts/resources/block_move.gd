class_name BlockMove
extends Move

@export var duration := 0.4

func _init() -> void:
	weight = 0.0
	category = Category.DEFENSIVE
	move_name = "Block"
