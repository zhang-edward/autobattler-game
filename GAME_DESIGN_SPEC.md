# Game Design Spec: MVP

This is the high-level guide for building the MVP. It describes what the game should do, not how to code it.

All numbers are starting values. Expect to change them after playtesting.

## The game in brief

The player runs a superhero agency. They send heroes on missions, grow those heroes, and try to beat a final villain before the agency's reputation collapses.

The player can't directly control a fight, so fights are spectacle with real stakes. The strategy comes from three choices:

- Which missions to take, and which to let expire.
- Which heroes to send, and how many.
- When to swap heroes in or out during a fight.

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
2. Hero rest timers and negative trait timers go down by 1 day.
3. Villains in open missions recover health.
4. Mission expiry timers go down by 1 day.
5. Each expired mission is removed and costs 3 reputation.
6. 1 new mission arrives.
7. If reputation is below 0, the run is lost.

## Missions

- The inbox starts with 3 missions.
- Each mission has 1 to 3 villains and expires in 5 to 8 days.
- About 1 in 3 missions is easy, such as a few bank robbers. Easy missions are good for training heroes.
- The final mission has no expiry.
- Choosing to ignore a mission is a valid decision, and costs reputation when it expires.

### Rising pressure

Missions get harder as days pass. The villain's level on a new mission is `1 + floor(day / 5)`.

The final villain doesn't change. Rising mission difficulty is what eventually pushes the player to attempt the final mission, because reputation gets harder to protect.

### Villain strength

- A level 1 villain has 26 stat points.
- Each extra level adds 3 stat points.
- A villain has the same number of moves as a hero of that level has move slots.
- Villains have no traits in the MVP.
- In a 2-villain mission, each villain has 75% of those stat points. In a 3-villain mission, each has 60%.

On an easy mission, villains are 2 levels lower, down to a minimum of level 1, and have half the stat points.

## Sending heroes

The player picks **starters** and a **bench** for each mission. A mission needs at least 1 starter.

The player judges the matchup themselves. The screen shows stat totals and moves for both sides. It doesn't show a win chance.

This means team size is a tool. The player can turn a hard fight into a 3v1, but those heroes can't take other missions while they rest.

## Fights

- Starters begin in the fight. Bench heroes wait.
- The mission is won when all villains are defeated.
- Every hero starts each fight at full health.
- Retreating to the bench doesn't restore a hero's health.

### Swapping

- At any point, the player can send a bench hero into the fight.
- At any point, the player can order an active hero to retreat to the bench.
- A hero can only leave when they're free to move. A hero being attacked must wait for an opening.

### When no active heroes remain

- If bench heroes remain, a 10-second timer starts. The player can send a bench hero in, or abandon the mission.
- If the timer runs out, the mission is lost.
- If no bench heroes remain, the mission is lost right away.

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
| Starter or bench hero, not defeated | 2 days |
| Defeated hero | 5 days |

Bench heroes rest even if they never entered. Committing a backup is a real cost.

Heroes can't die in the MVP.

## Hero growth

There are two kinds of growth:

- **Training** is small and steady. It's XP, which gives levels and stat points.
- **Character moments** are big, stepwise changes. They give new moves and traits.

Training unlocks slots. Character moments fill them. A hero needs both to grow.

### Training

A hero gains XP if they entered the fight and finished above 25% health.

| Mission result | XP |
|---|---|
| Win | 200 |
| Loss | 100 |

Heroes who fall to 25% health or below get no XP from that fight. Heroes who never entered get no XP either.

### Level-ups

Each level gives 3 stat points for the player to spend. One point adds:

| Stat | Increase |
|---|---|
| Strength | +2 |
| Defense | +3 |
| Agility | +20 |
| Vitality | +15 |

Slots unlock in a fixed order:

| Level | Unlock | Move slots | Trait slots |
|---|---|---|---|
| 1 | Starting slots | 3 | 0 |
| 2 | Trait slot | 3 | 1 |
| 3 | Move slot | 4 | 1 |
| 4 | Trait slot | 4 | 2 |
| 5 | Move slot | 5 | 2 |
| 6 | Trait slot | 5 | 3 |

Levels above 6 give stat points only.

### Character moments

A hero has a moment the first time they fall to 25% health or below in a fight. This can only happen once per hero, per fight. Winning isn't required, and a landslide team win still counts.

| Hero has | What happens |
|---|---|
| An empty move slot | They learn a random new move during the fight, and use it straight away |
| An empty trait slot | They gain a random trait during the fight, and its effect starts straight away |
| Both | Both happen |
| No empty slots, and is below level 6 | 50% chance of a negative trait |
| No empty slots, and is level 6 or above | Nothing |

- A character moment is a cinematic beat. It shows through the screen and the hero's behavior, with no speech lines.
- A hit that defeats a hero outright skips any new move or trait, because the hero is down. The negative trait chance still applies.
- The post-fight screen shows what each hero gained.

### Negative traits

- They use their own 3 slots, separate from positive traits.
- Each lasts 5 days, then goes away.
- A hero with 3 negative traits can't gain another.

This makes rushing an under-trained hero into hard fights risky.

## Heroes

- The run starts with 3 heroes.
- Each starts at level 1 with 26 stat points.
- Each starts with 2 moves, plus 1 empty move slot.

Each hero's first low-health moment gives them a third move, so even a new hero can have a big moment early.

## Recruiting

- Winning a mission adds its villains to the recruit list.
- Recruiting costs 3 reputation per villain, and can't take reputation below 0.
- A recruit joins as a hero at the villain's level, with their stats and moves.
- They have that level's slots. Their move slots are full, and their trait slots are empty.
- The final villain can't be recruited.

This is the main use of reputation beyond surviving. The player trades safety for a stronger roster.

## Final mission

- The final mission is in the inbox from day 1.
- The player can see the final villain's stats and moves from the start.
- It works like any other mission. It can be attempted at any time and as often as the player likes.
- A loss costs reputation, and the villain keeps their damage and recovers over time.
- The final villain fights alone. They're level 8, with 2.5 times normal vitality.
- Beating them wins the run.

## Not in the MVP

- Effects for landslide wins, such as overconfidence and villain capture.
- Hero death.
- Villains growing from close fights.
- Money and renown.
- Charisma, skill and power types.
- Mid-fight team meter.
- Traits on villains.

## Build order

1. **Add the campaign layer.** Add days, Next Day, hero rest, reputation, mission expiry, kept villain damage, and win and game-over screens. Hide money.
2. **Support several fighters per mission.** Update hero assignment and the post-fight screen, and allow up to 3 villains. Starters only at this stage.
3. **Add the bench and live swapping.** Include the 10-second timer and abandoning a mission.
4. **Add level-ups and slots.** Add stat point spending and the fixed unlock order.
5. **Add character moments.** Add mid-fight moves first, then traits and negative traits.
6. **Add rising difficulty, the final mission and recruiting.**

## Open items

- **Trait list.** No positive or negative traits have been chosen yet. A small list needs approval before step 6.
- **Fight data.** We don't yet know how often heroes reach low health. Step 1 answers this.
- **Tuning.** Rest length, mission arrival rate, XP and villain difficulty will need playtesting together. With 3 heroes resting 2 days after each mission, the current numbers should leave the player slightly short of heroes if they send teams.
- **Group fights.** Easy missions should usually end in landslides, and 2 or 3 villains should feel about as hard as 1 strong villain. The skirmish runner can test both.
