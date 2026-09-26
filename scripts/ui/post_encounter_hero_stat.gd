class_name PostEncounterHeroStat
extends HBoxContainer

@onready var hero_name_label: Label = $HeroName
@onready var villains_defeated_label: Label = $VillainsDefeated
@onready var assists_label: Label = $Assists
@onready var damage_dealt_label: Label = $DamageDealt
@onready var civilians_saved_label: Label = $CiviliansSaved
@onready var exp_bar: ProgressBar = $ExpBar

func configure(config: EntityConfig):
	hero_name_label.text = config.entity_name
	villains_defeated_label.text = str(config.defeated_villain_names.size())
	assists_label.text = str(config.num_assists)
	damage_dealt_label.text = str(config.damage_dealt)
	civilians_saved_label.text = str(config.num_civs_saved)
	exp_bar.value = config.exp
