extends Node

var player_lineup: Array[EntityConfig] = []
var player_reserves: Array[EntityConfig] = []
var civilian_hero_prospects: Array[Prospect] = []
var num_saved_civilians := 0
var num_killed_civilians := 0
var money := 5000

var villain_lineup: Array[EntityConfig] = []
var captured_heroes: Array[EntityConfig] = []

func _ready():
	player_lineup = generate_random_entity_configs(5, EntityConfig.EntityType.HERO)
	villain_lineup = generate_random_entity_configs(1, EntityConfig.EntityType.VILLAIN)

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
