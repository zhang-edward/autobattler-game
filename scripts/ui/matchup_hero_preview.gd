class_name MatchupHeroPreview
extends PanelContainer

@onready var hero_name: Label = %HeroName
@onready var level_value: Label = %LevelValue
@onready var offense_moves: SpecialAbilityGrid = %OffenseMoves
@onready var change_hero_button: Button = %ChangeHero

signal on_change_hero()

func _ready():
	change_hero_button.pressed.connect(change_hero_clicked)
	offense_moves.heading_label.text = "Offense"

func configure(entity_config: EntityConfig):
	hero_name.text = entity_config.entity_name
	level_value.text = str(entity_config.level)
	offense_moves.configure_from_abilities(entity_config.abilities)

func change_hero_clicked():
	on_change_hero.emit()
