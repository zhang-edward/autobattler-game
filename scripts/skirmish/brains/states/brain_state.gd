class_name BrainState
extends State

const Y_TOLERANCE := 0.2
const DASH_MIN_DISTANCE := 150.0

@onready var brain: AIBrain = entity as AIBrain

# Called by AIBrain in place of physics_update, so the intent is made on the entity's own tick.
func get_intent(_delta: float) -> Intent:
	return null

func _y_direction(to_target: Vector2) -> Vector2:
	# Line up on the target's row, since hits only land within Y_AXIS_HIT_RANGE
	if absf(to_target.y) > IsometryUtils.Y_AXIS_HIT_RANGE * Y_TOLERANCE:
		return Vector2(0.0, signf(to_target.y))
	return Vector2.ZERO

func _movement(direction: Vector2, facing: float, dash := 0.0) -> Intent:
	var intent := Intent.new()
	intent.direction = direction
	intent.facing = facing
	intent.dash = dash
	return intent

func _action(ability: Ability, facing: float) -> Intent:
	var intent := Intent.new()
	intent.facing = facing
	intent.ability = ability
	return intent
