class_name FleeingState
extends BrainState

const FLEE_SECONDS := 3.0

var _time_left := 0.0

func _ready() -> void:
	brain.entity.took_hit.connect(_on_took_hit)

func enter(_msg := {}) -> void:
	_time_left = FLEE_SECONDS

func _on_took_hit() -> void:
	_time_left = FLEE_SECONDS

func _physics_process(delta: float) -> void:
	if state_machine == null or state_machine.state != self:
		return
	_time_left -= delta * brain.entity.hitstop_scale
	if _time_left <= 0.0 and brain.entity.state_machine.state == brain.entity.move_state:
		brain.entity.state_machine.transition_to(brain.entity.tag_out_state, {"entry_side": brain.entity.facing()})

func get_intent(_delta: float) -> Intent:
	var away := Vector2.ZERO
	var nearest_dist := INF
	for other in brain.opponents():
		var offset: Vector2 = brain.entity.global_position - other.global_position
		nearest_dist = minf(nearest_dist, offset.length())
		if offset != Vector2.ZERO:
			away += offset / offset.length_squared()
	if away == Vector2.ZERO:
		return null

	var facing := signf(away.x)
	var dash := 0.0
	if nearest_dist < DASH_MIN_DISTANCE and not brain.entity.is_on_wall():
		dash = facing
	return _movement(away.normalized() * AttackState.SPEED, facing, dash)
