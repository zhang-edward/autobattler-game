class_name Team
extends RefCounted

## A team in the league: identity and roster.

const MAX_ROSTER := 6

# Unique ids so schedules and results can refer to teams. Save/load will
# need to restore this counter.
static var _next_id := 1

var id: int
var team_name := ""
## Two-letter badge text, e.g. "BB".
var abbreviation := ""
var color := Color.WHITE
var is_player := false
var roster: Array[Hero] = []


func _init() -> void:
	id = _next_id
	_next_id += 1


static func create(name_: String, abbreviation_: String, color_: Color) -> Team:
	var team := Team.new()
	team.team_name = name_
	team.abbreviation = abbreviation_
	team.color = color_
	return team


func roster_count() -> int:
	return roster.size()


func has_roster_space() -> bool:
	return roster.size() < MAX_ROSTER


## Adds a hero if there's room. Returns whether it was added.
func add_hero(hero: Hero) -> bool:
	if not has_roster_space() or roster.has(hero):
		return false
	roster.append(hero)
	return true


## Returns whether the hero was on the roster.
func remove_hero(hero: Hero) -> bool:
	if not roster.has(hero):
		return false
	roster.erase(hero)
	return true


## Total salary of everyone on the roster.
func payroll() -> int:
	var total := 0
	for hero in roster:
		if hero.contract != null:
			total += hero.contract.salary
	return total


func can_afford(salary: int, payroll_cap: int) -> bool:
	return payroll() + salary <= payroll_cap


## Average overall rating of the roster, or 0 for an empty roster.
func overall_rating() -> float:
	if roster.is_empty():
		return 0.0
	var total := 0.0
	for hero in roster:
		total += hero.overall_rating()
	return total / roster.size()
