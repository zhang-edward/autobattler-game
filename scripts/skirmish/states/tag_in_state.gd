class_name TagInState
extends SkirmishState

const RUN_TIME := 0.45
const RUN_DISTANCE := 100.0

@export var move_state: MoveState

var _t := 0.0
var _from := Vector2.ZERO
var _target := Vector2.ZERO

func enter(_msg := {}) -> void:
	_t = 0.0
	_target = Skirmish.HERO_START if e.entity_type == EntityConfig.EntityType.HERO else Skirmish.VILLAIN_START
	var offset := -RUN_DISTANCE if e.entity_type == EntityConfig.EntityType.HERO else RUN_DISTANCE
	e.position = Vector2(_target.x + offset, _target.y)
	e.modulate.a = 0.0
	_from = e.position
	e.intent = null
	e.absolute_velocity = Vector2.ZERO
	e.z = 0.0
	e.z_velocity = 0.0
	e.rig.play_animation("male-rig/walk")
	e.rig_wrapper.scale.x = 1.0 if _from.x < _target.x else -1.0

func physics_update(delta: float) -> void:
	_t += delta
	var k := clampf(_t / RUN_TIME, 0.0, 1.0)
	e.position = _from.lerp(_target, k)
	e.modulate.a = k
	if k >= 1.0:
		# Hurtbox is inactive until tag-in animation is done
		e.set_active(true)
		state_machine.transition_to(move_state)
