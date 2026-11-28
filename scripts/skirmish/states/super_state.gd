class_name SuperState
extends SkirmishState

## A hero's super move. Each power type has one (names in Hero.SUPER_NAMES):
##   Elemental       Nova Beam: a huge, fast energy beam that launches
##   Physical        Rush Combo: a lunging rush that launches on contact
##   Psychic         Mind Surge: heals the team and blasts the opponent from anywhere
##   Transformation  Power Up: hits harder, attacks faster and takes less damage for a while
## Attack damage scales with Skill. The hero has super armor while it plays:
## hits still deal damage but don't interrupt it.

const PROJECTILE_SCENE := preload("res://prefabs/projectile.tscn")
const SPAWN_OFFSET := Vector2(60.0, -109.0)
const SUPER_COLOR := Color(1.0, 0.8, 0.25)

# TUNE: base damage of each attacking super, before Skill scaling.
const NOVA_BEAM_DAMAGE := 40
const NOVA_BEAM_SIZE := Vector2(240.0, 120.0)
const NOVA_BEAM_SPEED := 1100.0
const NOVA_BEAM_LIFESPAN := 1.6
const RUSH_DAMAGE := 45
const RUSH_SPEED := 1400.0
const RUSH_SECONDS := 0.35
const MIND_SURGE_DAMAGE := 25
# TUNE: share of the team's max health Mind Surge heals.
const MIND_SURGE_HEAL := 0.12
# TUNE: Power Up lasts this long, with these multipliers.
const POWER_UP_SECONDS := 8.0
const POWER_UP_DAMAGE := 1.4
const POWER_UP_SPEED := 1.25
const POWER_UP_DAMAGE_TAKEN := 0.7

# How long the hero is locked in the super, by power type.
const DURATIONS := {
	Hero.PowerType.ELEMENTAL: 0.6,
	Hero.PowerType.PHYSICAL: RUSH_SECONDS + 0.3,
	Hero.PowerType.PSYCHIC: 0.6,
	Hero.PowerType.TRANSFORMATION: 0.5,
}

var _time_left := 0.0
var _rushing := false


func enter(_msg := {}) -> void:
	e.absolute_velocity = Vector2.ZERO
	_rushing = false
	var target := _target()
	if target != null:
		e.rig_wrapper.scale.x = -1.0 if target.position.x < e.position.x else 1.0
	var power_type := e.entity_config.power_type
	_time_left = DURATIONS[power_type]
	match power_type:
		Hero.PowerType.ELEMENTAL:
			_nova_beam()
		Hero.PowerType.PHYSICAL:
			_rush_combo()
		Hero.PowerType.PSYCHIC:
			_mind_surge(target)
		Hero.PowerType.TRANSFORMATION:
			_power_up()


func physics_update(delta: float) -> void:
	_time_left -= delta
	if _rushing and _time_left < DURATIONS[Hero.PowerType.PHYSICAL] - RUSH_SECONDS:
		_rushing = false
	if not _rushing:
		e.absolute_velocity *= 0.85
	if _time_left <= 0.0:
		state_machine.transition_to(e.move_state)


func _target() -> SkirmishEntity:
	if e.skirmish == null:
		return null
	var target := e.skirmish.active_for(Skirmish.other_side(e.side))
	if target == null or not is_instance_valid(target) or target.is_dead or not target.is_active:
		return null
	return target


func _nova_beam() -> void:
	e.rig.play_animation("male-rig/punch_big")
	var hit := HitConfig.create(NOVA_BEAM_DAMAGE, Vector2(500.0, -350.0), true, 0.15, HitConfig.Kind.SUPER)
	var beam := PROJECTILE_SCENE.instantiate() as Projectile
	e.get_parent().add_child(beam)
	beam.init(e.position + Vector2(e.facing() * SPAWN_OFFSET.x, 0.0), SPAWN_OFFSET.y, e.facing(),
		NOVA_BEAM_SPEED, NOVA_BEAM_LIFESPAN, NOVA_BEAM_SIZE, e, hit)
	var visual := beam.get_node("Polygon2D") as Polygon2D
	# The projectile's diamond is 30px across
	visual.scale = NOVA_BEAM_SIZE / 30.0
	visual.color = SUPER_COLOR
	ScreenShake.shake_horizontal(10, 0.2, 12)


func _rush_combo() -> void:
	e.rig.play_animation("male-rig/dash_forward")
	_rushing = true
	e.absolute_velocity = Vector2(e.facing() * RUSH_SPEED, 0.0)
	var config := HitboxConfig.new()
	config.offset = Vector2(80.0, -100.0)
	config.size = Vector2(160.0, 140.0)
	config.lifetime = RUSH_SECONDS
	config.hit = HitConfig.create(RUSH_DAMAGE, Vector2(600.0, -400.0), true, 0.15, HitConfig.Kind.SUPER)
	e.spawn_hitbox(config)


func _mind_surge(target: SkirmishEntity) -> void:
	e.rig.play_animation("male-rig/frontarm_jab")
	e.skirmish.heal_team(e, roundi(e.skirmish.health_for(e.side).max_value * MIND_SURGE_HEAL))
	if target == null:
		return
	var hit := HitConfig.create(MIND_SURGE_DAMAGE, Vector2(300.0, -300.0), true, 0.15, HitConfig.Kind.SUPER)
	if target.take_hit(hit, e):
		var effect := EffectConfig.new()
		effect.pos = target.global_position + Vector2(0.0, -110.0)
		effect.anim = HitEffectRegistry.HIT_NEW
		effect.dir = Vector2(e.facing(), 0.0)
		effect.angle_range_rad = Hitbox.EFFECT_ANGLE_RANGE
		EffectManager.spawn_effect(effect)


func _power_up() -> void:
	e.rig.play_animation("male-rig/idle")
	e.entity_config.add_boost("power_up", POWER_UP_SECONDS, POWER_UP_DAMAGE, POWER_UP_SPEED, POWER_UP_DAMAGE_TAKEN)
	ScreenShake.shake_horizontal(8, 0.3, 10)
