class_name HeroExpGainPanel
extends PanelContainer

@onready var exp_bar: ProgressBar = %EXPBar
@onready var hero_name: Label = %HeroName
@onready var hero_level: Label = %HeroLevel
@onready var exp_gain_amt: Label = %EXPGain

var entity_config: EntityConfig

func configure(config: EntityConfig):
	entity_config = config
	hero_name.text = config.entity_name
	hero_level.text = "Lv. " + str(config.level)
	
func setup_reward(gain_amt: int):
	exp_gain_amt.text = "+" + str(gain_amt)
	exp_bar.value = entity_config.exp
	exp_bar.max_value = entity_config.exp_to_next_level
	incr_exp_bar(gain_amt)

func incr_exp_bar(amt: float):
	if amt <= 0:
		return
	exp_bar.value += 0.2
	if exp_bar.value >= exp_bar.max_value:
		entity_config.exp_to_next_level = entity_config.get_exp_to_next_level(entity_config.level)
		entity_config.level += 1
		hero_level.text = "Lv. " + str(entity_config.level)
		exp_bar.max_value = entity_config.exp_to_next_level
		exp_bar.value = 0
	await get_tree().create_timer(0.01).timeout
	incr_exp_bar(amt - 0.2)
