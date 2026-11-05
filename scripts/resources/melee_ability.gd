class_name MeleeAbility
extends Ability

@export var hitbox: HitboxConfig
@export var velocity := Vector2.ZERO
@export_range(0.0, 0.5) var friction := 0.0

func _init() -> void:
	weight = 5.0
	category = Category.OFFENSIVE
