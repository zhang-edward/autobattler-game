class_name SkirmishStatusRow
extends PanelContainer

const HERO_FILL := preload("res://prefabs/styles/hero_health_bar.tres")
const VILLAIN_FILL := preload("res://prefabs/styles/villain_health_bar.tres")
const ABILITY_COOLDOWN_ROW := preload("res://prefabs/ui/skirmish/ability_cooldown_row.tscn")

const ACTIVE_BORDER := Color(1, 1, 0)

@onready var _name_label: Label = $VBox/HBox/NameLabel
@onready var _bar: ProgressBar = $VBox/HBox/HealthBar
@onready var _wounds_bar: ProgressBar = $VBox/HBox/HealthBar/WoundsBar
@onready var retreat_button: Button = $VBox/HBox/RetreatButton
@onready var _abilities: VBoxContainer = $VBox/Abilities

var entity: SkirmishEntity

signal retreat_pressed(e: SkirmishEntity)

func _ready() -> void:
	retreat_button.pressed.connect(func(): retreat_pressed.emit(entity))

func configure(e: SkirmishEntity) -> void:
	entity = e
	_name_label.text = e.entity_config.entity_name
	_bar.max_value = e.entity_config.get_max_health()
	_bar.value = e.entity_config.curr_health
	_wounds_bar.max_value = e.entity_config.get_max_health()
	var fill := HERO_FILL if e.entity_type == EntityConfig.EntityType.HERO else VILLAIN_FILL
	_bar.add_theme_stylebox_override("fill", fill)
	for ability in e.entity_config.abilities:
		var ability_cooldown_row := ABILITY_COOLDOWN_ROW.instantiate() as AbilityCooldownRow
		_abilities.add_child(ability_cooldown_row)
		ability_cooldown_row.configure(e, ability)
	refresh()

func refresh() -> void:
	if entity == null or not is_instance_valid(entity) or entity.entity_config == null:
		_bar.value = 0
		_wounds_bar.visible = false
		return
	_bar.value = entity.entity_config.curr_health
	_wounds_bar.value = entity.entity_config.curr_wounds
	_wounds_bar.visible = entity.entity_config.curr_health <= 0
	for ability_cooldown_row in _abilities.get_children():
		(ability_cooldown_row as AbilityCooldownRow).refresh()

func set_active_highlight(active: bool) -> void:
	var stylebox := get_theme_stylebox("panel") as StyleBoxFlat
	if active:
		stylebox.border_color = ACTIVE_BORDER
		stylebox.set_border_width_all(2)
	else:
		stylebox.set_border_width_all(0)
