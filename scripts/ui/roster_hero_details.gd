class_name RosterHeroDetails
extends PanelContainer

@onready var special_abilities_panel: SpecialAbilitiesPanel = %SpecialAbilitiesPanel
@onready var character_stats_panel: CharacterStatsPanel = %CharacterStatsPanel
@onready var hero_name: Label = %HeroName
@onready var back_button: Button = %BackButton
@onready var health_bar: HealthBar = %HealthBar

func configure(entity_config: EntityConfig):
	hero_name.text = entity_config.entity_name
	health_bar.configure(entity_config)
	special_abilities_panel.configure(entity_config)
	character_stats_panel.configure(entity_config)
