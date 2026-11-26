class_name Bracket
extends RefCounted

## The post-season: 8 seeds, single elimination, no byes. Each pairing is
## one best-of-3 match, like the regular season.
##
## Quarterfinals: 1v8, 4v5, 2v7, 3v6. The 1v8 and 4v5 winners meet in one
## semifinal, the 2v7 and 3v6 winners in the other, so the top two seeds
## can only meet in the final.

const SEED_COUNT := 8
const ROUND_NAMES: Array[String] = ["Quarterfinals", "Semifinals", "Final"]
## Seed pairings for the quarterfinals, in bracket order (1-based seeds).
const QUARTERFINAL_SEEDS: Array[Vector2i] = [
	Vector2i(1, 8), Vector2i(4, 5), Vector2i(2, 7), Vector2i(3, 6),
]

## seeds[0] is the 1 seed.
var seeds: Array[Team] = []
## rounds[0] is the quarterfinals. A round is only added once the one
## before it is finished.
var rounds: Array[Array] = []
## Post-season matches are numbered on from the regular season's weeks.
var first_week := 1


## A bracket from the top 8 teams in rank order. `first_week` is the week
## number to give the quarterfinals (the week after the regular season).
static func create(seeded_teams: Array[Team], first_week_: int) -> Bracket:
	var bracket := Bracket.new()
	if seeded_teams.size() != SEED_COUNT:
		push_error("Bracket needs %d teams, got %d" % [SEED_COUNT, seeded_teams.size()])
		return bracket
	bracket.seeds = seeded_teams.duplicate()
	bracket.first_week = first_week_
	var quarterfinals: Array[LeagueMatch] = []
	for pair in QUARTERFINAL_SEEDS:
		quarterfinals.append(LeagueMatch.create(first_week_, bracket.team_at_seed(pair.x), bracket.team_at_seed(pair.y)))
	bracket.rounds.append(quarterfinals)
	return bracket


static func round_name(round_index: int) -> String:
	return ROUND_NAMES[round_index] if round_index >= 0 and round_index < ROUND_NAMES.size() else ""


func round_count() -> int:
	return ROUND_NAMES.size()


## 1-based seed, or 0 if the team isn't in the post-season.
func seed_of(team: Team) -> int:
	return seeds.find(team) + 1


func team_at_seed(seed: int) -> Team:
	return seeds[seed - 1]


func has_team(team: Team) -> bool:
	return seeds.has(team)


## The index of the round being played now (the last one added).
func current_round_index() -> int:
	return rounds.size() - 1


func current_round() -> Array[LeagueMatch]:
	var result: Array[LeagueMatch] = []
	if not rounds.is_empty():
		result.assign(rounds[-1])
	return result


func is_current_round_complete() -> bool:
	return current_round().all(func(m: LeagueMatch) -> bool: return m.is_played)


## Starts the next round from the current round's winners, in bracket
## order. Returns false if the current round isn't finished or the final
## has been played.
func advance() -> bool:
	if not is_current_round_complete() or is_complete():
		return false
	var winners: Array[Team] = []
	for match_ in current_round():
		winners.append(match_.winner())
	var week := first_week + rounds.size()
	var next_round: Array[LeagueMatch] = []
	for i in range(0, winners.size(), 2):
		next_round.append(LeagueMatch.create(week, winners[i], winners[i + 1]))
	rounds.append(next_round)
	return true


## Whether the final has been played.
func is_complete() -> bool:
	return rounds.size() == round_count() and is_current_round_complete()


## Null until the final has been played.
func champion() -> Team:
	return current_round()[0].winner() if is_complete() else null


## Null until the final has been played.
func runner_up() -> Team:
	return current_round()[0].loser() if is_complete() else null


## How far a team went: the index of the round they lost in (0 for the
## quarterfinals), round_count() for the champion, or -1 if they weren't in
## the post-season or are still alive.
func elimination_round(team: Team) -> int:
	if not has_team(team):
		return -1
	for round_index in rounds.size():
		for match_ in rounds[round_index]:
			if match_.is_played and match_.loser() == team:
				return round_index
	return round_count() if champion() == team else -1


## `team`'s match in the current round, or null if they're out.
func current_match_for(team: Team) -> LeagueMatch:
	for match_ in current_round():
		if match_.involves(team):
			return match_
	return null


## Every post-season match, quarterfinals first.
func all_matches() -> Array[LeagueMatch]:
	var result: Array[LeagueMatch] = []
	for round_matches in rounds:
		result.append_array(round_matches)
	return result
