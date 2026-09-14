class_name TacticalEncounter
extends Node2D

@export var hero_tactical_entity_scene: PackedScene
@export var villain_tactical_entity_scene: PackedScene
@export var tactical_entity_status_scene: PackedScene
@onready var hero_status_vbox: VBoxContainer = $CanvasLayer/HeroStatusContainer/MarginContainer/VBoxContainer
@onready var villain_status_vbox: VBoxContainer = $CanvasLayer/VillainStatusContainer/MarginContainer/VBoxContainer

const HERO_START_POS = Vector2(-400, -200)
const VILLAIN_START_POS = Vector2(400, -200)

var hero_entity_statuses: Array[TacticalEntityStatus] = []
var hero_entities: Array[TacticalEntity] = []
var villain_entities: Array[TacticalEntity] = []
var villain_entity_statuses: Array[TacticalEntityStatus] = []
var civilian_entities: Array[TacticalEntity] = []

var selected_hero: HeroTacticalEntity

func _ready() -> void:
	reset_all_entity_round_state()
	hero_entity_statuses = init_entity_statuses(GameVariables.player_lineup, hero_status_vbox)
	villain_entity_statuses = init_entity_statuses(GameVariables.villain_lineup, villain_status_vbox)
	hero_entities = init_ingame_entities(GameVariables.player_lineup, HERO_START_POS, EntityConfig.EntityType.HERO)
	villain_entities = init_ingame_entities(GameVariables.villain_lineup, VILLAIN_START_POS, EntityConfig.EntityType.VILLAIN)

func reset_all_entity_round_state():
	for ec in GameVariables.player_lineup:
		ec.curr_health = ec.max_health
		ec.gained_exp = 0
		ec.num_kills = 0
		ec.num_assists = 0
	# Don't track exp, kills, assists on villains
	for ec in GameVariables.villain_lineup:
		ec.curr_health = ec.max_health
	
func init_entity_statuses(lineup: Array[EntityConfig], container: Container):
	var entity_statuses: Array[TacticalEntityStatus] = []
	for ec in lineup:
		var entity_config = ec as EntityConfig
		var tac_entity_status = tactical_entity_status_scene.instantiate() as TacticalEntityStatus
		container.add_child(tac_entity_status)
		entity_statuses.append(tac_entity_status)
		tac_entity_status.configure_entity_config(entity_config)
	return entity_statuses

func init_ingame_entities(lineup: Array[EntityConfig], start_pos: Vector2, entity_type: EntityConfig.EntityType):
	var pos = start_pos
	var entities: Array[TacticalEntity] = []
	for ec in lineup:
		var entity_config = ec as EntityConfig
		var tac_entity_scene = villain_tactical_entity_scene if entity_type == EntityConfig.EntityType.VILLAIN else hero_tactical_entity_scene
		var tac_entity = tac_entity_scene.instantiate() as TacticalEntity
		add_child(tac_entity)
		entities.append(tac_entity)
		tac_entity.configure_from_entity_config(entity_config)
		tac_entity.global_position = pos
		pos.y += 100
	return entities

func select_hero_entity(hte: HeroTacticalEntity):
	if selected_hero != null:
		selected_hero.deselect()
	selected_hero = hte
	var selected_status: TacticalEntityStatus
	for s in hero_entity_statuses:
		s.deselect()
		if s.entity_config == hte.entity_config:
			selected_status = s
	if selected_status != null:
		selected_status.select()
