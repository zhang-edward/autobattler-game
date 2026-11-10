class_name DownedState
extends SkirmishState

const DOWNED_SECONDS := 3.0
const CHARACTER_MOMENT_ON_DOWNED_CHANCE := 0.0
# const CHARACTER_MOMENT_ON_DOWNED_CHANCE := 0.5
const CHARACTER_MOMENT_DELAY_SECONDS := 1.0

var _time_left := 0.0
var _character_moment := false

func enter(_msg := {}) -> void:
	_time_left = DOWNED_SECONDS
	_character_moment = e.entity_type == EntityConfig.EntityType.HERO and not e.character_moment_state.has_played \
		and randf() < CHARACTER_MOMENT_ON_DOWNED_CHANCE
	e.absolute_velocity = Vector2.ZERO
	e.z = 0.0
	e.z_velocity = 0.0
	e.hurtbox.set_deferred("monitorable", false)
	e.hurtbox.set_deferred("monitoring", false)
	e.rig.play_animation("male-rig/downed")

func physics_update(delta: float) -> void:
	_time_left -= delta
	if _character_moment and _time_left <= DOWNED_SECONDS - CHARACTER_MOMENT_DELAY_SECONDS:
		_character_moment = false
		e.character_moment_rolled.emit()
		return
	if _time_left <= 0.0:
		e.is_dead = true
		e.healthbar.hide()
		e.died.emit()
		state_machine.transition_to(e.death_state)
