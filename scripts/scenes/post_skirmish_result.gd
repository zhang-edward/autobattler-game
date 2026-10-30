class_name PostSkirmishResult
extends Node2D

@export var hero_exp_gain_panel_scene: PackedScene
@export var skirmish_reward_panel_scene: PackedScene

@onready var result_label: Label = %ResultLabel
@onready var hero_exp_bars: VBoxContainer = %HeroExpBars
@onready var skirmish_result_container: HBoxContainer = %SkirmishResultContainer
@onready var continue_button: Button = %Continue
@onready var post_skirmish_villain_details: PostSkirmishVillainDetails = %PostSkirmishVillainDetails

func _ready():
	setup_hero_exp_gain_panels()
	handle_skirmish_result()
	continue_button.pressed.connect(on_continue)
	
func on_continue():
	get_tree().change_scene_to_file("res://scenes/dispatch.tscn")

func handle_skirmish_result():
	var threat_req_config = GameVariables.selected_threat_request_config
	var winner = GameVariables.skirmish_winner
	var did_player_win = winner == EntityConfig.EntityType.HERO
	if did_player_win:
		result_label.text = "Victory!"
		for c in hero_exp_bars.get_children():
			var child = c as HeroExpGainPanel
			child.setup_reward(threat_req_config.reward.exp_gain)
	else:
		result_label.text = "Defeat..."
		for c in hero_exp_bars.get_children():
			var child = c as HeroExpGainPanel
			var reduced_exp = round(threat_req_config.reward.exp_gain * 0.5)
			child.setup_reward(reduced_exp)
	add_skirmish_reward_panels(did_player_win)
	var enemy_config: EntityConfig = threat_req_config.enemy_configs[0]
	post_skirmish_villain_details.configure(enemy_config)

func add_skirmish_reward_panels(did_player_win: bool):
	var threat_req_config = GameVariables.selected_threat_request_config
	var exp_gain = threat_req_config.reward.exp_gain
	var money = threat_req_config.reward.money
	var renown = threat_req_config.reward.renown
	if !did_player_win:
		exp_gain = round(exp_gain * 0.5)
		money = round(money * 0.5)
		renown = 0
	add_skirmish_reward_panel("EXP", exp_gain)
	add_skirmish_reward_panel("Money", money)
	add_skirmish_reward_panel("Renown", renown)
	
func add_skirmish_reward_panel(reward_name: String, reward_value: int):
	var panel = skirmish_reward_panel_scene.instantiate() as SkirmishRewardPanel
	skirmish_result_container.add_child(panel)
	panel.setup_reward(reward_name, reward_value)

func setup_hero_exp_gain_panels():
	for h in GameVariables.selected_heroes_for_threat:
		var hero_exp_gain = hero_exp_gain_panel_scene.instantiate() as HeroExpGainPanel
		hero_exp_bars.add_child(hero_exp_gain)
		hero_exp_gain.configure(h)
