class_name PostEncounter
extends Node2D

@onready var pe_hero_stat_table: PostEncounterHeroStatTable = $CanvasLayer/VBoxContainer/PEHeroStatTable
@onready var pe_capture_rescue_table: PostEncounterCaptureRescueTable = $CanvasLayer/VBoxContainer/PECaptureRescueTable
@onready var back_button: Button = %BackButton
@onready var next_button: Button = %NextButton

var pe_state_scroll_index := 0

func _ready() -> void:
	pe_hero_stat_table.configure(GameVariables.player_lineup)
	next_button.pressed.connect(increment_scroll_index)
	back_button.pressed.connect(decrement_scroll_index)
	
func increment_scroll_index():
	if pe_state_scroll_index == 3:
		get_tree().change_scene_to_file("res://scenes/management.tscn")
	else:
		pe_state_scroll_index += 1
		render_curr_scroll_index_state()

func decrement_scroll_index():
	pe_state_scroll_index = max(0, pe_state_scroll_index - 1)
	render_curr_scroll_index_state()

func render_curr_scroll_index_state():
	match pe_state_scroll_index:
		0:
			pe_hero_stat_table.show()
			pe_capture_rescue_table.hide()
		1:
			pe_hero_stat_table.hide()
			pe_capture_rescue_table.show()
			pe_capture_rescue_table.header_label.text = "Captured Villains"
			pe_capture_rescue_table.cost_column.show()
			pe_capture_rescue_table.show_captured_rescued_entity_rows_prospects(GameVariables.captured_villain_prospects)
		2:
			pe_hero_stat_table.hide()
			pe_capture_rescue_table.show()
			pe_capture_rescue_table.header_label.text = "Rescued Civilians"
			pe_capture_rescue_table.cost_column.show()
			pe_capture_rescue_table.show_captured_rescued_entity_rows_prospects(GameVariables.civilian_hero_prospects)
		3:
			pe_hero_stat_table.hide()
			pe_capture_rescue_table.show()
			pe_capture_rescue_table.header_label.text = "Heroes Lost"
			pe_capture_rescue_table.cost_column.hide()
			pe_capture_rescue_table.show_captured_rescued_entity_rows(GameVariables.captured_heroes)
