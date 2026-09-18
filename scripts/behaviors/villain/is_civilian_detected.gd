@tool
class_name IsCivilianDetected
extends ConditionLeaf

static var VISION_RADIUS = 300
static var DETECTED_CIV_KEY = "DETECTED_CIV"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if blackboard.get_value(DETECTED_CIV_KEY) != null:
		var c = blackboard.get_value(DETECTED_CIV_KEY) as CivilianTacticalEntity
		if !is_instance_valid(c) or c.health_bar.value == 0:
			blackboard.set_value(DETECTED_CIV_KEY, null)
			return FAILURE
		else:
			return SUCCESS
	var villain = actor as VillainTacticalEntity
	var closest_civilian = get_closest_civilian(villain) as CivilianTacticalEntity
	if closest_civilian == null or !is_instance_valid(closest_civilian):
		return FAILURE
	var dist_to_villain = closest_civilian.global_position.distance_to(villain.global_position)
	if dist_to_villain <= VISION_RADIUS:
		blackboard.set_value(DETECTED_CIV_KEY, closest_civilian)
		return SUCCESS
	return FAILURE
	
func get_closest_civilian(villain: VillainTacticalEntity):
	var min_dist = INF
	var closest_civ: CivilianTacticalEntity
	var all_living_civs = villain.game.civilian_entities.filter(func (c): return is_instance_valid(c) and c.health_bar.value > 0)
	for c in all_living_civs:
		var civ = c as CivilianTacticalEntity
		var dist = villain.global_position.distance_to(civ.global_position)
		if dist < min_dist:
			min_dist = dist
			closest_civ = civ
	return closest_civ
