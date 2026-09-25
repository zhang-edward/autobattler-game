class_name GenericEntityStatRow
extends HBoxContainer

@onready var hero_name_label: Label = $VBoxContainer/HeroName
@onready var level_label: Label = $Level
@onready var hp_label: Label = $HP
@onready var attack_label: Label = $Attack
@onready var defense_label: Label = $Defense
@onready var ground_speed_label: Label = $GroundSpeed
@onready var air_speed_label: Label = $AirSpeed
@onready var cost: Label = $Cost

func configure_from_entity_config(ec: EntityConfig):
	hero_name_label.text = ec.entity_name
	level_label.text = str(ec.level)
	hp_label.text = str(ec.max_health)
	attack_label.text = str(ec.attack)
	defense_label.text = str(ec.defense)
	ground_speed_label.text = str(ec.ground_speed)
	air_speed_label.text = str(ec.air_speed)

func configure_from_prospect(prospect: Prospect):
	configure_from_entity_config(prospect.entity_config)
	cost.text = "$" + str(prospect.cost)
	
