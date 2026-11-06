class_name AIBrain
extends Brain

@export var state_machine: StateMachine

func get_intent(delta: float) -> Intent:
	return (state_machine.state as BrainState).get_intent(delta)

func draw_weighted() -> Ability:
	return pick_weighted(ready_abilities())

func ready_abilities() -> Array[Ability]:
	var abilities: Array[Ability] = []
	for ability in entity.entity_config.abilities:
		if ability != null and ability.weight > 0.0 \
				and entity.ability_cooldowns.get(ability, 0.0) <= 0.0:
			abilities.append(ability)
	return abilities

func pick_weighted(abilities: Array[Ability]) -> Ability:
	if abilities.is_empty():
		return null

	var total := 0.0
	for ability in abilities:
		total += ability.weight
	if total <= 0.0:
		return abilities[0]

	var roll := randf() * total
	for ability in abilities:
		if roll < ability.weight:
			return ability
		roll -= ability.weight
	return abilities[abilities.size() - 1]

func nearest_opponent() -> SkirmishEntity:
	var nearest: SkirmishEntity = null
	var nearest_dist := INF
	for node in entity.get_parent().get_children():
		var other := node as SkirmishEntity
		if other == null or other == entity or other.is_dead or not other.is_active or other.entity_type == entity.entity_type:
			continue
		var dist := entity.global_position.distance_squared_to(other.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = other
	return nearest
