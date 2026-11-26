class_name QuickSim
extends RefCounted

## Decides matches nobody watches, from team stats.
##
## Each team fields its best heroes (as many as the tier's fight size). Their
## average rating is the team rating. The rating gap sets the chance of
## winning each round, and rounds are rolled until one team has won two.
##
## The numbers here are placeholders. Once M2 connects the new stats to
## combat, tune them so quick-sim results match SkirmishRunner results.

# TUNE: how much each stat counts toward a hero's rating. Equal for now.
const STAT_WEIGHTS := {
	Hero.Stat.STRENGTH: 1.0,
	Hero.Stat.SKILL: 1.0,
	Hero.Stat.AGILITY: 1.0,
	Hero.Stat.VITALITY: 1.0,
	Hero.Stat.DEFENSE: 1.0,
}

# TUNE: the rating gap that gives the stronger team a 73% chance to win a
# round (it's the scale of a logistic curve). Smaller means more predictable.
const ROUND_RATING_SCALE := 1.5


## A hero's weighted average stat.
static func hero_rating(hero: Hero) -> float:
	var total := 0.0
	var weight_sum := 0.0
	for stat in Hero.Stat.values():
		total += hero.get_stat(stat) * STAT_WEIGHTS[stat]
		weight_sum += STAT_WEIGHTS[stat]
	return total / weight_sum


## The heroes a team fields: its highest-rated heroes, as many as the
## tier's fight size. The first one is the lead.
static func pick_lineup(team: Team, tier: LeagueTier.Tier) -> Array[Hero]:
	var heroes: Array[Hero] = team.roster.duplicate()
	heroes.sort_custom(func(a: Hero, b: Hero) -> bool: return hero_rating(a) > hero_rating(b))
	return heroes.slice(0, LeagueTier.fight_size(tier))


## Average rating of the team's lineup. 0 for an empty roster.
static func team_rating(team: Team, tier: LeagueTier.Tier) -> float:
	var lineup := pick_lineup(team, tier)
	if lineup.is_empty():
		return 0.0
	var total := 0.0
	for hero in lineup:
		total += hero_rating(hero)
	return total / lineup.size()


## Chance that the team rated `rating_a` wins a single round.
static func round_win_chance(rating_a: float, rating_b: float) -> float:
	return 1.0 / (1.0 + exp(-(rating_a - rating_b) / ROUND_RATING_SCALE))


## Chance of winning a best-of-3, given the chance of winning each round.
static func match_win_chance(round_chance: float) -> float:
	# Win 2-0, or win 2-1 (two ways to drop one of the first two rounds).
	var p := round_chance
	return p * p * (3.0 - 2.0 * p)


## Team A's chance of winning the match.
static func team_a_win_chance(match_: LeagueMatch, tier: LeagueTier.Tier) -> float:
	return match_win_chance(round_win_chance(team_rating(match_.team_a, tier), team_rating(match_.team_b, tier)))


## Plays the match out round by round and records the result.
static func simulate(match_: LeagueMatch, tier: LeagueTier.Tier, rng: RandomNumberGenerator) -> void:
	var p := round_win_chance(team_rating(match_.team_a, tier), team_rating(match_.team_b, tier))
	var rounds_a := 0
	var rounds_b := 0
	while rounds_a < LeagueMatch.ROUNDS_TO_WIN and rounds_b < LeagueMatch.ROUNDS_TO_WIN:
		if rng.randf() < p:
			rounds_a += 1
		else:
			rounds_b += 1
	match_.record_result(rounds_a, rounds_b)
