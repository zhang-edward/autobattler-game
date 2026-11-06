class_name Ability
extends Resource

enum Tier {LIGHT, MEDIUM, HEAVY}

@export var weight := 0.0
@export var ability_name := ""
@export var tier: Tier
## State scene instantiated under the entity's StateMachine at spawn.
@export var state_scene: PackedScene
@export var cooldown := 0.0
@export var ability_range := 80.0
@export var ability_min_range := 0.0
@export var anim := ""
@export var startup: PhaseConfig = PhaseConfig.create(0.0)
@export var recovery: PhaseConfig = PhaseConfig.create(0.0)

func in_reach(to_target: Vector2) -> bool:
	var gap := absf(to_target.x)
	return gap <= ability_range and gap >= ability_min_range \
			and absf(to_target.y) <= IsometryUtils.Y_AXIS_HIT_RANGE
