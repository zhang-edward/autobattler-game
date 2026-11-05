class_name Ability
extends Resource

enum Category {
	OFFENSIVE,
	DEFENSIVE,
}

## AI selection weight. DEFENSIVE abilities use 0 (reaction only, never picked).
@export var weight := 0.0
@export var category: Category = Category.OFFENSIVE
@export var ability_name := ""
## State scene instantiated under the entity's StateMachine at spawn.
@export var state_scene: PackedScene
@export var cooldown := 0.0
@export var ability_range := 80.0
@export var ability_min_range := 0.0
@export var anim := ""
@export var startup: PhaseConfig = PhaseConfig.create(0.0)
@export var recovery: PhaseConfig = PhaseConfig.create(0.0)
