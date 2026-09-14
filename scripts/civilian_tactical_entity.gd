class_name CivilianTacticalEntity
extends TacticalEntity

func _ready() -> void:
	sprite.self_modulate = Color(0, 0, 1)
	var health = randi_range(75, 125)
	health_bar.max_value = health
	health_bar.value = health
