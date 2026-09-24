class_name PostEncounterHeroStatTable
extends PanelContainer

@export var post_encounter_hero_stat_scene: PackedScene
@onready var table_container: VBoxContainer = %TableContainer

func configure(lineup: Array[EntityConfig]):
	for ec in lineup:
		var entity_config = ec as EntityConfig
		var pe_hero_stat = post_encounter_hero_stat_scene.instantiate()
		table_container.add_child(pe_hero_stat)
		pe_hero_stat.configure(entity_config)
