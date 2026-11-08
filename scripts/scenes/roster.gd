class_name Roster
extends Node2D

@onready var sidebar_menu: SidebarMenu = %SidebarMenu
@onready var grid_container: GridContainer = %GridContainer
@onready var hero_list_panel: PanelContainer = %HeroList
@onready var hero_details_panel: RosterHeroDetails = %HeroDetails

@export var roster_hero_preview_scene: PackedScene

var selected_entity: EntityConfig

func _ready() -> void:
	sidebar_menu.select_option(sidebar_menu.roster_option)
	sidebar_menu.roster_option.button.pressed.connect(hide_hero_details)
	sidebar_menu.on_advance_day.connect(update_hero_previews)
	update_hero_previews()
	hero_details_panel.back_button.pressed.connect(hide_hero_details)
	hero_list_panel.show()
	hero_details_panel.hide()

func update_hero_previews():
	for c in grid_container.get_children():
		c.queue_free()
	for c in GameVariables.player_lineup:
		var hero_preview = roster_hero_preview_scene.instantiate() as RosterHeroPreview
		grid_container.add_child(hero_preview)
		hero_preview.configure(c)
		hero_preview.on_clicked.connect(select_entity)

func select_entity(hero_preview: RosterHeroPreview):
	selected_entity = hero_preview.entity_config
	show_hero_details()
	
func hide_hero_details():
	hero_details_panel.hide()
	hero_list_panel.show()
	
func show_hero_details():
	hero_list_panel.hide()
	hero_details_panel.show()
	hero_details_panel.configure(selected_entity)
