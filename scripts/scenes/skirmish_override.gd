class_name SkirmishOverride
extends Node2D

@export var override_row_scene: PackedScene

@onready var hero_rows: VBoxContainer = %HeroRows
@onready var villain_rows: VBoxContainer = %VillainRows
@onready var back_button: Button = %Back
@onready var resolve_button: Button = %Resolve

var override_rows: Array[SkirmishOverrideRow] = []

func _ready() -> void:
	back_button.pressed.connect(go_to_assign_heroes_scene)
	resolve_button.pressed.connect(resolve_skirmish)
	var threat_skirmish = GameVariables.curr_threat_skirmish
	for h in threat_skirmish.heroes:
		add_override_row(h, hero_rows, 100.0)
	for v in threat_skirmish.threat_request_config.enemy_configs:
		add_override_row(v, villain_rows, 0.0)

func add_override_row(config: EntityConfig, container: VBoxContainer, start_health_pct: float):
	var row = override_row_scene.instantiate() as SkirmishOverrideRow
	container.add_child(row)
	row.configure(config, start_health_pct)
	override_rows.append(row)

func resolve_skirmish():
	var threat_skirmish = GameVariables.curr_threat_skirmish
	for row in override_rows:
		var config = row.entity_config
		config.reset_all_in_round_vars()
		config.curr_health = roundi(config.vitality * 10 * row.health_slider.value / 100.0)
	var all_villains_defeated = threat_skirmish.threat_request_config.enemy_configs.all(func(v: EntityConfig): return v.curr_health <= 0)
	threat_skirmish.winner = EntityConfig.EntityType.HERO if all_villains_defeated else EntityConfig.EntityType.VILLAIN
	GameVariables.resolve_threat_skirmish(threat_skirmish)
	get_tree().change_scene_to_file("res://scenes/post_skirmish_result.tscn")

func go_to_assign_heroes_scene():
	get_tree().change_scene_to_file("res://scenes/assign_heroes.tscn")
