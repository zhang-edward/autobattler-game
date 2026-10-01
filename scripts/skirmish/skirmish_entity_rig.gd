class_name SkirmishEntityRig
extends Node2D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var back_fist: Sprite2D = %BackFist
@onready var front_fist: Sprite2D = %FrontFist

signal on_emit_hitbox_enable()
signal on_throw_release()

func play_animation(anim_name: String):
	anim_player.play(anim_name)

func emit_hitbox_enable():
	on_emit_hitbox_enable.emit()

func emit_throw_release():
	on_throw_release.emit()
