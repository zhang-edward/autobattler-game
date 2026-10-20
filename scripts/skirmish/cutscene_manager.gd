class_name CutsceneManager
extends Node

const BEAT := 0.5
const ZOOM := 1.4
const ARENA_CENTER := Vector2(960.0, 540.0)
const DIM := Color(0.35, 0.35, 0.35, 1.0)

@onready var skirmish: Skirmish = get_parent()

var _camera: Camera2D
var _overlay: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camera = skirmish.get_node("%TagCamera") as Camera2D
	_camera.make_current()
	_overlay = skirmish.get_node("%TagDarken") as ColorRect
	_overlay.visible = false

func _exit_tree() -> void:
	get_tree().paused = false

func darken_screen(focus: Vector2, pair: Array) -> void:
	get_tree().paused = true
	_overlay.visible = true
	_dim_others(pair)
	await get_tree().create_timer(0.2).timeout

func speak(entity: SkirmishEntity, text: String) -> void:
	if entity == null or not is_instance_valid(entity) or entity.is_dead or text == "":
		return
	var bubble := _init_speech(entity, text)
	await get_tree().create_timer(BEAT).timeout
	if is_instance_valid(bubble):
		bubble.queue_free()

func tag_in(entity: SkirmishEntity, destination: Vector2, entry_side: float) -> void:
	entity.begin_tag_in(destination, entry_side)
	entity.process_mode = Node.PROCESS_MODE_ALWAYS
	await entity.tag_in_state.finished

func tag_out(entity: SkirmishEntity) -> void:
	if entity == null or not is_instance_valid(entity) or entity.is_dead:
		return
	entity.process_mode = Node.PROCESS_MODE_ALWAYS
	entity.begin_tag_out()
	await entity.tag_out_state.finished

func release() -> void:
	_overlay.visible = false
	_undim_all()
	var home := create_tween().set_parallel(true)
	home.tween_property(_camera, "zoom", Vector2.ONE, 0.25)
	home.tween_property(_camera, "position", ARENA_CENTER, 0.25)
	await home.finished
	get_tree().paused = false

func _dim_others(pair: Array) -> void:
	for e in skirmish.hero_team + skirmish.villain_team:
		if e == null or not is_instance_valid(e):
			continue
		e.modulate = Color.WHITE if e in pair else DIM

func _undim_all() -> void:
	for e in skirmish.hero_team + skirmish.villain_team:
		if e != null and is_instance_valid(e):
			e.modulate = Color.WHITE

func _init_speech(parent: Node2D, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	label.size = Vector2(200.0, 40.0)
	label.position = Vector2(-100.0, -300.0)
	label.z_index = 50
	parent.add_child(label)
	return label
