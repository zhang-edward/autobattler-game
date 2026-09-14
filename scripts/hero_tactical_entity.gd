class_name HeroTacticalEntity
extends TacticalEntity

@onready var button = $Button as Button
@export var hero_move_state: HeroState
@export var hero_save_civilian_state: HeroState
@onready var state_machine = $HeroTacStateMachine as StateMachine

func _ready():
	super._ready()
	button.pressed.connect(select)
	
func select():
	game.select_hero_entity(self)
	sprite.self_modulate = Color(1, 1, 0)

func deselect():
	sprite.self_modulate = Color(0, 1, 0)

func configure_from_entity_config(ec: EntityConfig):
	super.configure_from_entity_config(ec)
	sprite.self_modulate = Color(0, 1, 0)

func collide_area(area: Area2D):
	var parent = area.get_parent() as TacticalEntity
	if parent is VillainTacticalEntity:
		print("Go to skirmish screen!")
	elif parent is CivilianTacticalEntity:
		state_machine.transition_to(hero_save_civilian_state)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if game.selected_hero == self:
			state_machine.transition_to(hero_move_state, { "target_pos": game.get_global_mouse_position() })
