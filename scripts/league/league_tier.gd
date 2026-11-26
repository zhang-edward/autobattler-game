class_name LeagueTier
extends RefCounted

## Rules that change by league tier. Values marked TUNE are placeholders
## until balancing.

enum Tier { ROOKIE, PRO, ELITE }

const NAMES := {
	Tier.ROOKIE: "Rookie League",
	Tier.PRO: "Pro League",
	Tier.ELITE: "Elite League",
}

## Heroes per side in a fight: the lead plus tag-ins.
const FIGHT_SIZE := {
	Tier.ROOKIE: 2,
	Tier.PRO: 3,
	Tier.ELITE: 4,
}

# TUNE: only the Rookie cap ($2.0M) comes from the mockups.
const PAYROLL_CAP := {
	Tier.ROOKIE: 2_000_000,
	Tier.PRO: 3_000_000,
	Tier.ELITE: 4_000_000,
}

# TUNE: level range for heroes on generated (AI) teams at the start of a season.
const GENERATED_LEVEL_RANGE := {
	Tier.ROOKIE: Vector2i(1, 6),
	Tier.PRO: Vector2i(5, 12),
	Tier.ELITE: Vector2i(10, 20),
}

# TUNE: multiplies hero salaries, so stronger leagues pay more.
const SALARY_MULTIPLIER := {
	Tier.ROOKIE: 1.0,
	Tier.PRO: 1.5,
	Tier.ELITE: 2.0,
}


static func display_name(tier: Tier) -> String:
	return NAMES[tier]


static func fight_size(tier: Tier) -> int:
	return FIGHT_SIZE[tier]


static func tag_in_count(tier: Tier) -> int:
	return FIGHT_SIZE[tier] - 1


static func payroll_cap(tier: Tier) -> int:
	return PAYROLL_CAP[tier]


static func generated_level_range(tier: Tier) -> Vector2i:
	return GENERATED_LEVEL_RANGE[tier]


static func salary_multiplier(tier: Tier) -> float:
	return SALARY_MULTIPLIER[tier]


static func trades_unlocked(tier: Tier) -> bool:
	return tier >= Tier.PRO


static func free_agency_unlocked(tier: Tier) -> bool:
	return tier >= Tier.PRO


static func negotiation_unlocked(tier: Tier) -> bool:
	return tier >= Tier.PRO


static func is_top_tier(tier: Tier) -> bool:
	return tier == Tier.ELITE


## The tier a champion is promoted to. The top tier promotes to itself.
static func next_tier(tier: Tier) -> Tier:
	return mini(tier + 1, Tier.ELITE) as Tier
