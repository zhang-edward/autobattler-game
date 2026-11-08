class_name AssignHeroes
extends Node2D

@onready var back_button: Button = %Back
@onready var dispatch_button: Button = %Dispatch
@onready var choose_hero_modal: ChooseHeroModal = %ChooseHeroModal
@onready var hero_preview: MatchupHeroPreview = %MatchupHeroPreview
@onready var villain_preview: MatchupHeroPreview = %MatchupVillainPreview
@onready var stat_comparison: MatchupStatComparison = %MatchupStatComparison

func _ready() -> void:
	back_button.pressed.connect(go_to_dispatch_scene)
	dispatch_button.pressed.connect(go_to_skirmish_scene)
	if GameVariables.curr_threat_skirmish == null:
		_generate_debug_data()
	if GameVariables.curr_threat_skirmish.heroes.is_empty():
		GameVariables.curr_threat_skirmish.heroes = [GameVariables.player_lineup[0]]
	update_entity_previews()
	update_stat_comparison()
	hero_preview.on_change_hero.connect(open_choose_hero_modal)
	choose_hero_modal.on_confirm_hero_to_add.connect(update_selected_hero_for_threat_req)
	
func update_selected_hero_for_threat_req(hero_config: EntityConfig):
	GameVariables.curr_threat_skirmish.heroes = [hero_config]
	update_stat_comparison()
	update_entity_previews()

func _generate_debug_data():
	print("generating debug data...")
	GameVariables.curr_threat_skirmish = ThreatSkirmish.new(ThreatGenerator.generate_random_threat_requests(1, GameVariables.player_lineup)[0])
	GameVariables.curr_threat_skirmish.heroes = [GameVariables.player_lineup[0]]

func update_entity_previews():
	var threat_req = GameVariables.curr_threat_skirmish.threat_request_config
	var villain_config = threat_req.enemy_configs[0]
	var hero_config = GameVariables.curr_threat_skirmish.heroes[0]
	hero_preview.configure(hero_config)
	villain_preview.configure(villain_config)
	villain_preview.change_hero_button.hide()
	dispatch_button.disabled = hero_config.injury_recovery_days > 0
	dispatch_button.text = "Dispatch" if hero_config.injury_recovery_days == 0 else "Cannot dispatch! Hero is resting"

func update_stat_comparison():
	var threat_req = GameVariables.curr_threat_skirmish.threat_request_config
	var villain_config = threat_req.enemy_configs[0]
	stat_comparison.configure_stat_rows(GameVariables.curr_threat_skirmish.heroes[0], villain_config)

func go_to_dispatch_scene():
	get_tree().change_scene_to_file("res://scenes/dispatch.tscn")
	
func go_to_skirmish_scene():
	get_tree().change_scene_to_file("res://scenes/skirmish.tscn")

func open_choose_hero_modal():
	choose_hero_modal.show()
	choose_hero_modal.display_available_heroes(GameVariables.curr_threat_skirmish.heroes)
