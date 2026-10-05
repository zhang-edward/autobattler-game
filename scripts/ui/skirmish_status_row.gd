class_name SkirmishStatusRow
extends PanelContainer

const HERO_FILL := preload("res://prefabs/styles/hero_health_bar.tres")
const VILLAIN_FILL := preload("res://prefabs/styles/villain_health_bar.tres")

const ACTIVE_BORDER := Color(1, 1, 0)

@onready var _name_label: Label = $HBox/NameLabel
@onready var _bar: ProgressBar = $HBox/HealthBar

var entity: SkirmishEntity

func configure(e: SkirmishEntity) -> void:
	entity = e
	_name_label.text = e.entity_config.entity_name
	_bar.max_value = e.entity_config.max_health
	_bar.value = e.entity_config.curr_health
	var fill := HERO_FILL if e.entity_type == EntityConfig.EntityType.HERO else VILLAIN_FILL
	_bar.add_theme_stylebox_override("fill", fill)
	refresh()

func refresh() -> void:
	if entity == null or not is_instance_valid(entity) or entity.entity_config == null:
		_bar.value = 0
		return
	_bar.value = entity.entity_config.curr_health

func set_active_highlight(active: bool) -> void:
	var stylebox := get_theme_stylebox("panel") as StyleBoxFlat
	if active:
		stylebox.border_color = ACTIVE_BORDER
		stylebox.set_border_width_all(2)
	else:
		stylebox.set_border_width_all(0)
