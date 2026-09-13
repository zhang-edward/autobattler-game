class_name TacticalEntity
extends CharacterBody2D

@onready var game = get_node("/root/TacticalEncounter") as TacticalEncounter
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $ProgressBar

enum TacticalEntityType {
	HERO,
	VILLAIN,
	CIVILIAN
}
var tactical_entity_type: TacticalEntityType
var entity_config: EntityConfig

func configure_from_entity_config(ec: EntityConfig):
	entity_config = ec
	health_bar.max_value = ec.max_health
	health_bar.value = health_bar.max_value

func _physics_process(delta: float) -> void:
	move_and_slide()
