class_name HurtState
extends SkirmishState

const BASE_KNOCKBACK := 100.0
const HITSTUN_SECONDS := 0.3
const HITSTUN_STRENGTH_SCALE := 30.0

@export var move_state: MoveState
@export var fall_state: FallState
@export var death_state: DeathState

var hitstun_timer := 0.0

static func hitstun_for(strength: int) -> float:
	return HITSTUN_SECONDS * (HITSTUN_STRENGTH_SCALE + strength) / HITSTUN_STRENGTH_SCALE

func enter(msg := {}) -> void:
	var dir: Vector2 = msg.get("dir", Vector2.ZERO)
	e.absolute_velocity = dir.normalized() * BASE_KNOCKBACK
	hitstun_timer = hitstun_for(msg.get("strength", 0))
	e.rig.play_animation("male-rig/hurt")

func exit() -> void:
	e.absolute_velocity = Vector2.ZERO

func update(delta: float) -> void:
	e.absolute_velocity *= 0.9
	hitstun_timer -= delta
	if hitstun_timer <= 0:
		if e.z < 0:
			state_machine.transition_to(fall_state)
		else:
			state_machine.transition_to(move_state)
