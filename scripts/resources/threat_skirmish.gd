class_name ThreatSkirmish
extends RefCounted

var threat_request_config: ThreatRequestConfig
var heroes: Array[EntityConfig] = []
var bench_heroes: Array[EntityConfig] = []
var entered_heroes: Array[EntityConfig] = []
var leveled_up_heroes: Array[EntityConfig] = []
var winner: EntityConfig.EntityType
var reputation_change := 0

func _init(config: ThreatRequestConfig) -> void:
	threat_request_config = config
