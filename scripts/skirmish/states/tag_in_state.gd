class_name TagInState
extends SkirmishState

signal finished

const RUN_TIME := 0.15
const RUN_DISTANCE := 50.0

@export var move_state: MoveState

var _t := 0.0
var _from := Vector2.ZERO
var _destination := Vector2.ZERO

func enter(msg := {}) -> void:
	_t = 0.0
	var fallback := Skirmish.HERO_START if e.entity_type == EntityConfig.EntityType.HERO else Skirmish.VILLAIN_START
	_destination = msg.get("destination", fallback)
	var entry_side := float(msg.get("entry_side", 0.0))
	if entry_side == 0.0:
		entry_side = -1.0 if e.entity_type == EntityConfig.EntityType.HERO else 1.0
	e.position = Vector2(_destination.x + entry_side * RUN_DISTANCE, _destination.y)
	e.modulate.a = 0.0
	_from = e.position
	e.intent = null
	e.absolute_velocity = Vector2.ZERO
	e.z = 0.0
	e.z_velocity = 0.0
	e.rig.play_animation("male-rig/walk")
	e.rig_wrapper.scale.x = 1.0 if _from.x < _destination.x else -1.0

func physics_update(delta: float) -> void:
	_t += delta
	var k := clampf(_t / RUN_TIME, 0.0, 1.0)
	e.position = _from.lerp(_destination, k)
	e.modulate.a = k
	if k >= 1.0:
		e.set_active(true)
		state_machine.transition_to(move_state)
		finished.emit()
