class_name StatContainer
extends VBoxContainer

@onready var stat_name_label: Label = $StatName as Label
@onready var value_label: Label = $Value as Label

func set_stat_value(stat_name: String, value: int):
	stat_name_label.text = stat_name
	value_label.text = str(value)
