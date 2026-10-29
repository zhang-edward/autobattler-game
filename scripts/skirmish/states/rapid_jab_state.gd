class_name RapidJabState
extends AbilityState

const NUDGE_MOVE_SPEED = 50.0
const CYCLES := 2
const HITBOX_SIZE := Vector2(40, 40)
const HITBOX_LIFETIME := 0.1

var hitbox_scene: PackedScene = preload("res://prefabs/hitbox.tscn")
var hit: HitConfig = HitConfig.create(15)
# Even indices throw the front fist, odd indices the back fist
var jab_anims = [
	"male-rig/punch_flurry_1",
	"male-rig/punch_flurry_2",
	"male-rig/punch_flurry_3",
	"male-rig/punch_flurry_4",
]
var jab_interval := 0.12
var recovery_time := 0.3
var jab_index := 0
var timer := 0.0

func init(ability: Ability) -> void:
	var rapid_jab := ability as RapidJabAbility
	if rapid_jab == null:
		return
	jab_interval = rapid_jab.jab_interval
	recovery_time = rapid_jab.recovery_time

func enter(_msg := {}) -> void:
	jab_index = 0
	_jab()

func physics_update(delta: float) -> void:
	e.absolute_velocity = movement_direction() * NUDGE_MOVE_SPEED

	timer -= delta
	if timer > 0:
		return

	jab_index += 1
	if jab_index < _total_jabs():
		_jab()
	else:
		state_machine.transition_to(e.move_state)

func _total_jabs() -> int:
	return jab_anims.size() * CYCLES

func _jab() -> void:
	var anim_index := jab_index % jab_anims.size()
	e.rig.play_animation(jab_anims[anim_index])
	# The last jab holds for the recovery time instead of the interval
	timer = recovery_time if jab_index == _total_jabs() - 1 else jab_interval

	var fist: Node2D = e.rig.front_fist if anim_index % 2 == 0 else e.rig.back_fist
	var hitbox = hitbox_scene.instantiate() as Hitbox
	fist.add_child(hitbox)
	hitbox.init(Vector2(0, 0), HITBOX_SIZE, HITBOX_LIFETIME, e, hit)
