class_name Intent
extends RefCounted

# What a brain wants its entity to do this physics frame. A brain hands the entity
# exactly one Intent per frame (or null for idle). See MovementIntent and ActionIntent.

# Which way to face: -1 left, 1 right, 0 to leave facing alone. Set by the brain,
# which knows where the target is, so backing away doesn't turn the entity around.
var facing := 0.0
