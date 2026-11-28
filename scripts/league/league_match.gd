class_name LeagueMatch
extends RefCounted

## One scheduled match between two teams, and its result once played.
## A match is best of 3 rounds, so a finished match is 2-0 or 2-1.

const ROUNDS_TO_WIN := 2

## 1-based, to match the UI ("Week 8").
var week := 0
var team_a: Team
var team_b: Team
var rounds_a := 0
var rounds_b := 0
var is_played := false


static func create(week_: int, team_a_: Team, team_b_: Team) -> LeagueMatch:
	var match_ := LeagueMatch.new()
	match_.week = week_
	match_.team_a = team_a_
	match_.team_b = team_b_
	return match_


## Records a finished match. Returns false (and records nothing) if the
## score isn't a valid best-of-3 result.
func record_result(rounds_a_: int, rounds_b_: int) -> bool:
	if not is_valid_score(rounds_a_, rounds_b_):
		push_error("Invalid best-of-3 score %d-%d" % [rounds_a_, rounds_b_])
		return false
	rounds_a = rounds_a_
	rounds_b = rounds_b_
	is_played = true
	return true


static func is_valid_score(a: int, b: int) -> bool:
	return (a == ROUNDS_TO_WIN and b >= 0 and b < ROUNDS_TO_WIN) \
		or (b == ROUNDS_TO_WIN and a >= 0 and a < ROUNDS_TO_WIN)


func involves(team: Team) -> bool:
	return team_a == team or team_b == team


## The other team in the match, or null if `team` isn't playing.
func opponent_of(team: Team) -> Team:
	if team == team_a:
		return team_b
	if team == team_b:
		return team_a
	return null


## Null until the match is played.
func winner() -> Team:
	if not is_played:
		return null
	return team_a if rounds_a > rounds_b else team_b


## Null until the match is played.
func loser() -> Team:
	if not is_played:
		return null
	return team_b if rounds_a > rounds_b else team_a


func rounds_won_by(team: Team) -> int:
	if team == team_a:
		return rounds_a
	if team == team_b:
		return rounds_b
	return 0


func rounds_lost_by(team: Team) -> int:
	if team == team_a:
		return rounds_b
	if team == team_b:
		return rounds_a
	return 0
