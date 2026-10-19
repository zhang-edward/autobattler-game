class_name Skirmish
extends Node2D

signal finished(winner: EntityConfig.EntityType)

const HERO_START := Vector2(400.0, 700.0)
const VILLAIN_START := Vector2(1400.0, 700.0)
const ROW_SPACING := 200.0
# Delay between the last death and `finished`, so the body can land and fade first
const OUTRO_SECONDS := 1.5

# Wall layout, authored at this resolution and scaled to the current viewport
const WALL_BASE_SIZE := Vector2(1920.0, 1080.0)
const SIDE_WALL_THICKNESS := 20.0
const BOTTOM_WALL_CENTER_Y := 1000.0
const BOTTOM_WALL_HEIGHT := 136.375
# The top wall's lower edge sits on the horizon (see Background/Ground band fractions)
const TOP_WALL_CENTER_Y := 150.0
const TOP_WALL_HEIGHT := 320.0
const TOP_WALL_SIDE_INSET := 15.0

@export var entity_scene: PackedScene

@export_group("Standalone testing")
@export var debug_hero_count := 1
@export var debug_villain_count := 1

var _living: Array[SkirmishEntity] = []
var _finished := false

@onready var _left_wall: StaticBody2D = $VWall
@onready var _right_wall: StaticBody2D = $VWall2
@onready var _bottom_wall: StaticBody2D = $HWall
@onready var _top_wall: StaticBody2D = $HWall2

func _ready() -> void:
	get_viewport().size_changed.connect(_update_walls)
	_update_walls()
	if _living.is_empty():
		_setup_debug_matchup()

# Re-fits the four boundary walls to the current viewport so they stay on the screen edges
func _update_walls() -> void:
	var vp := get_viewport_rect().size
	var scale_y := vp.y / WALL_BASE_SIZE.y
	_place_wall(_left_wall, Vector2(0.0, vp.y * 0.5), Vector2(SIDE_WALL_THICKNESS, vp.y))
	_place_wall(_right_wall, Vector2(vp.x, vp.y * 0.5), Vector2(SIDE_WALL_THICKNESS, vp.y))
	_place_wall(_bottom_wall, Vector2(vp.x * 0.5, BOTTOM_WALL_CENTER_Y * scale_y), Vector2(vp.x, BOTTOM_WALL_HEIGHT * scale_y))
	_place_wall(_top_wall, Vector2(vp.x * 0.5, TOP_WALL_CENTER_Y * scale_y), Vector2(vp.x - TOP_WALL_SIDE_INSET * 2.0, TOP_WALL_HEIGHT * scale_y))

# Centres the wall's body on `center` and sizes its rectangle collider to `size`
func _place_wall(wall: StaticBody2D, center: Vector2, size: Vector2) -> void:
	wall.position = center
	var collider := wall.get_node("CollisionShape2D") as CollisionShape2D
	collider.position = Vector2.ZERO
	(collider.shape as RectangleShape2D).size = size

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
		config.curr_health = config.vitality
	for config in villains:
		config.curr_health = config.vitality
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
