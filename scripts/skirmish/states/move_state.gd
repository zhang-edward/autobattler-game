class_name MoveState
extends SkirmishState

@export var jump_state: JumpState

func enter(_msg := {}):
	e.rig.play_animation("male-rig/walk")

func physics_update(_delta: float) -> void:
	var intent := e.intent
	if intent != null and intent.ability != null:
		var next_state: State = e.ability_to_state.get(intent.ability)
		if next_state != null:
			state_machine.transition_to(next_state)
		return

	e.absolute_velocity = movement_direction() * e.move_speed
	if e.absolute_velocity == Vector2.ZERO:
		if e.rig.anim_player.current_animation != "male-rig/idle":
			e.rig.play_animation("male-rig/idle")
	else:
		if e.rig.anim_player.current_animation != "male-rig/walk":
			e.rig.play_animation("male-rig/walk")


	var movement := e.intent
	if e.z == 0 and movement != null and movement.jump:
		state_machine.transition_to(jump_state)
