class_name RosterHeroDetails
extends PanelContainer

@onready var special_abilities_panel: SpecialAbilitiesPanel = %SpecialAbilitiesPanel
@onready var character_stats_panel: CharacterStatsPanel = %CharacterStatsPanel
@onready var hero_name: Label = %HeroName
@onready var back_button: Button = %BackButton
@onready var health_bar: HealthBar = %HealthBar
@onready var inventory_panel: PanelContainer = %InventoryPanel
@onready var inventory_grid: SpecialAbilityGrid = %InventoryGrid

var entity_config: EntityConfig

func _ready() -> void:
	special_abilities_panel.set_drag_forwarding(Callable(), can_drop_equip, drop_equip)
	character_stats_panel.set_drag_forwarding(Callable(), can_drop_equip, drop_equip)
	inventory_panel.set_drag_forwarding(Callable(), can_drop_unequip, drop_unequip)

func configure(config: EntityConfig):
	entity_config = config
	hero_name.text = entity_config.entity_name
	health_bar.configure(entity_config)
	character_stats_panel.configure(entity_config)
	update_ability_grids()

func update_ability_grids():
	special_abilities_panel.configure(entity_config)
	inventory_grid.configure_from_abilities(GameVariables.ability_inventory)

func can_drop_equip(_at_position: Vector2, data: Variant) -> bool:
	return data is SpecialAbilityPreview and inventory_grid.is_ancestor_of(data)

func drop_equip(_at_position: Vector2, data: Variant):
	var preview := data as SpecialAbilityPreview
	GameVariables.ability_inventory.erase(preview.ability)
	entity_config.abilities.append(preview.ability)
	update_ability_grids()

func can_drop_unequip(_at_position: Vector2, data: Variant) -> bool:
	return data is SpecialAbilityPreview and special_abilities_panel.is_ancestor_of(data)

func drop_unequip(_at_position: Vector2, data: Variant):
	var preview := data as SpecialAbilityPreview
	entity_config.abilities.erase(preview.ability)
	GameVariables.ability_inventory.append(preview.ability)
	update_ability_grids()
