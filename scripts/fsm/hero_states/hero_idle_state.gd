class_name HeroIdleState
extends HeroState

@export var hero_move_state: HeroState

func enter(_msg := {}) -> void:
	hero.velocity = Vector2.ZERO

func handle_input(event: InputEvent) -> void:
	var game = hero.game as TacticalEncounter
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if game.selected_hero == hero:
			state_machine.transition_to(hero_move_state, { "target_pos": game.get_global_mouse_position() })
