class_name MatchScene
extends Node

## Plays the player's current League match: best of 3 rounds, each one a
## Skirmish. Records the result in League, then Continue finishes the week
## (or post-season round) and loads the player's next match.
##
## Placeholder UI: the match preview, results screen and season screens
## from the mockups come in M3. Lineups are each team's best heroes for now
## (QuickSim.pick_lineup); picking your own lineup also comes with M3.

const ROUND_BANNER_SECONDS := 1.2
const ROUND_RESULT_SECONDS := 2.0
const UI_LAYER := 20
const DARK_PANEL := preload("res://prefabs/styles/dark_panel.tres")

@export var skirmish_scene: PackedScene

var _match: LeagueMatch
var _player: Team
var _opponent: Team
var _player_lineup: Array[Hero] = []
var _opponent_lineup: Array[Hero] = []
var _player_rounds := 0
var _opponent_rounds := 0
var _round := 0
var _skirmish: Skirmish

var _score_label: Label
var _banner: Label
var _panel: PanelContainer
var _panel_title: Label
var _panel_body: Label
var _panel_button: Button


func _ready() -> void:
	_build_ui()
	if League.teams.is_empty():
		League.new_game()
	_advance_to_player_match()
	_match = League.player_match()
	if _match == null:
		_show_season_over()
		return
	_player = League.player_team()
	_opponent = _match.opponent_of(_player)
	_player_lineup = QuickSim.pick_lineup(_player, League.tier)
	_opponent_lineup = QuickSim.pick_lineup(_opponent, League.tier)
	_start_round()


## Sims ahead until the player has a match to play or the season is over
## (the player missed the post-season or was knocked out).
func _advance_to_player_match() -> void:
	while League.phase != League.Phase.SEASON_OVER and League.player_match() == null:
		League.sim_next()


func _start_round() -> void:
	_round += 1
	_refresh_score()
	_show_banner("Round %d" % _round)
	await get_tree().create_timer(ROUND_BANNER_SECONDS).timeout
	_banner.hide()
	_skirmish = skirmish_scene.instantiate() as Skirmish
	_skirmish.configure(_player_lineup, _opponent_lineup)
	_skirmish.finished.connect(_on_round_finished)
	add_child(_skirmish)


func _on_round_finished(winner: Skirmish.Side) -> void:
	var player_won := winner == Skirmish.Side.A
	if player_won:
		_player_rounds += 1
	else:
		_opponent_rounds += 1
	_refresh_score()
	_show_banner("%s take the round!" % (_player if player_won else _opponent).team_name)
	await get_tree().create_timer(ROUND_RESULT_SECONDS).timeout
	_skirmish.queue_free()
	_skirmish = null
	if _player_rounds >= LeagueMatch.ROUNDS_TO_WIN or _opponent_rounds >= LeagueMatch.ROUNDS_TO_WIN:
		_finish_match()
	else:
		_start_round()


func _finish_match() -> void:
	_banner.hide()
	League.record_player_result(_player_rounds, _opponent_rounds)
	var won := _player_rounds > _opponent_rounds
	var row := League.standings().row_for(_player)
	var body := "%s  %d – %d  %s" % [_player.team_name, _player_rounds, _opponent_rounds, _opponent.team_name]
	if League.phase == League.Phase.REGULAR_SEASON:
		body += "\nRecord %d–%d" % [row.wins, row.losses]
	_show_panel("Victory!" if won else "Defeat", body, "Continue", _on_continue)


func _on_continue() -> void:
	League.sim_next()
	get_tree().reload_current_scene()


func _show_season_over() -> void:
	_score_label.hide()
	var champion := League.bracket.champion() if League.bracket != null else null
	var body := "Champion: %s" % champion.team_name if champion != null else ""
	if champion == League.player_team():
		body += "\nThat's you!"
	var row := League.standings().row_for(League.player_team())
	if row != null:
		body += "\nYour regular season: %d–%d" % [row.wins, row.losses]
	_show_panel("Season over", body, "Back to title", func(): get_tree().change_scene_to_file("res://scenes/title.tscn"))


# ----- UI -----

func _match_label() -> String:
	if League.phase == League.Phase.POST_SEASON:
		return Bracket.round_name(League.bracket.current_round_index())
	return "Week %d" % League.current_week


func _refresh_score() -> void:
	_score_label.text = "%s  %d – %d  %s\n%s · Round %d" % [
		_player.team_name, _player_rounds, _opponent_rounds, _opponent.team_name,
		_match_label(), _round,
	]


func _show_banner(text: String) -> void:
	_banner.text = text
	_banner.show()


func _show_panel(title: String, body: String, button_text: String, on_pressed: Callable) -> void:
	_panel_title.text = title
	_panel_body.text = body
	_panel_button.text = button_text
	_panel_button.pressed.connect(on_pressed, CONNECT_ONE_SHOT)
	_panel.show()
	_panel_button.grab_focus()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = UI_LAYER
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	_score_label = Label.new()
	_score_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_score_label.position = Vector2(-400.0, 20.0)
	_score_label.size = Vector2(800.0, 70.0)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 22)
	root.add_child(_score_label)

	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 64)
	_banner.add_theme_constant_override("outline_size", 12)
	_banner.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.hide()
	root.add_child(_banner)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", DARK_PANEL)
	_panel.custom_minimum_size = Vector2(600.0, 0.0)
	_panel.hide()
	center.add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	_panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	_panel_title = Label.new()
	_panel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel_title.add_theme_font_size_override("font_size", 48)
	vbox.add_child(_panel_title)
	_panel_body = Label.new()
	_panel_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel_body.add_theme_font_size_override("font_size", 24)
	vbox.add_child(_panel_body)
	_panel_button = Button.new()
	_panel_button.custom_minimum_size = Vector2(240.0, 56.0)
	_panel_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_panel_button.add_theme_font_size_override("font_size", 24)
	vbox.add_child(_panel_button)
