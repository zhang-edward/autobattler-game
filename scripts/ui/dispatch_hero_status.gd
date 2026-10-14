class_name DispatchHeroStatus
extends PanelContainer

@onready var hero_name_label: Label = %HeroNameLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var portrait: Portrait = %Portrait

func init_from_entity_config(ec: EntityConfig):
	hero_name_label.text = ec.entity_name
	health_bar.max_value = ec.max_health
	health_bar.value = ec.curr_health
	portrait.render_portrait(ec.portrait_config)
