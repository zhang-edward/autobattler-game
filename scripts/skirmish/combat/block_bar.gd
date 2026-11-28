class_name BlockBar
extends RefCounted

## A team's shared block bar. Blocked hits drain it instead of health. When
## it empties, the team can't block until it has refilled completely. It
## refills slowly while the team isn't blocking.

# TUNE: seconds after the last block before the bar starts refilling.
const REGEN_DELAY := 2.0
# TUNE: share of the full bar refilled per second. 0.04 -> empty to full in 25s.
const REGEN_FRACTION_PER_SECOND := 0.04

var max_value := 0.0
var value := 0.0
## True from the moment the bar empties until it's full again.
var is_broken := false
var _since_last_block := 0.0


static func create(max_value_: float) -> BlockBar:
	var bar := BlockBar.new()
	bar.max_value = max_value_
	bar.value = max_value_
	return bar


func can_block() -> bool:
	return not is_broken


## Drains `amount` for a blocked hit. Returns true if this broke the bar.
func absorb(amount: float) -> bool:
	_since_last_block = 0.0
	value = maxf(value - amount, 0.0)
	if value <= 0.0 and not is_broken:
		is_broken = true
		return true
	return false


## Fills the bar and fixes a broken guard (Guard Boost assist).
func refill() -> void:
	value = max_value
	is_broken = false


func tick(delta: float) -> void:
	_since_last_block += delta
	if _since_last_block < REGEN_DELAY or value >= max_value:
		return
	value = minf(value + max_value * REGEN_FRACTION_PER_SECOND * delta, max_value)
	if is_broken and value >= max_value:
		is_broken = false
