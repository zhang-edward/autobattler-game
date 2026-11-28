class_name Schedule
extends RefCounted

## A single round-robin regular season: every team plays every other team
## once, one match per week. 16 teams make 15 weeks of 8 matches.

## weeks[0] is week 1.
var weeks: Array[Array] = []


## Builds a round robin with the circle method: one team stays put while
## the others rotate one place each week. The team order is shuffled first,
## so each seed gives a different schedule. Needs an even number of teams.
static func generate(teams: Array[Team], rng: RandomNumberGenerator) -> Schedule:
	var schedule := Schedule.new()
	var count := teams.size()
	if count < 2 or count % 2 != 0:
		push_error("Schedule needs an even number of teams, got %d" % count)
		return schedule

	var order: Array[Team] = teams.duplicate()
	_shuffle(order, rng)

	for week_index in count - 1:
		var week: Array[LeagueMatch] = []
		for i in count / 2:
			week.append(LeagueMatch.create(week_index + 1, order[i], order[count - 1 - i]))
		schedule.weeks.append(week)
		# Rotate everyone except the first team one place.
		order.insert(1, order.pop_back())
	return schedule


func week_count() -> int:
	return weeks.size()


## Matches in a 1-based week. Empty if the week doesn't exist.
func matches_in_week(week: int) -> Array[LeagueMatch]:
	var result: Array[LeagueMatch] = []
	if week < 1 or week > weeks.size():
		return result
	result.assign(weeks[week - 1])
	return result


## `team`'s match in a 1-based week, or null.
func match_for(team: Team, week: int) -> LeagueMatch:
	for match_ in matches_in_week(week):
		if match_.involves(team):
			return match_
	return null


## Every match in week order.
func all_matches() -> Array[LeagueMatch]:
	var result: Array[LeagueMatch] = []
	for week in weeks:
		result.append_array(week)
	return result


## `team`'s matches in week order.
func matches_for(team: Team) -> Array[LeagueMatch]:
	return all_matches().filter(func(m: LeagueMatch) -> bool: return m.involves(team))


## Every played match in week order.
func played_matches() -> Array[LeagueMatch]:
	return all_matches().filter(func(m: LeagueMatch) -> bool: return m.is_played)


## Whether every match in a 1-based week has a result.
func is_week_complete(week: int) -> bool:
	return matches_in_week(week).all(func(m: LeagueMatch) -> bool: return m.is_played)


func is_complete() -> bool:
	return all_matches().all(func(m: LeagueMatch) -> bool: return m.is_played)


## Fisher-Yates using the given RNG, so shuffles are reproducible.
static func _shuffle(array: Array, rng: RandomNumberGenerator) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = array[i]
		array[i] = array[j]
		array[j] = swap
