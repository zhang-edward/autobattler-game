class_name Prospect
extends RefCounted

enum ProspectType {
	FORMER_VILLAIN,
	SAVED_CIVILIAN
}

var entity_config: EntityConfig
var prospect_type: ProspectType
var cost := 0

func _init(ec: EntityConfig, ptype: ProspectType, c: int) -> void:
	entity_config = ec
	prospect_type = ptype
	cost = c
