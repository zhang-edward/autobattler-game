class_name Hitstop

const DEFAULT_DURATION := 0.08

# Entity instance id -> resume timestamp (ms). Tracks in-flight freezes so an overlapping
# hit extends the freeze 
static var _resume_at: Dictionary = {}

static func freeze(entities: Array, duration: float = DEFAULT_DURATION) -> void:
	for entity in entities:
		_freeze_one(entity, duration)

static func _freeze_one(entity: SkirmishEntity, duration: float) -> void:
	var id := entity.get_instance_id()
	var resume_at := Time.get_ticks_msec() + duration * 1000.0
	if _resume_at.get(id, 0.0) >= resume_at:
		return

	entity.hitstop_scale = 0.0
	_resume_at[id] = resume_at
	var tree := Engine.get_main_loop() as SceneTree
	tree.create_timer(duration).timeout.connect(_try_resume.bind(id, resume_at))

static func _try_resume(id: int, scheduled_resume_at: float) -> void:
	if _resume_at.get(id, 0.0) != scheduled_resume_at:
		return

	_resume_at.erase(id)
	var entity := instance_from_id(id) as SkirmishEntity
	if is_instance_valid(entity):
		entity.hitstop_scale = 1.0
