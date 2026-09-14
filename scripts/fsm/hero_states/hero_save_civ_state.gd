class_name HeroSaveCivState
extends HeroState

@export var save_civ_label_scene: PackedScene

var save_civ_label: SaveCivProgressLabel

func _ready() -> void:
	save_civ_label = save_civ_label_scene.instantiate() as SaveCivProgressLabel
	save_civ_label.hide()

func enter(_msg := {}) -> void:
	hero.velocity = Vector2.ZERO
