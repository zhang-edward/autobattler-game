class_name CivilianTacticalEntity
extends TacticalEntity

@onready var save_civ_progress_label = $SaveCivProgressLabel as SaveCivProgressLabel

func _ready() -> void:
	sprite.self_modulate = Color(0, 0, 1)
	var health = randi_range(75, 125)
	health_bar.max_value = health
	health_bar.value = health
	save_civ_progress_label.on_save.connect(save_civilian)
	
func save_civilian():
	print("civilian saved!")
	queue_free()

func _process(delta: float) -> void:
	var areas = entity_detector.get_overlapping_areas()
	var is_overlapping_hero := false
	for a in areas:
		if a.get_parent() is HeroTacticalEntity:
			is_overlapping_hero = true
	if is_overlapping_hero:
		if !save_civ_progress_label.is_saving:
			save_civ_progress_label.show()
			save_civ_progress_label.start_save_timer()
	else:
		save_civ_progress_label.hide()
		save_civ_progress_label.stop_save_timer()
