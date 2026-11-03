class_name MoveState
extends SkirmishState

@export var jump_state: JumpState

func physics_update(_delta: float) -> void:
	var intent := e.intent
	if intent != null and intent.ability != null:
		var next_state: State = e.ability_to_state.get(intent.ability)
		if next_state != null and e.ability_cooldowns.get(intent.ability, 0.0) <= 0.0:
			e.ability_cooldowns[intent.ability] = intent.ability.cooldown
			state_machine.transition_to(next_state)
			return

	e.absolute_velocity = movement_direction() * e.move_speed
	if e.absolute_velocity == Vector2.ZERO:
		if e.rig.anim_player.current_animation != "male-rig/idle":
			e.rig.play_animation("male-rig/idle")
	else:
		var anim := "male-rig/run" if movement_direction().length() > IdleState.SPEED else "male-rig/walk"
		if e.rig.anim_player.current_animation != anim:
			e.rig.play_animation(anim)

	var movement := e.intent
	if e.z == 0 and movement != null and movement.jump:
		state_machine.transition_to(jump_state)
