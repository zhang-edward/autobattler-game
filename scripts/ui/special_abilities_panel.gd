class_name SpecialAbilitiesPanel
extends PanelContainer

@onready var offense_moves: SpecialAbilityGrid = %OffenseMoves
@onready var defense_moves: SpecialAbilityGrid = %DefenseMoves

func configure(entity_config: EntityConfig):
	var offense_abilities = entity_config.abilities.filter(func (a: Ability): return a.category == Ability.Category.OFFENSIVE)
	var defense_abilities = entity_config.abilities.filter(func (a: Ability): return a.category == Ability.Category.DEFENSIVE)
	offense_moves.configure_from_abilities(offense_abilities)
	defense_moves.configure_from_abilities(defense_abilities)
