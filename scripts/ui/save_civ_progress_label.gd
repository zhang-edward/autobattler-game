class_name SaveCivProgressLabel
extends VBoxContainer

@onready var progress_bar: ProgressBar = $ProgressBar
var tween: Tween
var is_saving := false

signal on_save

func start_save_timer():
	is_saving = true
	tween = create_tween()
	tween.tween_property(progress_bar, "value", progress_bar.max_value, 10)
	var on_complete = func _on_complete():
		on_save.emit()
	tween.finished.connect(on_complete)

func stop_save_timer():
	is_saving = false
	if tween != null:
		tween.stop()
		progress_bar.value = 0
