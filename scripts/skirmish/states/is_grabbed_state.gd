class_name IsGrabbedState
extends SkirmishState

var _grabber: SkirmishEntity
var _hold_offset_x := 0.0  # horizontal offset from fist, in the grabber's facing space
var _start_fist_y := 0.0

func enter(msg := {}) -> void:
	_grabber = msg["grabber"] as SkirmishEntity
	var fist := _grabber.rig.back_fist.global_position
	_hold_offset_x = (e.global_position.x - fist.x) * _grabber.rig_wrapper.scale.x
	_start_fist_y = fist.y
	e.absolute_velocity = Vector2.ZERO  # otherwise move_and_slide() fights the attach
	e.rig.play_animation("male-rig/is_grabbed")

func update(_delta: float) -> void:
	if not is_instance_valid(_grabber):
		return
	var fist := _grabber.rig.back_fist.global_position
	e.global_position.x = fist.x + _hold_offset_x * _grabber.rig_wrapper.scale.x
	e.z = fist.y - _start_fist_y
