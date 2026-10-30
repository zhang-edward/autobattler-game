class_name ThrowState
extends AbilityState

const THROW_SPEED := 400.0
const THROW_LAUNCH := -500.0
const THROW_DELAY := 1.0

var throw_speed: float = THROW_SPEED
var throw_launch: float = THROW_LAUNCH
var throw_delay: float = THROW_DELAY

func init(ability: Ability) -> void:
	var grab_move := ability as GrabAbility
	if grab_move == null:
		return
	throw_speed = grab_move.throw_speed
	throw_launch = grab_move.throw_launch
	throw_delay = grab_move.throw_delay

func enter(_msg := {}) -> void:
	await get_tree().create_timer(throw_delay).timeout
	e.rig.play_animation("male-rig/grab_throw")
	e.rig.anim_player.animation_finished.connect(on_throw_finished, CONNECT_ONE_SHOT)
	e.rig.on_throw_release.connect(_release, CONNECT_ONE_SHOT)

func _release():
	if !is_instance_valid(e.grabbed_entity):
		return
	var target := e.grabbed_entity as SkirmishEntity
	var dir := Vector2(signf(target.position.x - e.position.x), 0.0)
	target.state_machine.transition_to(target.ragdoll_state, {
		"impulse": dir * throw_speed,
		"launch": throw_launch,
		"thrower": e
	})

func on_throw_finished(anim_name: String):
	if anim_name == "male-rig/grab_throw":
		e.grabbed_entity = null
		state_machine.transition_to(e.move_state)

func exit() -> void:
	if e.rig.on_throw_release.is_connected(_release):
		e.rig.on_throw_release.disconnect(_release)
