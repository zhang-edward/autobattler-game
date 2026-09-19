class_name TacticalEncounter
extends Node2D

@export var hero_tactical_entity_scene: PackedScene
@export var villain_tactical_entity_scene: PackedScene
@export var civ_tactical_entity_scene: PackedScene
@onready var civs_saved_label: Label = $CanvasLayer/HeroStatusContainer/MarginContainer/VBoxContainer/CivsSavedLabel
@onready var civs_killed_label: Label = $CanvasLayer/VillainStatusContainer/MarginContainer/VBoxContainer/CivsKilledLabel

const HERO_START_POS = Vector2(-600, -300)
const VILLAIN_START_POS = Vector2(600, -300)

var hero_entities: Array[TacticalEntity] = []
var villain_entities: Array[TacticalEntity] = []
var civilian_entities: Array[TacticalEntity] = []

var selected_hero: HeroTacticalEntity

func _ready() -> void:
	reset_all_entity_round_state()
	hero_entities = init_ingame_entities(GameVariables.player_lineup, HERO_START_POS, EntityConfig.EntityType.HERO)
	villain_entities = init_ingame_entities(GameVariables.villain_lineup, VILLAIN_START_POS, EntityConfig.EntityType.VILLAIN)
	civilian_entities = init_civilians()

func reset_all_entity_round_state():
	for ec in GameVariables.player_lineup:
		ec.curr_health = ec.max_health
		ec.gained_exp = 0
		ec.num_kills = 0
		ec.num_assists = 0
	# Don't track exp, kills, assists on villains
	for ec in GameVariables.villain_lineup:
		ec.curr_health = ec.max_health

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
	
func init_civilians():
	var civ_entities: Array[TacticalEntity] = []
	var num_civilians_to_spawn = randi_range(5, 12)
	for i in range(0, num_civilians_to_spawn):
		var civ_entity = civ_tactical_entity_scene.instantiate() as CivilianTacticalEntity
		add_child(civ_entity)
		var rand_x = randi_range(-400, 400)
		var rand_y = randi_range(-400, 400)
		civ_entity.global_position = Vector2(rand_x, rand_y)
		civ_entity.on_civilian_saved.connect(add_saved_civilian)
		civ_entity.on_civilian_killed.connect(add_killed_civilian)
		civ_entities.append(civ_entity)
	return civ_entities
	
func add_saved_civilian():
	GameVariables.num_saved_civilians += 1
	civs_saved_label.text = "Civilians Saved: " + str(GameVariables.num_saved_civilians)
	
func add_killed_civilian():
	GameVariables.num_killed_civilians += 1
	civs_killed_label.text = "Civilians Killed: " + str(GameVariables.num_killed_civilians)

func select_hero_entity(hte: HeroTacticalEntity):
	if selected_hero != null:
		selected_hero.deselect()
	selected_hero = hte
