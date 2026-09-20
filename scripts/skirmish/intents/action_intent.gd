class_name ActionIntent
extends Intent

enum Action {
	PUNCH,
	BLOCK,
	GRAB,
}

# Which action the brain wants 
var action: Action = Action.PUNCH

# How long to hold a BLOCK, in seconds. Ignored by the other actions.
var duration := 0.0

# Which move from the entity's moveset to perform.
var move: Move
