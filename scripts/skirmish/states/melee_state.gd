class_name MeleeState
extends AbilityState

var melee_ability: MeleeAbility

func init(ability_: Ability) -> void:
	super.init(ability_)
	melee_ability = ability as MeleeAbility

func _active_entered() -> void:
	phase_timer = melee_ability.hitbox.lifetime
	if melee_ability.velocity != Vector2.ZERO:
		e.absolute_velocity = Vector2(e.facing() * melee_ability.velocity.x, melee_ability.velocity.y)
	e.rig.anim_player.play_section_with_markers(ability.anim, "active", "recovery")

	# Squash on the lunge
	e.scale = Vector2(1.2, 1)
	var tween = e.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(e, "scale", Vector2(1, 1), 0.05)

	e.spawn_hitbox(melee_ability.hitbox)

func _active_update(delta: float) -> void:
	e.absolute_velocity *= 1.0 - melee_ability.friction
	phase_timer -= delta
	if phase_timer <= 0.0:
		_enter_phase(Phase.RECOVERY)
