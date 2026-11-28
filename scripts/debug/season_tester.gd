extends Control

## Debug tool: simulate a whole season without the fight scenes.
## Run scenes/debug/season_tester.tscn on its own (F6 with it open).
##
## Drives the League autoload, so it exercises the real game state. Every
## match, the player's included, is decided by the quick-sim.

const MONO_FONTS: PackedStringArray = ["Consolas", "Cascadia Mono", "Courier New", "monospace"]
const FONT_SIZE := 16
const PLAYER_COLOR := "#f5a04a"
const CUT_LINE_COLOR := "#4aa89a"
const DIM_COLOR := "#8a93a6"
const BOX_COLOR := Color(0.12, 0.14, 0.19)
const MATCH_BOX_WIDTH := 250.0

var _log_lines: PackedStringArray = []
## How many decided matches the higher-rated team won, to sanity-check the sim.
var _favourite_wins := 0
var _matches_counted := 0

var _seed_box: SpinBox
var _week_button: Button
var _season_button: Button
var _post_button: Button
var _everything_button: Button
var _status: Label
var _standings_text: RichTextLabel
var _log_text: RichTextLabel
var _bracket_title: Label
## One container per bracket column: quarterfinals, semifinals, final, champion.
var _bracket_columns: Array[VBoxContainer] = []


func _ready() -> void:
	_build_ui()
	_new_league()


# ----- simulation -----

func _new_league() -> void:
	League.new_game(int(_seed_box.value))
	_log_lines.clear()
	_favourite_wins = 0
	_matches_counted = 0
	_log("[b]New %s[/b] (seed %d)" % [LeagueTier.display_name(League.tier), League.seed_value])
	_log("You are the [color=%s]%s[/color]." % [PLAYER_COLOR, League.player_team().team_name])
	_refresh()


func _sim_week() -> void:
	if League.phase != League.Phase.REGULAR_SEASON:
		return
	var matches := League.current_matches()
	var chances := _chances_before(matches)
	_log("")
	_log("[b]Week %d[/b]" % League.current_week)
	League.sim_week()
	_count_favourites(chances)
	for match_ in matches:
		_log("  " + _match_text(match_, chances[match_]))
	if League.phase == League.Phase.POST_SEASON:
		_log("")
		_log("[b]Regular season complete.[/b] Top %d advance to the post-season." % Bracket.SEED_COUNT)
	_refresh()


func _sim_regular_season() -> void:
	while League.phase == League.Phase.REGULAR_SEASON:
		_sim_week()


func _sim_post_season() -> void:
	while League.phase == League.Phase.POST_SEASON:
		var matches := League.current_matches()
		var chances := _chances_before(matches)
		_log("")
		_log("[b]%s[/b] (week %d)" % [Bracket.round_name(League.bracket.current_round_index()), matches[0].week])
		League.sim_post_season_round()
		_count_favourites(chances)
		for match_ in matches:
			_log("  " + _match_text(match_, chances[match_], true))
	if League.phase == League.Phase.SEASON_OVER:
		_log_season_summary()
	_refresh()


func _sim_everything() -> void:
	_sim_regular_season()
	_sim_post_season()


## Team A's win chance for each match, taken before the matches are played.
func _chances_before(matches: Array[LeagueMatch]) -> Dictionary:
	var chances := {}
	for match_ in matches:
		chances[match_] = QuickSim.team_a_win_chance(match_, League.tier)
	return chances


## Call after the matches are played.
func _count_favourites(chances: Dictionary) -> void:
	for match_: LeagueMatch in chances:
		var chance: float = chances[match_]
		if is_equal_approx(chance, 0.5) or not match_.is_played:
			continue
		var favourite := match_.team_a if chance > 0.5 else match_.team_b
		_matches_counted += 1
		if match_.winner() == favourite:
			_favourite_wins += 1


func _log_season_summary() -> void:
	var bracket := League.bracket
	var champion := bracket.champion()
	var standings := League.standings()
	_log("")
	var promoted := League.promoted_team()
	var promotion_text := ", promoted to the %s" % LeagueTier.display_name(LeagueTier.next_tier(League.tier)) if promoted != null else ""
	_log("[b]Champion: %s[/b] (%d seed)%s." % [_team_label(champion), bracket.seed_of(champion), promotion_text])
	_log("Your season: %s" % _player_finish_text(League.player_team(), standings))
	if _matches_counted > 0:
		_log("[color=%s]The higher-rated team won %d of %d matches (%d%%).[/color]" % [
			DIM_COLOR, _favourite_wins, _matches_counted, roundi(100.0 * _favourite_wins / _matches_counted)])
	_log("")
	_log("[b]Draft order[/b]")
	var order := League.draft_order()
	for i in order.size():
		var team := order[i]
		var row := standings.row_for(team)
		var how_far := "missed post-season"
		if bracket.has_team(team):
			how_far = "out in the %s" % Bracket.round_name(bracket.elimination_round(team))
			if team == bracket.runner_up():
				how_far = "runner-up"
			elif team == champion:
				how_far = "champion"
		_log("  %2d. %s  [color=%s]%d-%d, %s[/color]" % [i + 1, _team_label(team, 24), DIM_COLOR, row.wins, row.losses, how_far])
	if promoted != null:
		_log("  [color=%s]%s skips the draft (promoted).[/color]" % [DIM_COLOR, champion.team_name])


func _player_finish_text(player: Team, standings: Standings) -> String:
	var bracket := League.bracket
	var row := standings.row_for(player)
	var text := "%d-%d, %s of 16" % [row.wins, row.losses, _ordinal(standings.rank_of(player))]
	if not bracket.has_team(player):
		return text + ", missed the post-season."
	if bracket.champion() == player:
		return text + ", [b]won the championship![/b]"
	if bracket.runner_up() == player:
		return text + ", lost in the final."
	return text + ", out in the %s." % Bracket.round_name(bracket.elimination_round(player))


# ----- helpers -----

## A team name, padded to `width`, in the player color for the player's team.
func _team_label(team: Team, width: int = 0) -> String:
	var text := team.team_name.rpad(width) if width > 0 else team.team_name
	return "[color=%s]%s[/color]" % [PLAYER_COLOR, text] if team.is_player else text


func _match_text(match_: LeagueMatch, a_chance: float, with_seeds: bool = false) -> String:
	var a := match_.team_a
	var b := match_.team_b
	var a_name := a.team_name
	var b_name := b.team_name
	if with_seeds:
		a_name = "(%d) %s" % [League.bracket.seed_of(a), a_name]
		b_name = "(%d) %s" % [League.bracket.seed_of(b), b_name]
	var a_text := ("[b]%s[/b]" if match_.winner() == a else "%s") % a_name.rpad(28)
	var b_text := ("[b]%s[/b]" if match_.winner() == b else "%s") % b_name.rpad(28)
	if a.is_player:
		a_text = "[color=%s]%s[/color]" % [PLAYER_COLOR, a_text]
	if b.is_player:
		b_text = "[color=%s]%s[/color]" % [PLAYER_COLOR, b_text]
	var odds := "[color=%s]%2d%% / %2d%%[/color]" % [DIM_COLOR, roundi(a_chance * 100), roundi((1.0 - a_chance) * 100)]
	return "%s %d-%d  %s %s" % [a_text, match_.rounds_a, match_.rounds_b, b_text, odds]


static func _ordinal(n: int) -> String:
	var suffix := "th"
	if n % 100 < 11 or n % 100 > 13:
		suffix = {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")
	return "%d%s" % [n, suffix]


func _log(line: String) -> void:
	_log_lines.append(line)


# ----- display -----

func _refresh() -> void:
	_standings_text.text = _standings_bbcode()
	_render_bracket()
	_log_text.text = "\n".join(_log_lines)

	var phase: League.Phase = League.phase
	_week_button.disabled = phase != League.Phase.REGULAR_SEASON
	_season_button.disabled = phase != League.Phase.REGULAR_SEASON
	_post_button.disabled = phase != League.Phase.POST_SEASON
	_everything_button.disabled = phase == League.Phase.SEASON_OVER

	match phase:
		League.Phase.SEASON_OVER:
			_status.text = "Season complete. Champion: %s" % League.bracket.champion().team_name
		League.Phase.POST_SEASON:
			_status.text = "Post-season: %s next" % Bracket.round_name(League.bracket.current_round_index())
		_:
			if League.current_week == 1:
				_status.text = "Preseason"
			else:
				_status.text = "Week %d of %d played" % [League.current_week - 1, League.schedule.week_count()]


func _standings_bbcode() -> String:
	var standings := League.standings()
	var leader := standings.leader()
	var lines: PackedStringArray = []
	lines.append("[b]%2s  %-24s %4s %3s %3s %5s %6s %5s  %-5s %4s[/b]" % ["#", "Team", "Rtg", "W", "L", "Win%", "RDiff", "Strk", "Last5", "GB"])
	for i in standings.rows.size():
		if i == Bracket.SEED_COUNT:
			lines.append("[color=%s]%s[/color]" % [CUT_LINE_COLOR, "-".repeat(71)])
		var row: Standings.Row = standings.rows[i]
		var win_pct := ("%.3f" % row.win_pct()).trim_prefix("0") if row.played() > 0 else "-"
		var diff := ("+%d" % row.round_diff()) if row.round_diff() > 0 else str(row.round_diff())
		var last_five := ""
		for won in row.last_results():
			last_five += "W" if won else "L"
		var behind := row.games_behind(leader)
		var gb := "-" if is_zero_approx(behind) else ("%d" % behind if is_equal_approx(behind, roundf(behind)) else "%.1f" % behind)
		var team_name := row.team.team_name + (" (YOU)" if row.team.is_player else "")
		var rating := "%.1f" % QuickSim.team_rating(row.team, League.tier)
		var line := "%2d  %-24s %4s %3d %3d %5s %6s %5s  %-5s %4s" % [i + 1, team_name, rating, row.wins, row.losses, win_pct, diff, row.streak(), last_five, gb]
		if row.team.is_player:
			line = "[color=%s]%s[/color]" % [PLAYER_COLOR, line]
		lines.append(line)
	return "\n".join(lines)


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.07, 0.08, 0.11)
	background.set_anchors_preset(PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	root.add_child(bar)

	var seed_label := Label.new()
	seed_label.text = "Seed"
	bar.add_child(seed_label)
	_seed_box = SpinBox.new()
	_seed_box.max_value = 999999
	_seed_box.value = 1
	bar.add_child(_seed_box)
	_add_button(bar, "New League", _new_league)
	_week_button = _add_button(bar, "Sim Week", _sim_week)
	_season_button = _add_button(bar, "Sim Regular Season", _sim_regular_season)
	_post_button = _add_button(bar, "Sim Post-Season", _sim_post_season)
	_everything_button = _add_button(bar, "Sim Everything", _sim_everything)
	_status = Label.new()
	_status.size_flags_horizontal = SIZE_EXPAND_FILL
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bar.add_child(_status)

	var split := HSplitContainer.new()
	split.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(split)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 20)
	split.add_child(left)
	_standings_text = _add_text_panel(left)
	_standings_text.fit_content = true
	_standings_text.size_flags_vertical = SIZE_SHRINK_BEGIN
	_build_bracket_view(left)

	_log_text = _add_text_panel(split)
	# Keep the newest results in view after each sim.
	_log_text.scroll_following = true


func _build_bracket_view(parent: Control) -> void:
	var section := VBoxContainer.new()
	section.size_flags_vertical = SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 10)
	parent.add_child(section)

	_bracket_title = Label.new()
	_bracket_title.add_theme_font_size_override("font_size", 18)
	section.add_child(_bracket_title)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	section.add_child(columns)

	for header in Bracket.ROUND_NAMES + ["Champion"]:
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 6)
		columns.add_child(column)
		var label := Label.new()
		label.text = header
		label.add_theme_color_override("font_color", Color(DIM_COLOR))
		column.add_child(label)
		var cells := VBoxContainer.new()
		cells.size_flags_vertical = SIZE_EXPAND_FILL
		column.add_child(cells)
		_bracket_columns.append(cells)


## Fills the bracket view. Hidden until the post-season starts.
func _render_bracket() -> void:
	for column in _bracket_columns:
		for child in column.get_children():
			child.queue_free()

	var bracket := League.bracket
	_bracket_title.get_parent().visible = bracket != null
	if bracket == null:
		return
	var seeds: Array[Team] = bracket.seeds
	_bracket_title.text = "Post-season bracket"

	for round_index in Bracket.ROUND_NAMES.size():
		var match_count := Bracket.QUARTERFINAL_SEEDS.size() >> round_index
		for i in match_count:
			var match_: LeagueMatch = null
			var team_a: Team = null
			var team_b: Team = null
			# Rounds not reached yet stay TBD.
			if round_index < bracket.rounds.size():
				match_ = bracket.rounds[round_index][i]
				team_a = match_.team_a
				team_b = match_.team_b
			_add_bracket_cell(round_index, _make_match_box(match_, team_a, team_b, seeds))

	var champion: Team = bracket.champion()
	_add_bracket_cell(Bracket.ROUND_NAMES.size(), _make_champion_box(champion, seeds))


## Each cell stretches to an equal share of the column height, so a
## semifinal lines up between the two quarterfinals that feed it.
func _add_bracket_cell(column_index: int, box: Control) -> void:
	var cell := CenterContainer.new()
	cell.size_flags_vertical = SIZE_EXPAND_FILL
	cell.add_child(box)
	_bracket_columns[column_index].add_child(cell)


func _make_box(highlight: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(MATCH_BOX_WIDTH, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = BOX_COLOR
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	if highlight:
		style.border_color = Color(PLAYER_COLOR)
		style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_match_box(match_: LeagueMatch, team_a: Team, team_b: Team, seeds: Array[Team]) -> Control:
	var has_player := (team_a != null and team_a.is_player) or (team_b != null and team_b.is_player)
	var panel := _make_box(has_player)
	var rows := VBoxContainer.new()
	panel.add_child(rows)
	rows.add_child(_make_team_row(team_a, match_, seeds))
	rows.add_child(_make_team_row(team_b, match_, seeds))
	return panel


func _make_team_row(team: Team, match_: LeagueMatch, seeds: Array[Team]) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var seed_label := Label.new()
	seed_label.custom_minimum_size.x = 18
	seed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	seed_label.add_theme_color_override("font_color", Color(DIM_COLOR))
	var name_label := Label.new()
	name_label.size_flags_horizontal = SIZE_EXPAND_FILL
	name_label.clip_text = true
	var score_label := Label.new()
	row.add_child(seed_label)
	row.add_child(name_label)
	row.add_child(score_label)

	if team == null:
		name_label.text = "TBD"
		name_label.add_theme_color_override("font_color", Color(DIM_COLOR))
		return row

	seed_label.text = str(seeds.find(team) + 1)
	name_label.text = team.team_name
	var lost := match_ != null and match_.is_played and match_.loser() == team
	if match_ != null and match_.is_played:
		score_label.text = str(match_.rounds_won_by(team))
	var color := Color(PLAYER_COLOR) if team.is_player else Color.WHITE
	if lost:
		color = color.darkened(0.5)
	name_label.add_theme_color_override("font_color", color)
	score_label.add_theme_color_override("font_color", color)
	return row


func _make_champion_box(champion: Team, seeds: Array[Team]) -> Control:
	var panel := _make_box(champion != null and champion.is_player)
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if champion == null:
		label.text = "TBD"
		label.add_theme_color_override("font_color", Color(DIM_COLOR))
	else:
		label.text = "(%d) %s" % [seeds.find(champion) + 1, champion.team_name]
		label.add_theme_color_override("font_color", Color(PLAYER_COLOR) if champion.is_player else Color.WHITE)
	panel.add_child(label)
	return panel


func _add_button(parent: Control, label: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _add_text_panel(parent: Control) -> RichTextLabel:
	var panel := RichTextLabel.new()
	panel.bbcode_enabled = true
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.size_flags_vertical = SIZE_EXPAND_FILL
	var regular := SystemFont.new()
	regular.font_names = MONO_FONTS
	var bold := SystemFont.new()
	bold.font_names = MONO_FONTS
	bold.font_weight = 700
	panel.add_theme_font_override("normal_font", regular)
	panel.add_theme_font_override("bold_font", bold)
	panel.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	panel.add_theme_font_size_override("bold_font_size", FONT_SIZE)
	parent.add_child(panel)
	return panel
