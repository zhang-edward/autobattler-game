class_name AssignHeroes
extends Node2D

@export var hero_preview_row: PackedScene

@onready var back_button: Button = %BackButton
@onready var choose_hero_modal: ChooseHeroModal = %ChooseHeroModal
@onready var hero_preview: MatchupHeroPreview = %MatchupHeroPreview
@onready var threat_details_container: ThreatDetailsContainer = %ThreatDetailsContainer
@onready var override_skirmish_results: CheckBox = %OverrideSkirmishResults
@onready var active_hero_rows: VBoxContainer = %ActiveHeroRows
@onready var bench_hero_rows: VBoxContainer = %BenchHeroRows
@onready var add_hero_button: Button = %AddHeroButton

var hero_to_change: EntityConfig
var viewed_hero: EntityConfig

func _ready() -> void:
	back_button.pressed.connect(go_to_dispatch_scene)
	add_hero_button.pressed.connect(open_choose_hero_modal.bind(null))
	threat_details_container.on_action_pressed.connect(go_to_skirmish_scene)
	choose_hero_modal.on_confirm_hero_to_add.connect(confirm_hero_from_modal)
	if GameVariables.curr_threat_skirmish == null:
		_generate_debug_data()
	for c in bench_hero_rows.get_children():
		c.queue_free()
	threat_details_container.update_selected_threat_req(GameVariables.curr_threat_skirmish.threat_request_config)
	threat_details_container.action_button.text = "Dispatch"
	view_hero_config(null)
	update_hero_rows()

func _generate_debug_data():
	print("generating debug data...")
	GameVariables.curr_threat_skirmish = ThreatSkirmish.new(ThreatGenerator.generate_random_threat_requests(1, GameVariables.player_lineup)[0])
	GameVariables.curr_threat_skirmish.heroes = [GameVariables.player_lineup[0]]

func update_hero_rows():
	for c in active_hero_rows.get_children():
		if c != add_hero_button:
			c.queue_free()
	var heroes = GameVariables.curr_threat_skirmish.heroes
	for hero_config in heroes:
		var row = hero_preview_row.instantiate() as HeroPreviewRow
		active_hero_rows.add_child(row)
		row.configure(hero_config)
		row.enable_actions_overlay = true
		row.on_change_clicked.connect(change_hero)
		row.on_remove_clicked.connect(remove_hero)
		row.on_view_clicked.connect(view_hero)
	active_hero_rows.move_child(add_hero_button, -1)
	add_hero_button.visible = GameVariables.player_lineup.any(func(c): return not heroes.has(c)) and heroes.size() < 3
	threat_details_container.action_button.disabled = heroes.is_empty()

func change_hero(row: HeroPreviewRow):
	open_choose_hero_modal(row.entity_config)

func remove_hero(row: HeroPreviewRow):
	GameVariables.curr_threat_skirmish.heroes.erase(row.entity_config)
	if viewed_hero == row.entity_config:
		view_hero_config(null)
	update_hero_rows()

func view_hero(row: HeroPreviewRow):
	view_hero_config(row.entity_config)

func view_hero_config(hero_config: EntityConfig):
	viewed_hero = hero_config
	hero_preview.configure(hero_config)

func confirm_hero_from_modal(hero_config: EntityConfig):
	var heroes = GameVariables.curr_threat_skirmish.heroes
	if hero_to_change == null:
		heroes.append(hero_config)
	else:
		heroes[heroes.find(hero_to_change)] = hero_config
		if viewed_hero == hero_to_change:
			view_hero_config(hero_config)
	update_hero_rows()

func go_to_dispatch_scene():
	get_tree().change_scene_to_file("res://scenes/dispatch.tscn")

func go_to_skirmish_scene():
	if override_skirmish_results.button_pressed:
		get_tree().change_scene_to_file("res://scenes/skirmish_override.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/skirmish.tscn")

func open_choose_hero_modal(hero_config: EntityConfig):
	hero_to_change = hero_config
	choose_hero_modal.show()
	choose_hero_modal.display_available_heroes(GameVariables.curr_threat_skirmish.heroes)
