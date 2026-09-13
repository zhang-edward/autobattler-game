class_name TacticalEntity
extends Node2D

enum TacticalEntityType {
	HERO,
	VILLAIN,
	CIVILIAN
}

@onready var sprite: Sprite2D = $Sprite2D
var tactical_entity_type: TacticalEntityType

func _ready():
	if tactical_entity_type == TacticalEntityType.HERO:
		sprite.self_modulate = Color(0, 1, 0)
	elif tactical_entity_type == TacticalEntityType.VILLAIN:
		sprite.self_modulate = Color(1, 0, 0)
	elif tactical_entity_type == TacticalEntityType.CIVILIAN:
		sprite.self_modulate = Color(0, 0, 1)
