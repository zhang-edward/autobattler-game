class_name SkirmishRunner
extends Node

## Balancing tool: plays many fights in a row between two builds and reports
## the results. Each team is `team size` heroes with the same build: a lead
## plus tag-ins on the bench.

@export var skirmish_scene: PackedScene
@export var fight_time_limit := 90.0

@onready var _setup_layer: CanvasLayer = $SetupLayer
@onready var _fight_layer: CanvasLayer = $FightLayer
@onready var _team_a_build: SkirmishRunnerBuildPanel = %TeamABuild
@onready var _team_b_build: SkirmishRunnerBuildPanel = %TeamBBuild
@onready var _team_size: SpinBox = %TeamSize
@onready var _fights: SpinBox = %Fights
@onready var _fight_button: Button = %FightButton
@onready var _results_label: Label = %ResultsLabel
@onready var _fight_status_label: Label = %FightStatusLabel
@onready var _stop_button: Button = %StopButton

var _rng := RandomNumberGenerator.new()
var _skirmish: Skirmish
var _fight_time := 0.0
var _fights_done := 0
var _a_wins := 0
var _b_wins := 0
var _draws := 0
var _total_length := 0.0
var _total_winner_hp := 0


func _ready() -> void:
	_rng.randomize()
	_team_a_build.build_changed.connect(_refresh_fight_button)
	_team_b_build.build_changed.connect(_refresh_fight_button)
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
	_a_wins = 0
	_b_wins = 0
	_draws = 0
	_total_length = 0.0
	_total_winner_hp = 0
	_setup_layer.hide()
	_fight_layer.show()
	_start_fight()


func _start_fight() -> void:
	_fight_status_label.text = "Fight %d/%d | %s" % [_fights_done + 1, int(_fights.value), _results_text()]
	var size := int(_team_size.value)
	_fight_time = 0.0
	_skirmish = skirmish_scene.instantiate() as Skirmish
	# Both sides tag on their own, so neither build gets an edge from it.
	_skirmish.configure(_build_team(_team_a_build, size), _build_team(_team_b_build, size), true)
	_skirmish.finished.connect(_on_fight_finished)
	add_child(_skirmish)


func _build_team(build: SkirmishRunnerBuildPanel, count: int) -> Array[Hero]:
	var team: Array[Hero] = []
	for i in count:
		var hero := build.build_hero(_rng)
		hero.hero_name += " %d" % (i + 1)
		team.append(hero)
	return team


func _on_fight_finished(winner: Skirmish.Side) -> void:
	if winner == Skirmish.Side.A:
		_a_wins += 1
	else:
		_b_wins += 1
	_total_length += _fight_time
	_total_winner_hp += _skirmish.health_for(winner).value
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
	var decided := maxi(_a_wins + _b_wins, 1)
	return "Team A %d | Team B %d | Draws %d | Avg length %ds | Avg winner HP %d" % [
		_a_wins,
		_b_wins,
		_draws,
		roundi(_total_length / decided),
		roundi(float(_total_winner_hp) / decided),
	]


func _refresh_fight_button() -> void:
	var a_points := _team_a_build.points()
	var b_points := _team_b_build.points()
	if not _team_a_build.has_moves() or not _team_b_build.has_moves():
		_fight_button.text = "Each team needs a move"
		_fight_button.disabled = true
	elif a_points != b_points:
		_fight_button.text = "Fight (Point totals differ: %d vs %d)" % [a_points, b_points]
		_fight_button.disabled = false
	else:
		_fight_button.text = "Fight"
		_fight_button.disabled = false
