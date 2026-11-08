extends Node

var player_lineup: Array[EntityConfig] = []
var captured_villain_prospects: Array[Prospect] = []
var money := 0
var reputation := 10
var threat_request_configs: Array[ThreatRequestConfig] = []
var curr_threat_skirmish: ThreatSkirmish
var levels_for_new_ability = [2, 5, 10, 15]
var curr_day: int = 1

static var REST_DAYS = 2
static var DEFEATED_REST_DAYS = 5
static var WIN_REPUTATION = 1
static var LOSS_REPUTATION = -2
static var EXPIRED_REPUTATION = -3

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
			
func resolve_threat_skirmish(threat_skirmish: ThreatSkirmish):
	# Calculate hero recovery time
	for h in threat_skirmish.heroes:
		h.injury_recovery_days = DEFEATED_REST_DAYS if h.curr_health <= 0 else REST_DAYS

	threat_skirmish.reputation_change = WIN_REPUTATION if threat_skirmish.winner == EntityConfig.EntityType.HERO else LOSS_REPUTATION
	reputation += threat_skirmish.reputation_change

	# If player won this skirmish, villains are defeated - remove this threat from threat list
	if threat_skirmish.winner == EntityConfig.EntityType.HERO:
		threat_request_configs = threat_request_configs.filter(func(c): return c != threat_skirmish.threat_request_config)

func advance_day():
	curr_day += 1
	for t in threat_request_configs:
		t.expiry_days -= 1
		if t.expiry_days <= 0:
			reputation += EXPIRED_REPUTATION
	threat_request_configs = threat_request_configs.filter(func(t: ThreatRequestConfig): return t.expiry_days > 0)
	# Tick down injuries
	for c in player_lineup:
		if c.injury_recovery_days > 0:
			c.injury_recovery_days -= 1
			if c.injury_recovery_days == 0:
				c.curr_health = c.get_max_health()
