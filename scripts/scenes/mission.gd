class_name Mission
extends Node

# Owns one mission: the tactical encounter, and the skirmishes that interrupt it.
# Neither of those knows about the other.

# Drawn above the tactical HUD; the skirmish's own HUD sits above this again
const SKIRMISH_LAYER = 10

@export var tactical: TacticalEncounter
@export var skirmish_scene: PackedScene

@onready var skirmish_range_circle: SkirmishRangeCircle = $SkirmishRangeCircle
@onready var skirmish_preview: SkirmishPreview = $CanvasLayer/SkirmishPreview

var skirmish_layer: CanvasLayer
var skirmish_heroes: Array[TacticalEntity]
var skirmish_villains: Array[TacticalEntity]

const SKIRMISH_RADIUS = 500

func _ready() -> void:
	tactical.skirmish_requested.connect(_on_skirmish_requested)
	skirmish_preview.on_skirmish_start.connect(open_skirmish)
	skirmish_range_circle.radius = SKIRMISH_RADIUS
	skirmish_range_circle.queue_redraw()
	skirmish_range_circle.hide()

# The request arrives from an area_entered callback, which runs while the physics
# server is flushing queries and refuses to have collision nodes added or removed
func _on_skirmish_requested(hero: HeroTacticalEntity, villain: VillainTacticalEntity):
	skirmish_heroes = get_all_entities_within_radius(hero.global_position, SKIRMISH_RADIUS, EntityConfig.EntityType.HERO)
	skirmish_villains = get_all_entities_within_radius(hero.global_position, SKIRMISH_RADIUS, EntityConfig.EntityType.VILLAIN)
	skirmish_preview.show_skirmish_preview(skirmish_heroes, skirmish_villains)
	# Add lerp to global position for smoother movement
	skirmish_range_circle.global_position = hero.global_position
	skirmish_range_circle.show()
	tactical.freeze()
	
func get_all_entities_within_radius(global_position: Vector2, radius: int, entity_type: EntityConfig.EntityType):
	var res: Array[TacticalEntity] = []
	var all_entities = tactical.hero_entities + tactical.villain_entities
	for entity in all_entities:
		if entity.global_position.distance_to(global_position) <= radius and entity.entity_config.entity_type == entity_type:
			res.append(entity)
	return res

func open_skirmish():
	skirmish_range_circle.hide()
	skirmish_preview.hide()
	if skirmish_layer != null:
		return
	var valid_skirmish_heroes = skirmish_heroes.filter(func (sh): return is_instance_valid(sh))
	var valid_skirmish_villains = skirmish_villains.filter(func (sv): return is_instance_valid(sv))
	var heroes: Array[EntityConfig] = []
	var villains: Array[EntityConfig] = []
	for sh in valid_skirmish_heroes:
		heroes.append(sh.entity_config)
	for sv in valid_skirmish_villains:
		villains.append(sv.entity_config)
	var skirmish = skirmish_scene.instantiate() as Skirmish
	skirmish.setup(heroes, villains)
	skirmish.finished.connect(end_skirmish)

	skirmish_layer = CanvasLayer.new()
	skirmish_layer.layer = SKIRMISH_LAYER
	skirmish_layer.add_child(skirmish)
	add_child(skirmish_layer)

	tactical.freeze()
	ScreenShake.target = skirmish_layer

func end_skirmish(winner: EntityConfig.EntityType):
	ScreenShake.stop()
	ScreenShake.target = null
	skirmish_layer.queue_free()
	skirmish_layer = null

	for sh in skirmish_heroes:
		sh.refresh_health_bar()
		if sh.entity_config.curr_health == 0:
			sh.defeat()
			
	for sv in skirmish_villains:
		sv.refresh_health_bar()
		if sv.entity_config.curr_health == 0:
			sv.defeat()

	if winner == EntityConfig.EntityType.HERO:
		for sv in skirmish_villains:
			var villain = sv as VillainTacticalEntity
			for sh in skirmish_heroes:
				if !sh.entity_config.defeated_villain_names.has(villain.entity_config.entity_name):
					sh.entity_config.num_assists += 1
			villain.defeat()

	skirmish_heroes = []
	skirmish_villains = []
	skirmish_range_circle.hide()

	# Last, so the loser is already on its way out when the frozen collision
	# shapes re-enter the physics space and re-report their overlaps
	tactical.unfreeze()
