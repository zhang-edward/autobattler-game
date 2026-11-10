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
	if not GameVariables.curr_threat_skirmish.leveled_up_heroes.is_empty():
		get_tree().change_scene_to_file("res://scenes/level_up.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/dispatch.tscn")

func handle_skirmish_result():
	var threat_req_config = GameVariables.curr_threat_skirmish.threat_request_config
	var winner = GameVariables.curr_threat_skirmish.winner
	var did_player_win = winner == EntityConfig.EntityType.HERO
	result_label.text = "Victory!" if did_player_win else "Defeat..."
	add_skirmish_reward_panels(did_player_win)
	var enemy_config: EntityConfig = threat_req_config.enemy_configs[0]
	post_skirmish_villain_details.configure(enemy_config)

func add_skirmish_reward_panels(did_player_win: bool):
	var threat_req_config = GameVariables.curr_threat_skirmish.threat_request_config
	var exp_gain = threat_req_config.reward.exp_gain
	var money = threat_req_config.reward.money
	if !did_player_win:
		exp_gain = round(exp_gain * 0.5)
		money = round(money * 0.5)
	add_skirmish_reward_panel("EXP", exp_gain)
	add_skirmish_reward_panel("Money", money)
	add_skirmish_reward_panel("Reputation", GameVariables.curr_threat_skirmish.reputation_change)
	
func add_skirmish_reward_panel(reward_name: String, reward_value: int):
	var panel = skirmish_reward_panel_scene.instantiate() as SkirmishRewardPanel
	skirmish_result_container.add_child(panel)
	panel.setup_reward(reward_name, reward_value)

func setup_hero_exp_gain_panels():
	var threat_skirmish = GameVariables.curr_threat_skirmish
	var exp_gain = threat_skirmish.threat_request_config.reward.exp_gain
	if threat_skirmish.winner != EntityConfig.EntityType.HERO:
		exp_gain = round(exp_gain * 0.5)
	var exp_share = roundi(float(exp_gain) / maxi(threat_skirmish.entered_heroes.size(), 1))
	for hero_config in threat_skirmish.heroes + threat_skirmish.bench_heroes:
		var panel = hero_exp_gain_panel_scene.instantiate() as HeroExpGainPanel
		hero_exp_bars.add_child(panel)
		panel.configure(hero_config)
		panel.setup_reward(exp_share if threat_skirmish.entered_heroes.has(hero_config) else 0)
		if panel.did_level_up:
			threat_skirmish.leveled_up_heroes.append(hero_config)
