class_name SkirmishRunnerBuildPanel
extends PanelContainer

signal build_changed

const ABILITIES_PATH := "res://abilities/"

@export var entity_type: EntityConfig.EntityType

@onready var _title_label: Label = %TitleLabel
@onready var _strength: SpinBox = %Strength
@onready var _defense: SpinBox = %Defense
@onready var _agility: SpinBox = %Agility
@onready var _evasion: SpinBox = %Evasion
@onready var _resilience: SpinBox = %Resilience
@onready var _strength_info: Label = %StrengthInfo
@onready var _defense_info: Label = %DefenseInfo
@onready var _agility_info: Label = %AgilityInfo
@onready var _evasion_info: Label = %EvasionInfo
@onready var _resilience_info: Label = %ResilienceInfo
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
	_refresh_stat_info()

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
	config.evasion = int(_evasion.value)
	config.resilience = int(_resilience.value)
	config.curr_health = config.get_max_health()
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
	return [_strength, _defense, _agility, _evasion, _resilience]

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

func _refresh_stat_info() -> void:
	var strength := _strength.value
	_strength_info.text = "Launch dealt ×%.2f   ·   Hitstun dealt ×%.2f" % [
		(SkirmishEntity.STRENGTH_LAUNCH_SCALE + strength) / SkirmishEntity.STRENGTH_LAUNCH_SCALE,
		HurtState.hitstun_for(1.0, int(strength)),
	]

	var agility := _agility.value
	var agility_time := (AbilityState.AGILITY_SCALE + AbilityState.AGILITY_BASELINE) / (AbilityState.AGILITY_SCALE + agility)
	_agility_info.text = "Move time ×%.2f   ·   Pushback dealt ×%.2f   ·   Dash speed ×%.2f" % [
		agility_time,
		agility_time,
		1.0 + agility / DashState.AGILITY_DASH_SCALE,
	]

	var defense := _defense.value
	_defense_info.text = "Block %d%%   ·   Blocked hits −%d damage   ·   Launch taken ×%.2f" % [
		roundi(100.0 * (SkirmishEntity.BLOCK_BASE_CHANCE + (1.0 - SkirmishEntity.BLOCK_BASE_CHANCE) * defense / (defense + SkirmishEntity.BLOCK_DEFENSE_SCALE))),
		roundi(defense * SkirmishEntity.BLOCK_REDUCTION_PER_DEFENSE),
		SkirmishEntity.DEFENSE_LAUNCH_SCALE / (SkirmishEntity.DEFENSE_LAUNCH_SCALE + defense),
	]

	var evasion := _evasion.value
	_evasion_info.text = "Dodge %d%%   ·   Pushback taken ×%.2f" % [
		roundi(100.0 * evasion / (evasion + SkirmishEntity.DODGE_EVASION_SCALE)),
		1.0 + evasion / SkirmishEntity.EVASION_PUSHBACK_SCALE,
	]

	var resilience := _resilience.value
	var escape_fraction := RagdollState.RAGDOLL_ESCAPE_HEALTH_FRACTION \
		* RagdollState.RESILIENCE_SCALE / (RagdollState.RESILIENCE_SCALE + resilience)
	var ignore_hitstun_threshold := resilience * SkirmishEntity.IGNORE_HITSTUN_DAMAGE_PER_RESILIENCE
	var ignore_hitstun_percent := func(damage: float) -> int:
		return roundi(100.0 / (1.0 + pow(damage / ignore_hitstun_threshold, SkirmishEntity.IGNORE_HITSTUN_STEEPNESS)))
	_resilience_info.text = "Escape after %d dmg (%d%%)   ·   " % [
		ceili(EntityConfig.BASE_HEALTH * escape_fraction),
		roundi(100.0 * escape_fraction),
	]
	if ignore_hitstun_threshold <= 0.0:
		_resilience_info.text += "Never shrugs off hits"
	else:
		_resilience_info.text += "Shrug off 50%% at %.1f dmg, %d%% at 4, %d%% at 20" % [
			ignore_hitstun_threshold,
			ignore_hitstun_percent.call(4.0),
			ignore_hitstun_percent.call(20.0),
		]

func _on_build_changed() -> void:
	_refresh_points_label()
	_refresh_stat_info()
	build_changed.emit()
