class_name TagIntent
extends Intent

# Benchmate to swap in. Only honored in MoveState; Skirmish.tag() owns validation
# (Move-only, no grab interruption), so a denied request just stalls one frame.
var target: SkirmishEntity
