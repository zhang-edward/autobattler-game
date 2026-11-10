class_name DownedState
extends SkirmishState

const DOWNED_SECONDS := 3.0

var _time_left := 0.0

func enter(_msg := {}) -> void:
	_time_left = DOWNED_SECONDS
	e.absolute_velocity = Vector2.ZERO
	e.z = 0.0
	e.z_velocity = 0.0
	e.hurtbox.set_deferred("monitorable", false)
	e.hurtbox.set_deferred("monitoring", false)
	e.rig.play_animation("male-rig/downed")

func physics_update(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		e.is_dead = true
		e.healthbar.hide()
		e.died.emit()
		state_machine.transition_to(e.death_state)
