@tool
class_name IsHeroInRange
extends ConditionLeaf

func tick(actor: Node, blackboard: Blackboard):
	var villain = actor as VillainTacticalEntity
	var target_hero = blackboard.get_value(IsHeroDetected.DETECTED_HERO_KEY)
	return SUCCESS if villain.is_overlapping_hero(target_hero) else FAILURE
