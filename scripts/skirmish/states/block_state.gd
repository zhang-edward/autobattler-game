class_name BlockState
extends SkirmishState

"""
Held guard, omnidirectional. Negates strikes but not grabs; see SkirmishEntity.take_hit.
Held for a duration the brain passes in, not until released.
"""

const BLOCK_TINT := Color(0.4, 0.6, 1.0)
# Used when a brain transitions in without passing a duration
const FALLBACK_DURATION := 0.4

@export var move_state: MoveState

var block_timer := 0.0

func enter(msg := {}) -> void:
	block_timer = float(msg.get("duration", FALLBACK_DURATION))
	e.sprite.modulate = BLOCK_TINT

func exit() -> void:
	e.sprite.modulate = Color.WHITE

func physics_update(delta: float) -> void:
	# Planted while guarding
	e.absolute_velocity = Vector2.ZERO

	block_timer -= delta
	if block_timer <= 0.0:
		state_machine.transition_to(move_state)
