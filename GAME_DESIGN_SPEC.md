# Game Design Spec

This is the high-level guide for the game. It describes what the game should do, not how to code it.

## Core fantasy

The player is a brilliant team manager. Through shrewd player development, draft picks and trades, they turn a bottom-feeding franchise into a championship organization.

An example run:

1. The player starts with a weak team of weak heroes. They get pummeled in the regular season.
2. They finish at the bottom of the rankings. It's not all bad: one hero developed a lot, despite mostly losing their fights.
3. They get the first pick in the draft lottery. A very exciting prospect with a lot of hype is at the top of the board. They pick them.
4. They waive the dead weight and trim the roster down to the new prospect, the breakout hero, and maybe one or two other interesting heroes.
5. The next season goes better. The breakout hero becomes a solid contributor and wins half their fights. The prospect starts slowly, then hits their stride and starts dominating. The team still finishes in the bottom half.
6. They get the 5th pick in the lottery. They draft a prospect they think is undervalued, and trim the roster again.
7. The next season is a breakout. The first pick has blossomed into a bona fide superstar. The breakout hero from the first season becomes a borderline star. The undervalued prospect isn't doing so well, but you can't win them all.
8. The team makes the post-season for the first time. They put up a good fight against the top-seeded eventual champions, but lose.
9. They get a lower draft pick. They bundle it with the borderline star and trade for a second superstar. The team is now a title contender.
10. The first superstar becomes an MVP-calibre hero, and the new superstar also tears up the box scores. The team finishes the season as the 2nd seed.
11. They demolish their first-round playoff matchup, and win the second round in an exciting series. That sets up a rematch with the top seed for the championship. After an exciting battle, they win their first ever championship.

## Gameplay loop

1. Start with a single, high-potential hero on the team.
2. Play through the season.
   1. Matches are best of 3 rounds.
   2. Fights start as 2v2, and eventually progress to 4v4 tag fights at most: a lead plus up to 3 tag-ins.
   3. After each fight, heroes gain XP. On a level-up, their stats improve automatically and they gain new moves.
   4. If the team's record is good enough, they go to the post-season.
3. Draft new heroes at the end of the season.
   1. Draft order is the inverse of regular-season record. Teams with worse records pick earlier.
   2. New prospects sign beginner contracts.
4. Repeat steps 2 and 3 until the team wins the championship.
   1. There are several league tiers. The player starts in the lowest tier.
   2. Winning a championship promotes the team to the next tier.

## Matches

Matches use tag-based fighting game mechanics, and play out as an autobattler.

### Hero moveset

| Move type | Examples |
|---|---|
| Offensive | Strikes, projectiles |
| Defensive | Blocks, dodges, counters |
| Movement | Dashes, jumps |
| Super | Uses meter that builds up |
| Tag assist | Heals, strike boosts, defensive boosts |

### Power types

| Power type | Focus |
|---|---|
| Elemental | Projectile-focused zoning |
| Physical | Strike-focused |
| Psychic | Support-focused |
| Transformation | Meter-focused |

## Team management

- Salary cap.
- Hero contracts. Negotiation unlocks in higher leagues.
- Scouting prospect potential. Each prospect has a star rating for each stat.
- Drafting prospects.
- Trades. These unlock in higher leagues.
- Free agents. These unlock in higher leagues.

## Progression

Heroes level up after gaining enough XP.

### Stats

| Stat | What it does |
|---|---|
| Strength | Physical attack damage |
| Skill | Special move damage |
| Agility | Dodge chance, attack speed |
| Vitality | Health |
| Defense | Block damage mitigation, armor |
| Charisma | Chance to recruit a supervillain |

### New moves

Heroes learn new moves based on their power type. On a new move, the player chooses from randomly generated options.
