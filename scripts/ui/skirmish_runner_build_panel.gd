class_name SkirmishRunnerBuildPanel
extends PanelContainer

signal build_changed

const ABILITIES_PATH := "res://abilities/"
const DEFENSIVE_ABILITIES_PATH := "res://abilities/defensive/"
const CHAIN_COUNT := 6
const LINK_COUNT := 5
const PICKER_WIDTH := 140.0
const MOVE_DETAIL_FONT_SIZE := 14

@export var entity_type: EntityConfig.EntityType

@onready var _title_label: Label = %TitleLabel
@onready var _chains: VBoxContainer = %Chains
@onready var _move_details: GridContainer = %MoveDetails
@onready var _defensive_moves: GridContainer = %DefensiveMoves

var _offensive_abilities: Array[OffensiveAbility] = []
var _defensive_toggles: Dictionary[DefensiveAbility, CheckBox] = {}
var _chain_pickers: Array[Array] = []
var _chain_cost_labels: Array[Label] = []

func _ready() -> void:
	_title_label.text = _build_name()
	_load_abilities()
	_build_chain_pickers()
	_build_move_details()

func has_moves() -> bool:
	return not _built_chains().is_empty()

func build_config() -> EntityConfig:
	var config: EntityConfig = EntityGenerator.generate_random_entity_configs(1, entity_type)[0]
	config.entity_name = _build_name()
	config.curr_health = config.get_max_health()
	config.chains = _built_chains()
	var abilities: Array[Ability] = []
	for chain in config.chains:
		for ability in chain.abilities:
			if not abilities.has(ability):
				abilities.append(ability)
	for ability in _defensive_toggles:
		if _defensive_toggles[ability].button_pressed:
			abilities.append(ability)
	config.abilities = abilities
	return config

func _load_abilities() -> void:
	for path in [ABILITIES_PATH, DEFENSIVE_ABILITIES_PATH]:
		for file_name in ResourceLoader.list_directory(path):
			if not file_name.ends_with(".tres"):
				continue
			var ability := load(path + file_name) as Ability
			if ability is OffensiveAbility:
				_offensive_abilities.append(ability)
			elif ability is DefensiveAbility:
				var toggle := CheckBox.new()
				toggle.text = "%s (%d)" % [ability.ability_name, ability.stamina_cost]
				toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				toggle.toggled.connect(_on_build_changed.unbind(1))
				_defensive_moves.add_child(toggle)
				_defensive_toggles[ability as DefensiveAbility] = toggle

func _build_chain_pickers() -> void:
	for i in CHAIN_COUNT:
		var row := HBoxContainer.new()
		_chains.add_child(row)
		var pickers: Array[OptionButton] = []
		for j in LINK_COUNT:
			var picker := OptionButton.new()
			picker.fit_to_longest_item = false
			picker.clip_text = true
			picker.custom_minimum_size.x = PICKER_WIDTH
			picker.add_item("-")
			for ability in _offensive_abilities:
				picker.add_item(ability.ability_name)
			picker.item_selected.connect(_on_build_changed.unbind(1))
			row.add_child(picker)
			pickers.append(picker)
		var cost_label := Label.new()
		row.add_child(cost_label)
		_chain_pickers.append(pickers)
		_chain_cost_labels.append(cost_label)

func _chain_from_pickers(pickers: Array) -> AbilityChain:
	var chain := AbilityChain.new()
	for picker in pickers:
		if picker.selected <= 0:
			break
		chain.abilities.append(_offensive_abilities[picker.selected - 1])
	return chain

func _built_chains() -> Array[AbilityChain]:
	var chains: Array[AbilityChain] = []
	for pickers in _chain_pickers:
		var chain := _chain_from_pickers(pickers)
		if not chain.abilities.is_empty():
			chains.append(chain)
	return chains

func _build_move_details() -> void:
	for header in ["Move", "Cost", "Damage", "Startup", "Active", "Recovery", "Hitstun"]:
		_add_move_detail(header)
	for ability in _offensive_abilities:
		var hit: HitConfig = null
		var active := 0.0
		if ability is MeleeAbility:
			hit = (ability as MeleeAbility).hitbox.hit
			active = (ability as MeleeAbility).hitbox.lifetime
		elif ability is RapidJabAbility:
			hit = (ability as RapidJabAbility).hitbox.hit
			active = (ability as RapidJabAbility).jab_interval * RapidJabState.JAB_MARKERS.size() * RapidJabState.CYCLES
		elif ability is ProjectileAbility:
			hit = (ability as ProjectileAbility).hit
			active = (ability as ProjectileAbility).active_duration
		_add_move_detail(ability.ability_name)
		_add_move_detail(str(ability.stamina_cost))
		_add_move_detail(str(hit.damage) if hit != null else "")
		_add_move_detail("%.2f" % ability.startup.duration)
		_add_move_detail("%.2f" % active)
		_add_move_detail("%.2f" % ability.recovery.duration)
		if hit == null:
			_add_move_detail("")
		elif hit.is_launcher:
			_add_move_detail("Launch")
		else:
			_add_move_detail("%.2f" % hit.base_hitstun)

func _add_move_detail(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", MOVE_DETAIL_FONT_SIZE)
	_move_details.add_child(label)

func _refresh_chain_costs() -> void:
	for i in _chain_pickers.size():
		var chain := _chain_from_pickers(_chain_pickers[i])
		_chain_cost_labels[i].text = "" if chain.abilities.is_empty() else "Cost %d" % chain.stamina_cost()

func _build_name() -> String:
	return EntityConfig.EntityType.keys()[entity_type].capitalize()

func _on_build_changed() -> void:
	_refresh_chain_costs()
	build_changed.emit()
