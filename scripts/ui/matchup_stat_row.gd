class_name MatchupStatRow
extends PanelContainer

@onready var hero_stat: Label = %HeroStat
@onready var stat_label: Label = %StatLabel
@onready var villain_stat: Label = %VillainStat

func configure_stat(stat_name: String, hero_value: int, villain_value: int):
	hero_stat.text = str(hero_value)
	villain_stat.text = str(villain_value)
	stat_label.text = stat_name
