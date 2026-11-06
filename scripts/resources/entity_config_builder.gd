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
	
func with_abilities(abilities: Array[Ability]):
	_entity_config.abilities = abilities
	return self
	
func with_entity_power_type(t: EntityConfig.EntityPowerType):
	_entity_config.entity_power_type = t
	return self
	
## Starts a builder pre-filled with a copy of an existing EntityConfig, so tweaks via
## with_*() never mutate the original. The abilities array is duplicated, but the
## Ability resources and portrait_config inside are shared references.
static func from_entity_config(source: EntityConfig) -> EntityConfigBuilder:
	var builder := EntityConfigBuilder.new()
	var copy := builder._entity_config
	copy.gender = source.gender
	copy.entity_name = source.entity_name
	copy.entity_type = source.entity_type
	copy.entity_power_type = source.entity_power_type
	copy.defense = source.defense
	copy.strength = source.strength
	copy.skill = source.skill
	copy.agility = source.agility
	copy.vitality = source.vitality
	copy.charisma = source.charisma
	copy.level = source.level
	copy.exp = source.exp
	copy.exp_to_next_level = source.exp_to_next_level
	copy.abilities = source.abilities.duplicate()
	copy.portrait_config = source.portrait_config
	copy.curr_health = source.curr_health
	copy.gained_exp = source.gained_exp
	copy.num_assists = source.num_assists
	copy.damage_dealt = source.damage_dealt
	return builder

func build() -> EntityConfig:
	var completed_entity_config = _entity_config
	reset()
	return completed_entity_config
