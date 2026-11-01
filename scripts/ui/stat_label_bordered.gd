class_name StatLabelBordered
extends PanelContainer

@onready var label: Label = %Label
@onready var value: Label = %Value

func configure(stat_name: String, stat_value: int):
	label.text = stat_name
	value.text = str(stat_value)
