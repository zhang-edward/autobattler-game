class_name SpecialAbilityPreview
extends PanelContainer

@onready var ability_icon: TextureRect = %AbilityIcon
@onready var ability_name: Label = %AbilityName

var draggable := false
var ability: Ability

func set_empty():
	ability_icon.modulate = Color(0, 0, 0, 0)
	ability_name.modulate = Color(0, 0, 0, 0)

func configure_from_ability(a: Ability):
	ability = a
	ability_name.text = a.ability_name

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not draggable:
		return null
	var drag_preview := duplicate() as Control
	# Add parent control and offset the preview scene to make the preview positioned at the center of the mouse
	var drag_root := Control.new()
	drag_root.add_child(drag_preview)
	drag_preview.size = size
	drag_preview.position = - size / 2
	drag_root.modulate.a = 1
	set_drag_preview(drag_root)
	return self
