class_name HitConfig
extends Resource

enum Kind {
	STRIKE,
	GRAB,
}

# Blocking negates a STRIKE but not a GRAB
@export var kind: Kind = Kind.STRIKE
@export var damage: int = 10
# Floor-plane knockback speed, in absolute (pre-IsometryUtils) units
@export var knockback: float = 100.0
# Altitude speed imparted on hit. Negative sends the target up, positive spikes it down.
@export var launch: float = 0.0
# Ragdoll the target instead of putting it in ordinary hitstun
@export var knockdown: bool = false
@export var hitstop: float = Hitstop.DEFAULT_DURATION

static func create(
	damage_: int,
	knockback_: float = 100.0,
	launch_: float = 0.0,
	knockdown_: bool = false,
	hitstop_: float = Hitstop.DEFAULT_DURATION,
	kind_: Kind = Kind.STRIKE
) -> HitConfig:
	var hit := HitConfig.new()
	hit.damage = damage_
	hit.knockback = knockback_
	hit.launch = launch_
	hit.knockdown = knockdown_
	hit.hitstop = hitstop_
	hit.kind = kind_
	return hit
