class_name DashState
extends SkirmishState

@export var fwd_speed := 400.0
@export var bck_speed := 300.0
@export var fwd_duration := 0.15
@export var bck_duration := 0.5

const EVASION_DASH_SCALE := 10.0

var dash_timer := 0.0

func enter(msg := {}) -> void:
	var direction: float = msg.get("direction", 0.0)
	var is_dash_fwd = direction == e.facing()
	dash_timer = fwd_duration if is_dash_fwd else bck_duration
	var speed = (fwd_speed if is_dash_fwd else bck_speed) * (1.0 + e.entity_config.evasion / EVASION_DASH_SCALE)
	e.absolute_velocity = Vector2(direction * speed, 0.0)
	e.rig.play_animation("male-rig/dash_forward" if is_dash_fwd else "male-rig/dash_back")

func physics_update(delta: float) -> void:
	e.absolute_velocity *= 0.95
	dash_timer -= delta
	if dash_timer <= 0.0:
		state_machine.transition_to(e.move_state)
