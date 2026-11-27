class_name RapidJabAbility
extends Ability

@export var jab_interval := 0.12
## TUNE: how many jabs in the flurry. Each one's hitstun outlasts the gap to
## the next, so once the first lands they all do.
@export var jab_count := 6
@export var hitbox: HitboxConfig

func _init() -> void:
	ability_name = "Rapid Jab"
