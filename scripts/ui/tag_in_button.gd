class_name TagInButton
extends PanelContainer

## Tags a benched hero in. Shows the hero's name and the tag assist they'll
## bring with them (icon and name), so the player knows what tagging them
## in will do.

const ASSIST_ICON_SIZE := Vector2(44.0, 44.0)

@onready var button: Button = $Button
@onready var hero_name_label: Label = %HeroName
@onready var _tag_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/Label
@onready var _row: HBoxContainer = $MarginContainer/HBoxContainer
var hero_to_switch_to: SkirmishEntity

signal on_click(hero: SkirmishEntity)

func _ready() -> void:
	button.pressed.connect(click)

func click():
	on_click.emit(hero_to_switch_to)

func init(entity: SkirmishEntity):
	hero_to_switch_to = entity
	hero_name_label.text = entity.entity_config.entity_name
	var assist := entity.entity_config.assist
	_tag_label.text = "Tag In · %s" % Hero.assist_name(assist)
	_add_assist_icon(assist)


# The assist's icon, at the end of the row (same icons as the boosts in a fight).
func _add_assist_icon(assist: Hero.Assist) -> void:
	var holder := Control.new()
	holder.custom_minimum_size = ASSIST_ICON_SIZE
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := BoostIcon.new()
	icon.boost_name = BoostIcon.ASSIST_ICONS[assist]
	icon.position = ASSIST_ICON_SIZE * 0.5
	holder.add_child(icon)
	_row.add_child(holder)
