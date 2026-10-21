class_name Skirmish
extends Node2D

signal finished(winner: EntityConfig.EntityType)

const HERO_START := Vector2(400.0, 700.0)
const VILLAIN_START := Vector2(1400.0, 700.0)
const HERO_BENCH := Vector2(400.0, 1200.0)
const VILLAIN_BENCH := Vector2(1400.0, 1200.0)
# Delay between the last death and `finished`, so the body can land and fade first
const OUTRO_SECONDS := 1.5
const STATUS_ROW := preload("res://prefabs/ui/skirmish/skirmish_status_row.tscn")

# Wall layout, authored at this resolution and scaled to the current viewport
const WALL_BASE_SIZE := Vector2(1920.0, 1080.0)
const SIDE_WALL_THICKNESS := 20.0
const BOTTOM_WALL_CENTER_Y := 1000.0
const BOTTOM_WALL_HEIGHT := 136.375
# The top wall's lower edge sits on the horizon (see Background/Ground band fractions)
const TOP_WALL_CENTER_Y := 150.0
const TOP_WALL_HEIGHT := 320.0
const TOP_WALL_SIDE_INSET := 15.0

@export var entity_scene: PackedScene

var hero_statuses: VBoxContainer
var villain_statuses: VBoxContainer

@export_group("Standalone testing")
@export var debug_hero_count := 3
@export var debug_villain_count := 3

var hero_team: Array[SkirmishEntity] = []
var villain_team: Array[SkirmishEntity] = []
var active_hero: SkirmishEntity
var active_villain: SkirmishEntity
var _finished := false
var _status_rows: Array[SkirmishStatusRow] = []

@onready var director: TagDirector = $TagDirector

@onready var _left_wall: StaticBody2D = $VWall
@onready var _right_wall: StaticBody2D = $VWall2
@onready var _bottom_wall: StaticBody2D = $HWall
@onready var _top_wall: StaticBody2D = $HWall2

func _ready() -> void:
	get_viewport().size_changed.connect(_update_walls)
	_update_walls()
	setup(GameVariables.selected_heroes_for_threat, GameVariables.selected_threat_request_config.enemy_configs)
	if hero_team.is_empty() and villain_team.is_empty():
		_setup_debug_matchup()
	_build_status_rows()

func _exit_tree() -> void:
	get_tree().paused = false

func _process(_delta: float) -> void:
	for row in _status_rows:
		row.refresh()
		var is_active := is_instance_valid(row.entity) and (row.entity == active_hero or row.entity == active_villain)
		row.set_active_highlight(is_active)

# Re-fits the four boundary walls to the current viewport so they stay on the screen edges
func _update_walls() -> void:
	var vp := get_viewport_rect().size
	var scale_y := vp.y / WALL_BASE_SIZE.y
	_place_wall(_left_wall, Vector2(0.0, vp.y * 0.5), Vector2(SIDE_WALL_THICKNESS, vp.y))
	_place_wall(_right_wall, Vector2(vp.x, vp.y * 0.5), Vector2(SIDE_WALL_THICKNESS, vp.y))
	_place_wall(_bottom_wall, Vector2(vp.x * 0.5, BOTTOM_WALL_CENTER_Y * scale_y), Vector2(vp.x, BOTTOM_WALL_HEIGHT * scale_y))
	_place_wall(_top_wall, Vector2(vp.x * 0.5, TOP_WALL_CENTER_Y * scale_y), Vector2(vp.x - TOP_WALL_SIDE_INSET * 2.0, TOP_WALL_HEIGHT * scale_y))

# Centres the wall's body on `center` and sizes its rectangle collider to `size`
func _place_wall(wall: StaticBody2D, center: Vector2, size: Vector2) -> void:
	wall.position = center
	var collider := wall.get_node("CollisionShape2D") as CollisionShape2D
	collider.position = Vector2.ZERO
	(collider.shape as RectangleShape2D).size = size

func setup(heroes: Array[EntityConfig], villains: Array[EntityConfig]) -> void:
	for h in heroes:
		h.reset_all_in_round_vars()
	for v in villains:
		v.reset_all_in_round_vars()
	hero_team = _spawn_side(heroes, HERO_START, HERO_BENCH)
	villain_team = _spawn_side(villains, VILLAIN_START, VILLAIN_BENCH)
	active_hero = hero_team[0] if not hero_team.is_empty() else null
	active_villain = villain_team[0] if not villain_team.is_empty() else null

func team_for(team: EntityConfig.EntityType) -> Array[SkirmishEntity]:
	return hero_team if team == EntityConfig.EntityType.HERO else villain_team

func active_for(team: EntityConfig.EntityType) -> SkirmishEntity:
	return active_hero if team == EntityConfig.EntityType.HERO else active_villain

func _build_status_rows() -> void:
	if not _status_rows.is_empty():
		return
	hero_statuses = get_node("%HeroStatuses") as VBoxContainer
	villain_statuses = get_node("%VillainStatuses") as VBoxContainer
	_add_status_rows(hero_team, hero_statuses)
	_add_status_rows(villain_team, villain_statuses)

func _add_status_rows(team: Array[SkirmishEntity], container: VBoxContainer) -> void:
	for entity in team:
		var row := STATUS_ROW.instantiate() as SkirmishStatusRow
		container.add_child(row)
		row.configure(entity)
		_status_rows.append(row)

func can_tag(team: EntityConfig.EntityType, incoming: SkirmishEntity) -> bool:
	if _finished or incoming == null or not is_instance_valid(incoming) or incoming.is_dead:
		return false
	var roster := team_for(team)
	if not roster.has(incoming):
		return false
	var current := active_for(team)
	if current == incoming:
		return false
	if current != null and is_instance_valid(current) and not current.is_dead:
		if current.state_machine == null or not (current.state_machine.state is MoveState):
			return false
	if _is_grab_in_progress():
		return false
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
		config.curr_health = config.vitality
	for config in villains:
		config.curr_health = config.vitality
	setup(heroes, villains)

func _on_entity_died(entity: SkirmishEntity) -> void:
	_release_grab_links(entity)
	var roster := team_for(entity.entity_type)
	if entity != active_for(entity.entity_type):
		if not _team_has_living(roster):
			_finish(_winning_side(entity.entity_type))
		return
	director.request_avenge(entity.entity_type)

func swap_refs(team: EntityConfig.EntityType, incoming: SkirmishEntity) -> void:
	if team == EntityConfig.EntityType.HERO:
		active_hero = incoming
	else:
		active_villain = incoming

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

func _healthiest_living_entity_on_team(team: Array[SkirmishEntity]) -> SkirmishEntity:
	var best: SkirmishEntity = null
	var best_frac := -1.0
	for e in team:
		if e == null or not is_instance_valid(e) or e.is_dead or e.is_active:
			continue
		var frac := float(e.entity_config.curr_health) / float(maxi(e.entity_config.vitality, 1))
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
