class_name SkirmishEntity
extends CharacterBody2D

# 2.5D beat-em-up entity. Screen Y is a depth axis (squashed by IsometryUtils.DEPTH_SCALE)
# and altitude is faked in `z`, so gravity is integrated by the states, not the physics engine.

signal died
signal took_hit(combo_hits: int, is_punish: bool)
signal combo_ended
signal character_moment_rolled

const GRAVITY := 980.0

# The final hit of a round knocks the hero down with at least this much pop
const DEATH_LAUNCH := -260.0
const JUGGLE_LAUNCH := -300.0
const DEATH_KNOCKBACK_MIN := 260.0
# Max depth-axis spread on a knockdown
const LAUNCH_Y_SPREAD := 0.25
const DAMAGE_NUMBER_OFFSET := Vector2(0.0, -160.0)

const SIDE_A_LAYER_INDEX = 9
const SIDE_B_LAYER_INDEX = 10
const SIDE_WALL_LAYER_INDEX = 12
# Both teams use the same rig, so side B is tinted to tell them apart.
const SIDE_B_TINT := Color(0.6, 0.75, 1.0)
# Glow while a boost (Power Up, Strike Boost) is active
const BOOST_GLOW := Color(1.35, 1.2, 0.7)
# Stronger gold glow while a super move is playing
const SUPER_GLOW := Color(1.8, 1.5, 0.5)
const BLOCKED_SUPER_COLOR := Color(0.45, 0.7, 1.0)
# Boost icons sit above the head, spaced this far apart
const BOOST_ICON_HEIGHT := -290.0
const BOOST_ICON_SPACING := 42.0

@onready var rig_wrapper: Sprite2D = $RigWrapper
@onready var debug_name_label: Label = $DebugNameLabel

@export var hitbox_scene: PackedScene
@export var move_speed := 125.0
@export var rig: SkirmishEntityRig
@export var shadow: Sprite2D
@export var hurtbox: Hurtbox
@export var state_machine: StateMachine
@export var hurt_state: HurtState
@export var death_state: DeathState
@export var downed_state: DownedState
@export var move_state: MoveState
@export var ragdoll_state: RagdollState
@export var tag_out_state: TagOutState
@export var tag_in_state: TagInState
@export var block_state: BlockState
@export var dash_state: DashState
@export var character_moment_state: CharacterMomentState
@export var brain: Brain:
	set(value):
		brain = value
		brain.entity = self

var entity_config: EntityConfig
## Which team this entity fights for.
var side: Skirmish.Side = Skirmish.Side.A
var is_active := true
var skirmish: Skirmish
var ability_to_state: Dictionary = {}
## Created in code alongside the move states (see configure_from_entity_config).
var super_state: SuperState

var hitstop_scale := 1.0:
	set(value):
		hitstop_scale = value
		if state_machine != null:
			state_machine.time_scale = value

var absolute_velocity := Vector2.ZERO

# Altitude: negative is up, 0 is the floor. Rendered by offsetting the sprite.
var z := 0.0
var z_velocity := 0.0
## Knocked out by the hit that emptied the team's health. Only ever the last
## hero standing at the end of a round.
var is_dead := false
var combo_hits := 0


var _shadow_base_scale: Vector2
var _boost_icons := {}
var _boost_icon_root: Node2D

func facing() -> float:
	var f := signf(rig_wrapper.scale.x)
	return f if f != 0.0 else 1.0

func _ready() -> void:
	_shadow_base_scale = shadow.scale
	state_machine.transitioned.connect(_on_state_transitioned, CONNECT_DEFERRED)
	_boost_icon_root = Node2D.new()
	_boost_icon_root.z_index = 40
	add_child(_boost_icon_root)

func _on_state_transitioned(_state_name: String) -> void:
	if combo_hits == 0 or state_machine.state == hurt_state or state_machine.state == ragdoll_state:
		return
	combo_hits = 0
	combo_ended.emit()

func spawn_hitbox(config: HitboxConfig) -> Hitbox:
	var hitbox = hitbox_scene.instantiate() as Hitbox
	rig_wrapper.add_child(hitbox)
	hitbox.init(config.offset, config.size, config.lifetime, self, config.hit)
	return hitbox

func configure_from_entity_config(ec: EntityConfig, side_: Skirmish.Side) -> void:
	entity_config = ec
	side = side_
	var layer_index = SIDE_A_LAYER_INDEX if side == Skirmish.Side.A else SIDE_B_LAYER_INDEX
	set_collision_layer_value(layer_index, true)
	if side == Skirmish.Side.B:
		rig.modulate = SIDE_B_TINT
	debug_name_label.text = entity_config.entity_name
	_build_move_map()
	super_state = SuperState.new()
	super_state.name = "SuperState"
	state_machine.add_child(super_state)
	super_state.state_machine = state_machine

# Tag entrance setup: visible and ticking so TagInState runs, but the hurtbox
# stays dark until TagInState completes into set_active(true).
func begin_tag_in(destination: Vector2, entry_side := 0.0) -> void:
	is_active = true
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	state_machine.transition_to(tag_in_state, {"destination": destination, "entry_side": entry_side})

func begin_tag_out() -> void:
	state_machine.transition_to(tag_out_state)

func set_active(value: bool) -> void:
	is_active = value
	visible = value
	# DISABLED freezes the whole subtree (entity, state machine, brain, rig anims)
	process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED
	if hurtbox != null:
		hurtbox.set_deferred("monitorable", value)
		hurtbox.set_deferred("monitoring", value)
	if not value:
		absolute_velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not is_active or brain == null:
		return
	if entity_config != null:
		entity_config.tick_boosts(delta * hitstop_scale)
	velocity = IsometryUtils.scale_velocity(absolute_velocity) * hitstop_scale
	move_and_slide()

func _process(_delta: float) -> void:
	# Altitude plus shift that keeps the sprite's center planted when it spins
	rig_wrapper.position.y = z
	shadow.scale = _shadow_base_scale * IsometryUtils.scale_shadow_from(z)
	if super_state != null and state_machine.state == super_state:
		rig_wrapper.modulate = SUPER_GLOW
	elif entity_config != null and entity_config.is_boosted():
		rig_wrapper.modulate = BOOST_GLOW
	else:
		rig_wrapper.modulate = Color.WHITE
	_update_boost_icons()


# One icon per active boost, centred over the head, following the hero into the air.
func _update_boost_icons() -> void:
	if entity_config == null or _boost_icon_root == null:
		return
	var active := entity_config.boost_names()
	for boost_name in _boost_icons.keys():
		if not active.has(boost_name):
			_boost_icons[boost_name].queue_free()
			_boost_icons.erase(boost_name)
	for boost_name in active:
		if not _boost_icons.has(boost_name):
			var icon := BoostIcon.new()
			icon.boost_name = boost_name
			_boost_icon_root.add_child(icon)
			_boost_icons[boost_name] = icon
		(_boost_icons[boost_name] as BoostIcon).fraction = entity_config.boost_fraction(boost_name)
	var names := _boost_icons.keys()
	for i in names.size():
		_boost_icons[names[i]].position.x = (i - (names.size() - 1) * 0.5) * BOOST_ICON_SPACING
	_boost_icon_root.position.y = BOOST_ICON_HEIGHT + z

func _build_move_map() -> void:
	ability_to_state.clear()
	if entity_config == null:
		return
	for ability in entity_config.abilities:
		if ability == null or ability.state_scene == null:
			continue
		var instance := ability.state_scene.instantiate() as AbilityState
		if instance == null:
			continue
		state_machine.add_child(instance)
		# StateMachine._ready already ran, so wire manually.
		instance.state_machine = state_machine
		instance.init(ability)
		ability_to_state[ability] = instance

# Whether this entity is in a state that can block. Mid-attack, stunned or
# knocked down heroes can't.
func _can_block() -> bool:
	var state := state_machine.state
	return not (
		state == death_state
		or state == tag_in_state
		or state == tag_out_state
		or state == ragdoll_state
		or state == hurt_state
		or state == downed_state
		or state == super_state
		or state is AbilityState
	)

## Whether this hero is free to tag out: anything but being hit, knocked
## down, blocking, or already tagging. A tag cuts an attack or dash short.
func can_tag_out() -> bool:
	var state := state_machine.state
	return not (
		state == death_state
		or state == tag_in_state
		or state == tag_out_state
		or state == ragdoll_state
		or state == hurt_state
		or state == downed_state
		or state == block_state
		or state == super_state
	)

## Whether this hero can start their super right now.
func can_start_super() -> bool:
	var state := state_machine.state
	return is_active and not is_dead and (state == move_state or state == dash_state)

## The projectile this hero has on screen, if any. One at a time.
var active_projectile: Projectile

func has_projectile_out() -> bool:
	return active_projectile != null and is_instance_valid(active_projectile) \
		and not active_projectile.is_queued_for_deletion()

## Down after the team's block bar broke: helpless and open to hits.
func is_guard_broken() -> bool:
	return state_machine.state == downed_state

# Rolls whether an incoming hit is blocked. Needs the team's block bar to be
# up. A hero already in blockstun keeps blocking the rest of the string.
func _rolls_block() -> bool:
	var bar: BlockBar = skirmish.block_bar_for(side) if skirmish != null else null
	if bar == null or not bar.can_block():
		return false
	if state_machine.state == block_state:
		return true
	return _can_block() and randf() < CombatStats.block_chance(entity_config.agility)

## Takes `damage` off the team's health and adds it to the box score.
## Returns true if it emptied the team's health and knocked this hero out.
func apply_damage(damage: int, source: SkirmishEntity) -> bool:
	if source != null and is_instance_valid(source):
		source.entity_config.damage_dealt += damage
		if skirmish != null:
			skirmish.add_meter(source.side, damage * SuperMeter.PER_DAMAGE_DEALT)
	entity_config.damage_taken += damage
	if skirmish != null:
		skirmish.add_meter(side, damage * SuperMeter.PER_DAMAGE_TAKEN)
	EffectManager.spawn_damage_number(global_position + Vector2(0.0, z) + DAMAGE_NUMBER_OFFSET, damage)
	if skirmish == null or not skirmish.deal_team_damage(side, damage):
		return false
	is_dead = true
	died.emit()
	return true

# Returns whether or not the hit connected
func take_hit(hit: HitConfig, source: SkirmishEntity) -> bool:
	if is_dead or not is_active:
		return false
	# Once a round is decided, nothing more lands
	if skirmish != null and skirmish.is_finished():
		return false
	# If hitbox owner somehow transitioned into a state which invalidates its hitbox, we don't need to process this hit anymore
	if source == null or not is_instance_valid(source) or source.is_dead or not source.is_active:
		return false
	if source.state_machine != null and hit.kind != HitConfig.Kind.PROJECTILE:
		var source_state: State = source.state_machine.state
		if source_state == source.ragdoll_state or source_state == source.death_state:
			return false

	var dir := Vector2(signf(position.x - source.position.x), 0.0)
	var damage := maxi(roundi(CombatStats.hit_damage(hit, source.entity_config) * entity_config.damage_taken_multiplier()), 1)
	var frozen: Array = [self] if hit.kind != HitConfig.Kind.STRIKE else [source, self]
	# Super armor: hits during a super still hurt, but don't interrupt it
	var armored := state_machine.state == super_state

	# Blocked: no health damage, the team's block bar takes it instead. If
	# that empties the bar, the guard breaks and the hero goes down.
	if not armored and _rolls_block():
		var drain := CombatStats.block_drain(damage, entity_config.defense) * entity_config.block_drain_multiplier()
		skirmish.add_meter(side, drain * SuperMeter.PER_BLOCK_DRAIN)
		var broke: bool = skirmish.block_bar_for(side).absorb(drain)
		if broke:
			state_machine.transition_to(downed_state)
			ScreenShake.shake_horizontal(14, 0.2, 12)
		else:
			state_machine.transition_to(block_state, {"dir": dir, "hitstun": hit.base_hitstun, "pushback": hit.pushback})
		Hitstop.freeze(frozen, hit.hitstop)
		if hit.kind == HitConfig.Kind.SUPER:
			# Make it obvious the super was stopped, not that it missed
			EffectManager.spawn_popup(global_position + Vector2(0.0, z) + DAMAGE_NUMBER_OFFSET, "BLOCKED!", BLOCKED_SUPER_COLOR)
		took_hit.emit(combo_hits, false)
		return true

	var in_combo := state_machine.state == hurt_state or state_machine.state == ragdoll_state or is_guard_broken()
	var is_punish := state_machine.state is AbilityState \
		and (state_machine.state as AbilityState).phase == AbilityState.Phase.RECOVERY

	combo_hits = combo_hits + 1 if in_combo else 1
	var knocked_out := apply_damage(damage, source)

	var launch_x := hit.launch.x * CombatStats.launch_multiplier(source.entity_config.strength)
	if knocked_out:
		# The round's final hit: send them flying, and they stay down
		var launch_y := hit.launch.y if hit.is_launcher and hit.launch.y != 0.0 else DEATH_LAUNCH
		launch_entity(dir * maxf(launch_x, DEATH_KNOCKBACK_MIN), launch_y, source)
		ScreenShake.shake_horizontal(16, 0.25, 12)
	elif is_guard_broken() or armored:
		pass # The damage lands, but the hero isn't knocked out of what they're doing
	elif hit.is_launcher or state_machine.state == ragdoll_state:
		launch_entity(dir * launch_x, hit.launch.y if hit.launch.y != 0.0 else JUGGLE_LAUNCH, source)
		ragdoll_state.add_ragdoll_damage(damage)
	else:
		state_machine.transition_to(hurt_state, {"dir": dir, "hitstun": hit.base_hitstun, "pushback": hit.pushback})

	Hitstop.freeze(frozen, hit.hitstop)

	if hit.is_launcher:
		ScreenShake.shake_horizontal(12, 0.1, 12)

	took_hit.emit(combo_hits, is_punish)
	return true

func launch_entity(impulse: Vector2, launch: float, launched_by: SkirmishEntity) -> void:
	impulse.y += impulse.length() * randf_range(-LAUNCH_Y_SPREAD, LAUNCH_Y_SPREAD)

	if state_machine.state == ragdoll_state:
		# Already ragdolling: relaunch in place rather than re-entering the state,
		# which would reset the altitude we're trying to add to
		ragdoll_state.relaunch(impulse, launch)
		ragdoll_state.launched_by = launched_by
	else:
		state_machine.transition_to(ragdoll_state, {"impulse": impulse, "launch": launch, "launched_by": launched_by})

func despawn() -> void:
	var tween := create_tween()
	tween.tween_property(rig, "modulate:a", 0.0, 0.4)
	tween.parallel().tween_property(shadow, "modulate:a", 0.0, 0.4)
	tween.tween_callback(set_active.bind(false))
