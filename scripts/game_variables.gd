extends Node

enum EncounterEndState {
	VICTORY,
	DEFEAT
}

var player_lineup: Array[EntityConfig] = []
var captured_villain_prospects: Array[Prospect] = []
var money := 0
var encounter_end_state: EncounterEndState
var villain_lineup: Array[EntityConfig] = []
var captured_heroes: Array[EntityConfig] = []
var threat_request_configs: Array[ThreatRequestConfig] = []
var selected_threat_request_config: ThreatRequestConfig
var selected_heroes_for_threat: Array[EntityConfig] = []
var selected_hero_for_threat: EntityConfig
var skirmish_winner: EntityConfig.EntityType
var levels_for_new_ability = [2, 5, 10, 15]

# Shared default kit: identical for all characters for now (tune later).
# Preloaded from .tres so tuning happens in the inspector, not code.
const PUNCH_DEFAULT: PunchAbility = preload("res://abilities/punch/punch_default.tres")
const GRAB_DEFAULT: GrabAbility = preload("res://abilities/grab/grab_default.tres")
const BLOCK_DEFAULT: BlockAbility = preload("res://abilities/block/block_default.tres")
const DODGE_DEFAULT: DodgeAbility = preload("res://abilities/dodge/dodge_default.tres")
const RAPID_JAB_DEFAULT: RapidJabAbility = preload("res://abilities/rapid_jab/rapid_jab_default.tres")
const UPPERCUT: PunchAbility = preload("res://abilities/uppercut/uppercut.tres")
const BIG_PUNCH: PunchAbility = preload("res://abilities/big_punch/big_punch.tres")
const ENERGY_BLAST: ProjectileAbility = preload("res://abilities/energy_blast/energy_blast_default.tres")

static var BASE_EXP_REWARD = 100
static var BASE_MONEY_REWARD = 100
static var BASE_RENOWN_REWARD = 100

func _ready():
	player_lineup = generate_random_entity_configs(5, EntityConfig.EntityType.HERO)
	villain_lineup = generate_random_entity_configs(1, EntityConfig.EntityType.VILLAIN)
	
func generate_random_stat_lines(lineup: Array[EntityConfig]):
	for ec in lineup:
		var entity_config = ec as EntityConfig
		entity_config.damage_dealt = randi_range(50, 100)
		entity_config.num_assists = randi_range(0, 5)
		entity_config.exp = randi_range(0, 100)
		entity_config.gained_exp = randi_range(50, 100)
		
func generate_random_prospects(num_prospects: int, prospect_type: Prospect.ProspectType) -> Array[Prospect]:
	var entity_configs = generate_random_entity_configs(num_prospects, EntityConfig.EntityType.HERO)
	var prospects: Array[Prospect] = []
	for c in entity_configs:
		prospects.append(Prospect.new(c, prospect_type, randi_range(200, 500)))
	return prospects

func generate_random_entity_configs(num_heroes: int, entity_type: EntityConfig.EntityType):
	var configs: Array[EntityConfig] = []
	for i in range(0, num_heroes):
		var rand_gender = NameGenerator.Gender.MALE if randi_range(0, 1) == 0 else NameGenerator.Gender.FEMALE
		var rand_name = NameGenerator.generate_name_string(rand_gender)
		var entity_config = EntityConfigBuilder.new() \
			.with_entity_type(entity_type) \
			.with_gender(EntityConfig.Gender.MALE if rand_gender == NameGenerator.Gender.MALE else EntityConfig.Gender.FEMALE) \
			.with_entity_name(rand_name) \
			.with_defense(randi_range(10, 20)) \
			.with_strength(randi_range(5, 15)) \
			.with_skill(randi_range(5, 15)) \
			.with_agility(randi_range(10, 15)) \
			.with_vitality(randi_range(8, 20)) \
			.with_charisma(randi_range(5, 15)) \
			.with_abilities([
				BIG_PUNCH,
				RAPID_JAB_DEFAULT,
				BLOCK_DEFAULT] as Array[Ability]) \
			.build()
		var portrait_config = PortraitConfig.generate_random_portrait_config(entity_config.gender)
		entity_config.portrait_config = portrait_config
		configs.append(entity_config)
	return configs

func generate_random_threat_requests(num_requests: int):
	var requests: Array[ThreatRequestConfig] = []
	var average_player_level = get_average_player_level_range()
	var enemy_level_range_lo = max(1, average_player_level - 1)
	var enemy_level_range_hi = average_player_level + 1
	for i in range(0, num_requests):
		var rand_enemy_level = randi_range(enemy_level_range_lo, enemy_level_range_hi)
		var enemy_configs = generate_enemy_config_at_level(rand_enemy_level, 1)
		var villain_config = enemy_configs[0]
		var villain_name = villain_config.entity_name
		var threat_reward = create_threat_reward()
		var threat_request_config = ThreatRequestConfigBuilder.new() \
			.with_title(villain_name + " encountered") \
			.with_description("Sample description") \
			.with_expiry_days(randi_range(5, 8)) \
			.with_level_requirement(rand_enemy_level) \
			.with_enemy_configs(enemy_configs) \
			.with_threat_type(ThreatRequestConfig.ThreatType.VILLAIN) \
			.with_threat_reward(threat_reward) \
			.build()
		requests.append(threat_request_config)
	return requests

func get_average_player_level_range():
	var level_sum = 0.0
	for c in player_lineup:
		level_sum += c.level
	return round(level_sum / player_lineup.size())

func generate_enemy_config_at_level(level: int, num_enemies: int):
	var random_enemies = generate_random_entity_configs(num_enemies, EntityConfig.EntityType.VILLAIN)
	for e in random_enemies:
		e.level = level
		e.exp_to_next_level = e.get_exp_to_next_level(e.level)
		# simulate level ups
		for i in range(1, level):
			var all_stat_keys = ["strength", "defense", "skill", "agility", "vitality", "charisma"]
			for j in range(0, 3):
				var random_stat = all_stat_keys.pick_random()
				e[random_stat] += 1
	return random_enemies

func create_threat_reward():
	var reward = ThreatReward.new()
	reward.exp_gain = BASE_EXP_REWARD
	reward.money = BASE_MONEY_REWARD
	reward.renown = BASE_RENOWN_REWARD
	return reward

func enhance_villain_stats(config: EntityConfig):
	config.vitality = round(config.vitality * 2.5)
	
func get_label_from_power_type(t: EntityConfig.EntityPowerType):
	match t:
		EntityConfig.EntityPowerType.ELEMENTAL:
			return "Elemental"
		EntityConfig.EntityPowerType.PHYSICAL:
			return "Physical"
		EntityConfig.EntityPowerType.TRANSFORMATION:
			return "Transformation"
		EntityConfig.EntityPowerType.PSYCHIC:
			return "Psychic"
		EntityConfig.EntityPowerType.GOD:
			return "God"
			
func get_all_abilities():
	return [
		PUNCH_DEFAULT,
		GRAB_DEFAULT,
		BLOCK_DEFAULT,
		DODGE_DEFAULT,
		RAPID_JAB_DEFAULT,
		UPPERCUT,
		BIG_PUNCH,
		ENERGY_BLAST,
	]
