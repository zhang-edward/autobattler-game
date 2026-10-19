class_name EnemyPreview
extends VBoxContainer

@export var stat_label_scene: PackedScene
@onready var stat_grid: GridContainer = %StatContainer
@onready var level_value: Label = %LevelValue
@onready var power_type: Label = %PowerType
@onready var enemy_name: Label = %EnemyName

func configure(config: EntityConfig):
	enemy_name.text = config.entity_name
	level_value.text = str(config.level)
	power_type.text = GameVariables.get_label_from_power_type(config.entity_power_type)
	add_stat_label("STR", config.strength)
	add_stat_label("SKL", config.skill)
	add_stat_label("AGI", config.agility)
	add_stat_label("VIT", config.vitality)
	add_stat_label("DEF", config.defense)
	add_stat_label("CHA", config.charisma)

func add_stat_label(stat_name: String, stat_value: int):
	var stat_label = stat_label_scene.instantiate() as StatLabel
	stat_grid.add_child(stat_label)
	stat_label.configure(stat_name, stat_value)
