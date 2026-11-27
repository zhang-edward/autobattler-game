class_name SkirmishRunnerBuildPanel
extends PanelContainer

## One team's build in SkirmishRunner: the five stats and the moves. Every
## hero on the team gets this build.

signal build_changed

@export var title := "Team A"

@onready var _title_label: Label = %TitleLabel
@onready var _strength: SpinBox = %Strength
@onready var _skill: SpinBox = %Skill
@onready var _agility: SpinBox = %Agility
@onready var _vitality: SpinBox = %Vitality
@onready var _defense: SpinBox = %Defense
@onready var _strength_info: Label = %StrengthInfo
@onready var _skill_info: Label = %SkillInfo
@onready var _agility_info: Label = %AgilityInfo
@onready var _vitality_info: Label = %VitalityInfo
@onready var _defense_info: Label = %DefenseInfo
@onready var _points_label: Label = %PointsLabel
@onready var _moves_by_tier: Dictionary[Ability.Tier, GridContainer] = {
	Ability.Tier.LIGHT: %LightMoves,
	Ability.Tier.MEDIUM: %MediumMoves,
	Ability.Tier.HEAVY: %HeavyMoves,
}

var _move_toggles: Dictionary[Ability, CheckBox] = {}
var _power_type: OptionButton
var _assist: OptionButton


func _ready() -> void:
	_title_label.text = title
	for stat in _stats():
		stat.value_changed.connect(_on_build_changed.unbind(1))
	_build_kit_pickers()
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


## A hero with this build. Name, looks and power type are random.
func build_hero(rng: RandomNumberGenerator) -> Hero:
	var hero := LeagueGenerator.generate_hero(rng)
	hero.hero_name = title
	hero.stats[Hero.Stat.STRENGTH] = int(_strength.value)
	hero.stats[Hero.Stat.SKILL] = int(_skill.value)
	hero.stats[Hero.Stat.AGILITY] = int(_agility.value)
	hero.stats[Hero.Stat.VITALITY] = int(_vitality.value)
	hero.stats[Hero.Stat.DEFENSE] = int(_defense.value)
	hero.moves = _selected_abilities()
	hero.power_type = _power_type.get_selected_id() as Hero.PowerType
	hero.assist = _assist.get_selected_id() as Hero.Assist
	return hero


## Power type (which sets the super) and tag assist pickers, under the points.
func _build_kit_pickers() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_power_type = OptionButton.new()
	for type in Hero.PowerType.values():
		_power_type.add_item("%s — Super: %s" % [Hero.power_type_name(type), Hero.SUPER_NAMES[type]], type)
	_assist = OptionButton.new()
	for assist in Hero.Assist.values():
		_assist.add_item("Assist: %s" % Hero.assist_name(assist), assist)
	row.add_child(_power_type)
	row.add_child(_assist)
	_points_label.add_sibling(row)


func _build_move_toggles() -> void:
	for ability in LeagueGenerator.all_abilities():
		var toggle := CheckBox.new()
		toggle.text = ability.ability_name
		toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toggle.toggled.connect(_on_build_changed.unbind(1))
		_moves_by_tier[ability.tier].add_child(toggle)
		_move_toggles[ability] = toggle


func _stats() -> Array[SpinBox]:
	return [_strength, _skill, _agility, _vitality, _defense]


func _selected_abilities() -> Array[Ability]:
	var abilities: Array[Ability] = []
	for ability in _move_toggles:
		if _move_toggles[ability].button_pressed:
			abilities.append(ability)
	return abilities


func _refresh_points_label() -> void:
	_points_label.text = "Points: %d" % points()


## What each stat does in combat, from CombatStats.
func _refresh_stat_info() -> void:
	var strength := _strength.value
	_strength_info.text = "Strike damage ×%.2f   ·   Launch ×%.2f" % [
		CombatStats.strength_damage_multiplier(strength),
		CombatStats.launch_multiplier(strength),
	]

	_skill_info.text = "Projectile and super damage ×%.2f" % CombatStats.skill_damage_multiplier(_skill.value)

	var agility := _agility.value
	_agility_info.text = "Attack time ×%.2f   ·   Block chance %d%%" % [
		CombatStats.action_time_scale(agility),
		roundi(100.0 * CombatStats.block_chance(agility)),
	]

	_vitality_info.text = "Health %d" % CombatStats.max_health(_vitality.value)

	# Every hero on a runner team has this build, so it's also the team average.
	var defense := _defense.value
	_defense_info.text = "Team block bar %d   ·   Blocked hit drain ×%.2f" % [
		roundi(CombatStats.block_bar_size(defense)),
		CombatStats.block_drain(1.0, defense),
	]


func _on_build_changed() -> void:
	_refresh_points_label()
	_refresh_stat_info()
	build_changed.emit()
