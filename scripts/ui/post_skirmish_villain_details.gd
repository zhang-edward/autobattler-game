class_name PostSkirmishVillainDetails
extends PanelContainer

@export var stat_label_scene: PackedScene

@onready var entity_name: Label = %EntityName
@onready var level_value_label: Label = %LevelValue
@onready var health_bar: HealthBar = %HealthBar
@onready var stat_grid: GridContainer = %StatGrid

func configure(entity_config: EntityConfig):
	entity_name.text = entity_config.entity_name
	health_bar.configure(entity_config)
	for c in stat_grid.get_children():
		c.queue_free()
	add_stat_row("STR", entity_config.strength)
	add_stat_row("RES", entity_config.resilience)
	add_stat_row("AGI", entity_config.agility)
	add_stat_row("EVA", entity_config.evasion)
	add_stat_row("DEF", entity_config.defense)

func add_stat_row(stat_name: String, stat_value: int):
	var stat_label = stat_label_scene.instantiate() as StatLabel
	stat_grid.add_child(stat_label)
	stat_label.configure(stat_name, stat_value)
