class_name TagOutState
extends SkirmishState

const RUN_TIME := 0.45
const RUN_DISTANCE := 100.0

var _t := 0.0
var _from := Vector2.ZERO
var _exit_x := 0.0

func enter(_msg := {}) -> void:
	_t = 0.0
	_from = e.position
	var offset = - RUN_DISTANCE if e.entity_type == EntityConfig.EntityType.HERO else RUN_DISTANCE
	_exit_x = _from.x + offset
	e.intent = null
	e.absolute_velocity = Vector2.ZERO
	e.z = 0.0
	e.z_velocity = 0.0
	# Disable hitboxes for tag-outs
	if e.hurtbox != null:
		e.hurtbox.set_deferred("monitorable", false)
		e.hurtbox.set_deferred("monitoring", false)
	e.rig.play_animation("male-rig/walk")
	e.rig_wrapper.scale.x = -1.0 if _exit_x < _from.x else 1.0

func physics_update(delta: float) -> void:
	_t += delta
	var k := clampf(_t / RUN_TIME, 0.0, 1.0)
	e.position = Vector2(lerpf(_from.x, _exit_x, k), _from.y)
	e.modulate.a = 1.0 - k
	if k >= 1.0:
		var bench := Skirmish.HERO_BENCH if e.entity_type == EntityConfig.EntityType.HERO else Skirmish.VILLAIN_BENCH
		e.position = bench
		e.modulate.a = 1.0
		e.set_active(false)
