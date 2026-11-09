class_name RagdollState
extends SkirmishState

"""
Knocked-down entity: a physics object that tumbles across the floor plane.

Not a RigidBody2D on purpose. Screen-Y is a depth axis here (squashed by
IsometryUtils.DEPTH_SCALE) and altitude is faked in SkirmishEntity.z, so Godot's 2D
gravity would pull bodies toward the front of the screen instead of down. We integrate
the three axes ourselves and let move_and_slide() handle only the floor-plane collisions.
"""

enum Phase {AIRBORNE, SLIDING, DOWNED}

@export var move_state: MoveState

@export_group("Physics")
# Ragdolls fall faster than the entity gravity, so hangtime doesn't drag
@export var gravity_scale := 1.0
# Fraction of altitude speed kept per floor bounce
@export var floor_restitution := 0.65
# Fraction of floor-plane speed kept when hitting the floor
@export var floor_skid_retention := 0.8
@export var air_drag := 40.0
@export var ground_friction := 400.0
# Below this altitude speed, stop bouncing and start sliding
@export var min_bounce_speed := 300.0
@export var wall_restitution := 0.6
@export var min_wall_bounce_speed := 200.0
@export var wall_damage_per_speed := 0.02
# Below this floor speed, stop sliding and lie down
@export var settle_speed := 40.0

@export_group("Timing")
@export var downed_seconds := 0.5
# Seconds of hitstop per unit of sideways speed when hitting a side wall
@export var wall_hitstop_per_speed := 0.0004

const ANIM_THROWN := "male-rig/is_thrown"
const ANIM_SLAM := "male-rig/ground_slam"
const ANIM_WALL_SLAM := "male-rig/wall_slam"
const ANIM_BOUNCE := "male-rig/bounce"
const ANIM_CRUMPLE := "male-rig/ground_crumple"
# How long the slam pose shows after an impact that bounces, before switching to ANIM_BOUNCE
const BOUNCE_ANIM_DELAY := 0.12
const MAX_WALL_SLAM_HITSTOP = 0.4
const RAGDOLL_ESCAPE_HEALTH_FRACTION := 0.4
const RESILIENCE_SCALE := 10.0
const ESCAPE_BLINK_SECONDS := 0.08

var phase: Phase
var downed_timer := 0.0
# > 0 while a bounce animation is pending. Driven by the state, not the animation player,
# so a long or looping slam animation can't hold it up.
var _bounce_anim_timer := 0.0
var _wall_slam_animation_resume_tween: Tween
var launched_by: SkirmishEntity
var ragdoll_damage := 0
var has_escaped_ragdoll := false
var _escape_blink_tween: Tween

func enter(msg := {}) -> void:
	ragdoll_damage = 0
	has_escaped_ragdoll = false
	relaunch(msg.get("impulse", Vector2.ZERO), msg.get("launch", 0.0))
	launched_by = msg["launched_by"]

# Applied on a fresh knockdown, and again on every hit that lands mid-ragdoll
func relaunch(impulse: Vector2, launch: float) -> void:
	e.absolute_velocity = impulse
	e.z_velocity = launch
	# Reset hurtbox if previously lying down
	if not e.is_dead and not has_escaped_ragdoll:
		e.hurtbox.set_deferred("monitorable", true)
	_enter_phase(Phase.AIRBORNE)
	_bounce_anim_timer = 0.0
	if _wall_slam_animation_resume_tween != null:
		_wall_slam_animation_resume_tween.kill()
	e.rig.play_animation(ANIM_THROWN)

func physics_update(delta: float) -> void:
	match phase:
		Phase.AIRBORNE:
			if _bounce_anim_timer > 0.0:
				_bounce_anim_timer -= delta
				if _bounce_anim_timer <= 0.0:
					e.rig.play_animation(ANIM_BOUNCE)
			e.z_velocity += SkirmishEntity.GRAVITY * gravity_scale * delta
			e.z += e.z_velocity * delta
			e.absolute_velocity = e.absolute_velocity.move_toward(Vector2.ZERO, air_drag * delta)
			_bounce_off_side_walls()
			if e.z >= 0.0 and e.z_velocity > 0.0:
				_land()
		Phase.SLIDING:
			e.absolute_velocity = e.absolute_velocity.move_toward(Vector2.ZERO, ground_friction * delta)
			if e.absolute_velocity.length() <= settle_speed:
				e.absolute_velocity = Vector2.ZERO
				_enter_phase(Phase.DOWNED)
			_bounce_off_side_walls()
		_:
			e.absolute_velocity = Vector2.ZERO

func update(delta: float) -> void:
	if phase == Phase.DOWNED:
		downed_timer -= delta
		if downed_timer <= 0.0:
			state_machine.transition_to(move_state)

func _enter_phase(next_phase: Phase) -> void:
	phase = next_phase
	match phase:
		Phase.DOWNED:
			e.rig.play_animation(ANIM_CRUMPLE)
			downed_timer = downed_seconds
			# Downed entities are safe until they're back in play
			# e.hurtbox.set_deferred("monitorable", false)
			if e.is_dead:
				e.despawn()

func _bounce_off_side_walls() -> void:
	# usually this is only 1 collision, but can be 2 collisions in the case of a corner
	for i in e.get_slide_collision_count():
		var wall_normal := e.get_slide_collision(i).get_normal()
		var is_side_wall := absf(wall_normal.x) > 0.5
		var is_moving_into_wall := signf(e.absolute_velocity.x) == -signf(wall_normal.x)
		if not is_side_wall or not is_moving_into_wall:
			continue
		var impact_speed := absf(e.absolute_velocity.x)
		if impact_speed < min_wall_bounce_speed:
			return
		e.absolute_velocity.x *= -wall_restitution

		# Hold the wall slam animation's first frame for the hitstop. Faster impacts freeze longer.
		e.rig_wrapper.scale.x = signf(wall_normal.x) # set flipX so slam animation plays in the right direction
		e.rig.play_animation(ANIM_WALL_SLAM)
		e.rig.anim_player.seek(0.0, true)
		e.rig.anim_player.pause()
		_bounce_anim_timer = 0.0
		var hitstop := minf(MAX_WALL_SLAM_HITSTOP, impact_speed * wall_hitstop_per_speed) # More speed = more hitstop
		Hitstop.freeze([e], hitstop)
		# Resume wall slam animation (from "bounce_off" frame) right after hitstop
		_wall_slam_animation_resume_tween = create_tween()
		_wall_slam_animation_resume_tween.tween_callback(
			e.rig.anim_player.play_section_with_markers.bind(ANIM_WALL_SLAM, &"bounce_off")
		).set_delay(hitstop)
		ScreenShake.shake_horizontal(12, 0.1, 12)

		# Wall impact damage calculation
		if not e.is_dead:
			var damage := roundi(impact_speed * wall_damage_per_speed)
			if launched_by != null and is_instance_valid(launched_by):
				launched_by.entity_config.damage_dealt += damage
			e.healthbar.value -= damage
			if e.entity_config != null:
				e.entity_config.curr_health = int(e.healthbar.value)
			if e.healthbar.value <= 0:
				e.is_dead = true
				e.healthbar.hide()
				e.died.emit()
			add_ragdoll_damage(damage)
		return

# Once the entity takes enough damage while ragdolled, it can't be hit again until it gets up.
# Higher "resilience" stat => lowers damage threshold.
func add_ragdoll_damage(damage: int) -> void:
	ragdoll_damage += damage
	if has_escaped_ragdoll or e.is_dead:
		return
	var threshold := e.entity_config.get_max_health() * RAGDOLL_ESCAPE_HEALTH_FRACTION \
		* RESILIENCE_SCALE / (RESILIENCE_SCALE + e.entity_config.resilience)
	if ragdoll_damage < threshold:
		return
	has_escaped_ragdoll = true
	e.hurtbox.set_deferred("monitorable", false)
	_escape_blink_tween = create_tween().set_loops()
	_escape_blink_tween.tween_property(e.rig, "modulate:a", 0.3, ESCAPE_BLINK_SECONDS)
	_escape_blink_tween.tween_property(e.rig, "modulate:a", 1.0, ESCAPE_BLINK_SECONDS)

func _land() -> void:
	e.z = 0.0

	if e.is_dead:
		state_machine.transition_to(e.death_state)
		return

	if e.z_velocity >= min_bounce_speed:
		e.rig.play_animation(ANIM_SLAM)
		e.z_velocity *= -floor_restitution
		e.absolute_velocity *= floor_skid_retention
		# The bounce launch happens this same frame, so show the slam for a beat
		# before physics_update switches to the bounce animation
		_bounce_anim_timer = BOUNCE_ANIM_DELAY
		Hitstop.freeze([e], 0.04)
		return

	# Final impact: nothing left to bounce, so the body crumples instead of slamming
	e.rig.play_animation(ANIM_CRUMPLE)
	_bounce_anim_timer = 0.0
	e.z_velocity = 0.0
	_enter_phase(Phase.SLIDING)

func exit() -> void:
	_bounce_anim_timer = 0.0
	if _escape_blink_tween != null:
		_escape_blink_tween.kill()
		e.rig.modulate.a = 1.0
	if _wall_slam_animation_resume_tween != null:
		_wall_slam_animation_resume_tween.kill()
	e.absolute_velocity = Vector2.ZERO
	e.z = 0.0
	e.z_velocity = 0.0
	e.hurtbox.set_deferred("monitorable", true)
