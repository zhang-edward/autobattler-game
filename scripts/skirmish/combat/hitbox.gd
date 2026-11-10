class_name Hitbox
extends Area2D

signal hit_connected

const EFFECT_ANGLE_RANGE := PI / 4

var _life_timer := 0.5
# Dictionary used as hash set, with dummy values (true) for each key
var _collision_exceptions := {}
var _source: SkirmishEntity
var _hit: HitConfig

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

func init(pos: Vector2, size: Vector2, lifetime: float, source: SkirmishEntity, hit: HitConfig):
	position = pos
	_collision_shape.shape = RectangleShape2D.new()
	_collision_shape.shape.size = size
	_life_timer = lifetime
	_source = source
	_hit = hit
	area_entered.connect(_handle_area_entered)

func _process(delta):
	# A frozen source holds its hitboxes too, so hitstop doesn't eat their lifetime
	if is_instance_valid(_source):
		delta *= _source.hitstop_scale
	_life_timer -= delta
	if _life_timer <= 0:
		queue_free()

func _handle_area_entered(body: Area2D):
	if _collision_exceptions.has(body):
		return
	_collision_exceptions[body] = true

	if body is not Hurtbox:
		return
	var target := (body as Hurtbox).parent as SkirmishEntity
	# Only hit the other side
	if target == null or target.entity_type == _source.entity_type:
		return
	# Attack out of range (not on the same horizontal axis)
	if abs(_source.position.y - target.position.y) > IsometryUtils.Y_AXIS_HIT_RANGE:
		return

	# The target owns the outcome, including whether it warrants hitstop or shake
	if target.take_hit(_hit, _source):
		spawn_effect(lerp(global_position, body.global_position, 0.5), target.global_position - _source.global_position, target)
		hit_connected.emit()

func spawn_effect(pos: Vector2, dir: Vector2, target: SkirmishEntity):
	var config = EffectConfig.new()
	config.pos = pos
	config.anim = HitEffectRegistry.HIT_1 if target.state_machine.state == target.block_state else HitEffectRegistry.HIT_NEW
	config.dir = dir
	config.angle_range_rad = EFFECT_ANGLE_RANGE
	EffectManager.spawn_effect(config)
