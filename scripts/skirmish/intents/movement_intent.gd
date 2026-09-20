class_name MovementIntent
extends Intent

# Floor-plane direction in absolute units, each axis in -1..1. Zero means stand still.
var direction := Vector2.ZERO
# True only on the frame the jump is requested. The brain owns the edge detection.
var jump := false
