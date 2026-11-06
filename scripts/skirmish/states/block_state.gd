class_name BlockState
extends SkirmishState

@export var duration := 0.4

var block_timer := 0.0

func enter(msg := {}) -> void:
	var dir: Vector2 = msg.get("dir", Vector2.ZERO)
	if dir.x != 0.0:
		e.rig_wrapper.scale.x = -dir.x
	block_timer = duration
	e.rig.anim_player.play_section_with_markers("male-rig/block", "active")
	e.absolute_velocity = Vector2(e.facing() * -400, 0)

func physics_update(delta: float) -> void:
	# Block pushback friction
	e.absolute_velocity *= 0.9

	block_timer -= delta
	if block_timer <= 0.0:
		state_machine.transition_to(e.move_state)
