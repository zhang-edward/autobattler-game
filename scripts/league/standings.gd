class_name Standings
extends RefCounted

## The league table, worked out from played matches. Rebuild it whenever
## results change; it holds no state of its own to save.
##
## Ranking: most wins, then best round difference, then most rounds won,
## then team name (so the order is always stable).

## One team's line in the table.
class Row:
	extends RefCounted

	var team: Team
	var wins := 0
	var losses := 0
	var rounds_won := 0
	var rounds_lost := 0
	## true for a win, oldest first.
	var results: Array[bool] = []

	func played() -> int:
		return wins + losses

	## 0.0 to 1.0. 0 before any matches.
	func win_pct() -> float:
		return float(wins) / played() if played() > 0 else 0.0

	func round_diff() -> int:
		return rounds_won - rounds_lost

	## "W4", "L1", or "" before any matches.
	func streak() -> String:
		if results.is_empty():
			return ""
		var last: bool = results[-1]
		var length := 0
		for i in range(results.size() - 1, -1, -1):
			if results[i] != last:
				break
			length += 1
		return ("W" if last else "L") + str(length)

	## The most recent `count` results, oldest first.
	func last_results(count: int = 5) -> Array[bool]:
		return results.slice(maxi(results.size() - count, 0))

	## Games behind `leader`. 0 for the leader.
	func games_behind(leader: Row) -> float:
		return ((leader.wins - wins) + (losses - leader.losses)) / 2.0


## Rows in rank order: rows[0] is 1st.
var rows: Array[Row] = []


static func compute(teams: Array[Team], matches: Array[LeagueMatch]) -> Standings:
	var standings := Standings.new()
	var by_team := {}
	for team in teams:
		var row := Row.new()
		row.team = team
		by_team[team] = row
		standings.rows.append(row)

	var sorted_matches: Array[LeagueMatch] = matches.duplicate()
	sorted_matches.sort_custom(func(a: LeagueMatch, b: LeagueMatch) -> bool: return a.week < b.week)
	for match_ in sorted_matches:
		if not match_.is_played:
			continue
		for team in [match_.team_a, match_.team_b]:
			if not by_team.has(team):
				continue
			var row: Row = by_team[team]
			var won: bool = match_.winner() == team
			if won:
				row.wins += 1
			else:
				row.losses += 1
			row.rounds_won += match_.rounds_won_by(team)
			row.rounds_lost += match_.rounds_lost_by(team)
			row.results.append(won)

	standings.rows.sort_custom(_ranks_higher)
	return standings


static func _ranks_higher(a: Row, b: Row) -> bool:
	if a.wins != b.wins:
		return a.wins > b.wins
	if a.round_diff() != b.round_diff():
		return a.round_diff() > b.round_diff()
	if a.rounds_won != b.rounds_won:
		return a.rounds_won > b.rounds_won
	return a.team.team_name < b.team.team_name


func row_for(team: Team) -> Row:
	for row in rows:
		if row.team == team:
			return row
	return null


## 1-based rank, or 0 if the team isn't in the table.
func rank_of(team: Team) -> int:
	for i in rows.size():
		if rows[i].team == team:
			return i + 1
	return 0


func leader() -> Row:
	return rows[0] if not rows.is_empty() else null


## The top `count` teams in rank order: the post-season field.
func top_teams(count: int) -> Array[Team]:
	var result: Array[Team] = []
	for i in mini(count, rows.size()):
		result.append(rows[i].team)
	return result
