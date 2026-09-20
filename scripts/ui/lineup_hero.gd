class_name LineupHero
extends PanelContainer

@export var stat_container_scene: PackedScene
@onready var stat_container_wrapper: HBoxContainer = $VBoxContainer/StatContainerWrapper
@onready var hero_name_label: Label = $VBoxContainer/HBoxContainer/VBoxContainer/Name
@onready var level_label: Label = $VBoxContainer/HBoxContainer/VBoxContainer/Level
@onready var button: Button = $Button

var entity_config: EntityConfig

signal on_select(lh: LineupHero)

func _ready() -> void:
	var select = func _select():
		on_select.emit(self)
	button.pressed.connect(select)

func setup(ec: EntityConfig):
	entity_config = ec
	hero_name_label.text = entity_config.entity_name
	level_label.text = "Lv. " + str(entity_config.level)
	var stats_to_show = [
		{ "stat_name": "HP", "value": entity_config.max_health },
		{ "stat_name": "ATK", "value": entity_config.attack },
		{ "stat_name": "DEF", "value": entity_config.defense },
		{ "stat_name": "G.SPD", "value": entity_config.ground_speed },
		{ "stat_name": "A.SPD", "value": entity_config.air_speed }
	]
	for c in stat_container_wrapper.get_children():
		if c is StatContainer:
			stat_container_wrapper.remove_child(c)
			c.queue_free()
	for stat in stats_to_show:
		var sc = stat_container_scene.instantiate() as StatContainer
		stat_container_wrapper.add_child(sc)
		sc.set_stat_value(stat.stat_name, stat.value)
