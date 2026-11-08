class_name HeroExpGainPanel
extends PanelContainer

@onready var exp_bar: ProgressBar = %EXPBar
@onready var hero_name: Label = %HeroName
@onready var hero_level: Label = %HeroLevel
@onready var exp_gain_amt: Label = %EXPGain
@onready var health_bar: HealthBar = %HealthBar

var entity_config: EntityConfig
var did_level_up := false

func _ready() -> void:
	did_level_up = false

func configure(config: EntityConfig):
	entity_config = EntityConfigBuilder.from_entity_config(config).build()
	hero_name.text = config.entity_name
	hero_level.text = "Lv. " + str(config.level)
	health_bar.configure(config)

func setup_reward(gain_amt: int):
	exp_gain_amt.text = "+" + str(gain_amt)
	exp_bar.value = entity_config.exp
	exp_bar.max_value = entity_config.exp_to_next_level
	incr_exp_bar(gain_amt)
	apply_rewards(entity_config, gain_amt)

func apply_rewards(ec: EntityConfig, gain_amt: int):
	for c in GameVariables.player_lineup:
		if c.entity_name == ec.entity_name:
			var new_exp_amt = ec.exp + gain_amt
			if new_exp_amt >= c.exp_to_next_level:
				c.exp = new_exp_amt - ec.exp_to_next_level
				c.level += 1
				did_level_up = true
				c.exp_to_next_level = c.get_exp_to_next_level(c.level)
			else:
				c.exp = new_exp_amt

func incr_exp_bar(amt: float):
	if amt <= 0:
		entity_config.exp = int(exp_bar.value)
		return
	exp_bar.value += 0.2
	if exp_bar.value >= exp_bar.max_value:
		did_level_up = true
		entity_config.exp_to_next_level = entity_config.get_exp_to_next_level(entity_config.level)
		entity_config.level += 1
		hero_level.text = "Lv. " + str(entity_config.level)
		exp_bar.max_value = entity_config.exp_to_next_level
		exp_bar.value = 0
	await get_tree().create_timer(0.01).timeout
	incr_exp_bar(amt - 0.2)
