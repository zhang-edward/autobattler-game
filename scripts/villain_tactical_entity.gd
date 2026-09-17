class_name VillainTacticalEntity
extends TacticalEntity

func configure_from_entity_config(ec: EntityConfig):
	super.configure_from_entity_config(ec)
	sprite.self_modulate = Color(1, 0, 0)

func is_overlapping_civilian(civ: CivilianTacticalEntity):
	var overlapping_areas = entity_detector.get_overlapping_areas()
	for a in overlapping_areas:
		if a.get_parent() == civ:
			return true
	return false
