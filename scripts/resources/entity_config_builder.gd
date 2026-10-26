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

func with_defense(def: int):
	_entity_config.defense = def
	return self

func with_strength(s: int):
	_entity_config.strength = s
	return self

func with_skill(sk: int):
	_entity_config.skill = sk
	return self

func with_agility(ag: int):
	_entity_config.agility = ag
	return self

func with_vitality(vit: int):
	_entity_config.vitality = vit
	return self

func with_charisma(cha: int):
	_entity_config.charisma = cha
	return self
	
func with_skirmish_moveset(moveset: Array[Move]):
	_entity_config.moveset = moveset
	return self
	
func with_entity_power_type(t: EntityConfig.EntityPowerType):
	_entity_config.entity_power_type = t
	return self
	
func build() -> EntityConfig:
	var completed_entity_config = _entity_config
	reset()
	return completed_entity_config
