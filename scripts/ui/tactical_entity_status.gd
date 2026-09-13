class_name TacticalEntityStatus
extends HBoxContainer

@onready var texture_rect: TextureRect = $TextureRect
@onready var hero_name_label: Label = $VBoxContainer/HeroNameLabel
@onready var health_bar: ProgressBar = $VBoxContainer/ProgressBar

var entity_config: EntityConfig

func configure_entity_config(ec: EntityConfig):
	entity_config = ec
	hero_name_label.text = entity_config.entity_name
	health_bar.max_value = entity_config.max_health
	health_bar.value = health_bar.max_value
