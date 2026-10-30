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
	await get_tree().create_timer(0.5).timeout
	var tween = create_tween()
	tween.tween_property(exp_bar, "value", exp_bar.value + gain_amt, 1.0)
