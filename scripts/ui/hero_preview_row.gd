class_name HeroPreviewRow
extends PanelContainer

@export var stat_label_scene: PackedScene
@onready var stat_grid: GridContainer = %StatGrid
@onready var level_label: RichTextLabel = %LevelLabel
@onready var hero_name: Label = %HeroName
@onready var remove_overlay: PanelContainer = %RemoveOverlay
@onready var button: Button = $Button

var enable_remove_overlay := false
var entity_config: EntityConfig

signal on_clicked(r: HeroPreviewRow)

func _ready() -> void:
	button.pressed.connect(click_hero)
	button.mouse_entered.connect(show_remove_overlay)
	button.mouse_exited.connect(hide_remove_overlay)

func show_remove_overlay():
	if enable_remove_overlay:
		remove_overlay.show()
	
func hide_remove_overlay():
	if enable_remove_overlay:
		remove_overlay.hide()

func click_hero():
	on_clicked.emit(self)

func configure(config: EntityConfig):
	entity_config = config
	hero_name.text = config.entity_name
	setup_level(config.level)
	add_stat_label("STR", config.strength)
	add_stat_label("SKL", config.skill)
	add_stat_label("AGI", config.agility)
	add_stat_label("VIT", config.vitality)
	add_stat_label("DEF", config.defense)
	add_stat_label("CHA", config.charisma)

func add_stat_label(stat_name: String, stat_value: int):
	var stat_label = stat_label_scene.instantiate() as StatLabel
	stat_grid.add_child(stat_label)
	stat_label.configure(stat_name, stat_value)

func setup_level(level: int):
	level_label.text = "[font_size=20]Lv[/font_size] [font_size=32]" + str(level) + "[/font_size]"

func deselect():
	add_theme_stylebox_override("panel", load("res://prefabs/styles/default_ui_panel_stylebox_stroke.tres"))

func select():
	add_theme_stylebox_override("panel", load("res://prefabs/styles/default_ui_panel_stylebox_highlighted.tres"))
