class_name SegmentedBar
extends HBoxContainer

@export var segment_scene: PackedScene
@export var fill_style: StyleBox

func configure(segment_count: int) -> void:
	for i in segment_count:
		var segment := segment_scene.instantiate() as ProgressBar
		segment.add_theme_stylebox_override("fill", fill_style)
		add_child(segment)

func set_value(value: float) -> void:
	for i in get_child_count():
		(get_child(i) as ProgressBar).value = clampf(value - i, 0.0, 1.0)
