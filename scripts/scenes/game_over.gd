class_name GameOver
extends Node2D

@onready var day_label: Label = %DayLabel
@onready var back_to_title_button: Button = %BackToTitle

func _ready() -> void:
	day_label.text = "Reputation fell below 0 on day " + str(GameVariables.curr_day) + "."
	back_to_title_button.pressed.connect(go_to_title_scene)

func go_to_title_scene():
	get_tree().change_scene_to_file("res://scenes/title.tscn")
