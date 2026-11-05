class_name AttackState
extends BrainState

const SPEED := 2.5

@export var idle_state: BrainState

var _ability: Ability

func enter(msg := {}) -> void:
	_ability = msg.get("ability")

func get_intent(_delta: float) -> Intent:
	var target := brain.nearest_opponent()
	if target == null:
		return null

	var to_target := target.global_position - brain.entity.global_position
	var facing := signf(to_target.x)
	if _ability == null or brain.entity.ability_cooldowns.get(_ability, 0.0) > 0.0:
		_ability = brain.draw_weighted()
		if _ability == null:
			state_machine.transition_to(idle_state)
			return null

	var direction := _y_direction(to_target)
	var speed := SPEED
	var dash := 0.0
	if absf(to_target.x) > _ability.ability_range:
		direction.x = facing
		if absf(to_target.x) - _ability.ability_range > DASH_MIN_DISTANCE:
			dash = facing
	elif absf(to_target.x) < _ability.ability_min_range:
		if brain.entity.is_on_wall():
			state_machine.transition_to(idle_state)
			return null
		direction.x = - facing
		speed = IdleState.SPEED
		if _ability.ability_min_range - absf(to_target.x) > DASH_MIN_DISTANCE:
			dash = - facing

	if direction != Vector2.ZERO:
		return _movement(direction.normalized() * speed, facing, dash)

	if brain.entity.state_machine.state == brain.entity.dash_state:
		return _movement(Vector2.ZERO, facing)

	# # Only MoveState reads intent.ability, so firing in any other state would drop it
	# if brain.entity.state_machine.state != brain.entity.move_state:
	# 	return _movement(Vector2.ZERO, facing)

	var intent := _action(_ability, facing)
	var target_state := target.state_machine.state
	if target_state == target.hurt_state \
			or (target_state == target.ragdoll_state and target.ragdoll_state.phase != RagdollState.Phase.DOWNED):
		state_machine.transition_to(self, {"ability": brain.draw_weighted()})
	else:
		state_machine.transition_to(idle_state)
	return intent
