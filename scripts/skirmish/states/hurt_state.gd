class_name HurtState
extends SkirmishState

const BASE_KNOCKBACK := 100.0
const HITSTUN_SECONDS := 0.3

@export var move_state: MoveState
@export var fall_state: FallState

var hitstun_timer := 0.0

func enter(msg := {}) -> void:
	var dir: Vector2 = msg.get("dir", Vector2.ZERO)
	e.absolute_velocity = dir.normalized() * BASE_KNOCKBACK
	hitstun_timer = HITSTUN_SECONDS
	e.sprite.modulate = Color(1, 0, 0)

func exit() -> void:
	e.absolute_velocity = Vector2.ZERO
	e.sprite.modulate = Color.WHITE

func update(delta: float) -> void:
	e.absolute_velocity *= 0.9

	hitstun_timer -= delta
	if hitstun_timer <= 0:
		if e.z < 0:
			state_machine.transition_to(fall_state)
		else:
			state_machine.transition_to(move_state)
