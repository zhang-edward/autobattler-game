class_name DodgeState
extends AbilityState

# Used when a brain transitions in without passing a duration
const DEFAULT_DURATION := 0.4
const OFFSET_X = -60
const OFFSET_Y = 30

var duration: float = DEFAULT_DURATION
var dodge_timer := 0.0
var _rig_default_position: Vector2

func init(ability: Ability) -> void:
	var dodge_move := ability as DodgeAbility
	if dodge_move == null:
		return
	duration = dodge_move.duration
	_rig_default_position = e.rig.position

func enter(_msg := {}) -> void:
	dodge_timer = duration
	e.rig.play_animation("male-rig/dodge")
	e.absolute_velocity = Vector2(e.facing() * -400, 30 * 1 if randf() < 0.5 else -1)

func physics_update(delta: float) -> void:
	# Dodge slide away friction
	e.absolute_velocity *= 0.9

	dodge_timer -= delta
	if dodge_timer <= 0.0:
		state_machine.transition_to(e.move_state)

func exit() -> void:
	e.rig.position = _rig_default_position