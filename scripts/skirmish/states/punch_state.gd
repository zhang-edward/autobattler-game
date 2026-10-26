class_name PunchState
extends AbilityState

const NUDGE_MOVE_SPEED = 50.0
const RECOVERY_TIMES := [0.4, 0.4, 0.4]
const BUFFER_WINDOW := 0.2

var hitbox_scene: PackedScene = preload("res://prefabs/hitbox.tscn")
# The two jabs are ordinary hits; the finisher knocks them down and sends them skidding
var hits: Array[HitConfig] = [
	HitConfig.create(20),
	HitConfig.create(20),
	HitConfig.create(30, 450.0, -350.0, true, 0.12),
]
var combo_anims = [
	"male-rig/frontarm_jab_instant",
	"male-rig/backarm_jab_instant",
	"male-rig/backarm_uppercut_instant"
]
var recovery_times: Array = RECOVERY_TIMES
var buffer_window: float = BUFFER_WINDOW
var combo_index := 0
var recovery_timer = 0
var comboing: bool

func init(ability: Ability) -> void:
	var punch_move := ability as PunchAbility
	if punch_move == null:
		return
	hits = punch_move.hits
	combo_anims = punch_move.combo_anims
	recovery_times = punch_move.recovery_times
	buffer_window = punch_move.buffer_window

func enter(msg := {}) -> void:
	combo_index = msg["combo_index"] if msg.has("combo_index") else 0
	recovery_timer = recovery_times[combo_index]
	comboing = false

	var combo_anim: String = combo_anims[combo_index]
	e.rig.play_animation(combo_anim)

	# Squash on the lunge
	e.scale = Vector2(1.2, 1)
	var tween = e.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(e, "scale", Vector2(1, 1), 0.05)

# Intents are written in physics frames, so a one-frame move intent is only
# reliably visible here, not in update()
func physics_update(delta: float) -> void:
	e.absolute_velocity = movement_direction() * NUDGE_MOVE_SPEED

	recovery_timer -= delta

	# Only another punch continues the combo
	var wants_punch: bool = e.intent != null and e.intent.ability is PunchAbility
	if recovery_timer <= BUFFER_WINDOW and wants_punch and combo_index < 2:
		comboing = true

	if recovery_timer <= 0:
		if comboing:
			state_machine.transition_to(self, {"combo_index": combo_index + 1})
		else:
			state_machine.transition_to(e.move_state)
