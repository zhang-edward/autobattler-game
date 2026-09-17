@tool
class_name AssignDirection
extends ActionLeaf

# Pick a random direction every TTL seconds
static var DIRECTION_TTL = 2000
static var DIRECTION_KEY = "direction"
static var DIRECTION_TS_KEY = "dir_last_updated_ts"

var directions = [
	Vector2.UP,
	Vector2.DOWN,
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2(-1, -1), # North west
	Vector2(-1, 1), # South west
	Vector2(1, -1), # North east
	Vector2(1, 1) # South east
]

func tick(actor: Node, blackboard: Blackboard) -> int:
	var dir = blackboard.get_value(DIRECTION_KEY)
	if dir == null:
		update_direction(blackboard)
	else:
		var direction_ts = blackboard.get_value(DIRECTION_TS_KEY)
		if Time.get_ticks_msec() - direction_ts > DIRECTION_TTL:
			update_direction(blackboard)
	return SUCCESS
		
func update_direction(blackboard: Blackboard):
	blackboard.set_value(DIRECTION_KEY, directions.pick_random())
	blackboard.set_value(DIRECTION_TS_KEY, Time.get_ticks_msec())
