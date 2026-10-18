class_name ThreatLabel
extends PanelContainer

@onready var label: Label = $MarginContainer/Label
@export var threat_label: ThreatRequestConfig.ThreatType

func configure(l: ThreatRequestConfig.ThreatType):
	if l == ThreatRequestConfig.ThreatType.VILLAIN:
		add_theme_stylebox_override("panel", load("res://prefabs/styles/villain_threat_type_label.tres"))
		label.text = "VILLAIN"
	elif l == ThreatRequestConfig.ThreatType.MOB:
		add_theme_stylebox_override("panel", load("res://prefabs/styles/mobs_threat_type_label.tres"))
		label.text = "MOBS"
