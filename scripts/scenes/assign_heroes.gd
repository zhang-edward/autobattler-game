class_name AssignHeroes
extends Node2D

@onready var back_button: Button = %Back
@onready var dispatch_button: Button = %Dispatch
@onready var add_hero_slot_1_button: Button =  %HeroSlot1Button
@onready var add_hero_slot_2_button: Button = %HeroSlot2Button
@onready var add_hero_slot_3_button: Button = %HeroSlot3Button
@onready var choose_hero_modal: ChooseHeroModal = %ChooseHeroModal
@onready var hero_slots: VBoxContainer = %HeroSlots
@onready var add_hero_buttons: VBoxContainer = %AddHeroButtons
@onready var enemy_preview_container: VBoxContainer = %EnemyPreviewContainer

@export var hero_preview_row_scene: PackedScene
@export var enemy_preview_scene: PackedScene

var selected_heroes: Array[EntityConfig] = []

func _ready() -> void:
	back_button.pressed.connect(go_to_dispatch_scene)
	dispatch_button.pressed.connect(go_to_skirmish_scene)
	add_hero_slot_1_button.pressed.connect(open_choose_hero_modal)
	add_hero_slot_2_button.pressed.connect(open_choose_hero_modal)
	add_hero_slot_3_button.pressed.connect(open_choose_hero_modal)
	choose_hero_modal.on_confirm_hero_to_add.connect(add_hero_to_selected)
	setup_enemy_preview(GameVariables.selected_threat_request_config)
	
func setup_enemy_preview(threat_req_config: ThreatRequestConfig):
	for c in enemy_preview_container.get_children():
		c.queue_free()
	for c in threat_req_config.enemy_configs:
		var enemy_preview = enemy_preview_scene.instantiate() as EnemyPreview
		enemy_preview_container.add_child(enemy_preview)
		enemy_preview.configure(c)

func go_to_dispatch_scene():
	get_tree().change_scene_to_file("res://scenes/dispatch.tscn")
	
func go_to_skirmish_scene():
	get_tree().change_scene_to_file("res://scenes/skirmish.tscn")

func open_choose_hero_modal():
	choose_hero_modal.show()
	choose_hero_modal.display_available_heroes(selected_heroes)

func add_hero_to_selected(config: EntityConfig):
	selected_heroes.append(config)
	update_heroes_in_slots()

func update_heroes_in_slots():
	for c in hero_slots.get_children():
		c.queue_free()
	for sh in selected_heroes:
		var preview_row = hero_preview_row_scene.instantiate() as HeroPreviewRow
		hero_slots.add_child(preview_row)
		preview_row.configure(sh)
		preview_row.enable_remove_overlay = true
		preview_row.on_clicked.connect(remove_from_selected)
	var num_hero_slots_to_show = 3 - selected_heroes.size()
	var add_hero_slot_buttons = add_hero_buttons.get_children()
	for i in range(0, add_hero_slot_buttons.size()):
		if i < num_hero_slots_to_show:
			add_hero_slot_buttons[i].show()
		else:
			add_hero_slot_buttons[i].hide()

func remove_from_selected(row: HeroPreviewRow):
	var config = row.entity_config
	selected_heroes = selected_heroes.filter(func (c): return c != config)
	update_heroes_in_slots()
