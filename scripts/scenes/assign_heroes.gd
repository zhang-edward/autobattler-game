class_name AssignHeroes
extends Node2D

@export var hero_preview_row: PackedScene

@onready var back_button: Button = %Back
@onready var dispatch_button: Button = %Dispatch
@onready var choose_hero_modal: ChooseHeroModal = %ChooseHeroModal
@onready var hero_preview: MatchupHeroPreview = %MatchupHeroPreview
@onready var villain_preview: MatchupHeroPreview = %MatchupVillainPreview
@onready var stat_comparison: MatchupStatComparison = %MatchupStatComparison
@onready var override_skirmish_results: CheckBox = %OverrideSkirmishResults
@onready var backup_rows: VBoxContainer = %BackupRows
@onready var backup_add_hero_button: Button = %BackupAddHeroButton

var choosing_backup := false

func _ready() -> void:
	back_button.pressed.connect(go_to_dispatch_scene)
	dispatch_button.pressed.connect(go_to_skirmish_scene)
	if GameVariables.curr_threat_skirmish == null:
		_generate_debug_data()
	update_entity_previews()
	update_stat_comparison()
	update_backup_rows()
	hero_preview.on_change_hero.connect(open_choose_hero_modal.bind(false))
	backup_add_hero_button.pressed.connect(open_choose_hero_modal.bind(true))
	choose_hero_modal.on_confirm_hero_to_add.connect(confirm_hero_from_modal)

func confirm_hero_from_modal(hero_config: EntityConfig):
	if choosing_backup:
		GameVariables.curr_threat_skirmish.bench_heroes = [hero_config]
	else:
		GameVariables.curr_threat_skirmish.heroes = [hero_config]
	update_stat_comparison()
	update_entity_previews()
	update_backup_rows()

func _generate_debug_data():
	print("generating debug data...")
	GameVariables.curr_threat_skirmish = ThreatSkirmish.new(ThreatGenerator.generate_random_threat_requests(1, GameVariables.curr_day)[0])
	GameVariables.curr_threat_skirmish.heroes = [GameVariables.player_lineup[0]]

func update_entity_previews():
	var threat_req = GameVariables.curr_threat_skirmish.threat_request_config
	var villain_config = threat_req.enemy_configs[0]
	var heroes = GameVariables.curr_threat_skirmish.heroes
	var hero_config = heroes[0] if not heroes.is_empty() else null
	hero_preview.configure(hero_config)
	villain_preview.configure(villain_config)
	villain_preview.change_hero_button.hide()
	if hero_config == null:
		dispatch_button.disabled = true
		dispatch_button.text = "Cannot dispatch! No hero selected"
	elif villain_config.curr_health <= 0:
		dispatch_button.disabled = true
		dispatch_button.text = "Cannot dispatch! Villain is recovering"
	else:
		dispatch_button.disabled = hero_config.injury_recovery_days > 0
		dispatch_button.text = "Dispatch" if hero_config.injury_recovery_days == 0 else "Cannot dispatch! Hero is resting"

func update_stat_comparison():
	var threat_req = GameVariables.curr_threat_skirmish.threat_request_config
	var villain_config = threat_req.enemy_configs[0]
	var heroes = GameVariables.curr_threat_skirmish.heroes
	stat_comparison.configure_stat_rows(heroes[0] if not heroes.is_empty() else null, villain_config)

func update_backup_rows():
	for c in backup_rows.get_children():
		if c != backup_add_hero_button:
			c.queue_free()
	var bench := GameVariables.curr_threat_skirmish.bench_heroes
	for hero_config in bench:
		var row = hero_preview_row.instantiate() as HeroPreviewRow
		backup_rows.add_child(row)
		row.configure(hero_config)
		row.enable_actions_overlay = true
		row.view_button.hide()
		row.stat_grid.hide()
		row.on_change_clicked.connect(open_choose_hero_modal.bind(true).unbind(1))
		row.on_remove_clicked.connect(remove_backup.unbind(1))
	backup_rows.move_child(backup_add_hero_button, -1)
	backup_add_hero_button.visible = bench.is_empty()

func remove_backup():
	GameVariables.curr_threat_skirmish.bench_heroes.clear()
	update_backup_rows()

func go_to_dispatch_scene():
	get_tree().change_scene_to_file("res://scenes/dispatch.tscn")

func go_to_skirmish_scene():
	if override_skirmish_results.button_pressed:
		get_tree().change_scene_to_file("res://scenes/skirmish_override.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/skirmish.tscn")

func open_choose_hero_modal(for_backup: bool):
	choosing_backup = for_backup
	choose_hero_modal.show()
	var assigned_heroes: Array[EntityConfig] = GameVariables.curr_threat_skirmish.heroes.duplicate()
	assigned_heroes.append_array(GameVariables.curr_threat_skirmish.bench_heroes)
	choose_hero_modal.display_available_heroes(assigned_heroes)
