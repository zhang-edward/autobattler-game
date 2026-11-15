class_name CharacterStatsPanel
extends PanelContainer

@onready var level: Label = %Level
@onready var exp_amount: Label = %ExpAmount
@onready var exp_bar: ProgressBar = %ExpBar
@onready var stat_list: VBoxContainer = %StatList

@export var stat_label_scene: PackedScene

func configure(entity_config: EntityConfig):
	exp_bar.value = entity_config.exp
	exp_bar.max_value = entity_config.exp_to_next_level
	level.text = "Lv " + str(entity_config.level)
	exp_amount.text = str(entity_config.exp) + "/" + str(entity_config.exp_to_next_level)
	for c in stat_list.get_children():
		c.queue_free()
	add_stat_label("Strength", entity_config.strength)
	add_stat_label("Resilience", entity_config.resilience)
	add_stat_label("Agility", entity_config.agility)
	add_stat_label("Evasion", entity_config.evasion)
	add_stat_label("Defense", entity_config.defense)

func add_stat_label(stat_name: String, stat_value: int):
	var stat_label = stat_label_scene.instantiate() as StatLabelBordered
	stat_list.add_child(stat_label)
	stat_label.configure(stat_name, stat_value)
