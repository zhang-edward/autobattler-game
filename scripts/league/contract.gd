class_name Contract
extends RefCounted

## A hero's contract. Seasons are numbered from 1. A contract signed in
## season S with length L covers seasons S through S + L - 1.

enum Kind { ROOKIE, STANDARD }

var kind: Kind = Kind.STANDARD
## Salary per season, in dollars.
var salary := 0
## Length in seasons, as signed.
var length := 1
## The first season the contract covers.
var signed_season := 1
## Draft info, for rookie contracts. 0 means not drafted.
var drafted_season := 0
var drafted_pick := 0


static func create(kind_: Kind, salary_: int, length_: int, signed_season_: int) -> Contract:
	var contract := Contract.new()
	contract.kind = kind_
	contract.salary = salary_
	contract.length = length_
	contract.signed_season = signed_season_
	return contract


## The last season the contract covers.
func final_season() -> int:
	return signed_season + length - 1


## Seasons left, counting the current one. 0 or less means expired.
func seasons_remaining(current_season: int) -> int:
	return final_season() - current_season + 1


func is_final_season(current_season: int) -> bool:
	return seasons_remaining(current_season) == 1


func is_expired(current_season: int) -> bool:
	return seasons_remaining(current_season) <= 0
