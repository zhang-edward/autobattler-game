class_name AIBrain
extends Brain

"""
Closes on the nearest opponent, holds at preferred_distance, and once in range picks
an OFFENSIVE move from the entity's moveset by weight. DEFENSIVE moves (block)
are reaction-only and never picked.
"""

@export_group("Approach")
@export var preferred_distance := 100.0
@export var deadzone := 20.0

@export_group("Timing")
@export var act_probability := 0.1


func get_intent(delta: float) -> Intent:
	var target := _nearest_opponent()
	if target == null:
		return null

	# Vector from this entity to its target. Screen y is drawn squashed, so undo that
	# to measure distance on the floor plane.
	var to_target := target.global_position - entity.global_position
	to_target.y /= IsometryUtils.DEPTH_SCALE
	var distance := to_target.length()
	# Face the target whatever else happens, so retreating doesn't turn the entity around
	var facing := signf(to_target.x)

	if distance > preferred_distance + deadzone:
		return _movement(to_target.normalized(), facing)

	if distance < preferred_distance - deadzone:
		return _movement(-to_target.normalized(), facing)

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
	intent.move = _draw_weighted()
	return intent

func _draw_weighted() -> Move:
	var candidates: Array[Move] = []
	if entity != null and entity.entity_config != null:
		for move in entity.entity_config.moveset:
			if move != null and move.category == Move.Category.OFFENSIVE and move.weight > 0.0:
				candidates.append(move)
	if candidates.is_empty():
		return null

	var total := 0.0
	for move in candidates:
		total += move.weight
	if total <= 0.0:
		return candidates[0]

	var roll := randf() * total
	for move in candidates:
		if roll < move.weight:
			return move
		roll -= move.weight
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
