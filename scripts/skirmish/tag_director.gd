class_name TagDirector
extends Node

enum Scenario {LOW_HEALTH, COWARD, AVENGE, GLORY}

const LINES := {
	Scenario.LOW_HEALTH: ["Help!", "I got you!"],
	Scenario.COWARD: ["Cover me!", "I've got this!"],
	Scenario.AVENGE: ["", "I'll avenge you!"],
	Scenario.GLORY: ["", "My turn!"],
}

const LOW_HP := 0.25
const COWARD_HP := 0.5
const GLORY_HP := 0.25

@onready var skirmish: Skirmish = get_parent()
@export var cutscene: CutsceneManager

var is_playing := false

var _ropes_called: Array[int] = []
var _coward_called: Array[int] = []
var _glory_called: Array[int] = []
var _pending: Array = []

func request_avenge(entity_type: EntityConfig.EntityType) -> void:
	var bench := skirmish._healthiest_living_entity_on_team(skirmish.team_for(entity_type))
	if bench == null:
		skirmish._finish(skirmish._winning_side(entity_type))
		return
	_pending.append([entity_type, bench, Scenario.AVENGE])

func _process(_delta: float) -> void:
	if is_playing or skirmish == null:
		return

	if not _pending.is_empty():
		var req: Array = _pending.pop_front()
		play_tag(req[0], req[1], req[2])
		return
	for team in [EntityConfig.EntityType.HERO, EntityConfig.EntityType.VILLAIN]:
		if _has_pending(team):
			continue
		if _check_voluntary(team):
			return
		if _check_glory(team):
			return

func _has_pending(team: EntityConfig.EntityType) -> bool:
	for req in _pending:
		if req[0] == team:
			return true
	return false

func play_tag(team: EntityConfig.EntityType, incoming: SkirmishEntity, scenario: Scenario) -> void:
	if is_playing:
		_pending.append([team, incoming, scenario])
		return
	if not skirmish.tag(team, incoming):
		if incoming != null and is_instance_valid(incoming) and not incoming.is_dead:
			_pending.append([team, incoming, scenario])
		return

	is_playing = true
	var outgoing := skirmish.active_for(team)
	if scenario == Scenario.AVENGE and outgoing != null and is_instance_valid(outgoing) and outgoing.is_dead and outgoing.rig.anim_player.is_playing():
		await outgoing.rig.anim_player.animation_finished

	print("tag: ", Scenario.keys()[scenario], " ", incoming.name)
	skirmish.swap_refs(team, incoming)
	var destination := Skirmish.HERO_START if team == EntityConfig.EntityType.HERO else Skirmish.VILLAIN_START
	var entry_side := -1.0 if team == EntityConfig.EntityType.HERO else 1.0
	if outgoing != null and is_instance_valid(outgoing):
		destination = outgoing.position
		entry_side = - outgoing.facing()
	var focus := incoming.position
	if outgoing != null and is_instance_valid(outgoing):
		focus = (outgoing.position + incoming.position) * 0.5
	focus += Vector2(0.0, -130.0)
	await cutscene.darken_screen(focus, [outgoing, incoming])

	var lines: Array = LINES[scenario]
	await cutscene.speak(outgoing, lines[0])
	await cutscene.tag_in(incoming, destination, entry_side)
	await cutscene.speak(incoming, lines[1])
	if outgoing != null and is_instance_valid(outgoing) and not outgoing.is_dead:
		await cutscene.tag_out(outgoing)
	await cutscene.release()
	is_playing = false

func _check_voluntary(team: EntityConfig.EntityType) -> bool:
	var active := skirmish.active_for(team)
	if active == null or not is_instance_valid(active) or active.is_dead or active.entity_config == null:
		return false
	var bench := skirmish._healthiest_living_entity_on_team(skirmish.team_for(team))
	if bench == null:
		return false
	var id := active.get_instance_id()
	if _frac(active) < LOW_HP and not id in _ropes_called:
		_ropes_called.append(id)
		_coward_called.append(id)
		_pending.append([team, bench, Scenario.LOW_HEALTH])
		return true
	if _frac(active) < COWARD_HP and not id in _coward_called:
		_coward_called.append(id)
		_pending.append([team, bench, Scenario.COWARD])
		return true
	return false

func _check_glory(team: EntityConfig.EntityType) -> bool:
	var foe := skirmish.active_for(EntityConfig.EntityType.VILLAIN if team == EntityConfig.EntityType.HERO else EntityConfig.EntityType.HERO)
	if foe == null or not is_instance_valid(foe) or foe.is_dead or foe.entity_config == null:
		return false
	if _frac(foe) >= GLORY_HP:
		return false
	var bench := skirmish._healthiest_living_entity_on_team(skirmish.team_for(team))
	if bench == null:
		return false
	var id := bench.get_instance_id()
	if id in _glory_called:
		return false
	_glory_called.append(id)
	_pending.append([team, bench, Scenario.GLORY])
	return true

func _frac(e: SkirmishEntity) -> float:
	return float(e.entity_config.curr_health) / float(maxi(e.entity_config.max_health, 1))
