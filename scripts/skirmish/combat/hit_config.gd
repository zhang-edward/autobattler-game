class_name HitConfig
extends Resource

enum Kind {
	STRIKE,
	GRAB,
	PROJECTILE,
}

# Blocking negates a STRIKE but not a GRAB
@export var kind: Kind = Kind.STRIKE
@export var damage: int = 10
# Airborne knockback. X is sideways speed. Y is vertical speed: negative goes up, 0 falls back to JUGGLE_LAUNCH.
@export var launch: Vector2 = Vector2(100.0, 0.0)
# Grounded knockback speed, for hitstun and blocked hits
@export var pushback: float = HurtState.BASE_KNOCKBACK
# Ragdoll the target instead of putting it in ordinary hitstun
@export var is_launcher: bool = false
@export var hitstop: float = Hitstop.DEFAULT_DURATION
@export var base_hitstun: float = HurtState.HITSTUN_SECONDS

static func create(
	damage_: int,
	launch_: Vector2 = Vector2(100.0, 0.0),
	is_launcher_: bool = false,
	hitstop_: float = Hitstop.DEFAULT_DURATION,
	kind_: Kind = Kind.STRIKE
) -> HitConfig:
	var hit := HitConfig.new()
	hit.damage = damage_
	hit.launch = launch_
	hit.is_launcher = is_launcher_
	hit.hitstop = hitstop_
	hit.kind = kind_
	return hit
