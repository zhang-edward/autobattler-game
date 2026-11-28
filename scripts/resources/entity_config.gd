class_name EntityConfig
extends RefCounted

## A hero's state for one round of a fight, built from their league Hero with
## from_hero(). Holds a snapshot of their stats and kit plus everything that
## happens to them during the round (box score, timed boosts), so the league
## Hero is never changed mid-fight. What each stat does is in CombatStats.

## Used by Hero and PortraitConfig. Kept here because portrait_config.gd is
## shared code that refers to EntityConfig.Gender.
enum Gender {
	MALE,
	FEMALE
}

## The league hero this round's state was made from.
var hero: Hero
var entity_name: String = ""

## Stats, copied from the hero
var strength: int = 0
var skill: int = 0
var agility: int = 0
var vitality: int = 0
var defense: int = 0

## Attacks. The super comes from `power_type`.
var abilities: Array[Ability] = []
var power_type: Hero.PowerType = Hero.PowerType.PHYSICAL
var assist: Hero.Assist = Hero.Assist.HEAL

# This round's box score
var damage_dealt := 0
var damage_taken := 0

## Timed boosts from supers and assists: name -> {left, total, damage,
## speed, taken, drain} (seconds, then multipliers).
var _boosts := {}


static func from_hero(hero_: Hero) -> EntityConfig:
	var config := EntityConfig.new()
	config.hero = hero_
	config.entity_name = hero_.hero_name
	config.strength = hero_.get_stat(Hero.Stat.STRENGTH)
	config.skill = hero_.get_stat(Hero.Stat.SKILL)
	config.agility = hero_.get_stat(Hero.Stat.AGILITY)
	config.vitality = hero_.get_stat(Hero.Stat.VITALITY)
	config.defense = hero_.get_stat(Hero.Stat.DEFENSE)
	config.abilities = hero_.moves.duplicate()
	config.power_type = hero_.power_type
	config.assist = hero_.assist
	return config


func reset_all_in_round_vars() -> void:
	damage_dealt = 0
	damage_taken = 0
	_boosts.clear()


## This hero's share of the team's health bar.
func get_max_health() -> int:
	return CombatStats.max_health(vitality)


func super_name() -> String:
	return Hero.SUPER_NAMES[power_type]


# ----- boosts -----

## Adds (or refreshes) a timed boost. `block_drain` scales how much of the
## block bar a blocked hit drains.
func add_boost(boost_name: String, seconds: float, damage := 1.0, speed := 1.0, damage_taken := 1.0, block_drain := 1.0) -> void:
	_boosts[boost_name] = {
		"left": seconds, "total": seconds,
		"damage": damage, "speed": speed, "taken": damage_taken, "drain": block_drain,
	}


func tick_boosts(delta: float) -> void:
	for boost_name in _boosts.keys():
		_boosts[boost_name].left -= delta
		if _boosts[boost_name].left <= 0.0:
			_boosts.erase(boost_name)


func is_boosted() -> bool:
	return not _boosts.is_empty()


## Names of the boosts active now.
func boost_names() -> Array:
	return _boosts.keys()


## How much of a boost is left, 1.0 (just started) to 0.0.
func boost_fraction(boost_name: String) -> float:
	var boost: Dictionary = _boosts.get(boost_name, {})
	return boost.left / boost.total if not boost.is_empty() and boost.total > 0.0 else 0.0


func damage_multiplier() -> float:
	return _product("damage")


func speed_multiplier() -> float:
	return _product("speed")


func damage_taken_multiplier() -> float:
	return _product("taken")


func block_drain_multiplier() -> float:
	return _product("drain")


func _product(key: String) -> float:
	var result := 1.0
	for boost in _boosts.values():
		result *= boost[key]
	return result
