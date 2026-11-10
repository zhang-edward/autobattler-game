class_name FleeingState
extends BrainState

func _physics_process(_delta: float) -> void:
	if state_machine == null or state_machine.state != self:
		return
	var e := brain.entity
	var e_state: State = e.state_machine.state
	# Allow fleeing entities to pass through side walls to escape (but only when they are moving / dashing)
	# Fleeing entities that are launched by an attack will bounce off walls, so they cannot get knocked out of bounds and allowed to escape
	var passing := e_state == e.move_state or e_state == e.dash_state or e_state == e.tag_out_state
	e.set_collision_mask_value(SkirmishEntity.SIDE_WALL_LAYER_INDEX, not passing)
	var arena_width := e.get_viewport_rect().size.x
	if e_state == e.move_state and (e.global_position.x < 0.0 or e.global_position.x > arena_width):
		e.state_machine.transition_to(e.tag_out_state, {"entry_side": e.facing()})

func get_intent(_delta: float) -> Intent:
	var away := Vector2.ZERO
	var nearest_dist := INF
	for other in brain.opponents():
		var offset: Vector2 = brain.entity.global_position - other.global_position
		nearest_dist = minf(nearest_dist, offset.length())
		if offset != Vector2.ZERO:
			away += offset / offset.length_squared()
	if away == Vector2.ZERO:
		return null

	var facing := signf(away.x)
	var dash := 0.0
	if nearest_dist < DASH_MIN_DISTANCE and not brain.entity.is_on_wall():
		dash = facing
	return _movement(away.normalized() * AttackState.SPEED, facing, dash)
