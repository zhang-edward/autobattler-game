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
