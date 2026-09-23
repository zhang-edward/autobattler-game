@tool
class_name Search
extends ActionLeaf

var DIST_THRESHOLD = 5

func tick(actor: Node, blackboard: Blackboard) -> int:
	var villain = actor as VillainTacticalEntity
	var search_tile_pos = blackboard.get_value(AssignSearchDest.SEARCH_DEST_KEY)
	villain.navigation_agent.target_position = search_tile_pos
	var next_path_pos: Vector2 = villain.navigation_agent.get_next_path_position()
	if villain.global_position.distance_to(next_path_pos) <= DIST_THRESHOLD:
		villain.velocity = Vector2.ZERO
	else:
		villain.velocity = villain.global_position.direction_to(next_path_pos) * villain.entity_config.ground_speed	
	return RUNNING
