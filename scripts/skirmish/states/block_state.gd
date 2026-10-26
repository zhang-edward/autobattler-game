class_name BlockState
extends MoveBasedState

"""
Held guard, omnidirectional. Negates strikes but not grabs; see SkirmishEntity.take_hit.
Held for a duration the brain passes in, not until released.
"""

const BLOCK_TINT := Color(0.4, 0.6, 1.0)
# Used when a brain transitions in without passing a duration
const FALLBACK_DURATION := 0.4

var duration: float = FALLBACK_DURATION
var block_timer := 0.0

func init(move: Move) -> void:
	var block_move := move as BlockMove
	if block_move == null:
		return
	duration = block_move.duration

func enter(_msg := {}) -> void:
	block_timer = duration
	e.rig.play_animation("male-rig/block")

func physics_update(delta: float) -> void:
	# Planted while guarding
	e.absolute_velocity = Vector2.ZERO

	block_timer -= delta
	if block_timer <= 0.0:
		state_machine.transition_to(e.move_state)
