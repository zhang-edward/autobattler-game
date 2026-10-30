class_name DodgeAbility
extends Ability

@export var duration := 0.4

func _init() -> void:
	weight = 0.0
	category = Category.DEFENSIVE
	ability_name = "Block"