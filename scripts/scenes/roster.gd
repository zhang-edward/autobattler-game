class_name Roster
extends Node2D

@onready var sidebar_menu: SidebarMenu = %SidebarMenu

func _ready() -> void:
	sidebar_menu.select_option(sidebar_menu.roster_option)
