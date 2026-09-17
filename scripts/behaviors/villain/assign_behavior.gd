@tool
class_name AssignBehavior
extends ActionLeaf

static var BEHAVIOR_KEY = "assigned_behavior"
static var HUNT_CIVILIAN = "hunt_civilian"
static var HUNT_HERO = "hunt_hero"

func tick(_actor: Node, blackboard: Blackboard) -> int:
	if blackboard.get_value(AssignBehavior.BEHAVIOR_KEY) == null:
		var behavior = AssignBehavior.HUNT_CIVILIAN
		blackboard.set_value(AssignBehavior.BEHAVIOR_KEY, behavior)
	return SUCCESS
