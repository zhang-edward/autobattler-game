class_name AIBrain
extends Brain

# Walks toward the nearest entity of the other type and holds at preferred_distance.
@export var preferred_distance := 100.0
@export var deadzone := 20.0

func get_intent(_delta: float) -> Intent:
	var target := _nearest_opponent()
	if target == null:
		return null

	# Floor-plane offset: screen y is drawn squashed, so undo that for the distance
	var offset := target.global_position - entity.global_position
	offset.y /= IsometryUtils.DEPTH_SCALE
	var distance := offset.length()

	var movement := MovementIntent.new()
	if distance > preferred_distance + deadzone:
		movement.direction = offset.normalized()
	elif distance < preferred_distance - deadzone:
		movement.direction = - offset.normalized()

	return movement

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
