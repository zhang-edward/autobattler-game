class_name HeroTacticalEntity
extends TacticalEntity

@onready var button = $Button as Button
@export var hero_move_state: HeroState
@onready var state_machine = $HeroTacStateMachine as StateMachine

static var SAVE_CIV_EXP = 5
static var ASSIST_EXP = 10
static var DEFEAT_VILLAIN_EXP = 50

func _ready():
	super._ready()
	button.pressed.connect(select)
	
func select():
	game.select_hero_entity(self)
	sprite.self_modulate = Color(1, 1, 0)

func deselect():
	sprite.self_modulate = Color(0, 1, 0)

func defeat():
	game.hero_entities.erase(self)
	super.defeat()

func capture():
	game.hero_entities.erase(self)
	GameVariables.captured_heroes.append(entity_config)
	queue_free()
	
func add_assist():
	entity_config.num_assists += 1
	entity_config.gained_exp += ASSIST_EXP

func add_villain_defeated(villain_name: String):
	entity_config.defeated_villain_names.append(villain_name)
	entity_config.gained_exp += DEFEAT_VILLAIN_EXP

func add_saved_civilian():
	entity_config.num_civs_saved += 1
	entity_config.gained_exp += SAVE_CIV_EXP

func configure_from_entity_config(ec: EntityConfig):
	super.configure_from_entity_config(ec)
	sprite.self_modulate = Color(0, 1, 0)

func collide_area(area: Area2D):
	var parent = area.get_parent() as TacticalEntity
	if parent is VillainTacticalEntity and health_bar.value > 0:
		game.skirmish_requested.emit(self, parent)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if game.selected_hero == self:
			state_machine.transition_to(hero_move_state, { "target_pos": game.get_global_mouse_position() })
