class_name LevelUp
extends Node2D

@export var level_up_new_ability_scene: PackedScene
@export var level_up_stat_row_scene: PackedScene

@onready var ability_list: VBoxContainer = %AbilityList
@onready var stat_list: VBoxContainer = %StatList

var hero_config: EntityConfig

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

func add_level_up_stat_row(stat_name: String, stat_value: int):
	var level_up_stat_row = level_up_stat_row_scene.instantiate() as LevelUpStatRow
	stat_list.add_child(level_up_stat_row)
	level_up_stat_row.configure(stat_name, stat_value)
	level_up_stat_row.on_increase.connect(increase_stat)

func increase_stat(stat_key: String):
	hero_config[stat_key] += 1
