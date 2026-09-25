class_name TopNavBar
extends PanelContainer

@onready var money_label = %Money
@onready var roster_button: Button = %Roster
@onready var encounter_button: Button = %Encounter

func _ready() -> void:
	money_label.text = "Money: $" + str(GameVariables.money)
	roster_button.pressed.connect(go_to_management_scene)
	encounter_button.pressed.connect(go_to_pre_encounter_scene)
	
func go_to_management_scene():
	print("Go to management scene")
	get_tree().change_scene_to_file("res://scenes/management.tscn")

func go_to_pre_encounter_scene():
	get_tree().change_scene_to_file("res://scenes/pre_encounter.tscn")
