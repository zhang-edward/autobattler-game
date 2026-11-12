class_name ComboCounter
extends VBoxContainer

const FADE_SECONDS := 0.4
const HITS_HOLD_SECONDS := 0.6
const PUNISH_HOLD_SECONDS := 1.0

@onready var hits_label: Label = %HitsLabel
@onready var punish_label: Label = %PunishLabel

var _hits_tween: Tween
var _punish_tween: Tween

func _ready() -> void:
	hits_label.modulate.a = 0.0
	punish_label.modulate.a = 0.0

func show_hits(hits: int) -> void:
	if _hits_tween != null:
		_hits_tween.kill()
	hits_label.text = str(hits) + " HITS"
	hits_label.modulate.a = 1.0

func end_combo() -> void:
	if hits_label.modulate.a == 0.0:
		return
	if _hits_tween != null:
		_hits_tween.kill()
	_hits_tween = create_tween()
	_hits_tween.tween_property(hits_label, "modulate:a", 0.0, FADE_SECONDS).set_delay(HITS_HOLD_SECONDS)

func show_punish() -> void:
	if _punish_tween != null:
		_punish_tween.kill()
	punish_label.modulate.a = 1.0
	_punish_tween = create_tween()
	_punish_tween.tween_property(punish_label, "modulate:a", 0.0, FADE_SECONDS).set_delay(PUNISH_HOLD_SECONDS)
