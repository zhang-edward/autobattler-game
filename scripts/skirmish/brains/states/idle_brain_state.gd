class_name IdleBrainState
extends BrainState

const SPEED := 1.0

@export var attack_state: BrainState
@export var preferred_distance := 500.0
@export var deadzone := 200.0
@export var dash_back_range := 120.0
@export var idle_time_min := 1.0
@export var idle_time_max := 3.0

var _time_left := 0.0

func _ready() -> void:
	_time_left = randf_range(idle_time_min, idle_time_max)

func enter(_msg := {}) -> void:
	brain.pick_target(preferred_distance + deadzone)

func _physics_process(delta: float) -> void:
	_time_left -= delta * brain.entity.hitstop_scale
	var entity_state: State = brain.entity.state_machine.state
	if entity_state == brain.entity.hurt_state or entity_state == brain.entity.block_state or entity_state == brain.entity.dodge_state:
		_time_left = 0.0

func _away_from_opponents() -> Vector2:
	var comfort_range := preferred_distance - deadzone
	var away := Vector2.ZERO
	for other in brain.opponents():
		var offset: Vector2 = brain.entity.global_position - other.global_position
		if offset != Vector2.ZERO and offset.length() < comfort_range:
			away += offset.normalized() * (1.0 - offset.length() / comfort_range)
	return away

func get_intent(_delta: float) -> Intent:
	var target := brain.nearest_opponent()
	if target == null:
		return null

	var defensive_ability := brain.ready_defensive_ability()
	if defensive_ability != null and not _target_is_open(target):
		var intent := Intent.new()
		intent.facing = signf(target.global_position.x - brain.entity.global_position.x)
		intent.defensive_ability = defensive_ability
		return intent

	var chase := brain.entity.entity_type == EntityConfig.EntityType.HERO and _target_is_fleeing(target)
	if _target_is_open(target) or ((chase or _time_left <= 0.0) and _target_is_hittable(target)):
		var chain := brain.take_queued_chain()
		if chain != null:
			_time_left = randf_range(idle_time_min, idle_time_max)
			state_machine.transition_to(attack_state, {"ability": chain.abilities[0]})

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
			dash = - facing
	direction = direction.normalized() + _away_from_opponents()
	return _movement(direction.normalized() * SPEED, facing, dash)
