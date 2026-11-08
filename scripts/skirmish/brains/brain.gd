class_name Brain
extends Node

# Decides what a SkirmishEntity wants to do. The entity assigns itself to `entity` when the
# brain is attached. States that need an intent call get_intent() from their own
# physics_update, so the brain only runs when the entity can act on the result.
var entity: SkirmishEntity

# Virtual. Return the intent for this frame, or null for idle.
func get_intent(_delta: float) -> Intent:
	return null
