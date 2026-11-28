class_name SuperMeter
extends RefCounted

## A team's super meter for one round. Fills from damage dealt and taken (so
## a team that's behind still gets its super), and a little from blocking.
## When it's full, the team's hero on the field can use their super.

const MAX_VALUE := 100.0
# TUNE: meter per point of damage. With ~300 team health a side, a 2v2
# round gives each team about 1.5 supers.
const PER_DAMAGE_DEALT := 0.45
const PER_DAMAGE_TAKEN := 0.3
# Per point of block bar drained by a blocked hit.
const PER_BLOCK_DRAIN := 0.25

var value := 0.0


func add(amount: float) -> void:
	value = minf(value + amount, MAX_VALUE)


func is_full() -> bool:
	return value >= MAX_VALUE


func spend() -> void:
	value = 0.0
