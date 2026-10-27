class_name HeroExpGainPanel
extends PanelContainer

@onready var exp_bar: ProgressBar = %EXPBar
@onready var hero_name: Label = %HeroName
@onready var hero_level: Label = %HeroLevel
@onready var exp_gain_amt: Label = %EXPGain

func configure(config: EntityConfig):
	hero_name.text = config.entity_name
	hero_level.text = "Lv. " + str(config.level)
	
func setup_reward(gain_amt: int):
	exp_gain_amt.text = "+" + str(gain_amt)
