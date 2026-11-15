class_name HealthBar
extends ProgressBar

const HERO_FILL := preload("res://prefabs/styles/hero_health_bar.tres")
const VILLAIN_FILL := preload("res://prefabs/styles/villain_health_bar.tres")

@onready var health_label: Label = %HealthLabel

func configure(config: EntityConfig):
	max_value = config.get_max_health()
	value = config.curr_health
	var fill := HERO_FILL if config.entity_type == EntityConfig.EntityType.HERO else VILLAIN_FILL
	add_theme_stylebox_override("fill", fill)
	health_label.text = str(config.curr_health) + " / " + str(config.get_max_health())
