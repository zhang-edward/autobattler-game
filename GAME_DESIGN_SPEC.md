# Game Design Spec: MVP

This is the high-level guide for building the MVP. It describes what the game should do, not how to code it.

All numbers are starting values. Expect to change them after playtesting.

## The game in brief

The player runs a superhero agency. They send heroes on missions, grow those heroes, and try to beat a final villain before the agency's reputation collapses.

The player can't directly control a fight, so fights are spectacle with real stakes. The strategy comes from three choices:

- Which missions to take, and which to let expire.
- Which hero to send, and whether to bring a backup.
- When to pull a hero out of a fight.

**Winning the run:** beat the final villain.

**Losing the run:** reputation falls below 0.

## Terms

| Term in this spec | Name in the code |
|---|---|
| Mission | Threat request (`ThreatRequestConfig`) |
| Fight | Skirmish (`Skirmish`) |
| Inbox | Dispatch scene |
| Move | `Ability` |
| Reputation | `GameVariables.reputation`. Replaces renown |

## Daily loop

1. The player looks at the inbox and the roster.
2. They send available heroes to any missions they choose.
3. Each mission plays out as a fight.
4. Mission results apply, including XP, level-ups and reputation.
5. The player can recruit defeated villains.
6. The player presses Next Day.

There's no limit on missions per day. The only limit is available heroes.

### When the player presses Next Day

1. The day number goes up by 1.
2. Hero rest timers go down by 1 day.
3. Villains in open missions recover health.
4. Mission expiry timers go down by 1 day.
5. Each expired mission is removed and costs 3 reputation.
6. 1 new mission arrives.
7. If reputation is below 0, the run is lost.

## Missions

- The inbox starts with 3 missions.
- Each mission has 1 villain and expires in 5 to 8 days.
- About 1 in 3 missions is easy, such as a bank robber. Easy missions are good for training heroes.
- The final mission has no expiry.
- Choosing to ignore a mission is a valid decision, and costs reputation when it expires.

### Rising pressure

Missions get harder as days pass. The villain's level on a new mission is `1 + floor(day / 5)`.

The final villain doesn't change. Rising mission difficulty is what eventually pushes the player to attempt the final mission, because reputation gets harder to protect.

### Villain strength

- A level 1 villain has 26 stat points.
- Each extra level adds 3 stat points.
- A villain has the same number of moves as a hero of that level.

On an easy mission, villains are 2 levels lower, down to a minimum of level 1, and have half the stat points.

## Sending heroes

Every fight is 1v1. The player picks 1 hero for each mission, and can add 1 backup hero.

The player judges the matchup themselves. The screen shows stats and moves for both sides. It doesn't show a win chance.

A backup is a safety net, but they can't take other missions while they rest.

## Fights

- The hero begins in the fight. The backup waits.
- The mission is won when the villain is defeated.
- Every hero starts each fight at full health.

### Retreating and the backup

- At any point, the player can order the hero to retreat.
- A retreating hero stops attacking and tries to keep away from the villain.
- They leave the fight by running off the left or right edge of the arena. A retreating hero can still be damaged or knocked down before they are able to escape.
- A retreated hero is out of the fight for good.
- When the hero retreats or is knocked out, the backup comes in.
- If there's no backup left, the mission is lost.

### Fleeing villains

- A villain at low health may flee.
- A villain who flees counts as defeated.

## Stats

Health comes from level, not a stat. A level 1 fighter has 140 health, plus 20 per level.

Every stat helps in fights, and more is always better. Each stat wins a different way, so a hero can specialize in one or two.

| Stat | What it does |
|---|---|
| Strength | Launched targets fly further sideways. Hits keep targets in hitstun longer. |
| Agility | Moves start and recover faster. Multi-hit moves land more hits. Its hits push targets back less, so follow-up hits stay in range. |
| Defense | Higher chance to block. A block holds against every hit that follows. Blocked hits lose a flat amount of damage, so small hits barely hurt and big hits still do. Launched less far. |
| Evasion | Higher chance to dodge. Pushed further back by hits, so it slides out of flurries. Faster dashes. |
| Resilience | After taking enough damage while launched, the fighter can't be hit until they get up. Higher resilience reaches this sooner. Has a chance to shrug off a hit without flinching. Small hits are almost always shrugged off, and big hits almost never are. Higher resilience raises the cutoff. |

**Block versus dodge.** Both only work when the fighter isn't already being hit. A block lasts through a whole flurry, unless the fighter dodges out of it. A dodge is rolled for each hit. So Defense beats many small hits, and Evasion beats single big hits. A fighter can dodge in the middle of a move, but can't block during one.

**Walls.** Launched fighters bounce off the side walls and take damage based on how fast they hit. A wall hit can finish a fighter.

## Mission results

### Reputation

The run starts with 10 reputation.

| Result | Reputation |
|---|---|
| Win | +1 |
| Loss | −1 |
| Mission expired | −3 |

Ignoring a mission costs more than losing it. Trying and failing is always better than not showing up.

### After a loss

- The mission stays open, and its expiry timer keeps running.
- Villains keep their damage, then recover 10% of their maximum health per day.
- A villain at 0 health sits out any attempt until they've recovered some health.

This is how a doomed hero can buy time. Their damage helps the next attempt.

### Hero rest

| Hero | Rest |
|---|---|
| Hero or backup, not defeated | 2 days |
| Defeated hero | 5 days |

A backup rests even if they never entered. Bringing a backup is a real cost.

Heroes can't die in the MVP.

## Hero growth

Heroes grow through XP, which gives levels.

### Training

A hero gains XP if they entered the fight. The mission's XP is split evenly among the heroes who entered.

| Mission result | XP |
|---|---|
| Win | 200 |
| Loss | 100 |

Heroes who never entered get no XP.

### Level-ups

Each level gives 3 stat points for the player to spend. One point adds 1 to Strength, Agility, Defense, Evasion or Resilience.

At certain levels, the hero also picks a new move.

## Heroes

- The run starts with 3 heroes.
- Each starts at level 1 with 26 stat points.
- Each starts with 2 moves.

## Recruiting

- Winning a mission adds its villain to the recruit list.
- Recruiting costs 3 reputation per villain, and can't take reputation below 0.
- A recruit joins as a hero at the villain's level, with their stats and moves.
- The final villain can't be recruited.

This is the main use of reputation beyond surviving. The player trades safety for a stronger roster.

## Final mission

- The final mission is in the inbox from day 1.
- The player can see the final villain's stats and moves from the start.
- It works like any other mission. It can be attempted at any time and as often as the player likes.
- A loss costs reputation, and the villain keeps their damage and recovers over time.
- The final villain is level 8, with 2.5 times normal health.
- Beating them wins the run.

## Not in the MVP

- Effects for landslide wins, such as overconfidence and villain capture.
- Hero death.
- Villains growing from close fights.
- Money and renown.
- Charisma and power types.
- Mid-fight team meter.
- Traits.
- Character moments.
- Fights with more than one hero or villain on each side.

## Build order

1. **Add the campaign layer.** Add days, Next Day, hero rest, reputation, mission expiry, kept villain damage, and win and game-over screens. Hide money.
2. **Add the backup and retreating.** The backup comes in when the hero retreats or is knocked out.
3. **Add level-ups.** Add stat point spending and new moves.
4. **Add rising difficulty, the final mission and recruiting.**

## Open items

- **Fight data.** We don't yet know how often heroes reach low health. Step 1 answers this.
- **Tuning.** Rest length, mission arrival rate, XP and villain difficulty will need playtesting together. With 3 heroes resting 2 days after each mission, the current numbers should leave the player slightly short of heroes if they bring backups.
- **Stat points.** Stat point totals need retuning for the current stats. This spec gives a level 1 fighter 26 points, but the skirmish runner's default build is 50, with 10 in each stat.
