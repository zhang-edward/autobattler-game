class_name SpecialAbilitiesPanel
extends PanelContainer

@onready var offense_moves: SpecialAbilityGrid = %OffenseMoves

func configure(entity_config: EntityConfig):
	offense_moves.configure_from_abilities(entity_config.abilities)
