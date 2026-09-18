@tool
class_name IsHeroDetected
extends ConditionLeaf

static var VISION_RADIUS = 300
static var DETECTED_HERO_KEY = "DETECTED_HERO"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if blackboard.get_value(DETECTED_HERO_KEY) != null:
		var h = blackboard.get_value(DETECTED_HERO_KEY) as HeroTacticalEntity
		if !is_instance_valid(h) or h.health_bar.value == 0:
			blackboard.set_value(DETECTED_HERO_KEY, null)
			return FAILURE
		else:
			return SUCCESS
	var villain = actor as VillainTacticalEntity
	var closest_hero = get_closest_hero(villain) as HeroTacticalEntity
	if closest_hero == null or !is_instance_valid(closest_hero):
		return FAILURE
	var dist_to_villain = closest_hero.global_position.distance_to(villain.global_position)
	if dist_to_villain <= VISION_RADIUS:
		blackboard.set_value(DETECTED_HERO_KEY, closest_hero)
		return SUCCESS
	return FAILURE
	
func get_closest_hero(villain: VillainTacticalEntity):
	var min_dist = INF
	var closest_hero: HeroTacticalEntity
	var all_living_heroes = villain.game.hero_entities.filter(func (h: HeroTacticalEntity): return is_instance_valid(h) and h.health_bar.value > 0)
	for h in all_living_heroes:
		var hero = h as HeroTacticalEntity
		var dist = villain.global_position.distance_to(hero.global_position)
		if dist < min_dist:
			min_dist = dist
			closest_hero = hero
	return closest_hero
