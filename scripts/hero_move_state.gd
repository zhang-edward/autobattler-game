class_name HeroMoveState
extends HeroState

@export var idle_state: HeroState
@export var dest_marker_scene: PackedScene

var target_pos: Vector2
var dest_marker: ColorRect
const ARRIVAL_THRESHOLD = 5.0

func _ready() -> void:
	dest_marker = dest_marker_scene.instantiate() as ColorRect
	add_child(dest_marker)
	dest_marker.hide()

func enter(msg := {}) -> void:
	_set_target_pos(msg.target_pos)
	
func _set_target_pos(pos: Vector2):
	target_pos = pos
	dest_marker.show()
	dest_marker.global_position = target_pos
	
func handle_input(event: InputEvent) -> void:
	var game = hero.game as TacticalEncounter
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if game.selected_hero == hero:
			_set_target_pos(game.get_global_mouse_position())

func physics_update(delta: float) -> void:
	var dist = hero.global_position.distance_to(target_pos)
	if dist < ARRIVAL_THRESHOLD:
		state_machine.transition_to(idle_state)
	else:
		hero.velocity = hero.global_position.direction_to(target_pos) * hero.entity_config.ground_speed
		
func update(_delta: float) -> void:
	if dest_marker != null:
		dest_marker.visible = hero.game.selected_hero == hero

func exit() -> void:
	dest_marker.hide()
