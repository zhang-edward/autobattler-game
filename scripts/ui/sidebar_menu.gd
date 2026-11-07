class_name SidebarMenu
extends PanelContainer

@onready var request_inbox_option: SidebarMenuOption = %RequestInboxOption
@onready var roster_option: SidebarMenuOption = %RosterOption
@onready var advance_button: Button = %AdvanceDay
@onready var day_label: Label = %Day
@onready var money_label: Label = %Money
@onready var renown_label: Label = %Renown

var selected_option: SidebarMenuOption

signal on_advance_day

func _ready() -> void:
	request_inbox_option.clicked.connect(go_to_request_inbox)
	roster_option.clicked.connect(go_to_roster)
	day_label.text = "Day " + str(GameVariables.curr_day)
	advance_button.pressed.connect(advance_day)
	money_label.text = "$" + str(GameVariables.money)
	renown_label.text = str(GameVariables.renown)
	
func advance_day():
	GameVariables.advance_day()	
	day_label.text = "Day " + str(GameVariables.curr_day)
	on_advance_day.emit()
	
func go_to_request_inbox():
	get_tree().change_scene_to_file("res://scenes/dispatch.tscn")

func go_to_roster():
	get_tree().change_scene_to_file("res://scenes/roster.tscn")

func select_option(option: SidebarMenuOption):
	if selected_option != null:
		selected_option.dehighlight()
	selected_option = option
	selected_option.highlight()
