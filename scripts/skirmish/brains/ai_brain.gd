class_name AIBrain
extends Brain

const TIER_WEIGHTS := {
	Ability.Tier.LIGHT: 10.0,
	Ability.Tier.MEDIUM: 5.0,
	Ability.Tier.HEAVY: 2.0,
}
const FLEE_HEALTH_FRACTION := 1.0 / 3.0
const FLEE_CHANCE := 0.25

@export var state_machine: StateMachine
@export var fleeing_brain_state: FleeingBrainState

var target: SkirmishEntity

func _ready() -> void:
	entity.took_hit.connect(_on_took_hit)

func _on_took_hit() -> void:
	if entity.entity_type != EntityConfig.EntityType.VILLAIN or state_machine.state == fleeing_brain_state:
		return
	if entity.entity_config.curr_health <= entity.entity_config.get_max_health() * FLEE_HEALTH_FRACTION and randf() < FLEE_CHANCE:
		state_machine.transition_to(fleeing_brain_state)

func get_intent(delta: float) -> Intent:
	return (state_machine.state as BrainState).get_intent(delta)

func draw_weighted() -> Ability:
	return pick_weighted(ready_abilities())

func ready_abilities() -> Array[Ability]:
	var abilities: Array[Ability] = []
	for ability in entity.entity_config.abilities:
		if ability != null and entity.ability_cooldowns.get(ability, 0.0) <= 0.0:
			abilities.append(ability)
	return abilities

func pick_weighted(abilities: Array[Ability]) -> Ability:
	if abilities.is_empty():
		return null

	var total := 0.0
	for ability in abilities:
		total += TIER_WEIGHTS[ability.tier]

	var roll := randf() * total
	for ability in abilities:
		var weight: float = TIER_WEIGHTS[ability.tier]
		if roll < weight:
			return ability
		roll -= weight
	return abilities[abilities.size() - 1]

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
		if other == null or other == entity or other.is_dead or not other.is_active or other.entity_type == entity.entity_type:
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
