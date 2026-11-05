class_name RapidJabState
extends AbilityState

const CYCLES := 2
const JAB_ANIM := "male-rig/punch_flurry"
# Each jab plays from its marker to the next one. Even indices throw the front fist, odd indices the back fist
const JAB_MARKERS: Array[StringName] = [&"", &"punch_2", &"punch_3", &"punch_4"]

var rapid_jab: RapidJabAbility
var jab_index := 0

func init(ability_: Ability) -> void:
	super.init(ability_)
	rapid_jab = ability as RapidJabAbility

func _active_entered() -> void:
	jab_index = 0
	_jab()

func _active_update(delta: float) -> void:
	phase_timer -= delta
	if phase_timer > 0:
		return

	jab_index += 1
	_jab()
	if jab_index == _total_jabs() - 1:
		_enter_phase(Phase.RECOVERY)

func _total_jabs() -> int:
	return JAB_MARKERS.size() * CYCLES

func _jab() -> void:
	var anim_index := jab_index % JAB_MARKERS.size()
	var end_marker: StringName = JAB_MARKERS[anim_index + 1] if anim_index + 1 < JAB_MARKERS.size() else &""
	e.rig.anim_player.play_section_with_markers(JAB_ANIM, JAB_MARKERS[anim_index], end_marker)
	phase_timer = rapid_jab.jab_interval
	e.spawn_hitbox(rapid_jab.hitbox)
