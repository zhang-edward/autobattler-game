class_name SkirmishPreview
extends PanelContainer

@export var skirmish_preview_stat_row_scene: PackedScene
@onready var battle_button: Button = %BattleButton
@onready var hero_container: VBoxContainer = %HeroContainer
@onready var villain_container: VBoxContainer = %VillainContainer

signal on_skirmish_start

func _ready() -> void:
	hide()
	battle_button.pressed.connect(start_skirmish)
	
func start_skirmish():
	on_skirmish_start.emit()

func add_skirmish_preview_stat_rows(container: VBoxContainer, entities: Array[EntityConfig]):
	# Clear out previous rows
	for c in container.get_children():
		c.queue_free()
	for ec in entities:
		var entity_config = ec as EntityConfig
		var skirmish_preview_stat_row = skirmish_preview_stat_row_scene.instantiate() as SkirmishPreviewStatRow
		container.add_child(skirmish_preview_stat_row)
		skirmish_preview_stat_row.configure(entity_config)
