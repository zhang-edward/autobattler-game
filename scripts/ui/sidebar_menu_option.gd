class_name SidebarMenuOption
extends PanelContainer

@onready var option_label: Label = %OptionLabel
@export var option_text: String = ""
@onready var button: Button = %Button

signal clicked()

func _ready() -> void:
	option_label.text = option_text
	button.pressed.connect(click)

func click():
	clicked.emit()

func highlight():
	add_theme_stylebox_override("panel", load("res://prefabs/styles/default_ui_panel_stylebox_yellow.tres"))
	option_label.add_theme_color_override("font_color", Color("131322ff"))
	
func dehighlight():
	add_theme_stylebox_override("panel", load("res://prefabs/styles/default_ui_panel_stylebox_stroke.tres"))
	option_label.add_theme_color_override("font_color", Color("#ffffff"))
