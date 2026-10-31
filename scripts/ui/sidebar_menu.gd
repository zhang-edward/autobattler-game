class_name SidebarMenu
extends PanelContainer

@onready var request_inbox_option: SidebarMenuOption = %RequestInboxOption
@onready var roster_option: SidebarMenuOption = %RosterOption

var selected_option: SidebarMenuOption

func _ready() -> void:
	request_inbox_option.clicked.connect(go_to_request_inbox)
	roster_option.clicked.connect(go_to_roster)
	
func go_to_request_inbox():
	get_tree().change_scene_to_file("res://scenes/dispatch.tscn")

func go_to_roster():
	get_tree().change_scene_to_file("res://scenes/roster.tscn")

func select_option(option: SidebarMenuOption):
	if selected_option != null:
		selected_option.dehighlight()
	selected_option = option
	selected_option.highlight()
