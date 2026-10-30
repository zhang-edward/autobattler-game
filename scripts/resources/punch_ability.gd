class_name PunchAbility
extends Ability

# The two jabs are ordinary hits; the finisher knocks them down and sends them skidding
@export var hits: Array[HitConfig] = [
	HitConfig.create(20),
	HitConfig.create(20),
	HitConfig.create(30, 450.0, -350.0, true, 0.12),
]
@export var combo_anims: Array[String] = [
	"male-rig/frontarm_jab",
	"male-rig/backarm_jab",
	"male-rig/backarm_uppercut",
]
@export var recovery_times: Array[float] = [0.4, 0.4, 0.4]
@export var buffer_window := 0.2

func _init() -> void:
	weight = 5.0
	category = Category.OFFENSIVE
	ability_name = "Punch"
