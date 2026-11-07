class_name AbilityTypeLabel
extends PanelContainer

@onready var label: Label = %Label

func configure_from_ability(a: Ability):
	if a.category == Ability.Category.OFFENSIVE:
		label.text = "Offensive"
	elif a.category == Ability.Category.DEFENSIVE:
		label.text = "Defensive"
