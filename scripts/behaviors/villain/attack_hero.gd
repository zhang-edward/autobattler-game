@tool
class_name AttackHero
extends ActionLeaf

var timer: Timer

func tick(actor: Node, blackboard: Blackboard) -> int:
	var villain = actor as VillainTacticalEntity
	villain.velocity = Vector2.ZERO
	# TODO: Do nothing for now, will figure out skirmish transition logic later
	print("Attacked hero!")
	return SUCCESS
