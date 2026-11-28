class_name DamageNumber
extends Node2D

const RISE := 60.0
const DURATION := 0.7

@onready var label: Label = $Label

func play(damage: int) -> void:
	play_text(str(damage))


## Pops any text, e.g. "+24" in green for a heal.
func play_text(text: String, color := Color.WHITE) -> void:
	label.text = text
	label.modulate = color
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - RISE, DURATION) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, DURATION).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
