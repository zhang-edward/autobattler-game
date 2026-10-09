class_name MoveState
extends SkirmishState

@export var jump_state: JumpState
@export var punch_state: PunchState
@export var block_state: BlockState
@export var grab_state: GrabState

func enter(_msg := {}):
	e.rig.play_animation("male-rig/walk")

func physics_update(_delta: float) -> void:
	var action := e.intent as ActionIntent
	if action != null:
		match action.action:
			ActionIntent.Action.BLOCK:
				state_machine.transition_to(block_state, {"duration": action.duration})
			ActionIntent.Action.GRAB:
				state_machine.transition_to(grab_state)
			_:
				state_machine.transition_to(punch_state)
		return

	e.absolute_velocity = movement_direction() * e.move_speed
	if e.absolute_velocity == Vector2.ZERO:
		if e.rig.anim_player.current_animation != "male-rig/idle":
			e.rig.play_animation("male-rig/idle")
	else:
		if e.rig.anim_player.current_animation != "male-rig/walk":
			e.rig.play_animation("male-rig/walk")


	var movement := e.intent as MovementIntent
	if e.z == 0 and movement != null and movement.jump:
		state_machine.transition_to(jump_state)
