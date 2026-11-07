class_name ProjectileAbility
extends Ability

@export var hit: HitConfig = HitConfig.create(20, 200.0, 0.0, false, Hitstop.DEFAULT_DURATION, HitConfig.Kind.PROJECTILE)
@export var active_duration := 0.2
@export var velocity := Vector2.ZERO
@export_range(0.0, 0.5) var friction := 0.0
@export var speed := 500.0
@export var lifespan := 1.2
@export var hitbox_size := Vector2(30, 30)
@export var projectile_scene: PackedScene

func _init() -> void:
	ability_name = "Energy Blast"
	ability_range = 300.0
