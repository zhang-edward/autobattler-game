class_name MatchupStatComparison
extends PanelContainer

@export var stat_row_scene: PackedScene
@onready var matchup_stat_container: VBoxContainer = %MatchupStatContainer

func configure_stat_rows(hero_config: EntityConfig, villain_config: EntityConfig):
	for c in matchup_stat_container.get_children():
		c.queue_free()
	add_stat_row("Strength", hero_config.strength, villain_config.strength)
	add_stat_row("Defense", hero_config.defense, villain_config.defense)	
	add_stat_row("Skill", hero_config.skill, villain_config.skill)
	add_stat_row("Agility", hero_config.agility, villain_config.agility)
	add_stat_row("Vitality", hero_config.vitality, villain_config.vitality)
	
func add_stat_row(stat_name: String, hero_value: int, villain_value: int):
	var stat_row = stat_row_scene.instantiate() as MatchupStatRow
	matchup_stat_container.add_child(stat_row)
	stat_row.configure_stat(stat_name, hero_value, villain_value)
	
