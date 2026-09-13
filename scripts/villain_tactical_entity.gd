class_name VillainTacticalEntity
extends TacticalEntity

func configure_from_entity_config(ec: EntityConfig):
	super.configure_from_entity_config(ec)
	sprite.self_modulate = Color(1, 0, 0)
