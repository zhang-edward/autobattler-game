class_name FollowUpState
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
	if ability_state != null:
		var follow_up := _draw_follow_up(ability_state, to_target)
		if follow_up == null:
			return null
		state_machine.transition_to(attack_state, {"ability": follow_up})
		return _action(follow_up, facing)

	var target_state := target.state_machine.state
	if target_state == target.hurt_state \
			or (target_state == target.ragdoll_state and target.ragdoll_state.phase != RagdollState.Phase.DOWNED):
		state_machine.transition_to(attack_state, {"ability": brain.draw_weighted()})
	else:
		state_machine.transition_to(idle_state)
	return _movement(Vector2.ZERO, facing)

func _draw_follow_up(ability_state: AbilityState, to_target: Vector2) -> Ability:
	var candidates: Array[Ability] = []
	for ability in brain.ready_abilities():
		if ability_state.can_cancel_into(ability) and ability.in_reach(to_target):
			candidates.append(ability)
	return brain.pick_weighted(candidates)
