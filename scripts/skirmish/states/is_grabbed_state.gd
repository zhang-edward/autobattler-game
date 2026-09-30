class_name IsGrabbedState
extends SkirmishState

func enter(msg := {}) -> void:
	var grabber = msg["grabber"] as SkirmishEntity
	var fist = grabber.rig.back_fist.global_position
	e.rig.play_animation("male-rig/is_grabbed")
