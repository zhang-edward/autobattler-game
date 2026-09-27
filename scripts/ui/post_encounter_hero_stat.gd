class_name PostEncounterHeroStat
extends HBoxContainer

@onready var hero_name_label: Label = $HeroName
@onready var villains_defeated_label: Label = $VillainsDefeated
@onready var assists_label: Label = $Assists
@onready var damage_dealt_label: Label = $DamageDealt
@onready var civilians_saved_label: Label = $CiviliansSaved
@onready var level_label: Label = $Level
@onready var exp_bar: ProgressBar = $ExpBar

var gained_exp_remaining := 0
var gain_exp_timer: Timer
var entity_config: EntityConfig
static var EXP_INCREMENT = 1

func configure(config: EntityConfig):
	entity_config = config
	hero_name_label.text = config.entity_name
	villains_defeated_label.text = str(config.defeated_villain_names.size())
	assists_label.text = str(config.num_assists)
	damage_dealt_label.text = str(config.damage_dealt)
	civilians_saved_label.text = str(config.num_civs_saved)
	level_label.text = str(config.level)
	exp_bar.value = config.exp
	exp_bar.max_value = config.exp_to_next_level
	add_gained_exp()

func add_gained_exp():
	await get_tree().create_timer(0.5).timeout
	gained_exp_remaining = entity_config.gained_exp
	gain_exp_timer = Timer.new()
	gain_exp_timer.autostart = true
	gain_exp_timer.one_shot = false
	gain_exp_timer.timeout.connect(add_exp_increment)
	gain_exp_timer.wait_time = 0.02
	add_child(gain_exp_timer)

func add_exp_increment():
	if gained_exp_remaining == 0 and is_instance_valid(gain_exp_timer):
		gain_exp_timer.stop()
		gain_exp_timer.queue_free()
	else:
		exp_bar.value += EXP_INCREMENT
		if exp_bar.value >= exp_bar.max_value:
			exp_bar.value = exp_bar.value - exp_bar.max_value
			entity_config.handle_level_up()
			exp_bar.max_value = entity_config.exp_to_next_level
			level_label.text = str(entity_config.level)
		gained_exp_remaining -= EXP_INCREMENT
