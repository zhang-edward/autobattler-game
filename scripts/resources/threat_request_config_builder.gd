class_name ThreatRequestConfigBuilder
extends RefCounted

var threat_request_config: ThreatRequestConfig

func _init() -> void:
	reset()

func reset() -> ThreatRequestConfigBuilder:
	threat_request_config = ThreatRequestConfig.new()
	return self

func with_title(value: String) -> ThreatRequestConfigBuilder:
	threat_request_config.title = value
	return self

func with_description(value: String) -> ThreatRequestConfigBuilder:
	threat_request_config.description = value
	return self

func with_expiry_days(value: int) -> ThreatRequestConfigBuilder:
	threat_request_config.expiry_days = value
	return self

func with_level_requirement(value: int) -> ThreatRequestConfigBuilder:
	threat_request_config.level_requirement = value
	return self

func with_enemy_configs(value: Array[EntityConfig]) -> ThreatRequestConfigBuilder:
	threat_request_config.enemy_configs = value
	return self
	
func with_threat_type(value: ThreatRequestConfig.ThreatType):
	threat_request_config.threat_type = value
	return self

func build() -> ThreatRequestConfig:
	var completedthreat_request_config := threat_request_config
	reset()
	return completedthreat_request_config
