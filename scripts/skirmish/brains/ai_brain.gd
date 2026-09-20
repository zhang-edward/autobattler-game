class_name AIBrain
extends Brain

"""
Closes on the nearest opponent, holds at preferred_distance, and once in range picks
punch / block / grab from a weighted bag.
"""

@export_group("Approach")
@export var preferred_distance := 50.0
@export var deadzone := 20.0

@export_group("Action weights")
@export var punch_weight := 5.0
@export var block_weight := 3.0
@export var grab_weight := 2.0

@export_group("Timing")
# Pause between arriving in range and committing to an action
@export var reaction_time := 0.2
@export var min_block_duration := 1.0
@export var max_block_duration := 2.0

var _reaction_timer := 0.0

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
		_reaction_timer = reaction_time
		return _movement(to_target.normalized(), facing)

	if distance < preferred_distance - deadzone:
		_reaction_timer = reaction_time
		return _movement(-to_target.normalized(), facing)

	# In range: stand still until the reaction timer runs out, then act
	_reaction_timer -= delta
	if _reaction_timer > 0.0:
		return _movement(Vector2.ZERO, facing)

	_reaction_timer = reaction_time
	return _pick_action(facing)

func _movement(direction: Vector2, facing: float) -> MovementIntent:
	var intent := MovementIntent.new()
	intent.direction = direction
	intent.facing = facing
	return intent

func _pick_action(facing: float) -> ActionIntent:
	var intent := ActionIntent.new()
	intent.facing = facing
	intent.action = _draw_weighted()
	if intent.action == ActionIntent.Action.BLOCK:
		intent.duration = randf_range(min_block_duration, max_block_duration)
	return intent

func _draw_weighted() -> ActionIntent.Action:
	var total := punch_weight + block_weight + grab_weight
	if total <= 0.0:
		return ActionIntent.Action.PUNCH

	var roll := randf() * total
	if roll < punch_weight:
		return ActionIntent.Action.PUNCH
	roll -= punch_weight
	if roll < block_weight:
		return ActionIntent.Action.BLOCK
	return ActionIntent.Action.GRAB

func _nearest_opponent() -> SkirmishEntity:
	var nearest: SkirmishEntity = null
	var nearest_dist := INF
	for node in entity.get_parent().get_children():
		var other := node as SkirmishEntity
		if other == null or other == entity or other.is_dead or other.entity_type == entity.entity_type:
			continue
		var dist := entity.global_position.distance_squared_to(other.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = other
	return nearest
