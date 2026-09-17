@tool
class_name AttackCivilian
extends ActionLeaf

func tick(actor: Node, blackboard: Blackboard) -> int:
	var villain = actor as VillainTacticalEntity
	villain.velocity = Vector2.ZERO
	return SUCCESS
