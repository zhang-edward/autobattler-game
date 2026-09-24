class_name HeroMoveState
extends HeroState

@export var idle_state: HeroState
@export var dest_marker_scene: PackedScene

var target_pos: Vector2
var dest_marker: Sprite2D
const ARRIVAL_THRESHOLD = 5.0

func _ready() -> void:
	dest_marker = dest_marker_scene.instantiate() as Sprite2D
	add_child(dest_marker)
	dest_marker.hide()

func enter(msg := {}) -> void:
	target_pos = msg.target_pos
	hero.navigation_agent.target_position = target_pos
	dest_marker.show()
	dest_marker.global_position = target_pos

func physics_update(delta: float) -> void:
	var dist = hero.global_position.distance_to(target_pos)
	if dist < ARRIVAL_THRESHOLD:
		state_machine.transition_to(idle_state)
	else:
		var next_path_pos: Vector2 = hero.navigation_agent.get_next_path_position()
		hero.velocity = hero.global_position.direction_to(next_path_pos) * hero.entity_config.ground_speed

func update(_delta: float) -> void:
	if dest_marker != null:
		dest_marker.visible = hero.game.selected_hero == hero

func exit() -> void:
	dest_marker.hide()
