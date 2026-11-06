class_name LevelUpStatRow
extends PanelContainer

@onready var stat_label: Label = %Stat
@onready var value_label: Label = %Value
@onready var increase_button: Button = %Increase
@onready var decrease_button: Button = %Decrease
@onready var confirm_button: Button = %Confirm

signal on_increase(stat_key: String)
signal on_decrease(stat_key: String)

var original_value: int
var level_up_scene_ref: LevelUp

func _ready() -> void:
	decrease_button.hide()

func configure(level_up: LevelUp, stat_name: String, stat_value: int):
	level_up_scene_ref = level_up
	original_value = stat_value
	stat_label.text = stat_name
	value_label.text = str(stat_value)
	increase_button.pressed.connect(increase_stat)
	decrease_button.pressed.connect(decrease_stat)
	
func increase_stat():
	if level_up_scene_ref.stat_points_to_distribute > 0:
		on_increase.emit(stat_label.text.to_lower())
		var new_value = int(value_label.text) + 1
		value_label.text = str(new_value)
		decrease_button.show()
	
func decrease_stat():
	on_decrease.emit(stat_label.text.to_lower())
	var new_value = int(value_label.text) - 1
	value_label.text = str(new_value)
	if new_value == original_value:
		decrease_button.hide()
