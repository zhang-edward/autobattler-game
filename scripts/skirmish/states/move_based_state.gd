class_name MoveBasedState
extends SkirmishState

# States driven by a Move asset. Tuning is initialized once at spawn via
# init() — never passed in on enter(). Dynamic per-event data (combo_index,
# dir, impulse, grabber) still travels via transition msg.
func init(_move: Move) -> void:
	pass
