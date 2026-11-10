class_name CharacterMomentState
extends SkirmishState

signal finished

const MOMENT_SECONDS := 1.0

var has_played := false
var _time_left := 0.0

func enter(_msg := {}) -> void:
	has_played = true
	_time_left = MOMENT_SECONDS
	e.absolute_velocity = Vector2.ZERO
	e.hurtbox.set_deferred("monitorable", false)
	e.hurtbox.set_deferred("monitoring", false)
	e.rig.play_animation("male-rig/level_up")

func physics_update(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		e.hurtbox.set_deferred("monitorable", true)
		e.hurtbox.set_deferred("monitoring", true)
		state_machine.transition_to(e.move_state)
		finished.emit()
