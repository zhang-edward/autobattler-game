class_name DeathState
extends SkirmishState

func enter(_msg := {}) -> void:
	e.rig.play_animation("male-rig/defeat")
	e.rig.anim_player.animation_finished.connect(on_defeat, CONNECT_ONE_SHOT)
	
func on_defeat(_anim_name):
	e.despawn()
