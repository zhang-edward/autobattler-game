class_name RapidJabAbility
extends Ability

@export var jab_interval := 0.12
@export var hitbox: HitboxConfig

func _init() -> void:
	ability_name = "Rapid Jab"
