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
# Swap to a benched teammate this much healthier (health fraction) than self
const TAG_HEALTH_MARGIN := 0.2

var _reaction_timer := 0.0

func get_intent(delta: float) -> Intent:
	# Voluntary tags come from Move only; Skirmish.tag() re-validates (grab lock).
	if entity.is_active and entity.skirmish != null and entity.state_machine != null and entity.state_machine.state is MoveState:
		var mate := _healthier_benchmate()
		if mate != null:
			var tag := TagIntent.new()
			tag.target = mate
			var opp := _nearest_opponent()
			if opp != null:
				tag.facing = signf((opp.global_position - entity.global_position).x)
			return tag
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
		if other == null or other == entity or other.is_dead or not other.is_active or other.entity_type == entity.entity_type:
			continue
		var dist := entity.global_position.distance_squared_to(other.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = other
	return nearest

func _healthier_benchmate() -> SkirmishEntity:
	if entity.skirmish == null or entity.entity_config == null:
		return null
	var my_frac := float(entity.entity_config.curr_health) / float(maxi(entity.entity_config.max_health, 1))
	var best: SkirmishEntity = null
	var best_frac := -1.0
	for mate in entity.skirmish.team_for(entity.entity_type):
		if mate == null or not is_instance_valid(mate) or mate == entity or mate.is_dead or mate.is_active:
			continue
		if mate.entity_config == null:
			continue
		var frac := float(mate.entity_config.curr_health) / float(maxi(mate.entity_config.max_health, 1))
		if frac - my_frac > TAG_HEALTH_MARGIN and frac > best_frac:
			best_frac = frac
			best = mate
	return best
