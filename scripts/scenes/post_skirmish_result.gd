class_name PostSkirmishResult
extends Node2D

@export var hero_exp_gain_panel_scene: PackedScene
@export var skirmish_reward_panel_scene: PackedScene
@onready var result_label: Label = %ResultLabel
@onready var hero_exp_bars: VBoxContainer = %HeroExpBars
@onready var skirmish_result_panel: HBoxContainer = %SkirmishResultPanel
@onready var continue_button: Button = %Continue

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
			var reduced_exp = round(threat_req_config.reward_exp_gain * 0.5)
			child.setup_rewawrd(reduced_exp)
	add_skirmish_result_panels(did_player_win)

func add_skirmish_result_panels(did_player_win: bool):
	var threat_req_config = GameVariables.selected_threat_request_config
	var exp_gain = threat_req_config.reward.exp_gain
	var money = threat_req_config.reward.money
	var renown = threat_req_config.reward.renown
	if !did_player_win:
		exp_gain = round(exp_gain * 0.5)
		money = round(money * 0.5)
		renown = 0
	var exp_panel = skirmish_reward_panel_scene.instantiate() as SkirmishRewardPanel
	exp_panel.setup_reward("EXP", exp_gain)
	var money_panel = skirmish_reward_panel_scene.instantiate() as SkirmishRewardPanel
	money_panel.setup_reward("Money", money)
	var renown_panel = skirmish_reward_panel_scene.instantiate() as SkirmishRewardPanel
	renown_panel.setup_reward("Renown", renown)

func setup_hero_exp_gain_panels():
	for h in GameVariables.selected_heroes_for_threat:
		var hero_exp_gain = hero_exp_gain_panel_scene.instantiate() as HeroExpGainPanel
		hero_exp_bars.add_child(hero_exp_gain)
		hero_exp_gain.configure(h)
