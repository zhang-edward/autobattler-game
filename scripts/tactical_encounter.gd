class_name TacticalEncounter
extends Node2D

@export var tactical_encounter_entity_scene: PackedScene
@export var tactical_entity_status_scene: PackedScene
@onready var hero_status_vbox: VBoxContainer = $CanvasLayer/HeroStatusContainer/MarginContainer/VBoxContainer
@onready var villain_status_vbox: VBoxContainer = $CanvasLayer/VillainStatusContainer/MarginContainer/VBoxContainer

const PLAYER_START_POS = Vector2(-400, -200)
const VILLAIN_START_POS = Vector2(400, -200)

func _ready() -> void:
	reset_all_entity_round_state()
	init_entity_statuses(GameVariables.player_lineup, hero_status_vbox)
	init_entity_statuses(GameVariables.villain_lineup, villain_status_vbox)
	init_ingame_entities(GameVariables.player_lineup, PLAYER_START_POS)
	init_ingame_entities(GameVariables.villain_lineup, VILLAIN_START_POS)

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
	for ec in lineup:
		var entity_config = ec as EntityConfig
		var tac_entity_status = tactical_entity_status_scene.instantiate() as TacticalEntityStatus
		container.add_child(tac_entity_status)
		tac_entity_status.configure_entity_config(entity_config)

func init_ingame_entities(lineup: Array[EntityConfig], start_pos: Vector2):
	var pos = start_pos
	for ec in lineup:
		var entity_config = ec as EntityConfig
		var tac_entity = tactical_encounter_entity_scene.instantiate() as TacticalEntity
		add_child(tac_entity)
		tac_entity.configure_from_entity_config(entity_config)
		tac_entity.global_position = pos
		pos.y += 100
