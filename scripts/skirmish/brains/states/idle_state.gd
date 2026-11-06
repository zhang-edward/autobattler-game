class_name IdleState
extends BrainState

const SPEED := 1.0

@export var attack_state: BrainState
@export var preferred_distance := 300.0
@export var deadzone := 20.0
@export var dash_back_range := 120.0
@export var idle_time_min := 1.0
@export var idle_time_max := 3.0

var _time_left := 0.0

func _ready() -> void:
	_time_left = randf_range(idle_time_min, idle_time_max)

func _physics_process(delta: float) -> void:
	_time_left -= delta * brain.entity.hitstop_scale
	var entity_state: State = brain.entity.state_machine.state
	if entity_state == brain.entity.hurt_state or entity_state == brain.entity.block_state or entity_state == brain.entity.dodge_state:
		_time_left = 0.0

func get_intent(_delta: float) -> Intent:
	var target := brain.nearest_opponent()
	if target == null:
		return null

	var target_attacking := _target_is_attacking(target)
	if _target_is_open(target) or (_time_left <= 0.0 and not target_attacking):
		_time_left = randf_range(idle_time_min, idle_time_max)
		var ability := brain.draw_weighted()
		if ability != null:
			state_machine.transition_to(attack_state, {"ability": ability})

	var to_target := target.global_position - brain.entity.global_position
	# Face the target whatever else happens, so retreating doesn't turn the entity around
	var facing := signf(to_target.x)
	var gap := absf(to_target.x)
	var direction := _y_direction(to_target)
	var dash := 0.0
	if gap > preferred_distance + deadzone:
		direction.x = facing
	elif gap < preferred_distance - deadzone:
		direction.x = - facing
		if gap < dash_back_range and preferred_distance - gap > DASH_MIN_DISTANCE and not brain.entity.is_on_wall():
			dash = -facing
	return _movement(direction.normalized() * SPEED, facing, dash)
