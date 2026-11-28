class_name LeagueGenerator
extends RefCounted

## Generates random heroes and teams. Every function takes a
## RandomNumberGenerator, so a seed reproduces the same league.
## (Portraits use the global RNG and aren't reproduced. They're cosmetic.)

## The 16 teams from the standings mockup: name and badge abbreviation.
const TEAM_IDENTITIES: Array[Array] = [
	["Bayside Bolts", "BB"],
	["Gale Riders", "GR"],
	["Iron Harbor Titans", "IH"],
	["Skyline Strikers", "SS"],
	["Ember City Wardens", "EC"],
	["Crimson Comets", "CC"],
	["Northgate Owls", "NO"],
	["Redwood Rangers", "RW"],
	["Steel Valley Sentinels", "SV"],
	["Cobalt Coast Kings", "CK"],
	["Dustbowl Drifters", "DD"],
	["Frostpeak Yetis", "FY"],
	["Granite Peak Golems", "GP"],
	["Neon Harbor Hex", "NH"],
	["Thunder Bay Ravens", "TB"],
	["Rustwater Rams", "RR"],
]

const TEAMS_PER_LEAGUE := 16
# TUNE: the roster mockups show 4 of 6 spots filled.
const STARTING_ROSTER_SIZE := 4

## One-word hero names are a prefix plus a suffix ("Ironjaw", "Dustdevil").
const NAME_PREFIXES: Array[String] = [
	"Iron", "Dust", "Patch", "Hull", "Rip", "Mind", "Star", "Glim", "Quick",
	"Storm", "Night", "Ember", "Frost", "Volt", "Grit", "Shade", "Brick", "Flint",
]
const NAME_SUFFIXES: Array[String] = [
	"jaw", "devil", "work", "breaker", "tide", "well", "ling", "mer", "line",
	"fist", "wing", "spark", "guard", "fall", "shot", "hook", "mark", "crest",
]
## Two-word hero names are an adjective plus a noun ("Rook Sentry", "Quiet Lantern").
const NAME_ADJECTIVES: Array[String] = [
	"Rook", "Quiet", "Nova", "Silent", "Crimson", "Lucky", "Hollow", "Golden",
	"Wild", "Atomic", "Velvet", "Grim", "Bright", "Copper",
]
const NAME_NOUNS: Array[String] = [
	"Sentry", "Lantern", "Kane", "Torque", "Pike", "Moth", "Bulwark", "Comet",
	"Anvil", "Specter", "Warden", "Viper", "Echo", "Ballast",
]

# TUNE: chance that each stat's potential is 1..5 stars.
const POTENTIAL_WEIGHTS := [0.15, 0.30, 0.30, 0.18, 0.07]

# TUNE: a level-1 stat is its potential plus this random range, so high
# potential stats also start a little higher. Gives 2..9 like the draft mockup.
const BASE_STAT_BONUS := Vector2i(1, 4)

# TUNE: salary = (base + per_rating * overall rating) * tier multiplier,
# rounded down to the nearest $10K. A Lv 5 hero rated ~9 earns ~$375K.
const SALARY_BASE := 150_000
const SALARY_PER_RATING := 25_000
const SALARY_ROUNDING := 10_000
const CONTRACT_LENGTH_RANGE := Vector2i(1, 3)

const ABILITIES_PATH := "res://abilities/"
# Starting attacks: one of each tier.
const STARTING_MOVE_TIERS: Array[Ability.Tier] = [Ability.Tier.LIGHT, Ability.Tier.MEDIUM, Ability.Tier.HEAVY]

static var _all_abilities: Array[Ability] = []


## A new level-1 hero with random stats and potential, and no contract.
static func generate_hero(rng: RandomNumberGenerator, used_names: Dictionary = {}) -> Hero:
	var hero := Hero.new()
	hero.hero_name = generate_hero_name(rng, used_names)
	hero.power_type = rng.randi_range(0, Hero.PowerType.size() - 1) as Hero.PowerType
	hero.gender = EntityConfig.Gender.MALE if rng.randf() < 0.5 else EntityConfig.Gender.FEMALE
	hero.portrait_config = PortraitConfig.generate_random_portrait_config(hero.gender)
	for stat in Hero.Stat.values():
		var stars := rng.rand_weighted(PackedFloat32Array(POTENTIAL_WEIGHTS)) + 1
		hero.potential[stat] = stars
		hero.stats[stat] = stars + rng.randi_range(BASE_STAT_BONUS.x, BASE_STAT_BONUS.y)
	assign_starting_moves(hero, rng)
	hero.assist = rng.randi_range(0, Hero.Assist.size() - 1) as Hero.Assist
	return hero


## Gives a hero one random move of each starting tier.
static func assign_starting_moves(hero: Hero, rng: RandomNumberGenerator) -> void:
	hero.moves.clear()
	for tier in STARTING_MOVE_TIERS:
		var options := all_abilities().filter(func(a: Ability) -> bool: return a.tier == tier)
		if not options.is_empty():
			hero.moves.append(options[rng.randi_range(0, options.size() - 1)])


## Every move in res://abilities/, sorted by file name so picks are
## reproducible with a seed. Loaded once.
static func all_abilities() -> Array[Ability]:
	if _all_abilities.is_empty():
		var file_names := Array(ResourceLoader.list_directory(ABILITIES_PATH))
		file_names.sort()
		for file_name: String in file_names:
			if file_name.ends_with(".tres"):
				var ability := load(ABILITIES_PATH + file_name) as Ability
				if ability != null:
					_all_abilities.append(ability)
	return _all_abilities


## A hero at `level`, as if an AI manager had levelled them up from 1.
static func generate_hero_at_level(rng: RandomNumberGenerator, level: int, used_names: Dictionary = {}) -> Hero:
	var hero := generate_hero(rng, used_names)
	for i in range(1, level):
		hero.grant_level(hero.pick_ai_level_up_stat(rng))
	return hero


## A name not already in `used_names`. Adds the new name to it.
static func generate_hero_name(rng: RandomNumberGenerator, used_names: Dictionary = {}) -> String:
	for attempt in 100:
		var hero_name: String
		if rng.randf() < 0.5:
			hero_name = _pick(rng, NAME_PREFIXES) + _pick(rng, NAME_SUFFIXES)
		else:
			hero_name = _pick(rng, NAME_ADJECTIVES) + " " + _pick(rng, NAME_NOUNS)
		if not used_names.has(hero_name):
			used_names[hero_name] = true
			return hero_name
	# Every combination tried was taken: fall back to a numbered name.
	var fallback := "Hero %d" % (used_names.size() + 1)
	used_names[fallback] = true
	return fallback


static func salary_for(hero: Hero, tier: LeagueTier.Tier) -> int:
	var raw := (SALARY_BASE + SALARY_PER_RATING * hero.overall_rating()) * LeagueTier.salary_multiplier(tier)
	return int(floor(raw / SALARY_ROUNDING)) * SALARY_ROUNDING


## A team with a starting roster of heroes on standard contracts that fit
## under the tier's payroll cap.
static func generate_team(rng: RandomNumberGenerator, identity_index: int, tier: LeagueTier.Tier,
		season: int = 1, used_names: Dictionary = {}) -> Team:
	var identity: Array = TEAM_IDENTITIES[identity_index]
	var team := Team.create(identity[0], identity[1], _team_color(identity_index))
	var levels := LeagueTier.generated_level_range(tier)
	for i in STARTING_ROSTER_SIZE:
		var hero := generate_hero_at_level(rng, rng.randi_range(levels.x, levels.y), used_names)
		var length := rng.randi_range(CONTRACT_LENGTH_RANGE.x, CONTRACT_LENGTH_RANGE.y)
		hero.contract = Contract.create(Contract.Kind.STANDARD, salary_for(hero, tier), length, season)
		team.add_hero(hero)
	_fit_payroll_to_cap(team, LeagueTier.payroll_cap(tier))
	return team


## All 16 teams in a league. The team at `player_index` is the player's.
static func generate_league_teams(rng: RandomNumberGenerator, tier: LeagueTier.Tier,
		player_index: int = 0, season: int = 1) -> Array[Team]:
	var used_names := {}
	var teams: Array[Team] = []
	for i in TEAMS_PER_LEAGUE:
		var team := generate_team(rng, i, tier, season, used_names)
		team.is_player = i == player_index
		teams.append(team)
	return teams


## Scales salaries down if the roster is over the cap.
static func _fit_payroll_to_cap(team: Team, cap: int) -> void:
	var payroll := team.payroll()
	if payroll <= cap:
		return
	var scale := float(cap) / payroll
	for hero in team.roster:
		hero.contract.salary = int(floor(hero.contract.salary * scale / SALARY_ROUNDING)) * SALARY_ROUNDING


## Spreads the 16 team colors evenly around the color wheel.
static func _team_color(identity_index: int) -> Color:
	return Color.from_hsv(float(identity_index) / TEAM_IDENTITIES.size(), 0.6, 0.9)


static func _pick(rng: RandomNumberGenerator, options: Array[String]) -> String:
	return options[rng.randi_range(0, options.size() - 1)]
