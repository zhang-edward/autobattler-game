class_name Intent
extends RefCounted

# What a brain wants its entity to do this physics frame. A brain hands the entity
# exactly one Intent per frame (or null for idle). Carries both movement and move use:
# ability == null means "just move", non-null means "use this Move".

# Which way to face: -1 left, 1 right, 0 to leave facing alone. Set by the brain,
# which knows where the target is, so backing away doesn't turn the entity around.
var facing := 0.0
# Floor-plane direction in absolute units, each axis in -1..1. Zero means stand still.
var direction := Vector2.ZERO
# True only on the frame the jump is requested. The brain owns the edge detection.
var jump := false
# Which move from the entity's moveset to perform. Null means no move this frame.
var move: Move
