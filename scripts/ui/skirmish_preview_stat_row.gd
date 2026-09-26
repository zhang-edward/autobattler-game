class_name SkirmishPreviewStatRow
extends HBoxContainer

@export var stat_container_scene: PackedScene
@onready var hero_name_label: Label = $VBoxContainer/HeroName
@onready var stat_list_container: HBoxContainer = %StatListContainer
@onready var move_icon_container: HBoxContainer = %MoveIconContainer

func configure(entity_config: EntityConfig):
	hero_name_label.text = entity_config.entity_name
	var stat_list = [
		{ "name": "Attack", "value": entity_config.attack },
		{ "name": "Defense", "value": entity_config.defense },
		{ "name": "Lv.", "value": entity_config.level }
	]
	for stat in stat_list:
		var stat_container = stat_container_scene.instantiate() as StatContainer
		stat_list_container.add_child(stat_container)
		stat_container.set_stat_value(stat.name, stat.value)
