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

func _ready():
	player_lineup = generate_random_entity_configs(5, EntityConfig.EntityType.HERO)
	villain_lineup = generate_random_entity_configs(1, EntityConfig.EntityType.VILLAIN)
	
func generate_random_stat_lines(lineup: Array[EntityConfig]):
	for ec in lineup:
		var entity_config = ec as EntityConfig
		entity_config.damage_dealt = randi_range(50, 100)
		entity_config.num_assists = randi_range(0, 5)
		entity_config.defeated_villain_names = ["test1", "test2", "test3"]
		entity_config.num_civs_saved = randi_range(5, 10)
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
		var entity_config = EntityConfigBuilder.new()\
			.with_entity_type(entity_type)\
			.with_gender(EntityConfig.Gender.MALE if rand_gender == NameGenerator.Gender.MALE else EntityConfig.Gender.FEMALE)\
			.with_entity_name(rand_name)\
			.with_defense(randi_range(10, 20))\
			.with_strength(randi_range(5, 15))\
			.with_skill(randi_range(5, 15))\
			.with_agility(randi_range(100, 150))\
			.with_vitality(randi_range(75, 200))\
			.with_charisma(randi_range(5, 15))\
			.build()
		var portrait_config = PortraitConfig.generate_random_portrait_config(entity_config.gender)
		entity_config.portrait_config = portrait_config
		configs.append(entity_config)
	return configs

func generate_random_threat_requests(num_requests: int):
	var requests: Array[ThreatRequestConfig] = []
	for i in range(0, num_requests):
		var enemy_configs = generate_random_entity_configs(1, EntityConfig.EntityType.VILLAIN)
		var villain_name = enemy_configs[0].entity_name
		var threat_request_config = ThreatRequestConfigBuilder.new()\
			.with_title(villain_name + " encountered")\
			.with_description("Sample description")\
			.with_expiry_days(randi_range(5, 8))\
			.with_level_requirement(1)\
			.with_enemy_configs(enemy_configs)\
			.with_threat_type(ThreatRequestConfig.ThreatType.VILLAIN)\
			.build()
		requests.append(threat_request_config)
	return requests
	
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
