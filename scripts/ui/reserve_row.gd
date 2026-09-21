class_name ReserveRow
extends PanelContainer

var is_recruitable: bool = false
var entity_config: EntityConfig

@onready var hero_name_label: Label = %HeroName
@onready var level_label: Label = %Level
@onready var hp_label: Label = %HP
@onready var attack_label: Label = %Attack
@onready var defense_label: Label = %Defense
@onready var ground_speed_label: Label = %GroundSpeed
@onready var air_speed_label: Label = %AirSpeed
@onready var exp_label: Label = %Exp
@onready var action_button: Button = %ActionButton
@onready var wrapper_button: Button = $WrapperButton

signal on_recruit(row: ReserveRow)
signal on_select(row: ReserveRow)

func _ready() -> void:
	var recruit = func _recruit():
		on_recruit.emit(self)
	var select = func _select():
		on_select.emit(self)
	action_button.pressed.connect(recruit)
	wrapper_button.pressed.connect(select)

func setup(ec: EntityConfig):
	entity_config = ec
	hero_name_label.text = ec.entity_name
	level_label.text = str(ec.level)
	hp_label.text = str(ec.max_health)
	attack_label.text = str(ec.attack)
	defense_label.text = str(ec.defense)
	ground_speed_label.text = str(ec.ground_speed)
	air_speed_label.text = str(ec.air_speed)
	exp_label.text = str(ec.exp)
	action_button.visible = is_recruitable
	if action_button.visible:
		action_button.text = "Recruit ($" + str(ec.recruit_cost) + ")"

func highlight():
	add_theme_stylebox_override("panel", load("res://prefabs/styles/default_ui_panel_stylebox_hl.tres"))
	
func dehighlight():
	add_theme_stylebox_override("panel", load("res://prefabs/styles/default_ui_panel_stylebox.tres"))
