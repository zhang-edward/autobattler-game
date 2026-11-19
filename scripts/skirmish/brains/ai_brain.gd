class_name AIBrain
extends Brain

const FLEE_CHANCE := 0.25
const FLEE_ROLL_SECONDS_MIN := 1.0
const FLEE_ROLL_SECONDS_MAX := 2.0

@export var state_machine: StateMachine
@export var fleeing_brain_state: FleeingBrainState
@export var flee_roll_timer: Timer

var target: SkirmishEntity
var queued_chain: AbilityChain
var active_chain: AbilityChain
var chain_index := 0

func _ready() -> void:
	flee_roll_timer.timeout.connect(_on_flee_roll_timer_timeout)
	flee_roll_timer.start(randf_range(FLEE_ROLL_SECONDS_MIN, FLEE_ROLL_SECONDS_MAX))

func _on_flee_roll_timer_timeout() -> void:
	flee_roll_timer.start(randf_range(FLEE_ROLL_SECONDS_MIN, FLEE_ROLL_SECONDS_MAX))
	if entity.entity_type != EntityConfig.EntityType.VILLAIN or entity.is_dead or entity.entity_config.curr_health > 0:
		return
	if state_machine.state == fleeing_brain_state or entity.state_machine.state == entity.downed_state:
		return
	if randf() < FLEE_CHANCE:
		state_machine.transition_to(fleeing_brain_state)

func get_intent(delta: float) -> Intent:
	if queued_chain == null:
		queued_chain = _draw_chain()
	return (state_machine.state as BrainState).get_intent(delta)

func take_queued_chain() -> AbilityChain:
	if queued_chain == null or entity.stamina < queued_chain.stamina_cost():
		return null
	active_chain = queued_chain
	chain_index = 0
	queued_chain = _draw_chain()
	return active_chain

func next_chain_link() -> OffensiveAbility:
	if active_chain == null or chain_index + 1 >= active_chain.abilities.size():
		return null
	var ability := active_chain.abilities[chain_index + 1]
	if entity.stamina < ability.stamina_cost:
		return null
	chain_index += 1
	return ability

func _draw_chain() -> AbilityChain:
	return null if entity.chains.is_empty() else entity.chains.pick_random()

func nearest_opponent() -> SkirmishEntity:
	if not is_instance_valid(target) or target.is_dead or not target.is_active:
		target = _closest_opponent()
	return target

func pick_target(target_range: float) -> void:
	var in_range := opponents().filter(func(other): return entity.global_position.distance_to(other.global_position) <= target_range)
	target = in_range.pick_random() if not in_range.is_empty() else null

func opponents() -> Array[SkirmishEntity]:
	var found: Array[SkirmishEntity] = []
	for node in entity.get_parent().get_children():
		var other := node as SkirmishEntity
		if other == null or other == entity or other.is_dead or not other.is_active or other.entity_type == entity.entity_type:
			continue
		found.append(other)
	return found

func _closest_opponent() -> SkirmishEntity:
	var nearest: SkirmishEntity = null
	var nearest_dist := INF
	for other in opponents():
		var dist := entity.global_position.distance_squared_to(other.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = other
	return nearest
