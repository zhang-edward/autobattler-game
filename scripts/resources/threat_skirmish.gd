class_name ThreatSkirmish
extends RefCounted

var threat_request_config: ThreatRequestConfig
var heroes: Array[EntityConfig] = []
var winner: EntityConfig.EntityType

func _init(config: ThreatRequestConfig) -> void:
	threat_request_config = config
