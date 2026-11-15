class_name MeleeAbility
extends OffensiveAbility

@export var hitbox: HitboxConfig
@export var velocity := Vector2.ZERO
@export_range(0.0, 0.5) var friction := 0.0
