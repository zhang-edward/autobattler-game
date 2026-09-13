class_name TacticalEntityStatus
extends PanelContainer

@onready var texture_rect: TextureRect = $HBoxContainer/TextureRect
@onready var hero_name_label: Label = $HBoxContainer/VBoxContainer/HeroNameLabel
@onready var health_bar: ProgressBar = $HBoxContainer/VBoxContainer/ProgressBar

var entity_config: EntityConfig

func configure_entity_config(ec: EntityConfig):
	entity_config = ec
	hero_name_label.text = entity_config.entity_name
	health_bar.max_value = entity_config.max_health
	health_bar.value = health_bar.max_value

func select():
	var stylebox = get_theme_stylebox("panel") as StyleBoxFlat
	stylebox.border_color = Color(1, 1, 0)
	stylebox.set_border_width_all(3)
	
func deselect():
	var stylebox = get_theme_stylebox("panel") as StyleBoxFlat
	stylebox.set_border_width_all(0)
