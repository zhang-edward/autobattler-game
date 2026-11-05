class_name LevelUpStatRow
extends PanelContainer

@onready var stat_label: Label = %Stat
@onready var value_label: Label = %Value
@onready var button: Button = %Button

signal on_increase(stat_key: String)

func configure(stat_name: String, stat_value: int):
	stat_label.text = stat_name
	value_label.text = str(stat_value)
	button.pressed.connect(increase_stat)
	
func increase_stat():
	on_increase.emit(stat_label.text.to_lower())
	value_label.text = str(int(value_label.text) + 1)
