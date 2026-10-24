class_name ThreatRequestConfig
extends RefCounted

enum ThreatType {
	MOB,
	VILLAIN
}

var title: String = ""
var description: String = ""
var expiry_days: int = 0
var level_requirement: int = 0
var enemy_configs: Array[EntityConfig] = []
var threat_type: ThreatType
var reward: ThreatReward
