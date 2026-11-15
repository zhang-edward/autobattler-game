class_name AbilityState
extends SkirmishState

enum Phase {STARTUP, ACTIVE, RECOVERY}

const AGILITY_BASELINE := 5.0
const AGILITY_SCALE := 10.0

var ability: Ability
var phase: Phase
var phase_timer := 0.0
var hit_connected := false

func init(ability_: Ability) -> void:
	ability = ability_

func can_cancel_into(other: Ability) -> bool:
	return other.tier > ability.tier # or \
		# (ability.tier == Ability.Tier.LIGHT and other.tier == Ability.Tier.LIGHT)

func enter(_msg := {}) -> void:
	hit_connected = false
	e.absolute_velocity = Vector2.ZERO
	_enter_phase(Phase.STARTUP)

func physics_update(delta: float) -> void:
	if phase == Phase.ACTIVE:
		_active_update(delta)
		return

	if phase == Phase.RECOVERY and hit_connected:
		var intent := e.brain.get_intent(delta)
		if intent != null and intent.ability != null and can_cancel_into(intent.ability):
			state_machine.transition_to(e.move_state)
			return

	var config := ability.startup if phase == Phase.STARTUP else ability.recovery
	e.absolute_velocity *= 1.0 - config.friction

	phase_timer -= delta
	if phase_timer > 0.0:
		return
	if phase == Phase.STARTUP:
		_enter_phase(Phase.ACTIVE)
	else:
		state_machine.transition_to(e.move_state)

func _enter_phase(next_phase: Phase) -> void:
	phase = next_phase
	match phase:
		Phase.STARTUP:
			if ability.startup.duration <= 0.0:
				_enter_phase(Phase.ACTIVE)
				return
			var duration := ability.startup.duration * (AGILITY_SCALE + AGILITY_BASELINE) / (AGILITY_SCALE + e.entity_config.agility)
			_start_timed_phase(ability.startup, duration, &"", &"active")
		Phase.ACTIVE:
			_active_entered()
		Phase.RECOVERY:
			if ability.recovery.duration <= 0.0:
				state_machine.transition_to(e.move_state)
				return
			var duration := ability.recovery.duration * (AGILITY_SCALE + AGILITY_BASELINE) / (AGILITY_SCALE + e.entity_config.agility)
			_start_timed_phase(ability.recovery, duration, &"recovery", &"")

func _start_timed_phase(config: PhaseConfig, duration: float, start_marker: StringName, end_marker: StringName) -> void:
	phase_timer = duration
	if config.velocity != Vector2.ZERO:
		e.absolute_velocity = Vector2(e.facing() * config.velocity.x, config.velocity.y)
	if ability.anim.is_empty():
		return
	var animation: Animation = e.rig.anim_player.get_animation(ability.anim)
	var start_time: float = 0.0 if start_marker.is_empty() else animation.get_marker_time(start_marker)
	var end_time: float = animation.length if end_marker.is_empty() else animation.get_marker_time(end_marker)
	var speed: float = (end_time - start_time) / duration
	e.rig.anim_player.play_section_with_markers(ability.anim, start_marker, end_marker, -1, speed)

func _spawn_hitbox(config: HitboxConfig) -> void:
	e.spawn_hitbox(config).hit_connected.connect(_handle_hit_connected)

func _handle_hit_connected() -> void:
	hit_connected = true

func _active_entered() -> void:
	pass

func _active_update(_delta: float) -> void:
	pass
