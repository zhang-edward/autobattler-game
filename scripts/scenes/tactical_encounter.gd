class_name TacticalEncounter
extends Node2D

@export var hero_tactical_entity_scene: PackedScene
@export var villain_tactical_entity_scene: PackedScene
@export var civ_tactical_entity_scene: PackedScene

@onready var hud: CanvasLayer = $CanvasLayer
@onready var civs_saved_label: Label = $CanvasLayer/HeroStatusContainer/MarginContainer/VBoxContainer/CivsSavedLabel
@onready var civs_killed_label: Label = $CanvasLayer/VillainStatusContainer/MarginContainer/VBoxContainer/CivsKilledLabel
@onready var spawn_layer: TileMapLayer = $TileMap/Spawn
@onready var ground_layer: TileMapLayer = $TileMap/Ground
@onready var skirmish_preview: SkirmishPreview = $CanvasLayer/SkirmishPreview
@onready var camera: Camera2D = $Camera2D

const HERO_START_POS = Vector2(-600, -300)
const VILLAIN_START_POS = Vector2(600, -300)

# Emitted when a hero runs into a villain. Mission decides what to do about it.
signal skirmish_requested(hero: HeroTacticalEntity, villain: VillainTacticalEntity)

var hero_entities: Array[TacticalEntity] = []
var villain_entities: Array[TacticalEntity] = []
var civilian_entities: Array[TacticalEntity] = []

var selected_hero: HeroTacticalEntity

func _ready() -> void:
	reset_all_entity_round_state()
	hero_entities = init_ingame_entities(GameVariables.player_lineup, get_hero_spawn_positions(), EntityConfig.EntityType.HERO)
	villain_entities = init_ingame_entities(GameVariables.villain_lineup, get_villain_spawn_positions(), EntityConfig.EntityType.VILLAIN)
	civilian_entities = init_civilians()

func reset_all_entity_round_state():
	for ec in GameVariables.player_lineup:
		ec.curr_health = ec.max_health
		ec.gained_exp = 0
		ec.num_assists = 0
		ec.defeated_villain_names = []
	# Don't track exp, kills, assists on villains
	for ec in GameVariables.villain_lineup:
		ec.curr_health = ec.max_health

func get_used_cells_by_id_local(tile_atlas_coords: Vector2i):
	var positions = spawn_layer.get_used_cells_by_id(0, tile_atlas_coords)
	return positions.map(func (t): return spawn_layer.map_to_local(t))

func get_hero_spawn_positions():
	return get_used_cells_by_id_local(Vector2i(4, 18))

func get_villain_spawn_positions():
	return get_used_cells_by_id_local(Vector2i(4, 17))

func init_ingame_entities(lineup: Array[EntityConfig], spawn_positions: Array, entity_type: EntityConfig.EntityType):
	var entities: Array[TacticalEntity] = []
	var index := 0
	for ec in lineup:
		var entity_config = ec as EntityConfig
		var tac_entity_scene = villain_tactical_entity_scene if entity_type == EntityConfig.EntityType.VILLAIN else hero_tactical_entity_scene
		var tac_entity = tac_entity_scene.instantiate() as TacticalEntity
		add_child(tac_entity)
		entities.append(tac_entity)
		tac_entity.configure_from_entity_config(entity_config)
		tac_entity.global_position = spawn_positions[index]
		index += 1
	return entities
	
func init_civilians():
	var civ_spawn_positions = get_used_cells_by_id_local(Vector2(19, 13))
	civ_spawn_positions.shuffle()
	var civ_entities: Array[TacticalEntity] = []
	var num_civilians_to_spawn = randi_range(3, 8)
	for i in range(0, num_civilians_to_spawn):
		var civ_entity = civ_tactical_entity_scene.instantiate() as CivilianTacticalEntity
		add_child(civ_entity)
		var rand_pos = civ_spawn_positions[i]
		civ_entity.global_position = Vector2(rand_pos.x, rand_pos.y)
		civ_entity.on_civilian_saved.connect(add_saved_civilian)
		civ_entity.on_civilian_killed.connect(add_killed_civilian)
		civ_entities.append(civ_entity)
	return civ_entities
	
func debug_set_civilian_count(target_count: int) -> void:
	target_count = max(target_count, 0)
	civilian_entities = civilian_entities.filter(func (c): return is_instance_valid(c))
	var diff = target_count - civilian_entities.size()
	if diff > 0:
		var civ_spawn_positions = get_used_cells_by_id_local(Vector2(19, 13))
		civ_spawn_positions.shuffle()
		for i in range(diff):
			var civ_entity = civ_tactical_entity_scene.instantiate() as CivilianTacticalEntity
			add_child(civ_entity)
			if civ_spawn_positions.size() > 0:
				var rand_pos = civ_spawn_positions[i % civ_spawn_positions.size()]
				civ_entity.global_position = Vector2(rand_pos.x, rand_pos.y)
			civ_entity.on_civilian_saved.connect(add_saved_civilian)
			civ_entity.on_civilian_killed.connect(add_killed_civilian)
			civilian_entities.append(civ_entity)
	elif diff < 0:
		for i in range(-diff):
			if civilian_entities.is_empty():
				break
			var c = civilian_entities.pop_back()
			if is_instance_valid(c):
				c.queue_free()

func add_saved_civilian():
	GameVariables.num_saved_civilians += 1
	civs_saved_label.text = "Civilians Saved: " + str(GameVariables.num_saved_civilians)
	handle_encounter_end_condition()
	
func add_killed_civilian():
	GameVariables.num_killed_civilians += 1
	civs_killed_label.text = "Civilians Killed: " + str(GameVariables.num_killed_civilians)
	handle_encounter_end_condition()
	
func handle_encounter_end_condition():
	var num_accounted_civs = GameVariables.num_saved_civilians + GameVariables.num_killed_civilians
	if num_accounted_civs == civilian_entities.size():
		var num_saved = GameVariables.num_saved_civilians
		var num_killed = GameVariables.num_killed_civilians
		GameVariables.encounter_end_state = GameVariables.EncounterEndState.VICTORY if num_saved > num_killed else GameVariables.EncounterEndState.DEFEAT
		get_tree().change_scene_to_file("res://scenes/post_encounter.tscn")

func select_hero_entity(hte: HeroTacticalEntity):
	if selected_hero != null:
		selected_hero.deselect()
	selected_hero = hte

func freeze():
	process_mode = Node.PROCESS_MODE_DISABLED
	hud.hide()

func unfreeze():
	process_mode = Node.PROCESS_MODE_INHERIT
	hud.show()
