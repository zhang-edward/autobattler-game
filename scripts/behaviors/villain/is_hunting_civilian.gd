@tool
class_name IsHuntingCivilian
extends ConditionLeaf

func tick(_actor: Node, blackboard: Blackboard) -> int:
	if blackboard.get_value(AssignBehavior.BEHAVIOR_KEY) != null:
		var behavior = blackboard.get_value(AssignBehavior.BEHAVIOR_KEY)
		return SUCCESS if behavior == AssignBehavior.HUNT_CIVILIAN else FAILURE
	return FAILURE
