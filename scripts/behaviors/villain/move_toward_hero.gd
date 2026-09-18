@tool
class_name MoveTowardHero
extends ActionLeaf

func tick(actor: Node, blackboard: Blackboard) -> int:
	var villain = actor as VillainTacticalEntity
	var target_hero: HeroTacticalEntity = blackboard.get_value(IsHeroDetected.DETECTED_HERO_KEY)
	villain.velocity = villain.global_position.direction_to(target_hero.global_position) * villain.entity_config.ground_speed
	return RUNNING
