class_name Title
extends Node2D

@onready var new_game_button: Button = %NewGame

func _ready() -> void:
	new_game_button.pressed.connect(start_new_game)

func start_new_game():
	GameVariables.new_game()
	get_tree().change_scene_to_file("res://scenes/dispatch.tscn")
