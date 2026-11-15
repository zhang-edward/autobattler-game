class_name AbilityCooldownRow
extends HBoxContainer

@onready var _name_label: Label = $AbilityName
@onready var _cooldown_overlay: ProgressBar = $AbilityIcon/CooldownOverlay

var entity: SkirmishEntity
var ability: Ability

func configure(e: SkirmishEntity, a: Ability) -> void:
	entity = e
	ability = a
	_name_label.text = a.ability_name
	_cooldown_overlay.max_value = a.cooldown
	refresh()

func refresh() -> void:
	_cooldown_overlay.value = entity.ability_cooldowns.get(ability, 0.0)
