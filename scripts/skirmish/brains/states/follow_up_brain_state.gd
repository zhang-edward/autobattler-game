class_name FollowUpBrainState
extends BrainState

@export var attack_state: BrainState
@export var idle_state: BrainState

func get_intent(_delta: float) -> Intent:
	var target := brain.nearest_opponent()
	if target == null:
		return null

	var to_target := target.global_position - brain.entity.global_position
	var facing := signf(to_target.x)
	var ability_state := brain.entity.state_machine.state as AbilityState
	if ability_state != null and _target_is_hittable(target):
		var follow_up := brain.next_chain_link()
		if follow_up == null:
			return null
		state_machine.transition_to(attack_state, {"ability": follow_up})
		return _action(follow_up, facing)

	brain.active_chain = null
	var chain := brain.take_queued_chain() if _target_is_open(target) else null
	if chain != null:
		state_machine.transition_to(attack_state, {"ability": chain.abilities[0]})
	else:
		state_machine.transition_to(idle_state)
	return _movement(Vector2.ZERO, facing)
