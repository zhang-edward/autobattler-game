class_name VillainTacticalEntity
extends TacticalEntity

@onready var debug_behavior_label: Label = $DebugBehaviorLabel
@onready var villain_btree: BeehaveTree = $VillainBehavior

func configure_from_entity_config(ec: EntityConfig):
	super.configure_from_entity_config(ec)
	sprite.self_modulate = Color(1, 0, 0)

func is_overlapping_civilian(civ: CivilianTacticalEntity):
	var overlapping_areas = entity_detector.get_overlapping_areas()
	for a in overlapping_areas:
		if a.get_parent() == civ:
			return true
	return false

func is_overlapping_hero(hero: HeroTacticalEntity):
	var overlapping_areas = entity_detector.get_overlapping_areas()
	for a in overlapping_areas:
		if a.get_parent() == hero:
			return true
	return false

func _process(delta: float) -> void:
	debug_behavior_label.text = villain_btree.blackboard.get_value(AssignBehavior.BEHAVIOR_KEY)
