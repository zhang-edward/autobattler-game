@tool
class_name IsInRange
extends ConditionLeaf

func tick(actor: Node, blackboard: Blackboard):
	var villain = actor as VillainTacticalEntity
	var target_civ = blackboard.get_value(IsCivilianDetected.DETECTED_CIV_KEY)
	return SUCCESS if villain.is_overlapping_civilian(target_civ) else FAILURE
