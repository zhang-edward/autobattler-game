class_name DownedState
extends SkirmishState

## Guard break: the team's block bar just emptied. The hero is stuck on the
## floor and can be hit freely, then gets back up. Hits deal damage but don't
## knock them out of it.

# TUNE: how long a guard break leaves the hero helpless.
const GUARD_BREAK_SECONDS := 2.0

var _time_left := 0.0

func enter(_msg := {}) -> void:
	_time_left = GUARD_BREAK_SECONDS
	e.absolute_velocity = Vector2.ZERO
	e.z = 0.0
	e.z_velocity = 0.0
	e.rig.play_animation("male-rig/downed")

func physics_update(delta: float) -> void:
	e.absolute_velocity *= 0.9
	_time_left -= delta
	if _time_left <= 0.0:
		state_machine.transition_to(e.move_state)
