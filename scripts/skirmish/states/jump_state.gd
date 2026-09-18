class_name JumpState
extends SkirmishState

const JUMP_VELOCITY = 500

@export var fall_state: FallState

func enter(_msg := {}) -> void:
	fighter.z_velocity = -JUMP_VELOCITY

func physics_update(delta: float) -> void:
	var direction_x = Input.get_axis("move_left", "move_right")
	var direction_y = Input.get_axis("move_up", "move_down")
	fighter.absolute_velocity = Vector2(direction_x, direction_y) * fighter.move_speed

	fighter.z += fighter.z_velocity * delta
	fighter.z_velocity += SkirmishEntity.GRAVITY * delta

	if fighter.z_velocity >= 0:
		state_machine.transition_to(fall_state)
