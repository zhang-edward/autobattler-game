class_name ThrowState
extends SkirmishState

var THROW_SPEED = 400

@export var move_state: MoveState

func enter(_msg := {}) -> void:
	await get_tree().create_timer(1.0).timeout
	e.rig.play_animation("male-rig/grab_throw")
	e.rig.anim_player.animation_finished.connect(on_throw_finished, CONNECT_ONE_SHOT)
	e.rig.on_throw_release.connect(_release, CONNECT_ONE_SHOT)

func _release():
	var target := e.grabbed_entity as SkirmishEntity
	var dir := Vector2(signf(target.position.x - e.position.x), 0.0)
	target.state_machine.transition_to(target.ragdoll_state, {
		"impulse": dir * THROW_SPEED,
		"launch": -500.0,
		"thrower": e
	})

func on_throw_finished(anim_name: String):
	if anim_name == "male-rig/grab_throw":
		e.grabbed_entity = null
		state_machine.transition_to(move_state)

func exit() -> void:
	if e.rig.on_throw_release.is_connected(_release):
		e.rig.on_throw_release.disconnect(_release)
