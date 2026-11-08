class_name SkirmishOverrideRow
extends HBoxContainer

@onready var entity_name: Label = %EntityName
@onready var health_slider: HSlider = %HealthSlider
@onready var health_value: Label = %HealthValue

var entity_config: EntityConfig

func _ready() -> void:
	health_slider.value_changed.connect(update_health_value)

func configure(config: EntityConfig, start_health_pct: float):
	entity_config = config
	entity_name.text = config.entity_name
	health_slider.value = start_health_pct
	update_health_value(start_health_pct)

func update_health_value(value: float):
	health_value.text = str(int(value)) + "%"
