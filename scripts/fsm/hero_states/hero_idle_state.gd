class_name HeroIdleState
extends HeroState

@export var hero_move_state: HeroState

func enter(_msg := {}) -> void:
	hero.velocity = Vector2.ZERO
