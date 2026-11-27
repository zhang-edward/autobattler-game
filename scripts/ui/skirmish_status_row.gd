class_name SkirmishStatusRow
extends PanelContainer

## One hero's line in the fight HUD: their name, outlined while they're on
## the field. Health is shared per team, so it's shown once per team instead.

const ACTIVE_BORDER := Color(1, 1, 0)

@onready var _name_label: Label = $HBox/NameLabel

var entity: SkirmishEntity

func configure(e: SkirmishEntity) -> void:
	entity = e
	_name_label.text = e.entity_config.entity_name

func set_active_highlight(active: bool) -> void:
	var stylebox := get_theme_stylebox("panel") as StyleBoxFlat
	if active:
		stylebox.border_color = ACTIVE_BORDER
		stylebox.set_border_width_all(2)
	else:
		stylebox.set_border_width_all(0)
