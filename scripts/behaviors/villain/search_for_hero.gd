@tool
class_name SearchForHero
extends ActionLeaf

func tick(actor: Node, blackboard: Blackboard) -> int:
	var villain = actor as VillainTacticalEntity
	var direction = blackboard.get_value(AssignDirection.DIRECTION_KEY)
	villain.velocity = direction * villain.entity_config.ground_speed
	return RUNNING
