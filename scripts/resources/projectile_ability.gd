class_name ProjectileAbility
extends Ability

@export var hit: HitConfig = HitConfig.create(20, 200.0, 0.0, false, Hitstop.DEFAULT_DURATION, HitConfig.Kind.PROJECTILE)
@export var anim := "male-rig/frontarm_jab"
@export var release_delay := 0.15
@export var recovery_time := 0.5
@export var speed := 500.0
@export var lifespan := 1.2
@export var hitbox_size := Vector2(30, 30)
@export var projectile_scene: PackedScene

func _init() -> void:
	weight = 5.0
	category = Category.OFFENSIVE
	ability_name = "Energy Blast"
	ability_range = 300.0
