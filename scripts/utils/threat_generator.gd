class_name ThreatGenerator
extends RefCounted

static var BASE_EXP_REWARD = 100
static var BASE_MONEY_REWARD = 100

static func generate_random_threat_requests(num_requests: int, player_lineup: Array[EntityConfig]):
	var requests: Array[ThreatRequestConfig] = []
	var average_player_level = get_average_player_level_range(player_lineup)
	var enemy_level_range_lo = max(1, average_player_level - 1)
	var enemy_level_range_hi = average_player_level + 1
	for i in range(0, num_requests):
		var rand_enemy_level = randi_range(enemy_level_range_lo, enemy_level_range_hi)
		var enemy_configs = EntityGenerator.generate_enemy_config_at_level(rand_enemy_level, 1)
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

static func get_average_player_level_range(player_lineup: Array[EntityConfig]):
	var level_sum = 0.0
	for c in player_lineup:
		level_sum += c.level
	return round(level_sum / player_lineup.size())

static func create_threat_reward():
	var reward = ThreatReward.new()
	reward.exp_gain = BASE_EXP_REWARD
	reward.money = BASE_MONEY_REWARD
	return reward
