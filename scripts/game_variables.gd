extends Node

var player_lineup: Array[EntityConfig] = []
var captured_villain_prospects: Array[Prospect] = []
var money := 0
var renown := 0
var threat_request_configs: Array[ThreatRequestConfig] = []
var selected_threat_request_config: ThreatRequestConfig
var selected_heroes_for_threat: Array[EntityConfig] = []
var selected_hero_for_threat: EntityConfig
var skirmish_winner: EntityConfig.EntityType
var levels_for_new_ability = [2, 5, 10, 15]
var curr_day: int = 1

static var REST_DAYS = 2
static var DEFEATED_REST_DAYS = 5

func _ready():
	player_lineup = EntityGenerator.generate_random_entity_configs(5, EntityConfig.EntityType.HERO)

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
			
func advance_day():
	curr_day += 1
	for t in threat_request_configs:
		t.expiry_days -= 1
	threat_request_configs = threat_request_configs.filter(func(t: ThreatRequestConfig): return t.expiry_days > 0)
	# Tick down injuries
	for c in player_lineup:
		if c.injury_recovery_days > 0:
			c.injury_recovery_days -= 1
