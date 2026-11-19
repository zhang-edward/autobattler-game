class_name AbilityChain
extends RefCounted

var abilities: Array[OffensiveAbility] = []

func stamina_cost() -> int:
	var total := 0
	for ability in abilities:
		total += ability.stamina_cost
	return total
