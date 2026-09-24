class_name Skirmish
extends Node2D

signal finished(winner: EntityConfig.EntityType)

const HERO_START := Vector2(400.0, 700.0)
const VILLAIN_START := Vector2(1400.0, 700.0)
const ROW_SPACING := 200.0
# Delay between the last death and `finished`, so the body can land and fade first
const OUTRO_SECONDS := 1.5

@export var entity_scene: PackedScene

@export_group("Standalone testing")
@export var debug_hero_count := 1
@export var debug_villain_count := 1

var _living: Array[SkirmishEntity] = []
var _finished := false

func _ready() -> void:
	if _living.is_empty():
		_setup_debug_matchup()

func setup(heroes: Array[EntityConfig], villains: Array[EntityConfig]) -> void:
	_spawn_side(heroes, HERO_START)
	_spawn_side(villains, VILLAIN_START)

func _spawn_side(configs: Array[EntityConfig], start: Vector2) -> void:
	# setup() runs before this scene is added to the tree, so @onready isn't resolved yet
	var battlefield := $Battlefield as Node2D
	var pos := start
	for config in configs:
		var entity := entity_scene.instantiate() as SkirmishEntity
		entity.name = config.entity_name
		battlefield.add_child(entity)
		entity.configure_from_entity_config(config)
		entity.position = pos
		entity.died.connect(_on_entity_died.bind(entity))
		_living.append(entity)
		pos.y += ROW_SPACING

# Lets this scene be run on its own for testing, without a tactical encounter to set it up
func _setup_debug_matchup() -> void:
	var heroes: Array[EntityConfig] = GameVariables.generate_random_entity_configs(debug_hero_count, EntityConfig.EntityType.HERO)
	var villains: Array[EntityConfig] = GameVariables.generate_random_entity_configs(debug_villain_count, EntityConfig.EntityType.VILLAIN)
	for config in heroes:
		config.curr_health = config.max_health
	for config in villains:
		config.curr_health = config.max_health
	setup(heroes, villains)

func _on_entity_died(entity: SkirmishEntity) -> void:
	_living.erase(entity)
	for other in _living:
		if other.entity_type == entity.entity_type:
			return
	_finish(EntityConfig.EntityType.VILLAIN if entity.entity_type == EntityConfig.EntityType.HERO else EntityConfig.EntityType.HERO)

func _finish(winner: EntityConfig.EntityType) -> void:
	if _finished:
		return
	_finished = true
	await get_tree().create_timer(OUTRO_SECONDS).timeout
	finished.emit(winner)
