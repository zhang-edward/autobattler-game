class_name GrabState
extends SkirmishState

"""
Grab attempt. Lands through a guard, and resolves as a knockdown rather than a
scripted throw. Recovers slowly, so a whiffed grab is punishable.
"""

const GRAB_TINT := Color(1.0, 0.85, 0.3)
# Long next to a jab's 0.2
const RECOVERY_TIME := 0.5
const GRAB_SIZE := Vector2(72, 72)
const GRAB_ACTIVE_TIME := 0.15

@export var move_state: MoveState

var hitbox_scene: PackedScene = preload("res://prefabs/hitbox.tscn")
# Low damage; the knockdown and floor impact carry the hit
var hit: HitConfig = HitConfig.create(5, 180.0, -220.0, true, 0.12, HitConfig.Kind.GRAB)

var recovery_timer := 0.0

func enter(_msg := {}) -> void:
	recovery_timer = RECOVERY_TIME

	var hitbox = hitbox_scene.instantiate()
	e.add_child(hitbox)
	var hitbox_offset: Vector2 = $GrabLocation.position
	hitbox_offset.x *= -1 if e.sprite.flip_h else 1
	hitbox.init(hitbox_offset, GRAB_SIZE, GRAB_ACTIVE_TIME, e, hit)

	e.sprite.modulate = GRAB_TINT

func exit() -> void:
	e.sprite.modulate = Color.WHITE

func physics_update(delta: float) -> void:
	# Planted for the whole attempt
	e.absolute_velocity = Vector2.ZERO

	recovery_timer -= delta
	if recovery_timer <= 0.0:
		state_machine.transition_to(move_state)
