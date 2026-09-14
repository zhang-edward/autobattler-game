class_name TacticalEntity
extends CharacterBody2D

@onready var game = get_node("/root/TacticalEncounter") as TacticalEncounter
@export var sprite: Sprite2D
@export var health_bar: ProgressBar
@export var entity_detector: Area2D

enum TacticalEntityType {
	HERO,
	VILLAIN,
	CIVILIAN
}
var tactical_entity_type: TacticalEntityType
var entity_config: EntityConfig

func _ready() -> void:
	entity_detector.area_entered.connect(collide_area)
	
func collide_area(area: Area2D):
	print(area)
	pass

func configure_from_entity_config(ec: EntityConfig):
	entity_config = ec
	health_bar.max_value = ec.max_health
	health_bar.value = health_bar.max_value

func _physics_process(_delta: float) -> void:
	move_and_slide()
