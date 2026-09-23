@tool
class_name AssignBehavior
extends ActionLeaf

static var BEHAVIOR_KEY = "assigned_behavior"
static var BEHAVIOR_UPDATED_TS = "behavior_updated_ts"
static var HUNT_CIVILIAN = "hunt_civilian"
static var HUNT_HERO = "hunt_hero"
static var BEHAVIOR_TTL = 10000

func tick(_actor: Node, blackboard: Blackboard) -> int:
	if blackboard.get_value(AssignBehavior.BEHAVIOR_KEY) == null:
		update_assigned_behavior(blackboard)
	else:
		var timestamp = blackboard.get_value(AssignBehavior.BEHAVIOR_UPDATED_TS)
		if Time.get_ticks_msec() - timestamp > BEHAVIOR_TTL:
			update_assigned_behavior(blackboard)
	return SUCCESS

func update_assigned_behavior(blackboard: Blackboard):
	# Debug: always hunt heroes
	var behavior = AssignBehavior.HUNT_HERO
	#var behavior = AssignBehavior.HUNT_HERO if randi_range(0, 1) == 0 else AssignBehavior.HUNT_CIVILIAN
	blackboard.set_value(AssignBehavior.BEHAVIOR_KEY, behavior)
	blackboard.set_value(AssignBehavior.BEHAVIOR_UPDATED_TS, Time.get_ticks_msec())
