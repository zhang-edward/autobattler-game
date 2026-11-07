class_name LevelUpNewAbility
extends PanelContainer

@onready var ability_name: Label = %AbilityName
@onready var ability_description: Label = %AbilityDescription
@onready var ability_type_label: AbilityTypeLabel = %AbilityTypeLabel
@onready var button: Button = %Button

signal on_select(a: LevelUpNewAbility)
var ability: Ability

func _ready() -> void:
	button.pressed.connect(select_ability)

func select_ability():
	on_select.emit(self)

func configure(a: Ability):
	ability = a
	ability_name.text = a.ability_name
	ability_type_label.configure_from_ability(a)

func highlight():
	add_theme_stylebox_override("panel", load("res://prefabs/styles/default_ui_panel_stylebox_light.tres"))
	
func dehighlight():
	add_theme_stylebox_override("panel", load("res://prefabs/styles/default_ui_panel_stylebox.tres"))
