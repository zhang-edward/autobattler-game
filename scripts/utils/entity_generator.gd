class_name EntityGenerator
extends RefCounted

const ABILITIES_PATH := "res://abilities/"

static func generate_random_prospects(num_prospects: int, prospect_type: Prospect.ProspectType) -> Array[Prospect]:
	var entity_configs = generate_random_entity_configs(num_prospects, EntityConfig.EntityType.HERO)
	var prospects: Array[Prospect] = []
	for c in entity_configs:
		prospects.append(Prospect.new(c, prospect_type, randi_range(200, 500)))
	return prospects

static func random_ability_of_tier(tier: Ability.Tier) -> Ability:
	var abilities_with_matching_tier = get_all_abilities().filter(func(a: Ability): return a.tier == tier)
	return abilities_with_matching_tier.pick_random()

static func generate_random_entity_configs(num_heroes: int, entity_type: EntityConfig.EntityType):
	var configs: Array[EntityConfig] = []
	for i in range(0, num_heroes):
		var rand_gender = NameGenerator.Gender.MALE if randi_range(0, 1) == 0 else NameGenerator.Gender.FEMALE
		var rand_name = NameGenerator.generate_name_string(rand_gender)

		var abilities: Array[Ability] = [
			random_ability_of_tier(Ability.Tier.LIGHT),
			random_ability_of_tier(Ability.Tier.MEDIUM),
			random_ability_of_tier(Ability.Tier.MEDIUM),
			random_ability_of_tier(Ability.Tier.HEAVY),
		]

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
			.with_abilities(abilities) \
			.build()
		var portrait_config = PortraitConfig.generate_random_portrait_config(entity_config.gender)
		entity_config.portrait_config = portrait_config
		configs.append(entity_config)
	return configs

static func generate_enemy_config_at_level(level: int, num_enemies: int):
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

static func enhance_villain_stats(config: EntityConfig):
	config.vitality = round(config.vitality * 2.5)

static func get_all_abilities():
	var all_abilities: Array[Ability] = []
	for file_name in ResourceLoader.list_directory(ABILITIES_PATH):
		if not file_name.ends_with(".tres"):
			continue
		var ability := load(ABILITIES_PATH + file_name) as Ability
		if ability != null:
			all_abilities.append(ability)
	return all_abilities
