class_name RapidJabAbility
extends Ability

@export var jab_interval := 0.12
@export var hitbox: HitboxConfig

func _init() -> void:
	weight = 10.0
	ability_name = "Rapid Jab"
