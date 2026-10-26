class_name EntityConfig
extends RefCounted

enum EntityType {
	HERO,
	VILLAIN,
	MOB
}

enum EntityPowerType {
	ELEMENTAL,
	PHYSICAL,
	TRANSFORMATION,
	PSYCHIC,
	GOD
}

enum Gender {
	MALE,
	FEMALE
}

# Static variables
var gender: Gender
var entity_name: String = ""
var entity_type: EntityType
var entity_power_type: EntityPowerType # TODO: Does nothing currently

## Stats
var defense: int = 5
var strength: int = 0
var skill: int = 0 # TODO: Does nothing currently
var agility: int = 0
var vitality: int = 0
var charisma: int = 0 # TODO: Does nothing currently

var level := 1
var exp := 0
var exp_to_next_level := 100
var moveset: Array[Move] = []
var portrait_config: PortraitConfig

# In-round state
var curr_health := 0
var gained_exp := 0
var num_assists := 0
var damage_dealt := 0

func handle_level_up():
	level += 1
	exp_to_next_level = get_exp_to_next_level(level)
	defense += cond_stat_update(1, 5)
	strength += cond_stat_update(1, 3)
	skill += cond_stat_update(1, 3)
	agility += cond_stat_update(15, 25)
	vitality += cond_stat_update(10, 20)
	charisma += cond_stat_update(1, 3)

func cond_stat_update(lo: int, hi: int):
	var should_incr = randi_range(0, 1) == 0
	return randi_range(lo, hi) if should_incr else 0
	
func reset_all_in_round_vars():
	curr_health = vitality
	gained_exp = 0
	num_assists = 0
	damage_dealt = 0

func get_exp_to_next_level(level: int) -> int:
	var base_exp: float = 100.0
	var exponent: float = 1.8
	var flat_exp: float = 50.0
	return int(floor(base_exp * pow(level, exponent) + flat_exp * level))
