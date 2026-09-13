class_name EntityConfigBuilder
extends RefCounted

var _entity_config: EntityConfig

func _init() -> void:
	reset()
	
func reset() -> EntityConfigBuilder:
	_entity_config = EntityConfig.new()
	return self
	
func with_gender(g: EntityConfig.Gender):
	_entity_config.gender = g
	return self

func with_entity_name(en: String):
	_entity_config.entity_name = en
	return self

func with_entity_type(et: EntityConfig.EntityType):
	_entity_config.entity_type = et
	return self 

func with_max_health(mh: int):
	_entity_config.max_health = mh
	return self

func with_attack(atk: int):
	_entity_config.attack = atk
	return self
	
func with_defense(def: int):
	_entity_config.defense = def
	return self
	
func with_ground_speed(gspd: int):
	_entity_config.ground_speed = gspd
	return self

func with_air_speed(aspd: int):
	_entity_config.air_speed = aspd
	return self
	
func with_can_fly(cf: bool):
	_entity_config.can_fly = cf
	return self
	
func with_skirmish_moveset(mset: Array[Move]):
	_entity_config.skirmish_moveset = mset
	return self
	
func build() -> EntityConfig:
	var completed_entity_config = _entity_config
	reset()
	return completed_entity_config
