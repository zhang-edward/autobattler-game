class_name ThreatLabel
extends PanelContainer

enum ThreatType {
	VILLAIN,
	MOBS
}

@onready var label: Label = $MarginContainer/Label
@export var threat_label: ThreatType

func init_threat_label(l: ThreatType):
	if l == ThreatType.VILLAIN:
		add_theme_stylebox_override("panel", load("res://prefabs/styles/villain_threat_type_label.tres"))
		label.text = "VILLAIN"
	elif l == ThreatType.MOBS:
		add_theme_stylebox_override("panel", load("res://prefabs/styles/mobs_threat_type_label.tres"))
		label.text = "MOBS"
