class_name ChainRow
extends HBoxContainer

@onready var _name_label: Label = $AbilityName
@onready var _stamina_overlay: ProgressBar = $AbilityIcon/StaminaOverlay

var entity: SkirmishEntity
var stamina_cost := 0

func configure(e: SkirmishEntity, text: String, cost: int) -> void:
	entity = e
	stamina_cost = cost
	_name_label.text = "%s (%d)" % [text, cost]
	_stamina_overlay.max_value = cost
	refresh()

func refresh() -> void:
	_stamina_overlay.value = maxf(stamina_cost - entity.stamina, 0.0)
