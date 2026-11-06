class_name ProjectileState
extends AbilityState

const SPAWN_OFFSET := Vector2(50, -109)

var projectile_ability: ProjectileAbility
var release_timer := 0.0
var recovery_timer := 0.0
var released := false

func init(ability: Ability) -> void:
	projectile_ability = ability as ProjectileAbility

func enter(_msg := {}) -> void:
	e.rig.play_animation(projectile_ability.anim)
	release_timer = projectile_ability.release_delay
	recovery_timer = projectile_ability.recovery_time
	released = false

func physics_update(delta: float) -> void:
	e.absolute_velocity = Vector2.ZERO

	release_timer -= delta
	if release_timer <= 0.0 and not released:
		released = true
		_release()

	recovery_timer -= delta
	if recovery_timer <= 0.0:
		state_machine.transition_to(e.move_state)

func _release() -> void:
	var projectile := projectile_ability.projectile_scene.instantiate() as Projectile
	e.get_parent().add_child(projectile)
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
