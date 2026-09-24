class_name PostEncounterCaptureRescueTable
extends PanelContainer

@export var captured_rescued_entity_row_scene: PackedScene
@onready var table_container: VBoxContainer = %TableContainer
@onready var cost_column: Label = %Cost
@onready var header_label: Label = %HeaderLabel

func show_captured_rescued_entity_rows(configs: Array[EntityConfig]):
	for child in table_container.get_children():
		if child is CapturedRescuedEntityRow:
			child.queue_free()
	for c in configs:
		var entity_config = c as EntityConfig
		var cr_entity_row = captured_rescued_entity_row_scene.instantiate() as CapturedRescuedEntityRow
		table_container.add_child(cr_entity_row)
		cr_entity_row.configure_from_entity_config(entity_config)
		cr_entity_row.cost.hide()

func show_captured_rescued_entity_rows_prospects(prospects: Array[Prospect]):
	for child in table_container.get_children():
		if child is CapturedRescuedEntityRow:
			child.queue_free()
	for c in prospects:
		var prospect = c as Prospect
		var cr_entity_row = captured_rescued_entity_row_scene.instantiate() as CapturedRescuedEntityRow
		table_container.add_child(cr_entity_row)
		cr_entity_row.configure_from_prospect(prospect)
