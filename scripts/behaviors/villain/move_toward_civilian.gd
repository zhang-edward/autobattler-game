@tool
class_name MoveTowardCivilian
extends ActionLeaf

func tick(actor: Node, blackboard: Blackboard) -> int:
	var villain = actor as VillainTacticalEntity
	var target_civilian: CivilianTacticalEntity = blackboard.get_value(IsCivilianDetected.DETECTED_CIV_KEY)
	villain.velocity = villain.global_position.direction_to(target_civilian.global_position) * villain.entity_config.ground_speed
	return RUNNING
