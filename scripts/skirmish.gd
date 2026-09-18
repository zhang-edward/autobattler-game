class_name Skirmish
extends Node2D

@export var hero: SkirmishEntity
@export var villain: SkirmishEntity

func _ready() -> void:
	hero.entity_type = EntityConfig.EntityType.HERO
	villain.entity_type = EntityConfig.EntityType.VILLAIN
