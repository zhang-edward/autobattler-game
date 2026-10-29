class_name BlockState
extends AbilityState

"""
Held guard, omnidirectional. Negates strikes but not grabs; see SkirmishEntity.take_hit.
Held for a duration the brain passes in, not until released.
"""

var duration: float
var block_timer := 0.0

func init(ability: Ability) -> void:
	var block_move := ability as BlockAbility
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
