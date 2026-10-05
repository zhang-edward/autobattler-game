class_name Skirmish
extends Node2D

signal finished(winner: EntityConfig.EntityType)

const HERO_START := Vector2(400.0, 700.0)
const VILLAIN_START := Vector2(1400.0, 700.0)
# Off-arena (behind the HWall), so a benched body can never block or be hit
const HERO_BENCH := Vector2(400.0, 1200.0)
const VILLAIN_BENCH := Vector2(1400.0, 1200.0)
# Delay between the last death and `finished`, so the body can land and fade first
const OUTRO_SECONDS := 1.5

@export var entity_scene: PackedScene

@export_group("Standalone testing")
@export var debug_hero_count := 3
@export var debug_villain_count := 3

var hero_team: Array[SkirmishEntity] = []
var villain_team: Array[SkirmishEntity] = []
var active_hero: SkirmishEntity
var active_villain: SkirmishEntity
var _finished := false

func _ready() -> void:
	if hero_team.is_empty() and villain_team.is_empty():
		_setup_debug_matchup()

func setup(heroes: Array[EntityConfig], villains: Array[EntityConfig]) -> void:
	hero_team = _spawn_side(heroes, HERO_START, HERO_BENCH)
	villain_team = _spawn_side(villains, VILLAIN_START, VILLAIN_BENCH)
	active_hero = hero_team[0] if not hero_team.is_empty() else null
	active_villain = villain_team[0] if not villain_team.is_empty() else null

func team_for(team: EntityConfig.EntityType) -> Array[SkirmishEntity]:
	return hero_team if team == EntityConfig.EntityType.HERO else villain_team

func active_for(team: EntityConfig.EntityType) -> SkirmishEntity:
	return active_hero if team == EntityConfig.EntityType.HERO else active_villain

# Voluntary swap. Move-only and never interrupts a grab; returns false when denied
# so MoveState can fall through to normal movement instead of stalling.
func tag(team: EntityConfig.EntityType, entity: SkirmishEntity) -> bool:
	if _finished or entity == null or not is_instance_valid(entity) or entity.is_dead:
		return false
	var roster := team_for(team)
	if not roster.has(entity):
		return false
	var current := active_for(team)
	if current == entity:
		return false
	if current != null and is_instance_valid(current) and not current.is_dead:
		if current.state_machine == null or not (current.state_machine.state is MoveState):
			return false
	if _is_grab_in_progress():
		return false
	_do_tag(team, entity)
	return true

func _spawn_side(configs: Array[EntityConfig], start: Vector2, bench: Vector2) -> Array[SkirmishEntity]:
	# setup() runs before this scene is added to the tree, so @onready isn't resolved yet
	var battlefield := $Battlefield as Node2D
	var team: Array[SkirmishEntity] = []
	for i in configs.size():
		var config := configs[i]
		var entity := entity_scene.instantiate() as SkirmishEntity
		entity.name = config.entity_name
		entity.skirmish = self
		battlefield.add_child(entity)
		entity.configure_from_entity_config(config)
		entity.died.connect(_on_entity_died.bind(entity))
		if i == 0:
			entity.position = start
			entity.set_active(true)
		else:
			entity.position = bench
			entity.set_active(false)
		team.append(entity)
	return team

# Lets this scene be run on its own for testing, without a tactical encounter to set it up
func _setup_debug_matchup() -> void:
	var heroes: Array[EntityConfig] = GameVariables.generate_random_entity_configs(debug_hero_count, EntityConfig.EntityType.HERO)
	var villains: Array[EntityConfig] = GameVariables.generate_random_entity_configs(debug_villain_count, EntityConfig.EntityType.VILLAIN)
	for config in heroes:
		config.curr_health = config.max_health
	for config in villains:
		config.curr_health = config.max_health
	setup(heroes, villains)

func _on_entity_died(entity: SkirmishEntity) -> void:
	_release_grab_links(entity)
	var roster := team_for(entity.entity_type)
	var next := _healthiest_living_bench(roster)
	# Dead bench member (shouldn't happen; bench can't be hit): just check the team
	if entity != active_for(entity.entity_type):
		if not _team_has_living(roster):
			_finish(_winning_side(entity.entity_type))
		return
	if next != null:
		_do_tag(entity.entity_type, next)
		return
	_finish(_winning_side(entity.entity_type))

func _do_tag(team: EntityConfig.EntityType, entity: SkirmishEntity) -> void:
	var start := HERO_START if team == EntityConfig.EntityType.HERO else VILLAIN_START
	var bench := HERO_BENCH if team == EntityConfig.EntityType.HERO else VILLAIN_BENCH
	var current := active_for(team)
	if current != null and is_instance_valid(current) and not current.is_dead:
		current.position = bench
		current.z = 0.0
		current.z_velocity = 0.0
		current.set_active(false)
	entity.position = start
	entity.z = 0.0
	entity.z_velocity = 0.0
	entity.absolute_velocity = Vector2.ZERO
	entity.intent = null
	entity.set_active(true)
	if team == EntityConfig.EntityType.HERO:
		active_hero = entity
	else:
		active_villain = entity
	# Re-enter Move so the incoming fighter restarts its walk anim
	if entity.state_machine != null and entity.state_machine.state != null:
		entity.state_machine.transition_to(entity.state_machine.state)

func _is_grab_in_progress() -> bool:
	for e in [active_hero, active_villain]:
		if e == null or not is_instance_valid(e) or e.is_dead:
			continue
		if e.grabbed_entity != null and is_instance_valid(e.grabbed_entity):
			return true
		if e.state_machine == null:
			continue
		var st = e.state_machine.state
		if st is GrabState or st is IsGrabbedState or st is ThrowState:
			return true
	return false

func _release_grab_links(dead: SkirmishEntity) -> void:
	for e in hero_team + villain_team:
		if e != null and is_instance_valid(e) and e.grabbed_entity == dead:
			e.grabbed_entity = null
	var victim := dead.grabbed_entity as SkirmishEntity
	dead.grabbed_entity = null
	if victim != null and is_instance_valid(victim) and not victim.is_dead:
		victim.state_machine.transition_to(victim.hurt_state, {"dir": Vector2.ZERO})

func _healthiest_living_bench(roster: Array[SkirmishEntity]) -> SkirmishEntity:
	var best: SkirmishEntity = null
	var best_frac := -1.0
	for e in roster:
		if e == null or not is_instance_valid(e) or e.is_dead or e.is_active:
			continue
		if e.entity_config == null:
			continue
		var frac := float(e.entity_config.curr_health) / float(maxi(e.entity_config.max_health, 1))
		if frac > best_frac:
			best_frac = frac
			best = e
	return best

func _team_has_living(roster: Array[SkirmishEntity]) -> bool:
	for e in roster:
		if e != null and is_instance_valid(e) and not e.is_dead:
			return true
	return false

func _winning_side(loser: EntityConfig.EntityType) -> EntityConfig.EntityType:
	return EntityConfig.EntityType.VILLAIN if loser == EntityConfig.EntityType.HERO else EntityConfig.EntityType.HERO

func _finish(winner: EntityConfig.EntityType) -> void:
	if _finished:
		return
	_finished = true
	await get_tree().create_timer(OUTRO_SECONDS).timeout
	finished.emit(winner)
