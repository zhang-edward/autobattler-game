class_name ChooseHeroModal
extends PanelContainer

@onready var hero_list_container: VBoxContainer = %HeroListContainer
@onready var dispatch_button: Button = %Dispatch
@onready var back_button: Button = %Back
@export var hero_preview_row: PackedScene

var selected_hero: HeroPreviewRow

signal on_confirm_hero_to_add(c: EntityConfig)

func _ready() -> void:
	back_button.pressed.connect(close_modal)
	dispatch_button.pressed.connect(confirm_hero_to_add)

func close_modal():
	hide()
	
func confirm_hero_to_add():
	if selected_hero != null:
		on_confirm_hero_to_add.emit(selected_hero.entity_config)
	close_modal()

func display_available_heroes(selected_heroes: Array[EntityConfig]):
	var hero_configs = GameVariables.player_lineup.filter(func (c): return !selected_heroes.has(c))
	# Clear out old hero list and update based on latest selected hero lineup
	for child in hero_list_container.get_children():
		child.queue_free()
	for c in hero_configs:
		var config = c as EntityConfig
		var preview_row = hero_preview_row.instantiate() as HeroPreviewRow
		hero_list_container.add_child(preview_row)
		preview_row.configure(config)
		preview_row.on_clicked.connect(select_hero_to_add)

func select_hero_to_add(row: HeroPreviewRow):
	if selected_hero != null:
		selected_hero.deselect()
	selected_hero = row
	selected_hero.select()
