extends Node

## The current game: the player's league, its teams, the schedule and the
## post-season. Autoloaded as `League`. Screens read from it and call it; it
## has no UI of its own.
##
## A season runs: REGULAR_SEASON (15 weeks) -> POST_SEASON (3 rounds) ->
## SEASON_OVER. Each step plays every unplayed match with the quick-sim, so
## record the player's result first when they played their match.
## The offseason (contracts, draft, next season) comes in M5.

signal week_completed(week: int)
signal regular_season_completed
signal post_season_round_completed(round_index: int)
signal season_completed(champion: Team)

enum Phase { REGULAR_SEASON, POST_SEASON, SEASON_OVER }

var rng := RandomNumberGenerator.new()
## The seed the current game was started with.
var seed_value := 0
var tier: LeagueTier.Tier = LeagueTier.Tier.ROOKIE
var season := 1
var phase: Phase = Phase.REGULAR_SEASON
var teams: Array[Team] = []
var schedule: Schedule
## The next regular-season week to play (1-based).
var current_week := 1
## Created when the regular season ends.
var bracket: Bracket


## Starts a new game in the Rookie League. Pass a seed to reproduce a
## league; -1 picks a random one.
func new_game(seed_: int = -1, player_index: int = 0) -> void:
	seed_value = seed_ if seed_ >= 0 else randi()
	rng.seed = seed_value
	tier = LeagueTier.Tier.ROOKIE
	season = 1
	teams = LeagueGenerator.generate_league_teams(rng, tier, player_index, season)
	_start_season()


func _start_season() -> void:
	schedule = Schedule.generate(teams, rng)
	current_week = 1
	bracket = null
	phase = Phase.REGULAR_SEASON


# ----- reading the state -----

func player_team() -> Team:
	for team in teams:
		if team.is_player:
			return team
	return null


## Rebuilt from results on every call.
func standings() -> Standings:
	return Standings.compute(teams, schedule.all_matches())


## The matches being played now: this week's, or the current post-season
## round's. Empty once the season is over.
func current_matches() -> Array[LeagueMatch]:
	match phase:
		Phase.REGULAR_SEASON:
			return schedule.matches_in_week(current_week)
		Phase.POST_SEASON:
			return bracket.current_round()
	return []


## The player's match right now, or null (knocked out, or the season is over).
func player_match() -> LeagueMatch:
	var player := player_team()
	for match_ in current_matches():
		if match_.involves(player):
			return match_
	return null


## The tier the champion moves up to, or null if the season isn't over or
## the league is already the top tier.
func promoted_team() -> Team:
	if phase != Phase.SEASON_OVER or LeagueTier.is_top_tier(tier):
		return null
	return bracket.champion()


## Pick order for the draft. Empty until the season is over.
func draft_order() -> Array[Team]:
	if phase != Phase.SEASON_OVER:
		return []
	return DraftOrder.compute(standings(), bracket, promoted_team())


# ----- moving the season on -----

## Records the result of the player's current match, from the player's side.
## Returns false if there's no match to record or the score isn't valid.
func record_player_result(player_rounds: int, opponent_rounds: int) -> bool:
	var match_ := player_match()
	if match_ == null or match_.is_played:
		return false
	if match_.team_a == player_team():
		return match_.record_result(player_rounds, opponent_rounds)
	return match_.record_result(opponent_rounds, player_rounds)


## Finishes the current regular-season week: quick-sims every unplayed match,
## then moves to the next week. After week 15 the post-season starts.
func sim_week() -> void:
	if phase != Phase.REGULAR_SEASON:
		return
	var week := current_week
	_sim_unplayed(schedule.matches_in_week(week))
	current_week += 1
	week_completed.emit(week)
	if current_week > schedule.week_count():
		bracket = Bracket.create(standings().top_teams(Bracket.SEED_COUNT), schedule.week_count() + 1)
		phase = Phase.POST_SEASON
		regular_season_completed.emit()


## Finishes the current post-season round the same way. After the final the
## season is over.
func sim_post_season_round() -> void:
	if phase != Phase.POST_SEASON:
		return
	var round_index := bracket.current_round_index()
	_sim_unplayed(bracket.current_round())
	post_season_round_completed.emit(round_index)
	if not bracket.advance():
		phase = Phase.SEASON_OVER
		season_completed.emit(bracket.champion())


## Sims whatever comes next: a week or a post-season round.
func sim_next() -> void:
	match phase:
		Phase.REGULAR_SEASON:
			sim_week()
		Phase.POST_SEASON:
			sim_post_season_round()


func sim_regular_season() -> void:
	while phase == Phase.REGULAR_SEASON:
		sim_week()


func sim_post_season() -> void:
	while phase == Phase.POST_SEASON:
		sim_post_season_round()


func _sim_unplayed(matches: Array[LeagueMatch]) -> void:
	for match_ in matches:
		if not match_.is_played:
			QuickSim.simulate(match_, tier, rng)
