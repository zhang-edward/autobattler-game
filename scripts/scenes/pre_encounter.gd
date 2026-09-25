class_name PreEncounter
extends Node2D

@export var generic_entity_stat_row_scene: PackedScene
@onready var hero_stat_container: VBoxContainer = %HeroStatContainer
@onready var villain_stat_container: VBoxContainer = %VillainStatContainer
@onready var start_button: Button = %StartButton

func _ready() -> void:
	init_entity_stat_rows(hero_stat_container, GameVariables.player_lineup)
	init_entity_stat_rows(villain_stat_container, GameVariables.villain_lineup)
	start_button.pressed.connect(go_to_tactical_encounter)
	
func go_to_tactical_encounter():
	get_tree().change_scene_to_file("res://scenes/mission.tscn")
	
func init_entity_stat_rows(container: VBoxContainer, lineup: Array[EntityConfig]):
	for ec in lineup:
		var stat_row = generic_entity_stat_row_scene.instantiate() as GenericEntityStatRow
		container.add_child(stat_row)
		stat_row.configure_from_entity_config(ec)
		stat_row.cost.hide()
