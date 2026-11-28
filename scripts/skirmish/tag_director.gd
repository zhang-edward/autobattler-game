class_name TagDirector
extends Node

## Plays tag-ins as short cutscenes: the screen darkens, the outgoing hero
## calls for help, the incoming hero runs on and the outgoing one runs off.
## Requests queue up and play one at a time.
##
## Sides in `auto_tag_sides` also tag on their own: every so often, the hero
## who has been on the bench longest comes in. The opponent always does this;
## the player's side only does in the Skirmish Runner.

enum Scenario {CALL_FOR_HELP, COVER_ME, MY_TURN}

## What the outgoing hero says. The incoming hero calls out their assist
## (see Skirmish.ASSIST_LINES).
const LINES := {
	Scenario.CALL_FOR_HELP: ["Help!"],
	Scenario.COVER_ME: ["Cover me!"],
	Scenario.MY_TURN: [""],
}

# TUNE: seconds between automatic tags, picked at random in this range.
const AUTO_TAG_INTERVAL := Vector2(10.0, 18.0)

@onready var skirmish: Skirmish = get_parent()
@export var cutscene: CutsceneManager

var is_playing := false
var auto_tag_sides: Array[Skirmish.Side] = []

## Each request is [side, incoming entity, scenario].
var _pending: Array = []
var _auto_tag_timers := {}
## When each hero last went to the bench, in seconds of fight time.
var _benched_at := {}
var _clock := 0.0


## Turns on automatic tagging for `sides`.
func set_auto_tag_sides(sides: Array[Skirmish.Side]) -> void:
	auto_tag_sides = sides
	for side in sides:
		_auto_tag_timers[side] = _next_auto_tag_delay()


## Whether a tag is playing or waiting to play.
func is_busy() -> bool:
	return is_playing or not _pending.is_empty()


## A tag-in the player (or the AI) chose.
func request_manual_tag(side: Skirmish.Side, incoming_entity: SkirmishEntity) -> void:
	_pending.append([side, incoming_entity, Scenario.values().pick_random()])


func _process(delta: float) -> void:
	if skirmish == null:
		return
	_clock += delta
	if not is_playing and not _pending.is_empty():
		var req: Array = _pending.pop_front()
		play_tag(req[0], req[1], req[2])
	if skirmish.is_finished():
		return
	for side: Skirmish.Side in auto_tag_sides:
		_tick_auto_tag(side, delta)


func _tick_auto_tag(side: Skirmish.Side, delta: float) -> void:
	if is_busy():
		return
	_auto_tag_timers[side] = maxf(_auto_tag_timers[side] - delta, 0.0)
	if _auto_tag_timers[side] > 0.0:
		return
	# Due: tag as soon as the hero on the field is free.
	var incoming := _longest_benched(side)
	if incoming != null and skirmish.can_tag(side, incoming):
		request_manual_tag(side, incoming)
		_auto_tag_timers[side] = _next_auto_tag_delay()


## The benched hero who's waited longest. Heroes who haven't played yet
## count as waiting since the start, in lineup order.
func _longest_benched(side: Skirmish.Side) -> SkirmishEntity:
	var best: SkirmishEntity = null
	var best_time := INF
	var team := skirmish.team_for(side)
	for i in team.size():
		var e := team[i]
		if e == null or not is_instance_valid(e) or e.is_dead or e.is_active:
			continue
		var since: float = _benched_at.get(e, -1000.0 + i)
		if since < best_time:
			best_time = since
			best = e
	return best


func _next_auto_tag_delay() -> float:
	return randf_range(AUTO_TAG_INTERVAL.x, AUTO_TAG_INTERVAL.y)


func play_tag(side: Skirmish.Side, incoming: SkirmishEntity, scenario: Scenario) -> void:
	if is_playing:
		_pending.append([side, incoming, scenario])
		return
	if not skirmish.can_tag(side, incoming):
		# Wait and retry if the hero on the field is busy (mid-attack, in
		# hitstun). Drop the request if the round is over or the incoming
		# hero can no longer come in.
		if not skirmish.is_finished() and incoming != null and is_instance_valid(incoming) \
				and not incoming.is_dead and not incoming.is_active:
			_pending.append([side, incoming, scenario])
		return

	is_playing = true
	var outgoing := skirmish.active_for(side)
	skirmish.swap_refs(side, incoming)
	var destination := Skirmish.start_for(side)
	var entry_side := Skirmish.entry_direction(side)
	if outgoing != null and is_instance_valid(outgoing):
		destination = outgoing.position
		entry_side = - outgoing.facing()
		_benched_at[outgoing] = _clock
	var focus := incoming.position
	if outgoing != null and is_instance_valid(outgoing):
		focus = (outgoing.position + incoming.position) * 0.5
	focus += Vector2(0.0, -130.0)
	await cutscene.darken_screen(focus, [outgoing, incoming])

	var lines: Array = LINES[scenario]
	await cutscene.speak(outgoing, lines[0])
	await cutscene.tag_in(incoming, destination, entry_side)
	# The incoming hero's tag assist: they call it out, then it takes effect
	await cutscene.speak(incoming, Skirmish.assist_line(incoming.entity_config.assist))
	skirmish.apply_assist(incoming)
	if outgoing != null and is_instance_valid(outgoing) and not outgoing.is_dead:
		await cutscene.tag_out(outgoing)
	await cutscene.release()
	is_playing = false
