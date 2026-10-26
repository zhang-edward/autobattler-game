class_name AbilityState
extends SkirmishState

# States driven by an Ability asset. Tuning is initialized once at spawn via
# init() — never passed on enter(). Dynamic per-event data (combo_index,
# dir, impulse, grabber) still travels via transition msg.
func init(_ability: Ability) -> void:
	pass
