class_name BlockState
extends AbilityState

var duration: float
var block_timer := 0.0

func init(ability: Ability) -> void:
	var block_move := ability as BlockAbility
	if block_move == null:
		return
	duration = block_move.duration

func enter(_msg := {}) -> void:
	block_timer = duration
	e.rig.anim_player.play_section_with_markers("male-rig/block", "active")
	e.absolute_velocity = Vector2(e.facing() * -400, 0)

func physics_update(delta: float) -> void:
	# Block pushback friction
	e.absolute_velocity *= 0.9

	block_timer -= delta
	if block_timer <= 0.0:
		state_machine.transition_to(e.move_state)
