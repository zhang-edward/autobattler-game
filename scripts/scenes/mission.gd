class_name Mission
extends Node

# Owns one mission: the tactical encounter, and the skirmishes that interrupt it.
# Neither of those knows about the other.

# Drawn above the tactical HUD; the skirmish's own HUD sits above this again
const SKIRMISH_LAYER = 10

@export var tactical: TacticalEncounter
@export var skirmish_scene: PackedScene
@onready var skirmish_preview = $CanvasLayer/SkirmishPreview

var skirmish_layer: CanvasLayer
var skirmish_hero: HeroTacticalEntity
var skirmish_villain: VillainTacticalEntity

func _ready() -> void:
	tactical.skirmish_requested.connect(_on_skirmish_requested)
	skirmish_preview.on_skirmish_start.connect(open_skirmish)

# The request arrives from an area_entered callback, which runs while the physics
# server is flushing queries and refuses to have collision nodes added or removed
func _on_skirmish_requested(hero: HeroTacticalEntity, villain: VillainTacticalEntity):
	skirmish_hero = hero
	skirmish_villain = villain
	skirmish_preview.show_skirmish_preview([hero.entity_config], [villain.entity_config])
	tactical.freeze()

func open_skirmish():
	if skirmish_layer != null or not is_instance_valid(skirmish_hero) or not is_instance_valid(skirmish_villain):
		return
	var heroes: Array[EntityConfig] = [skirmish_hero.entity_config]
	var villains: Array[EntityConfig] = [skirmish_villain.entity_config]
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

	skirmish_hero.refresh_health_bar()
	skirmish_villain.refresh_health_bar()

	if winner == EntityConfig.EntityType.HERO:
		skirmish_hero.entity_config.num_kills += 1
		skirmish_villain.defeat()
	else:
		skirmish_hero.capture()

	skirmish_hero = null
	skirmish_villain = null
	# Last, so the loser is already on its way out when the frozen collision
	# shapes re-enter the physics space and re-report their overlaps
	tactical.unfreeze()
