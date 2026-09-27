class_name Portrait
extends Control

@onready var face_texture: TextureRect = $Face
@onready var eyes_texture: TextureRect = $Eyes
@onready var eyebrows_texture: TextureRect = $Eyebrows
@onready var nose_texture: TextureRect = $Nose
@onready var mouth_texture: TextureRect = $Mouth
@onready var hair_texture: TextureRect = $Hair
@onready var clothes_texture: TextureRect = $Clothes
@onready var facial_hair_texture: TextureRect = $FacialHair

func render_portrait(portrait_config: PortraitConfig):
	_apply_texture(face_texture, "face", portrait_config.face_path)
	_apply_texture(eyes_texture, "eyes", portrait_config.eyes_path)
	_apply_texture(eyebrows_texture, "eyebrows", portrait_config.eyebrows_path)
	_apply_texture(nose_texture, "nose", portrait_config.nose_path)
	_apply_texture(mouth_texture, "mouth", portrait_config.mouth_path)
	_apply_texture(hair_texture, "hair", portrait_config.hair_path)
	_apply_texture(clothes_texture, "clothing", portrait_config.clothes_path)
	_apply_texture(facial_hair_texture, "facial_hair", portrait_config.facial_hair_path)

## path is expected as "<gender>/<resource_name>" (e.g. "unisex/base01"),
## matching the subfolder layout under assets/portraits/placeholder.
## An empty path hides the layer instead of trying to load it (e.g. most
## female entities have no facial_hair_path since no female assets exist yet).
func _apply_texture(texture_rect: TextureRect, folder: String, path: String) -> void:
	if path == "":
		texture_rect.texture = null
		texture_rect.visible = false
		return
	texture_rect.texture = load("res://assets/portraits/placeholder/%s/%s.png" % [folder, path])
	texture_rect.visible = true
