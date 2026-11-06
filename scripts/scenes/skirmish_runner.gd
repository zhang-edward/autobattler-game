class_name SkirmishRunner
extends Node

@export var skirmish_scene: PackedScene
@export var fight_time_limit := 90.0

@onready var _setup_layer: CanvasLayer = $SetupLayer
@onready var _fight_layer: CanvasLayer = $FightLayer
@onready var _hero_build: SkirmishRunnerBuildPanel = %HeroBuild
@onready var _villain_build: SkirmishRunnerBuildPanel = %VillainBuild
@onready var _fights: SpinBox = %Fights
@onready var _fight_button: Button = %FightButton
@onready var _results_label: Label = %ResultsLabel
@onready var _fight_status_label: Label = %FightStatusLabel
@onready var _stop_button: Button = %StopButton

var _skirmish: Skirmish
var _fight_time := 0.0
var _fights_done := 0
var _hero_wins := 0
var _villain_wins := 0
var _draws := 0
var _total_length := 0.0
var _total_winner_hp := 0

func _ready() -> void:
	_hero_build.build_changed.connect(_refresh_fight_button)
	_villain_build.build_changed.connect(_refresh_fight_button)
	_fight_button.pressed.connect(_start_run)
	_stop_button.pressed.connect(_finish_run)
	_refresh_fight_button()

func _process(delta: float) -> void:
	if _skirmish == null or _skirmish._finished:
		return
	_fight_time += delta
	if _fight_time >= fight_time_limit:
		_draws += 1
		_end_fight()

func _start_run() -> void:
	_fights_done = 0
	_hero_wins = 0
	_villain_wins = 0
	_draws = 0
	_total_length = 0.0
	_total_winner_hp = 0
	_setup_layer.hide()
	_fight_layer.show()
	_start_fight()

func _start_fight() -> void:
	_fight_status_label.text = "Fight %d/%d | %s" % [_fights_done + 1, int(_fights.value), _results_text()]
	var villains: Array[EntityConfig] = [_villain_build.build_config()]
	GameVariables.selected_hero_for_threat = _hero_build.build_config()
	GameVariables.selected_threat_request_config = ThreatRequestConfigBuilder.new().with_enemy_configs(villains).build()
	_fight_time = 0.0
	_skirmish = skirmish_scene.instantiate() as Skirmish
	_skirmish.return_to_post_skirmish = false
	_skirmish.finished.connect(_on_fight_finished)
	add_child(_skirmish)

func _on_fight_finished(winner: EntityConfig.EntityType) -> void:
	if winner == EntityConfig.EntityType.HERO:
		_hero_wins += 1
	else:
		_villain_wins += 1
	_total_length += _fight_time
	_total_winner_hp += _skirmish.active_for(winner).entity_config.curr_health
	_end_fight()

func _end_fight() -> void:
	_skirmish.queue_free()
	_skirmish = null
	_fights_done += 1
	if _fights_done >= int(_fights.value):
		_finish_run()
	else:
		_start_fight()

func _finish_run() -> void:
	if _skirmish != null:
		_skirmish.queue_free()
		_skirmish = null
	_results_label.text = _results_text()
	_fight_layer.hide()
	_setup_layer.show()

func _results_text() -> String:
	var decided := maxi(_hero_wins + _villain_wins, 1)
	return "Hero %d | Villain %d | Draws %d | Avg length %ds | Avg winner HP %d" % [
		_hero_wins,
		_villain_wins,
		_draws,
		roundi(_total_length / decided),
		roundi(float(_total_winner_hp) / decided),
	]

func _refresh_fight_button() -> void:
	var hero_points := _hero_build.points()
	var villain_points := _villain_build.points()
	if not _hero_build.has_moves() or not _villain_build.has_moves():
		_fight_button.text = "Each side needs a move"
		_fight_button.disabled = true
	elif hero_points != villain_points:
		_fight_button.text = "Fight (Point totals differ)" % [hero_points, villain_points]
		# _fight_button.disabled = true
	else:
		_fight_button.text = "Fight"
		_fight_button.disabled = false
