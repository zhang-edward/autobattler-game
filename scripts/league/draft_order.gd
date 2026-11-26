class_name DraftOrder
extends RefCounted

## Works out the order of the one-round draft at the end of a season.
##
## 1. Teams that missed the post-season, worst regular-season record first.
## 2. Post-season teams, in order of how far they went: quarterfinal losers,
##    then semifinal losers, then the runner-up. Teams knocked out in the same
##    round pick worst regular-season rank first.
## 3. The champion picks last, unless they were promoted. A promoted team
##    skips the draft (in the top tier the champion isn't promoted, so they
##    pick last).


## The teams in pick order: index 0 has the first pick. `promoted` is the
## team leaving for the next tier, or null if nobody is promoted.
static func compute(standings: Standings, bracket: Bracket, promoted: Team = null) -> Array[Team]:
	var order: Array[Team] = []

	# 1. Missed the post-season, worst first.
	for i in range(standings.rows.size() - 1, -1, -1):
		var team: Team = standings.rows[i].team
		if not bracket.has_team(team):
			order.append(team)

	# 2 and 3. Post-season teams by how far they went, then by worst rank.
	var post_season: Array[Team] = bracket.seeds.duplicate()
	post_season.sort_custom(func(a: Team, b: Team) -> bool:
		var round_a := bracket.elimination_round(a)
		var round_b := bracket.elimination_round(b)
		if round_a != round_b:
			return round_a < round_b
		return standings.rank_of(a) > standings.rank_of(b))
	for team in post_season:
		if team != promoted:
			order.append(team)

	return order
