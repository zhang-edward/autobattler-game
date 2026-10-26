class_name GrabState
extends MoveBasedState

"""
Grab attempt. Lands through a guard, and resolves as a knockdown rather than a
scripted throw. Recovers slowly, so a whiffed grab is punishable.
"""

const GRAB_TINT := Color(1.0, 0.85, 0.3)
const RECOVERY_TIME := 1.0
const GRAB_SIZE := Vector2(72, 72)
const GRAB_ACTIVE_TIME := 0.15

# Assigned at spawn alongside init() — the throw half of this GrabMove.
var throw_state: ThrowState

var hitbox_scene: PackedScene = preload("res://prefabs/hitbox.tscn")
# Low damage; the knockdown and floor impact carry the hit
var hit: HitConfig = HitConfig.create(15, 180.0, -220.0, true, 0.12, HitConfig.Kind.GRAB)
var recovery_time: float = RECOVERY_TIME

var recovery_timer := 0.0

func init(move: Move) -> void:
	var grab_move := move as GrabMove
	if grab_move == null:
		return
	hit = grab_move.hit
	recovery_time = grab_move.recovery_time

func enter(_msg := {}) -> void:
	e.rig.play_animation("male-rig/grab")
	recovery_timer = recovery_time

func physics_update(delta: float) -> void:
	# Planted for the whole attempt
	e.absolute_velocity = Vector2.ZERO
	
	if e.grabbed_entity != null:
		e.state_machine.transition_to(throw_state)
	else:
		recovery_timer -= delta
		if recovery_timer <= 0.0:
			state_machine.transition_to(e.move_state)
