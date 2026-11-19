class_name SkirmishStatusRow
extends PanelContainer

const HERO_FILL := preload("res://prefabs/styles/hero_health_bar.tres")
const VILLAIN_FILL := preload("res://prefabs/styles/villain_health_bar.tres")
const CHAIN_ROW := preload("res://prefabs/ui/skirmish/chain_row.tscn")
const QUEUED_ALPHA := 1.0
const UNQUEUED_ALPHA := 0.45

const ACTIVE_BORDER := Color(1, 1, 0)

@onready var _name_label: Label = $VBox/HBox/NameLabel
@onready var _bar: ProgressBar = $VBox/HBox/HealthBar
@onready var _wounds_bar: ProgressBar = $VBox/HBox/HealthBar/WoundsBar
@onready var retreat_button: Button = $VBox/HBox/RetreatButton
@onready var _stamina_bar: ProgressBar = $VBox/StaminaBar
@onready var _defensive_status_label: Label = $VBox/DefensiveStatusLabel
@onready var _abilities: VBoxContainer = $VBox/Abilities

var entity: SkirmishEntity
var _chain_rows: Dictionary[AbilityChain, ChainRow] = {}

signal retreat_pressed(e: SkirmishEntity)

func _ready() -> void:
	retreat_button.pressed.connect(func(): retreat_pressed.emit(entity))

func configure(e: SkirmishEntity) -> void:
	entity = e
	_name_label.text = e.entity_config.entity_name
	_bar.max_value = e.entity_config.get_max_health()
	_bar.value = e.entity_config.curr_health
	_wounds_bar.max_value = e.entity_config.get_max_health()
	_stamina_bar.max_value = SkirmishEntity.STAMINA_MAX
	var fill := HERO_FILL if e.entity_type == EntityConfig.EntityType.HERO else VILLAIN_FILL
	_bar.add_theme_stylebox_override("fill", fill)
	for chain in e.chains:
		var chain_row := CHAIN_ROW.instantiate() as ChainRow
		_abilities.add_child(chain_row)
		var names: Array[String] = []
		for ability in chain.abilities:
			names.append(ability.ability_name)
		chain_row.configure(e, " > ".join(names), chain.stamina_cost())
		_chain_rows[chain] = chain_row
	for ability in e.entity_config.abilities:
		if ability is DefensiveAbility:
			var chain_row := CHAIN_ROW.instantiate() as ChainRow
			_abilities.add_child(chain_row)
			chain_row.configure(e, ability.ability_name, ability.stamina_cost)
	refresh()

func refresh() -> void:
	if entity == null or not is_instance_valid(entity) or entity.entity_config == null:
		_bar.value = 0
		_wounds_bar.visible = false
		return
	_bar.value = entity.entity_config.curr_health
	_wounds_bar.value = entity.entity_config.curr_wounds
	_wounds_bar.visible = entity.entity_config.curr_health <= 0
	_stamina_bar.value = entity.stamina
	if entity.defensive_status is BlockAbility:
		_defensive_status_label.text = "Block %d" % entity.block
	elif entity.defensive_status is DodgeAbility:
		_defensive_status_label.text = "Dodge"
	else:
		_defensive_status_label.text = ""
	for chain_row in _abilities.get_children():
		(chain_row as ChainRow).refresh()
	var queued_chain := (entity.brain as AIBrain).queued_chain
	for chain in _chain_rows:
		_chain_rows[chain].modulate.a = QUEUED_ALPHA if chain == queued_chain else UNQUEUED_ALPHA

func set_active_highlight(active: bool) -> void:
	var stylebox := get_theme_stylebox("panel") as StyleBoxFlat
	if active:
		stylebox.border_color = ACTIVE_BORDER
		stylebox.set_border_width_all(2)
	else:
		stylebox.set_border_width_all(0)
