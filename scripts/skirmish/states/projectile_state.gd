class_name ProjectileState
extends AbilityState

const SPAWN_OFFSET := Vector2(50, -109)

var projectile_ability: ProjectileAbility

func init(ability_: Ability) -> void:
	super.init(ability_)
	projectile_ability = ability as ProjectileAbility

# Projectiles are thrown from range, so their recovery can't be cancelled
# into a follow-up: it always plays out, which is the window to punish them.
func can_cancel_into(_other: Ability) -> bool:
	return false

func _active_entered() -> void:
	phase_timer = projectile_ability.active_duration
	if projectile_ability.velocity != Vector2.ZERO:
		e.absolute_velocity = Vector2(e.facing() * projectile_ability.velocity.x, projectile_ability.velocity.y)
	e.rig.anim_player.play_section_with_markers(ability.anim, "active", "recovery")
	_release()

func _active_update(delta: float) -> void:
	e.absolute_velocity *= 1.0 - projectile_ability.friction
	phase_timer -= delta
	if phase_timer <= 0.0:
		_enter_phase(Phase.RECOVERY)

func _release() -> void:
	var projectile := projectile_ability.projectile_scene.instantiate() as Projectile
	e.get_parent().add_child(projectile)
	e.active_projectile = projectile
	projectile.init(
		e.position + Vector2(e.facing() * SPAWN_OFFSET.x, 0),
		SPAWN_OFFSET.y,
		e.facing(),
		projectile_ability.speed,
		projectile_ability.lifespan,
		projectile_ability.hitbox_size,
		e,
		projectile_ability.hit
	)
