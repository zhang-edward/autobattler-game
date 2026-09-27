class_name PortraitConfig
extends RefCounted

static var FACE_RESOURCE_NAMES = {
	"male": [],
	"female": [],
	"unisex": ["base01", "base02", "base03", "base04"]
}
static var CLOTHING_RESOURCE_NAMES = {
	"male": ["clothing06", "clothing09"],
	"female": ["clothing02", "clothing03", "clothing08", "clothing11", "clothing14"],
	"unisex": ["clothing01", "clothing04", "clothing05", "clothing07", "clothing10"]
}
static var EYEBROW_RESOURCE_NAMES = {
	"male": [],
	"female": [],
	"unisex": ["eyebrows01", "eyebrows02", "eyebrows03", "eyebrows04", "eyebrows07"]
}
static var EYES_RESOURCE_NAMES = {
	"male": ["eyes01", "eyes02"],
	"female": ["eyes03", "eyes04", "eyes06", "eyes07", "eyes14", "eyes15"],
	"unisex": ["eyes05", "eyes11"]
}
static var NOSE_RESOURCE_NAMES = {
	"male": [],
	"female": [],
	"unisex": ["nose01", "nose02", "nose03", "nose06"]
}
static var MOUTH_RESOURCE_NAMES = {
	"male": ["mouth01"],
	"female": ["mouth03", "mouth08", "mouth09"],
	"unisex": ["mouth04", "mouth07", "mouth12"]
}
static var HAIR_RESOURCE_NAMES = {
	"male": ["hair02", "hair03", "hair04", "hair05", "hair06", "hair07", "hair08", "hair09", "hair11", "hair12"],
	"female": ["hair15", "hair17", "hair24", "hair26", "hair27", "hair31", "hair34", "hair37"],
	"unisex": []
}
static var FACIAL_HAIR_RESOURCE_NAMES = {
	"male": ["facial02", "facial03", "facial05", "facial12"],
	"female": [],
	"unisex": []
}

var face_path: String = ""
var eyes_path: String = ""
var eyebrows_path: String = ""
var nose_path: String = ""
var mouth_path: String = ""
var hair_path: String = ""
var clothes_path: String = ""
var facial_hair_path: String = ""

static func generate_random_portrait_config(gender: EntityConfig.Gender):
	var gender_path_key = "male" if gender == EntityConfig.Gender.MALE else "female"
	var portrait_config = PortraitConfig.new()
	portrait_config.face_path = get_random_key(gender_path_key, FACE_RESOURCE_NAMES)
	portrait_config.eyes_path = get_random_key(gender_path_key, EYES_RESOURCE_NAMES)
	portrait_config.eyebrows_path = get_random_key(gender_path_key, EYEBROW_RESOURCE_NAMES)
	portrait_config.nose_path = get_random_key(gender_path_key, NOSE_RESOURCE_NAMES)
	portrait_config.mouth_path = get_random_key(gender_path_key, MOUTH_RESOURCE_NAMES)
	portrait_config.hair_path = get_random_key(gender_path_key, HAIR_RESOURCE_NAMES)
	portrait_config.clothes_path = get_random_key(gender_path_key, CLOTHING_RESOURCE_NAMES)
	portrait_config.facial_hair_path = get_random_key(gender_path_key, FACIAL_HAIR_RESOURCE_NAMES)
	return portrait_config
 
static func get_random_key(path_key: String, resource_name_mapping: Dictionary):
	var all_resources = resource_name_mapping[path_key] + resource_name_mapping["unisex"]
	if all_resources.is_empty():
		return ""
	var rand_key = all_resources.pick_random()
	var prefix = path_key if rand_key in resource_name_mapping[path_key] else "unisex"
	return prefix + "/" + rand_key
