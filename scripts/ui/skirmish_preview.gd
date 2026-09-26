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

func show_skirmish_preview(hero_entities: Array[TacticalEntity], villain_entities: Array[TacticalEntity]):
	show()
	var hero_entity_configs: Array[EntityConfig] = []
	var villain_entity_configs: Array[EntityConfig] = []
	for he in hero_entities:
		hero_entity_configs.append(he.entity_config)
	for ve in villain_entities:
		villain_entity_configs.append(ve.entity_config)
	add_skirmish_preview_stat_rows(hero_container, hero_entity_configs as Array[EntityConfig])
	add_skirmish_preview_stat_rows(villain_container, villain_entity_configs as Array[EntityConfig])

func add_skirmish_preview_stat_rows(container: VBoxContainer, entities: Array[EntityConfig]):
	# Clear out previous rows
	for c in container.get_children():
		c.queue_free()
	for ec in entities:
		var entity_config = ec as EntityConfig
		var skirmish_preview_stat_row = skirmish_preview_stat_row_scene.instantiate() as SkirmishPreviewStatRow
		container.add_child(skirmish_preview_stat_row)
		skirmish_preview_stat_row.configure(entity_config)
