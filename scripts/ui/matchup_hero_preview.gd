class_name MatchupHeroPreview
extends PanelContainer

@onready var hero_name: Label = %HeroName
@onready var level_value: Label = %LevelValue
@onready var offense_moves: SpecialAbilityGrid = %OffenseMoves
@onready var defense_moves: SpecialAbilityGrid = %DefenseMoves
@onready var change_hero_button: Button = %ChangeHero

signal on_change_hero()

func _ready():
	change_hero_button.pressed.connect(change_hero_clicked)
	offense_moves.heading_label.text = "Offense"
	defense_moves.heading_label.text = "Defense"

func configure(entity_config: EntityConfig):
	hero_name.text = entity_config.entity_name
	level_value.text = str(entity_config.level)
	var offense_abilities = entity_config.abilities.filter(func (a: Ability): return a.category == Ability.Category.OFFENSIVE)
	var defense_abilities = entity_config.abilities.filter(func (a: Ability): return a.category == Ability.Category.DEFENSIVE)
	offense_moves.configure_from_abilities(offense_abilities)
	defense_moves.configure_from_abilities(defense_abilities)

func change_hero_clicked():
	on_change_hero.emit()
