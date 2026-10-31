class_name SpecialAbilityPreview
extends PanelContainer

@onready var ability_icon: TextureRect = %AbilityIcon
@onready var ability_name: Label = %AbilityName

func set_empty():
	ability_icon.modulate = Color(0, 0, 0, 0)
	ability_name.modulate = Color(0, 0, 0, 0)

func configure_from_ability(ability: Ability):
	ability_name.text = ability.ability_name
