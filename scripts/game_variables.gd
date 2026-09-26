extends Node

var player_lineup: Array[EntityConfig] = []
var player_reserves: Array[EntityConfig] = []
var civilian_hero_prospects: Array[Prospect] = []
var captured_villain_prospects: Array[Prospect] = []
var num_saved_civilians := 0
var num_killed_civilians := 0
var money := 5000

var villain_lineup: Array[EntityConfig] = []
var captured_heroes: Array[EntityConfig] = []

func _ready():
	print("Went here!")
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
			.with_max_health(randi_range(75, 200))\
			.with_attack(randi_range(10, 20))\
			.with_defense(randi_range(10, 20))\
			.with_can_fly(randi_range(0, 1) == 0)\
			.with_ground_speed(randi_range(50, 200))\
			.with_air_speed(randi_range(100, 250))\
			.build()
		configs.append(entity_config)
	return configs
