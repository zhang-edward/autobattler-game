class_name StatLabel
extends PanelContainer

@onready var stat_name_label: Label = %StatName
@onready var stat_value_label: Label = %StatValue

func configure(stat_name: String, stat_value: int):
	stat_name_label.text = stat_name
	stat_value_label.text = str(stat_value)
