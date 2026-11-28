class_name CombatStats
extends RefCounted

## Every way a hero's stats change a fight, in one place. Combat code and the
## Skirmish Runner's stat descriptions both read from here.
##
## Stats start around 2-9 at level 1 and rise 1-3 per level-up, so the
## formulas are tuned for roughly 2-25.
##
##   Strength  strike damage, launch distance
##   Skill     projectile (special) damage
##   Agility   attack speed, chance to block
##   Vitality  health
##   Defense   team block bar size, less drain per blocked hit

# TUNE: +4% damage per point. 5 -> x1.2, 20 -> x1.8.
const STRENGTH_DAMAGE_PER_POINT := 0.04
const SKILL_DAMAGE_PER_POINT := 0.04
# TUNE: launch distance x (scale + Strength) / scale. 20 -> x1.67.
const STRENGTH_LAUNCH_SCALE := 30.0

# TUNE: attacks are 3% faster per point. 5 -> x0.87 time, 20 -> x0.63.
const AGILITY_SPEED_PER_POINT := 0.03
# TUNE: block chance = Agility / (Agility + scale), capped. 5 -> 29%, 10 -> 45%, 20 -> 63%.
const BLOCK_CHANCE_AGILITY_SCALE := 12.0
const BLOCK_CHANCE_MAX := 0.7

# TUNE: 5 -> 150 health, 20 -> 300.
const BASE_HEALTH := 100
const HEALTH_PER_VITALITY := 10

# TUNE: block bar = base + per point of the team's average Defense. 5 -> 60, 20 -> 150.
const BLOCK_BAR_BASE := 30.0
const BLOCK_BAR_PER_DEFENSE := 6.0
# TUNE: a blocked hit drains its damage x scale / (scale + Defense). 5 -> x0.8, 20 -> x0.5.
const BLOCK_DRAIN_DEFENSE_SCALE := 20.0


## Damage `hit` does when thrown by `attacker`: strikes scale with
## Strength, projectiles and supers with Skill. Boosts (Power Up, Strike
## Boost) multiply on top.
static func hit_damage(hit: HitConfig, attacker: EntityConfig) -> int:
	var multiplier := 1.0
	if hit.kind == HitConfig.Kind.STRIKE:
		multiplier = strength_damage_multiplier(attacker.strength)
	else:
		multiplier = skill_damage_multiplier(attacker.skill)
	multiplier *= attacker.damage_multiplier()
	return maxi(roundi(hit.damage * multiplier), 1)


static func strength_damage_multiplier(strength: float) -> float:
	return 1.0 + strength * STRENGTH_DAMAGE_PER_POINT


static func skill_damage_multiplier(skill: float) -> float:
	return 1.0 + skill * SKILL_DAMAGE_PER_POINT


static func launch_multiplier(strength: float) -> float:
	return (STRENGTH_LAUNCH_SCALE + strength) / STRENGTH_LAUNCH_SCALE


## Multiplier on attack startup and recovery times. Lower is faster.
static func action_time_scale(agility: float) -> float:
	return 1.0 / (1.0 + agility * AGILITY_SPEED_PER_POINT)


static func block_chance(agility: float) -> float:
	return minf(agility / (agility + BLOCK_CHANCE_AGILITY_SCALE), BLOCK_CHANCE_MAX)


static func max_health(vitality: float) -> int:
	return BASE_HEALTH + roundi(vitality * HEALTH_PER_VITALITY)


static func block_bar_size(average_defense: float) -> float:
	return BLOCK_BAR_BASE + average_defense * BLOCK_BAR_PER_DEFENSE


## How much of the block bar a blocked hit of `damage` drains.
static func block_drain(damage: float, defense: float) -> float:
	return damage * BLOCK_DRAIN_DEFENSE_SCALE / (BLOCK_DRAIN_DEFENSE_SCALE + defense)
