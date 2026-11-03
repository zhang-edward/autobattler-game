class_name IdleState
extends BrainState

const SPEED := 1.0

@export var approach_state: BrainState
@export var preferred_distance := 300.0
@export var deadzone := 20.0
@export var idle_time_min := 1.0
@export var idle_time_max := 3.0

var _time_left := 0.0

func enter(_msg := {}) -> void:
	_time_left = randf_range(idle_time_min, idle_time_max)

func get_intent(delta: float) -> Intent:
	var target := brain.nearest_opponent()
	if target == null:
		return null

	var target_state := target.state_machine.state
	_time_left -= delta
	if _time_left <= 0.0 \
			or target_state == target.hurt_state \
			or (target_state == target.ragdoll_state and target.ragdoll_state.phase != RagdollState.Phase.DOWNED):
		_time_left = randf_range(idle_time_min, idle_time_max)
		var ability := brain.draw_weighted()
		if ability != null:
			state_machine.transition_to(approach_state, {"ability": ability})

	var to_target := target.global_position - brain.entity.global_position
	# Face the target whatever else happens, so retreating doesn't turn the entity around
	var facing := signf(to_target.x)
	var gap := absf(to_target.x)
	var direction := _row_direction(to_target)
	if gap > preferred_distance + deadzone:
		direction.x = facing
	elif gap < preferred_distance - deadzone:
		direction.x = -facing
	return _movement(direction.normalized() * SPEED, facing)
