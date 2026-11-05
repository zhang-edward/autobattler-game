class_name PhaseConfig
extends Resource

@export var duration := 0.0
@export var velocity := Vector2.ZERO
@export_range(0.0, 0.5) var friction := 0.0

static func create(duration_: float, velocity_: Vector2 = Vector2.ZERO, friction_: float = 0.0) -> PhaseConfig:
	var phase := PhaseConfig.new()
	phase.duration = duration_
	phase.velocity = velocity_
	phase.friction = friction_
	return phase
