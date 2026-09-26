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
var skirmish_moveset: Array[Move] = []
var can_fly := false
var recruit_cost := 0

# In-round state
var curr_health := 0
var gained_exp := 0
var num_assists := 0
var damage_dealt := 0
var villains_defeated := 0
var num_civs_saved := 0
