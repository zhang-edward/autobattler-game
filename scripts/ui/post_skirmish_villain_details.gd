class_name PostSkirmishVillainDetails
extends PanelContainer

@export var stat_label_scene: PackedScene

@onready var entity_name: Label = %EntityName
@onready var level_value_label: Label = %LevelValue
@onready var hp_value_label: Label = %HPValue
@onready var stat_container: GridContainer = %StatContainer

func configure(entity_config: EntityConfig):
	entity_name.text = entity_config.entity_name
	level_value_label.text = str(entity_config.level)
	hp_value_label.text = str(entity_config.vitality)
