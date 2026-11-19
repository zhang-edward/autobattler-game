class_name SkirmishRunnerBuildPanel
extends PanelContainer

signal build_changed

const ABILITIES_PATH := "res://abilities/"
const DEFENSIVE_ABILITIES_PATH := "res://abilities/defensive/"

@export var entity_type: EntityConfig.EntityType

@onready var _title_label: Label = %TitleLabel
@onready var _moves_by_tier: Dictionary[Ability.Tier, GridContainer] = {
	Ability.Tier.LIGHT: %LightMoves,
	Ability.Tier.MEDIUM: %MediumMoves,
	Ability.Tier.HEAVY: %HeavyMoves,
}
@onready var _defensive_moves: GridContainer = %DefensiveMoves

var _move_toggles: Dictionary[Ability, CheckBox] = {}

func _ready() -> void:
	_title_label.text = _build_name()
	_build_move_toggles()

func has_moves() -> bool:
	return not _selected_abilities().is_empty()

func build_config() -> EntityConfig:
	var config: EntityConfig = EntityGenerator.generate_random_entity_configs(1, entity_type)[0]
	config.entity_name = _build_name()
	config.curr_health = config.get_max_health()
	config.abilities = _selected_abilities()
	return config

func _build_move_toggles() -> void:
	for path in [ABILITIES_PATH, DEFENSIVE_ABILITIES_PATH]:
		for file_name in ResourceLoader.list_directory(path):
			if not file_name.ends_with(".tres"):
				continue
			var ability := load(path + file_name) as Ability
			if ability == null:
				continue
			var toggle := CheckBox.new()
			toggle.text = ability.ability_name
			toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			toggle.toggled.connect(_on_build_changed.unbind(1))
			if ability is DefensiveAbility:
				_defensive_moves.add_child(toggle)
			else:
				_moves_by_tier[(ability as OffensiveAbility).tier].add_child(toggle)
			_move_toggles[ability] = toggle

func _selected_abilities() -> Array[Ability]:
	var abilities: Array[Ability] = []
	for ability in _move_toggles:
		if _move_toggles[ability].button_pressed:
			abilities.append(ability)
	return abilities

func _build_name() -> String:
	return EntityConfig.EntityType.keys()[entity_type].capitalize()

func _on_build_changed() -> void:
	build_changed.emit()
