class_name SkirmishEntityRig
extends CharacterBody2D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var back_fist_hitbox: Hitbox = %BackHitbox
@onready var front_fist_hitbox: Hitbox = %FrontHitbox

signal on_emit_hitbox_enable()
signal on_emit_hitbox_disable()

func _ready() -> void:
	back_fist_hitbox.disable()
	front_fist_hitbox.disable()

func play_animation(anim_name: String):
	anim_player.play(anim_name)

func emit_hitbox_enable():
	on_emit_hitbox_enable.emit()
	
func emit_hitbox_disable():
	on_emit_hitbox_disable.emit()
