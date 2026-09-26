class_name HeroSaveCivState
extends HeroState

@export var save_civ_label_scene: PackedScene
@export var hero_idle_state: HeroState

func enter(_msg := {}) -> void:
	hero.velocity = Vector2.ZERO
	var civilians = get_civilians_in_range()
	for c in civilians:
		if !c.is_being_saved:
			c.saving_hero = hero
			var save_civ_label = save_civ_label_scene.instantiate() as SaveCivProgressLabel
			hero.add_child(save_civ_label)
			save_civ_label.civ_ref = c
			save_civ_label.global_position = Vector2(c.global_position.x, c.global_position.y + 75)
			save_civ_label.start_save_timer()
		
func update(_delta: float) -> void:
	var civilians = get_civilians_in_range()
	if civilians.is_empty():
		state_machine.transition_to(hero_idle_state)

func get_civilians_in_range() -> Array[CivilianTacticalEntity]:
	var areas = hero.entity_detector.get_overlapping_areas()
	var civilians: Array[CivilianTacticalEntity] = []
	for a in areas:
		if a.get_parent() is CivilianTacticalEntity:
			civilians.append(a.get_parent())
	return civilians
