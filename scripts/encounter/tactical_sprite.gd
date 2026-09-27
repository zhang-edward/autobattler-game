class_name TacticalSprite
extends Node2D


@onready var face_sprite: Sprite2D = $Face
@onready var eyes_sprite: Sprite2D = $Eyes
@onready var eyebrows_sprite: Sprite2D = $Eyebrows
@onready var nose_sprite: Sprite2D = $Nose
@onready var mouth_sprite: Sprite2D = $Mouth
@onready var hair_sprite: Sprite2D = $Hair
@onready var clothes_sprite: Sprite2D = $Clothes
@onready var facial_hair_sprite: Sprite2D = $FacialHair

func select():
	pass
	
func deselect():
	pass

func render_portrait(portrait_config: PortraitConfig):
	_apply_texture(face_sprite, "face", portrait_config.face_path)
	_apply_texture(eyes_sprite, "eyes", portrait_config.eyes_path)
	_apply_texture(eyebrows_sprite, "eyebrows", portrait_config.eyebrows_path)
	_apply_texture(nose_sprite, "nose", portrait_config.nose_path)
	_apply_texture(mouth_sprite, "mouth", portrait_config.mouth_path)
	_apply_texture(hair_sprite, "hair", portrait_config.hair_path)
	_apply_texture(clothes_sprite, "clothing", portrait_config.clothes_path)
	_apply_texture(facial_hair_sprite, "facial_hair", portrait_config.facial_hair_path)

## path is expected as "<gender>/<resource_name>" (e.g. "unisex/base01"),
## matching the subfolder layout under assets/portraits/placeholder.
## An empty path hides the layer instead of trying to load it (e.g. most
## female entities have no facial_hair_path since no female assets exist yet).
func _apply_texture(sprite: Sprite2D, folder: String, path: String) -> void:
	if path == "":
		sprite.texture = null
		sprite.visible = false
		return
	sprite.texture = load("res://assets/portraits/placeholder/%s/%s.png" % [folder, path])
	sprite.visible = true
