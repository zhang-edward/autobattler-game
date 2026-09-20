class_name PunchState
extends SkirmishState

const NUDGE_MOVE_SPEED = 50.0
const RECOVERY_TIMES := [0.2, 0.2, 0.4]
const BUFFER_WINDOW := 0.2

@export var move_state: MoveState

var hitbox_scene: PackedScene = preload("res://prefabs/hitbox.tscn")
# The two jabs are ordinary hits; the finisher knocks them down and sends them skidding
var hits: Array[HitConfig] = [
	HitConfig.create(10),
	HitConfig.create(10),
	HitConfig.create(15, 450.0, -350.0, true, 0.12),
]
var combo_index := 0
var recovery_timer = 0
var comboing: bool

func enter(msg := {}) -> void:
	combo_index = msg["combo_index"] if msg.has("combo_index") else 0
	recovery_timer = RECOVERY_TIMES[combo_index]
	comboing = false

	var hitbox = hitbox_scene.instantiate()
	e.add_child(hitbox)
	var hitbox_offset = $HitLocation.position
	hitbox_offset.x *= -1 if e.sprite.flip_h else 1
	hitbox.init(hitbox_offset, Vector2(96, 96), 0.25, e, hits[combo_index])

	# Squash on the lunge
	e.scale = Vector2(1.2, 1)
	var tween = e.get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(e, "scale", Vector2(1, 1), 0.05)

# Intents are written in physics frames, so a one-frame ActionIntent is only
# reliably visible here, not in update()
func physics_update(delta: float) -> void:
	e.absolute_velocity = movement_direction() * NUDGE_MOVE_SPEED

	recovery_timer -= delta

	# Only another punch continues the combo
	var action := e.intent as ActionIntent
	var wants_punch: bool = action != null and action.action == ActionIntent.Action.PUNCH
	if recovery_timer <= BUFFER_WINDOW and wants_punch and combo_index < 2:
		comboing = true

	if recovery_timer <= 0:
		if comboing:
			state_machine.transition_to(self, {"combo_index": combo_index + 1})
		else:
			state_machine.transition_to(move_state)
