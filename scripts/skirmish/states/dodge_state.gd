class_name DodgeState
extends SkirmishState

const VX = 120
const VY = 800

@export var duration := 0.4

var dodge_timer := 0.0
var _rig_default_position: Vector2

func _ready() -> void:
	_rig_default_position = e.rig.position

func enter(msg := {}) -> void:
	var dir: Vector2 = msg.get("dir", Vector2.ZERO)
	if dir.x != 0.0:
		e.rig_wrapper.scale.x = -dir.x
	dodge_timer = duration
	e.rig.play_animation("male-rig/dodge")
	e.absolute_velocity = Vector2(e.facing() * -VX, VY * (1 if randf() < 0.5 else -1))

func physics_update(delta: float) -> void:
	# Dodge slide away friction
	e.absolute_velocity *= 0.9

	dodge_timer -= delta
	if dodge_timer <= 0.0:
		state_machine.transition_to(e.move_state)

func exit() -> void:
	e.rig.position = _rig_default_position