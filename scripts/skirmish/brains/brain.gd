class_name Brain
extends Node

# Decides what a SkirmishEntity wants to do each physics frame. The entity drives it:
# it assigns itself to `entity` when the brain is attached, and calls get_intent() at the
# top of its own physics step, so the state machine always sees this frame's intent.
var entity: SkirmishEntity

# Virtual. Return the intent for this frame, or null for idle.
func get_intent(_delta: float) -> Intent:
	return null
