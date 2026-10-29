class_name AIBrain
extends Brain

"""
Lines up on the nearest opponent's row, holds preferred_distance horizontally, and once in range picks
an OFFENSIVE ability from the entity's kit by weight. DEFENSIVE abilities (block)
are reaction-only and never picked.
"""

const Y_TOLERANCE := 0.2

@export_group("Approach")
@export var preferred_distance := 100.0
@export var deadzone := 20.0

@export_group("Timing")
@export var act_probability := 0.1


func get_intent(delta: float) -> Intent:
	var target := _nearest_opponent()
	if target == null:
		return null

	var to_target := target.global_position - entity.global_position
	# Face the target whatever else happens, so retreating doesn't turn the entity around
	var facing := signf(to_target.x)

	var direction := Vector2.ZERO
	# Line up on the target's row, since hits only land within Y_AXIS_HIT_RANGE
	if absf(to_target.y) > IsometryUtils.Y_AXIS_HIT_RANGE * Y_TOLERANCE:
		direction.y = signf(to_target.y)
	# Hold a horizontal gap
	var gap := absf(to_target.x)
	if gap > preferred_distance + deadzone:
		direction.x = facing
	elif gap < preferred_distance - deadzone:
		direction.x = - facing

	if direction != Vector2.ZERO:
		return _movement(direction.normalized(), facing)

	if randf() < act_probability:
		return _pick_action(facing)
	return _movement(Vector2.ZERO, facing)

func _movement(direction: Vector2, facing: float) -> Intent:
	var intent := Intent.new()
	intent.direction = direction
	intent.facing = facing
	return intent

func _pick_action(facing: float) -> Intent:
	var intent := Intent.new()
	intent.facing = facing
	intent.ability = _draw_weighted()
	return intent

func _draw_weighted() -> Ability:
	var candidates: Array[Ability] = []
	if entity != null and entity.entity_config != null:
		for ability in entity.entity_config.abilities:
			if ability != null and ability.category == Ability.Category.OFFENSIVE and ability.weight > 0.0:
				candidates.append(ability)
	if candidates.is_empty():
		return null

	var total := 0.0
	for ability in candidates:
		total += ability.weight
	if total <= 0.0:
		return candidates[0]

	var roll := randf() * total
	for ability in candidates:
		if roll < ability.weight:
			return ability
		roll -= ability.weight
	return candidates[candidates.size() - 1]

func _nearest_opponent() -> SkirmishEntity:
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
