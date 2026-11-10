class_name EffectManager
extends Node2D

static var instance: EffectManager
static var _effect_scene: PackedScene = preload("res://prefabs/effect.tscn")

func _ready() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

static func spawn_effect(config: EffectConfig) -> void:
	if instance == null:
		return
	var effect: Effect = _effect_scene.instantiate()
	instance.add_child(effect)
	effect.global_position = config.pos + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	effect.sprite_frames = config.anim
	effect.rotation = config.dir.angle() + randf_range(-config.angle_range_rad / 2, config.angle_range_rad / 2)
	effect.scale *= randf_range(0.9, 1.1)
	effect.play()
