class_name MatchupHeroPreview
extends PanelContainer

@onready var hero_name: Label = %HeroName
@onready var level_value: Label = %LevelValue
@onready var offense_moves: SpecialAbilityGrid = %OffenseMoves
@onready var change_hero_button: Button = %ChangeHero
@onready var level_container: HBoxContainer = %LevelContainer
@onready var move_grid_container: VBoxContainer = %MoveGridContainer

signal on_change_hero()

func _ready():
	change_hero_button.pressed.connect(change_hero_clicked)
	offense_moves.heading_label.text = "Offense"

func configure(entity_config: EntityConfig):
	level_container.visible = entity_config != null
	move_grid_container.visible = entity_config != null
	if entity_config == null:
		hero_name.text = "No hero selected"
		change_hero_button.text = "Choose Hero"
		return
	change_hero_button.text = "Change Hero"
	hero_name.text = entity_config.entity_name
	if entity_config.injury_recovery_days > 0:
		hero_name.text += " (Resting)"
	level_value.text = str(entity_config.level)
	offense_moves.configure_from_abilities(entity_config.abilities)

func change_hero_clicked():
	on_change_hero.emit()
