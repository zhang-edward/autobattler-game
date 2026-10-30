class_name GrabAbility
extends Ability

@export var hit: HitConfig = HitConfig.create(15, 180.0, -220.0, true, 0.12, HitConfig.Kind.GRAB)
@export var recovery_time := 1.0
@export var grab_size := Vector2(72, 72)
@export var active_time := 0.15
@export var throw_speed := 400.0
@export var throw_launch := -500.0
@export var throw_delay := 1.0
## Throw state scene instantiated alongside the grab state at spawn.
@export var throw_state_scene: PackedScene

func _init() -> void:
	weight = 2.0
	category = Category.OFFENSIVE
	ability_name = "Grab"
