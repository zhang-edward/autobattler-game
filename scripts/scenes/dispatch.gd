class_name Dispatch
extends Node2D

@onready var hero_lineup_container: HBoxContainer = %HeroLineupContainer
@export var hero_status_scene: PackedScene

func _ready() -> void:
	for hero_config in GameVariables.player_lineup:
		var hero_status = hero_status_scene.instantiate() as DispatchHeroStatus
		hero_lineup_container.add_child(hero_status)
		hero_status.init_from_entity_config(hero_config)
