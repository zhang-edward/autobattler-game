class_name SpecialAbilityGrid
extends VBoxContainer

@export var special_ability_preview_scene: PackedScene
@onready var heading_label: Label = %Heading
@onready var ability_grid: GridContainer = %AbilityGrid

func configure_from_abilities(abilities: Array[Ability]):
	for c in ability_grid.get_children():
		c.queue_free()
	for a in abilities:
		var sap = special_ability_preview_scene.instantiate() as SpecialAbilityPreview
		ability_grid.add_child(sap)
		sap.configure_from_ability(a)
