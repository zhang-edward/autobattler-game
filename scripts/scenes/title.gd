class_name Title
extends Node2D

@onready var new_game_button: Button = %NewGame

func _ready() -> void:
	new_game_button.pressed.connect(start_new_game)

func start_new_game():
	# TODO(M3/M7): route to the New Game flow once the league screens exist.
	# Until then this drops into a standalone debug fight.
	get_tree().change_scene_to_file("res://scenes/skirmish.tscn")
