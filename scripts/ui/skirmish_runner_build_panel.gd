class_name SkirmishRunnerBuildPanel
extends PanelContainer

signal build_changed

const ABILITIES_PATH := "res://abilities/"

@export var entity_type: EntityConfig.EntityType

@onready var _title_label: Label = %TitleLabel
@onready var _strength: SpinBox = %Strength
@onready var _defense: SpinBox = %Defense
@onready var _agility: SpinBox = %Agility
@onready var _vitality: SpinBox = %Vitality
@onready var _points_label: Label = %PointsLabel
@onready var _moves_by_tier: Dictionary[Ability.Tier, GridContainer] = {
	Ability.Tier.LIGHT: %LightMoves,
	Ability.Tier.MEDIUM: %MediumMoves,
	Ability.Tier.HEAVY: %HeavyMoves,
}

var _move_toggles: Dictionary[Ability, CheckBox] = {}

func _ready() -> void:
	_title_label.text = _build_name()
	for stat in _stats():
		stat.value_changed.connect(_on_build_changed.unbind(1))
	_build_move_toggles()
	_refresh_points_label()

func points() -> int:
	var total := 0
	for stat in _stats():
		total += roundi(stat.value / stat.step)
	return total

func has_moves() -> bool:
	return not _selected_abilities().is_empty()

func build_config() -> EntityConfig:
	var config: EntityConfig = EntityGenerator.generate_random_entity_configs(1, entity_type)[0]
	config.entity_name = _build_name()
	config.strength = int(_strength.value)
	config.defense = int(_defense.value)
	config.agility = int(_agility.value)
	config.vitality = int(_vitality.value)
	config.abilities = _selected_abilities()
	return config

func _build_move_toggles() -> void:
	for file_name in ResourceLoader.list_directory(ABILITIES_PATH):
		if not file_name.ends_with(".tres"):
			continue
		var ability := load(ABILITIES_PATH + file_name) as Ability
		if ability == null:
			continue
		var toggle := CheckBox.new()
		toggle.text = ability.ability_name
		toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toggle.toggled.connect(_on_build_changed.unbind(1))
		_moves_by_tier[ability.tier].add_child(toggle)
		_move_toggles[ability] = toggle

func _stats() -> Array[SpinBox]:
	return [_strength, _defense, _agility, _vitality]

func _selected_abilities() -> Array[Ability]:
	var abilities: Array[Ability] = []
	for ability in _move_toggles:
		if _move_toggles[ability].button_pressed:
			abilities.append(ability)
	return abilities

func _build_name() -> String:
	return EntityConfig.EntityType.keys()[entity_type].capitalize()

func _refresh_points_label() -> void:
	_points_label.text = "Points: %d" % points()

func _on_build_changed() -> void:
	_refresh_points_label()
	build_changed.emit()
