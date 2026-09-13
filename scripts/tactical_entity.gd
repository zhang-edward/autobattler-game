class_name TacticalEntity
extends Node2D

enum TacticalEntityType {
	HERO,
	VILLAIN,
	CIVILIAN
}

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $ProgressBar

var tactical_entity_type: TacticalEntityType

func configure_from_entity_config(ec: EntityConfig):
	if ec.entity_type == EntityConfig.EntityType.HERO:
		tactical_entity_type = TacticalEntityType.HERO
	elif ec.entity_type == EntityConfig.EntityType.VILLAIN:
		tactical_entity_type = TacticalEntityType.VILLAIN
	health_bar.max_value = ec.max_health
	health_bar.value = health_bar.max_value
	
	# TODO: placeholder to distinguish heroes, villains, and civilians simply
	if tactical_entity_type == TacticalEntityType.HERO:
		sprite.self_modulate = Color(0, 1, 0)
		health_bar.add_theme_stylebox_override("fill", load("res://prefabs/styles/hero_health_bar.tres"))
	elif tactical_entity_type == TacticalEntityType.VILLAIN:
		sprite.self_modulate = Color(1, 0, 0)
		health_bar.add_theme_stylebox_override("fill", load("res://prefabs/styles/villain_health_bar.tres"))
	elif tactical_entity_type == TacticalEntityType.CIVILIAN:
		sprite.self_modulate = Color(0, 0, 1)

func configure_civilian(hp: int):
	tactical_entity_type == TacticalEntityType.CIVILIAN
	health_bar.max_value = hp 
	health_bar.value = health_bar.max_value
