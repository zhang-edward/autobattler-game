class_name SidebarMenuOption
extends PanelContainer

@onready var option_label: Label = %OptionLabel
@export var option_text: String = ""

func _ready() -> void:
	option_label.text = option_text
