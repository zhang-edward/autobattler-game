class_name EntityConfig
extends RefCounted

enum EntityType {
	HERO,
	VILLAIN
}

enum Gender {
	MALE,
	FEMALE
}

# Static variables
var gender: Gender
var entity_name: String = ""
var entity_type: EntityType
var max_health := 100
var attack := 5
var defense := 5
var ground_speed := 100
var air_speed := 0
var level := 1
var exp := 0
var exp_to_next_level := 100
var skirmish_moveset: Array[Move] = []
var can_fly := false
var portrait_config: PortraitConfig

# In-round state
var curr_health := 0
var gained_exp := 0
var num_assists := 0
var damage_dealt := 0
var num_civs_saved := 0
var defeated_villain_names := []

func handle_level_up():
	level += 1	
	exp_to_next_level = get_exp_to_next_level(level)
	attack += cond_stat_update(1, 5)
	defense += cond_stat_update(1, 5)
	ground_speed += cond_stat_update(8, 15)
	if can_fly:
		air_speed += cond_stat_update(8, 15)
	max_health += cond_stat_update(5, 10)

func cond_stat_update(lo: int, hi: int):
	var should_incr = randi_range(0, 1) == 0
	return randi_range(lo, hi) if should_incr else 0
	
func reset_all_in_round_vars():
	curr_health = max_health
	gained_exp = 0
	num_assists = 0
	damage_dealt = 0
	num_civs_saved = 0
	defeated_villain_names = []
func get_exp_to_next_level(level: int) -> int:
	var base_exp: float = 100.0
	var exponent: float = 1.8
	var flat_exp: float = 50.0
	return int(floor(base_exp * pow(level, exponent) + flat_exp * level))
