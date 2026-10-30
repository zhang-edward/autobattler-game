class_name RapidJabAbility
extends Ability

@export var jab_interval := 0.12
@export var recovery_time := 0.3

func _init() -> void:
	weight = 10.0
	category = Category.OFFENSIVE
	ability_name = "Rapid Jab"
