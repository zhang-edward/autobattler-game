class_name AbilityCooldownRow
extends HBoxContainer

@onready var _name_label: Label = $AbilityName
@onready var _cooldown_overlay: ProgressBar = $AbilityIcon/CooldownOverlay

var entity: SkirmishEntity
var ability: Ability

func configure(e: SkirmishEntity, a: Ability) -> void:
	entity = e
	ability = a
	_name_label.text = "%s (%d)" % [a.ability_name, a.stamina_cost]
	_cooldown_overlay.max_value = a.stamina_cost
	refresh()

func refresh() -> void:
	_cooldown_overlay.value = maxf(ability.stamina_cost - entity.stamina, 0.0)
