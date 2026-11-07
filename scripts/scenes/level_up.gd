class_name LevelUp
extends Node2D

@export var level_up_new_ability_scene: PackedScene
@export var level_up_stat_row_scene: PackedScene

@onready var ability_list: VBoxContainer = %AbilityList
@onready var stat_list: VBoxContainer = %StatList
@onready var confirm_button: Button = %Confirm

var hero_config: EntityConfig
var stat_points_to_distribute := 3

func _ready() -> void:
	if GameVariables.selected_hero_for_threat == null:
		GameVariables.selected_hero_for_threat = GameVariables.generate_random_entity_configs(1, EntityConfig.EntityType.HERO)[0]
	hero_config = GameVariables.selected_hero_for_threat
	add_level_up_stat_row("Strength", hero_config.strength)
	add_level_up_stat_row("Defense", hero_config.defense)	
	add_level_up_stat_row("Skill", hero_config.skill)
	add_level_up_stat_row("Agility", hero_config.agility)
	add_level_up_stat_row("Vitality", hero_config.vitality)
	add_level_up_stat_row("Charisma", hero_config.charisma)
	confirm_button.pressed.connect(apply_and_transition_to_roster)

func apply_and_transition_to_roster():
	get_tree().change_scene_to_file("res://scenes/roster.tscn")

func add_level_up_stat_row(stat_name: String, stat_value: int):
	var level_up_stat_row = level_up_stat_row_scene.instantiate() as LevelUpStatRow
	stat_list.add_child(level_up_stat_row)
	level_up_stat_row.configure(self, stat_name, stat_value)
	level_up_stat_row.on_increase.connect(increase_stat)
	level_up_stat_row.on_decrease.connect(decrease_stat)

func increase_stat(stat_key: String):
	stat_points_to_distribute -= 1
	hero_config[stat_key] += 1

func decrease_stat(stat_key: String):
	stat_points_to_distribute += 1
	hero_config[stat_key] -= 1
