class_name Hero
extends RefCounted

## A hero in the league: identity, stats, potential, progression and contract.
## This is league data only. Fights will read it once M2 connects combat to it.

enum Stat { STRENGTH, SKILL, AGILITY, VITALITY, DEFENSE }
enum PowerType { ELEMENTAL, PHYSICAL, PSYCHIC, TRANSFORMATION }
## What the hero does for the team when they tag in.
enum Assist { HEAL, STRIKE_BOOST, GUARD_BOOST }

const STAT_NAMES := {
	Stat.STRENGTH: "Strength",
	Stat.SKILL: "Skill",
	Stat.AGILITY: "Agility",
	Stat.VITALITY: "Vitality",
	Stat.DEFENSE: "Defense",
}

const POWER_TYPE_NAMES := {
	PowerType.ELEMENTAL: "Elemental",
	PowerType.PHYSICAL: "Physical",
	PowerType.PSYCHIC: "Psychic",
	PowerType.TRANSFORMATION: "Transformation",
}

## Each power type has one super move. What they do is in SuperState.
const SUPER_NAMES := {
	PowerType.ELEMENTAL: "Nova Beam",
	PowerType.PHYSICAL: "Rush Combo",
	PowerType.PSYCHIC: "Mind Surge",
	PowerType.TRANSFORMATION: "Power Up",
}

const ASSIST_NAMES := {
	Assist.HEAL: "Heal",
	Assist.STRIKE_BOOST: "Strike Boost",
	Assist.GUARD_BOOST: "Guard Boost",
}

const MIN_POTENTIAL := 1
const MAX_POTENTIAL := 5

## How much a stat rises when picked on a level-up, indexed by that stat's
## potential in stars (index 0 unused). Matches the level-up mockup:
## 5 stars +3, 4 stars +2, 3 stars +2, 2 stars +1.
const GAIN_BY_POTENTIAL: Array[int] = [0, 1, 1, 2, 2, 3]

# TUNE: XP needed to reach the next level is this times the current level.
# Matches the roster mockup (500 XP at Lv 5).
const XP_PER_LEVEL := 100

# Unique ids so other league data can refer to heroes. Save/load will need
# to restore this counter.
static var _next_id := 1

var id: int
var hero_name := ""
var power_type: PowerType = PowerType.PHYSICAL
var gender: EntityConfig.Gender = EntityConfig.Gender.MALE
var portrait_config: PortraitConfig
var level := 1
## XP toward the next level.
var xp := 0
## Level-ups earned but not yet spent on a stat.
var pending_level_ups := 0
var stats: Dictionary[Stat, int] = {}
var potential: Dictionary[Stat, int] = {}
## Attacks: one light, one medium and one heavy to start. The super comes
## from the power type (see SUPER_NAMES).
var moves: Array[Ability] = []
var assist: Assist = Assist.HEAL
var contract: Contract


func _init() -> void:
	id = _next_id
	_next_id += 1
	for stat in Stat.values():
		stats[stat] = 0
		potential[stat] = MIN_POTENTIAL


static func stat_name(stat: Stat) -> String:
	return STAT_NAMES[stat]


static func power_type_name(type: PowerType) -> String:
	return POWER_TYPE_NAMES[type]


static func assist_name(assist_: Assist) -> String:
	return ASSIST_NAMES[assist_]


func super_name() -> String:
	return SUPER_NAMES[power_type]


func get_stat(stat: Stat) -> int:
	return stats[stat]


func get_potential(stat: Stat) -> int:
	return potential[stat]


## How much `stat` would rise if picked on a level-up.
func stat_gain(stat: Stat) -> int:
	return GAIN_BY_POTENTIAL[potential[stat]]


func xp_to_next_level() -> int:
	return XP_PER_LEVEL * level


## Adds XP and levels up as many times as it covers. Each level-up adds a
## pending stat pick. Returns the number of levels gained.
func add_xp(amount: int) -> int:
	xp += amount
	var gained := 0
	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		level += 1
		gained += 1
	pending_level_ups += gained
	return gained


## Spends one pending level-up on `stat`. Returns how much the stat rose,
## or 0 if there was no pending level-up.
func apply_level_up(stat: Stat) -> int:
	if pending_level_ups <= 0:
		return 0
	pending_level_ups -= 1
	var gain := stat_gain(stat)
	stats[stat] += gain
	return gain


## Levels up immediately and raises `stat`, without XP. Used when
## generating heroes who start above level 1.
func grant_level(stat: Stat) -> int:
	level += 1
	var gain := stat_gain(stat)
	stats[stat] += gain
	return gain


## The stat an AI manager raises on a level-up: random, weighted toward
## stats with higher potential.
func pick_ai_level_up_stat(rng: RandomNumberGenerator) -> Stat:
	var weights := PackedFloat32Array()
	for stat in Stat.values():
		weights.append(pow(potential[stat], 2))
	return Stat.values()[rng.rand_weighted(weights)] as Stat


## Average of the five stats.
func overall_rating() -> float:
	var total := 0
	for stat in Stat.values():
		total += stats[stat]
	return float(total) / Stat.size()


## Average potential, rounded to the nearest half star (the draft board
## shows half stars).
func overall_potential() -> float:
	var total := 0
	for stat in Stat.values():
		total += potential[stat]
	return snappedf(float(total) / Stat.size(), 0.5)


## The stat with the highest potential. Ties go to the higher current value.
func best_stat() -> Stat:
	var best: Stat = Stat.STRENGTH
	for stat in Stat.values():
		if potential[stat] > potential[best] \
				or (potential[stat] == potential[best] and stats[stat] > stats[best]):
			best = stat
	return best
