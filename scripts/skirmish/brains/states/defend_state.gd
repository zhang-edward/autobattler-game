class_name DefendState
extends BrainState

@export var idle_state: BrainState

func get_intent(_delta: float) -> Intent:
	var target := brain.nearest_opponent()
	if target == null:
		return null

	if not (target.brain as AIBrain).state_machine.state is AttackState:
		state_machine.transition_to(idle_state)

	return _movement(Vector2.ZERO, signf(target.global_position.x - brain.entity.global_position.x))
