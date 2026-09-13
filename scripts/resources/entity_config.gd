class_name EntityConfig
extends Object

enum EntityType {
	HERO,
	VILLAIN
}

var entity_name: String = ""
var entity_type: EntityType
var max_health := 100
var attack := 5
var defense := 5
var level := 1
var curr_exp := 0
var skirmish_moveset: Array[Move] = []
var tactical_abilities: Array[Ability] = []

func _init(en: String, et: EntityType, mhp: int, atk: int, def: int, lvl: int, ms: Array[Move]) -> void:
	entity_name = en
	entity_type = et
	max_health = mhp
	attack = atk
	defense = def
	level = lvl
	skirmish_moveset = ms
