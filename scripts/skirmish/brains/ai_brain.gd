class_name AIBrain
extends Brain

const TIER_WEIGHTS := {
	Ability.Tier.LIGHT: 10.0,
	Ability.Tier.MEDIUM: 5.0,
	Ability.Tier.HEAVY: 2.0,
}
# TUNE: the move used last is this much less likely to be picked again, so
# heroes mix up their moves instead of repeating one.
const REPEAT_WEIGHT := 0.25

@export var state_machine: StateMachine

## The move this hero used most recently (set by MoveState).
var last_ability: Ability

var target: SkirmishEntity

func get_intent(delta: float) -> Intent:
	return (state_machine.state as BrainState).get_intent(delta)

func draw_weighted() -> Ability:
	return pick_weighted(ready_abilities())

## Moves have no cooldowns, so every move is ready, except projectiles
## while this hero already has one on screen.
func ready_abilities() -> Array[Ability]:
	var abilities: Array[Ability] = []
	var projectile_out := entity.has_projectile_out()
	for ability in entity.entity_config.abilities:
		if ability != null and not (projectile_out and ability is ProjectileAbility):
			abilities.append(ability)
	return abilities

func pick_weighted(abilities: Array[Ability]) -> Ability:
	if abilities.is_empty():
		return null

	var total := 0.0
	for ability in abilities:
		total += _weight(ability)

	var roll := randf() * total
	for ability in abilities:
		var weight := _weight(ability)
		if roll < weight:
			return ability
		roll -= weight
	return abilities[abilities.size() - 1]

func _weight(ability: Ability) -> float:
	var weight: float = TIER_WEIGHTS[ability.tier]
	if ability == last_ability:
		weight *= REPEAT_WEIGHT
	return weight

func nearest_opponent() -> SkirmishEntity:
	if not is_instance_valid(target) or target.is_dead or not target.is_active:
		target = _closest_opponent()
	return target

func pick_target(target_range: float) -> void:
	var in_range := opponents().filter(func(other): return entity.global_position.distance_to(other.global_position) <= target_range)
	target = in_range.pick_random() if not in_range.is_empty() else null

func opponents() -> Array[SkirmishEntity]:
	var found: Array[SkirmishEntity] = []
	for node in entity.get_parent().get_children():
		var other := node as SkirmishEntity
		if other == null or other == entity or other.is_dead or not other.is_active or other.side == entity.side:
			continue
		found.append(other)
	return found

func _closest_opponent() -> SkirmishEntity:
	var nearest: SkirmishEntity = null
	var nearest_dist := INF
	for other in opponents():
		var dist := entity.global_position.distance_squared_to(other.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = other
	return nearest
