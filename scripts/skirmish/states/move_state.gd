class_name MoveState
extends SkirmishState

@export var jump_state: JumpState

func physics_update(delta: float) -> void:
	var intent := e.brain.get_intent(delta)
	if intent != null and intent.facing != 0.0:
		e.rig_wrapper.scale.x = -1.0 if intent.facing < 0.0 else 1.0
	elif e.absolute_velocity.x != 0.0:
		e.rig_wrapper.scale.x = -1.0 if e.absolute_velocity.x < 0.0 else 1.0

	if intent != null and intent.ability != null:
		var next_state: State = e.ability_to_state.get(intent.ability)
		# One projectile on screen per hero
		var blocked_projectile := intent.ability is ProjectileAbility and e.has_projectile_out()
		if next_state != null and not blocked_projectile:
			if e.brain is AIBrain:
				(e.brain as AIBrain).last_ability = intent.ability
			state_machine.transition_to(next_state)
			return

	if intent != null and intent.dash != 0.0:
		state_machine.transition_to(e.dash_state, {"direction": intent.dash})
		return

	var direction := intent.direction if intent != null else Vector2.ZERO

	e.absolute_velocity = direction * e.move_speed
	if e.absolute_velocity == Vector2.ZERO:
		if e.rig.anim_player.current_animation != "male-rig/idle":
			e.rig.play_animation("male-rig/idle")
	else:
		var anim := "male-rig/run" if direction.length() > IdleBrainState.SPEED else "male-rig/walk"
		if e.rig.anim_player.current_animation != anim:
			e.rig.play_animation(anim)

	if e.z == 0 and intent != null and intent.jump:
		state_machine.transition_to(jump_state)
