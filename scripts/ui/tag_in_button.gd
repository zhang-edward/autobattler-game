class_name TagInButton
extends PanelContainer

@onready var button: Button = $Button
@onready var hero_name_label: Label = %HeroName
var hero_to_switch_to: SkirmishEntity

signal on_click(hero: SkirmishEntity)

func _ready() -> void:
	button.pressed.connect(click)
	
func click():
	print("Clicked!")
	on_click.emit(hero_to_switch_to)

func init(entity: SkirmishEntity):
	hero_to_switch_to = entity
	hero_name_label.text = entity.entity_config.entity_name
