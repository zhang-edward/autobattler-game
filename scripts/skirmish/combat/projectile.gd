class_name Projectile
extends Area2D

var _source: SkirmishEntity
var _hit: HitConfig
var _direction := 1.0
var _speed := 0.0
var _life_timer := 0.0

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _visual: Polygon2D = $Polygon2D

func init(pos: Vector2, height: float, direction: float, speed: float, lifespan: float, size: Vector2, source: SkirmishEntity, hit: HitConfig) -> void:
	position = pos
	_collision_shape.position.y = height
	_collision_shape.shape = RectangleShape2D.new()
	_collision_shape.shape.size = size
	_visual.position.y = height
	_direction = direction
	_speed = speed
	_life_timer = lifespan
	_source = source
	_hit = hit
	area_entered.connect(_handle_area_entered)

func _physics_process(delta: float) -> void:
	position.x += _direction * _speed * delta
	_life_timer -= delta
	if _life_timer <= 0.0:
		queue_free()

func _handle_area_entered(body: Area2D) -> void:
	if is_queued_for_deletion():
		return
	if body is not Hurtbox:
		return
	if not is_instance_valid(_source):
		queue_free()
		return
	var target := (body as Hurtbox).parent as SkirmishEntity
	if target == null or target.entity_type == _source.entity_type:
		return
	if abs(position.y - target.position.y) > IsometryUtils.Y_AXIS_HIT_RANGE:
		return

	target.take_hit(_hit, _source)
	queue_free()
