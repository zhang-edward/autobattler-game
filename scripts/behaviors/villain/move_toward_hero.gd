@tool
class_name MoveTowardHero
extends ActionLeaf

func tick(actor: Node, blackboard: Blackboard) -> int:
	var villain = actor as VillainTacticalEntity
	var target_hero: HeroTacticalEntity = blackboard.get_value(IsHeroDetected.DETECTED_HERO_KEY)
	villain.navigation_agent.target_position = target_hero.global_position
	var next_path_pos: Vector2 = villain.navigation_agent.get_next_path_position()
	villain.velocity = villain.global_position.direction_to(next_path_pos) * villain.entity_config.ground_speed
	return RUNNING
