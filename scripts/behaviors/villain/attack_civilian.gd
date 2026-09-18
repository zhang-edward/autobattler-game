@tool
class_name AttackCivilian
extends ActionLeaf

var timer: Timer

func tick(actor: Node, blackboard: Blackboard) -> int:
	var villain = actor as VillainTacticalEntity
	villain.velocity = Vector2.ZERO
	var target_civilian: CivilianTacticalEntity = blackboard.get_value(IsCivilianDetected.DETECTED_CIV_KEY)
	if timer == null:
		timer = Timer.new()
		timer.wait_time = 2.0
		timer.autostart = true
		timer.one_shot = false
		var callable = Callable(self, "damage_civilian").bind(target_civilian)
		timer.timeout.connect(callable)
		add_child(timer)
	return FAILURE if target_civilian == null or target_civilian.health_bar.value == 0 else RUNNING
	
func damage_civilian(civ: CivilianTacticalEntity):
	civ.health_bar.value -= 10
	if civ.health_bar.value == 0:
		civ.die()
		timer.queue_free()
		timer = null
	
