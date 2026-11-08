class_name RosterHeroPreview
extends PanelContainer

@onready var hero_name: Label = %HeroName
@onready var level: Label = %Level
@onready var stat_grid: GridContainer = %StatGrid
@onready var exp_bar: ProgressBar = %ExpBar
@onready var exp_pct: Label = %ExpPct
@onready var button: Button = %Button
@onready var resting_overlay: PanelContainer = %RestingOverlay
@onready var resting_label: Label = %RestingLabel
@onready var health_bar: HealthBar = %HealthBar

@export var stat_label_scene: PackedScene
var entity_config: EntityConfig

signal on_clicked(hero_preview: RosterHeroPreview)

func _ready():
	button.pressed.connect(click)
	
func click():
	on_clicked.emit(self)

func configure(config: EntityConfig):
	entity_config = config
	hero_name.text = config.entity_name
	level.text = "Lv" + str(config.level)
	var curr_exp = float(config.exp)
	var exp_to_next_level = float(config.exp_to_next_level)
	exp_pct.text = "EXP " + str(round((curr_exp / exp_to_next_level) * 100.0)) + "%"
	exp_bar.max_value = exp_to_next_level
	exp_bar.value = curr_exp
	health_bar.configure(config)
	resting_overlay.visible = config.injury_recovery_days > 0
	resting_label.text = "Resting (" + str(config.injury_recovery_days) + (" day)" if config.injury_recovery_days == 1 else " days)")
	for c in stat_grid.get_children():
		c.queue_free()
	add_stat_row("STR", config.strength)
	add_stat_row("SKL", config.skill)
	add_stat_row("AGI", config.agility)
	add_stat_row("VIT", config.vitality)
	add_stat_row("DEF", config.defense)
	add_stat_row("CHA", config.charisma)

func add_stat_row(stat_name: String, stat_value: int):
	var stat_label = stat_label_scene.instantiate() as StatLabel
	stat_grid.add_child(stat_label)
	stat_label.configure(stat_name, stat_value)
