class_name HeroTacticalEntity
extends TacticalEntity

@onready var button = $Button as Button

func _ready():
	button.pressed.connect(select)
	
func select():
	game.select_hero_entity(self)
	sprite.self_modulate = Color(1, 1, 0)

func deselect():
	sprite.self_modulate = Color(0, 1, 0)

func configure_from_entity_config(ec: EntityConfig):
	super.configure_from_entity_config(ec)
	sprite.self_modulate = Color(0, 1, 0)
