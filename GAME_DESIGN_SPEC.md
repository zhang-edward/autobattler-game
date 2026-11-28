# Game Design Spec

Working title: **Superhero Battle League**.

This is the high-level guide for the game. It describes what the game should do, not how to code it. The mockups in `mockups/sports-sim/` show how each screen should look.

## Core fantasy

The player is a brilliant team manager. Through shrewd player development, draft picks and trades, they turn a bottom-feeding franchise into a championship organization.

An example run:

1. The player starts with a weak team of weak heroes. They get pummeled in the regular season.
2. They finish at the bottom of the rankings. It's not all bad: one hero developed a lot, despite mostly losing their fights.
3. They get the first pick in the draft. A very exciting prospect with a lot of hype is at the top of the board. They pick them.
4. They waive the dead weight and trim the roster down to the new prospect, the breakout hero, and maybe one or two other interesting heroes.
5. The next season goes better. The breakout hero becomes a solid contributor and wins half their fights. The prospect starts slowly, then hits their stride and starts dominating. The team still finishes in the bottom half.
6. They get the 5th pick in the draft. They draft a prospect they think is undervalued, and trim the roster again.
7. The next season is a breakout. The first pick has blossomed into a bona fide superstar. The breakout hero from the first season becomes a borderline star. The undervalued prospect isn't doing so well, but you can't win them all.
8. The team makes the post-season for the first time. They put up a good fight against the top-seeded eventual champions, but lose.
9. They get a lower draft pick. They bundle it with the borderline star and trade for a second superstar. The team is now a title contender.
10. The first superstar becomes an MVP-calibre hero, and the new superstar also tears up the box scores. The team finishes the season as the 2nd seed.
11. They demolish their first-round playoff matchup, and win the second round in an exciting series. That sets up a rematch with the top seed for the championship. After an exciting battle, they win their first ever championship.

## Gameplay loop

1. Start a new game with a team in the lowest league tier.
2. Play through the regular season: 15 matches, one per week.
   1. Before each match, the player sees a match preview and picks their lead hero and tag-ins.
   2. After each match, heroes gain XP. On a level-up, the player picks one stat to raise and may pick a new move.
3. If the team finishes in the top 8, it plays in the post-season.
4. At the end of the season, handle contracts and draft new heroes.
5. Repeat until the team wins the championship. Winning the championship promotes the team to the next tier.

## League structure

### Tiers

| Tier | Fight size | Unlocks |
|---|---|---|
| Rookie League | 2v2 (lead + 1 tag-in) | Draft, extend or waive contracts |
| Pro League | 3v3 (lead + 2 tag-ins) | Trades, free agency, contract negotiation |
| Elite League | 4v4 (lead + 3 tag-ins) | |

- The player starts in the lowest tier.
- Winning the championship promotes the team to the next tier.

### Regular season

- Each league tier has 16 teams.
- The regular season is a single round robin: 15 matches, one against every other team.
- Every team plays one match per week, so each week has 8 matches. The player's match is played out; the other 7 are simulated from team stats.
- Standings rank teams by record (wins, losses, win %), then by round difference. Standings also show streak, last 5 results and games behind.

### Post-season

- The top 8 teams by record make the post-season.
- The bracket has 8 seeds and no byes: 1v8, 4v5, 2v7, 3v6 in the first round, then semifinals and a final.
- The winner of the final is the champion and is promoted.

## Matches

Matches use tag-based fighting game mechanics, and play out as an autobattler.

- A match is best of 3 rounds.
- Each round is one fight. Fight size depends on the league tier (see Tiers).
- One hero per team is on the field at a time. The rest wait on the bench to tag in.
- Each team shares one health bar across all its heroes. A team loses the round when its health bar is empty. Individual heroes can't be knocked out.
- Moves have no cooldowns.
- Each team builds a super meter during the fight.

### What the player controls

Fights play out on their own. The player has two controls:

- **Tag in** a hero from the bench. If the hero on the field is busy (being hit, knocked down or blocking), the tag waits and happens as soon as they're free. A tag can cut an attack short.
- **Trigger a super move** when the team's super meter is full. Like tags, it fires as soon as the hero on the field is free.

The opposing team tags and uses supers on its own.

### Blocking

There are no dodges. Defense is blocking only.

- Heroes block automatically. Each incoming hit has a chance to be blocked, based on the defending hero's Agility.
- Each team has a shared block bar. Its size scales with the team's Defense.
- A blocked hit does no health damage. Instead it drains the block bar. Higher Defense means each blocked hit drains less.
- When the block bar empties, the guard breaks: the hero on the field is knocked down for a moment and can be hit freely. The team can't block again until the bar has refilled completely.
- The block bar refills slowly while the team isn't blocking.

### Hero moveset

Each hero has:

| Slot | What it is |
|---|---|
| Attacks | Strikes and projectiles, one each of light, medium and heavy to start. More are learned through level-ups. |
| Super | Set by the hero's power type (see below). Uses the super meter. |
| Tag assist | Fires when the hero tags in: Heal, Strike Boost or Guard Boost. |

Movement (dashing) and blocking are built in for every hero, so they aren't moves.

- **Projectiles:** a hero can only have one projectile on screen, and a projectile's recovery can't be cancelled, so a missed projectile can be punished.
- **Juggles:** a knocked-down hero can only be hit twice in the air (the launch and one follow-up), and can't be hit while getting up.

### Super meter

- Each team has a super meter that fills from damage dealt and damage taken (so a team that's behind still gets its super), and a little from blocking.
- When it's full, the player can trigger their hero's super. The meter empties.
- The hero has super armor during a super: hits still deal damage but don't interrupt it.
- Supers can't be blocked.
- Super damage scales with Skill.

### Power types

| Power type | Focus | Super |
|---|---|---|
| Elemental | Projectile-focused zoning | **Nova Beam:** a huge, fast energy beam that launches |
| Physical | Strike-focused | **Rush Combo:** a lunging rush that launches on contact |
| Psychic | Support-focused | **Mind Surge:** heals the team and blasts the opponent from anywhere |
| Transformation | Meter-focused | **Power Up:** hits harder, attacks faster and takes less damage for a while |

### Tag assists

When a hero tags in, their assist fires. Boosts that last a while (Strike Boost, Guard Boost, Power Up) show an icon over the hero with a ring that empties as the boost runs out.

| Assist | Effect |
|---|---|
| Heal | Restores some of the team's health (shown as a green number) |
| Strike Boost | The incoming hero hits harder for a few seconds |
| Guard Boost | Refills the block bar, fixes a broken guard, and blocked hits drain less for a few seconds |

### After a match

The results screen shows the winner, the round score, a box score for each hero, and XP gained. Level-ups are handled on this screen.

## Team management

### Roster and payroll

- A roster holds up to 6 heroes.
- Each team has a payroll cap (for example $2.0M in the Rookie League). Total salaries can't exceed it.

### Contracts

- Each hero has a contract with a salary per season and a length in seasons.
- Drafted prospects sign rookie contracts.
- In the Rookie League, the player can extend a contract at a fixed price, or waive the hero.
- Contract negotiation unlocks in the Pro League.

### Draft

- The draft is one round. Each team gets one pick.
- Teams that missed the post-season pick first, worst record first.
- Post-season teams pick next, in order of how far they went: teams knocked out in the first round, then the semifinals, then the runner-up.
- A promoted team skips the draft.
- Each prospect has a power type, current stats, a potential rating, and starting moves.
- Scouting reveals prospect information that is hidden by default.

### Trades and free agency

- Both unlock in the Pro League.
- Trades can include heroes and draft picks. The other team accepts or declines a trade offer.

## Progression

Heroes level up after gaining enough XP.

### Stats

| Stat | What it does |
|---|---|
| Strength | Physical attack damage |
| Skill | Projectile and super damage |
| Agility | Block chance, attack speed |
| Vitality | Health |
| Defense | Block bar size; less block drain per blocked hit |

- Each stat has a potential, shown as 1 to 5 stars.
- On a level-up, the player picks one stat to raise. The higher that stat's potential, the more it rises.

### New moves

- Heroes learn new moves at set levels, based on their power type.
- When a hero can learn a new move, the player chooses from randomly generated options.

## Screens and navigation

### Season screens

Season screens share a nav bar: Next Match, Roster, Standings, Free Agents and Trade, plus a menu button. Free Agents and Trade show as locked until the Pro League. The nav bar also shows the team name and record, payroll, and roster count.

| Screen | Purpose |
|---|---|
| Next Match | Match preview: both teams, lead heroes, moves, stat comparison, tag-ins |
| Roster | Hero list, stats with potential, moveset, season stats, contract |
| Standings | League table, last week's results, league leaders |
| Free Agents | Sign unsigned heroes (Pro League and up) |
| Trade | Build and send trade offers (Pro League and up) |

### Event screens

Event screens have no nav bar: the match itself, post-match results, the draft, the post-season bracket, end of season, and new game.
