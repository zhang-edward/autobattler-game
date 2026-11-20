class_name ChainRow
extends HBoxContainer

@onready var _name_label: Label = $AbilityName
@onready var _cost_overlay: ProgressBar = $AbilityIcon/CostOverlay

var entity: SkirmishEntity
var cost := 0
var uses_composure := false

func configure(e: SkirmishEntity, text: String, cost_: int, uses_composure_ := false) -> void:
	entity = e
	cost = cost_
	uses_composure = uses_composure_
	_name_label.text = "%s (%d)" % [text, cost]
	_cost_overlay.max_value = cost
	refresh()

func refresh() -> void:
	if uses_composure:
		_cost_overlay.value = cost if entity.composure_recovering else 0.0
	else:
		_cost_overlay.value = maxf(cost - entity.stamina, 0.0)
