class_name TeamHealth
extends RefCounted

## A team's shared health bar for one round. Every hero's hits come out of
## it, and the team loses the round when it's empty. Its size is the sum of
## the heroes' own health (see CombatStats.max_health).

var max_value := 0
var value := 0


static func create(max_value_: int) -> TeamHealth:
	var health := TeamHealth.new()
	health.max_value = max_value_
	health.value = max_value_
	return health


func is_empty() -> bool:
	return value <= 0


func fraction() -> float:
	return float(value) / maxf(max_value, 1.0)


func heal(amount: int) -> void:
	if not is_empty():
		value = mini(value + amount, max_value)


## Takes `amount` off. Returns true if this emptied the bar.
func take(amount: int) -> bool:
	if is_empty():
		return false
	value = maxi(value - amount, 0)
	return is_empty()
