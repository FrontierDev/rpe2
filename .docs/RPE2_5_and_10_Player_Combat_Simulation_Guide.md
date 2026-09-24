# RPE2 5-Player and 10-Player Combat Simulation Guide

**Purpose:** define a consistent method for future RPE2 party/raid damage, healing, resource, and threat simulations.

**Scope:** this guide is for balance simulations against the current RPE2 datasets and ruleset. It is not a replacement for the runtime combat engine. Before every simulation, re-read the current repository data for the branch being evaluated.

---

## 1. Mandatory simulation workflow

Before calculating any result:

1. **Read the current branch first.**
   - Confirm the branch/commit being simulated.
   - Read the current class dataset files, Core dataset, active ruleset defaults, Spell Rank PDD, and Spell Authoring Specification.
   - Do not reuse remembered coefficients after a balance commit.

2. **Define the simulation mode.**
   - Raw throughput.
   - Realized damage after mitigation.
   - Threat.
   - Healing/survivability.
   - Boss-health sizing.
   - State explicitly which modes are being reported.

3. **Define the encounter.**
   - Player count.
   - Exact roster and roles.
   - Character level.
   - Gear tier.
   - Encounter duration in turns.
   - Number and type of targets.
   - Whether the boss is assumed to attack the tank every turn.
   - Whether execute phases, adds, movement, control, or downtime exist.

4. **Build each character from current data.**
   - Race/class base progression.
   - Gear stats.
   - Weapon damage.
   - Passive traits that are actually present.
   - Active stance/form.
   - Relevant group buffs/debuffs.
   - Resource regeneration.
   - Spell ranks.

5. **Build a legal turn-by-turn rotation.**
   - Respect cooldown channels, GCDs, cooldowns, charges, conditions, resources, aura durations, and target requirements.
   - Do not count a spell simply because its formula is strong if the character cannot legally cast it.

6. **Calculate every independent damage source.**
   - Direct attacks.
   - Basic attacks.
   - Bonus actions.
   - Free actions.
   - Periodic effects.
   - Reactive effects.
   - Proc effects.
   - Talent/trait effects.
   - Execute effects.
   - Group-triggered effects.

7. **Report both character totals and source breakdowns.**
   - A party total without a source breakdown is not sufficient for balance work.

---

# 2. Standard group templates

## 2.1 Five-player reference group

Default composition:

| Slot | Reference role |
|---|---|
| 1 | Tank |
| 2 | Healer |
| 3 | DPS |
| 4 | DPS |
| 5 | DPS |

For continuity with the current calibration work, the default reference roster is:

- Protection Warrior — tank
- Retribution Paladin — DPS
- Fire Mage — DPS
- Ranged Hunter — DPS
- Priest — healer

This is a **reference roster**, not a required encounter composition. If a real event roster is known, simulate the real roster instead.

## 2.2 Ten-player reference group

Default composition:

| Slots | Reference role |
|---|---|
| 2 | Tanks |
| 2 | Healers |
| 6 | DPS |

Recommended class-diverse reference roster:

- Protection Warrior — tank
- Protection Paladin — tank
- Priest — healer
- Holy Paladin — healer
- Warrior — DPS
- Retribution Paladin — DPS
- Rogue — DPS
- Hunter — DPS
- Mage — DPS
- Shadow Priest — DPS

Do not derive 10-player output by simply doubling a 5-player result. A 10-player group changes:

- role distribution;
- buff/debuff coverage;
- shared proc frequency;
- threat competition;
- target coverage;
- cooldown overlap;
- group-wide effects.

Simulate all ten characters individually.

---

# 3. Standard calibration points

## 3.1 Canonical level

The current RPE character level cap is **60**.

Therefore the preferred canonical endgame checkpoints are:

- Level 60 with T0.5-equivalent gear.
- Level 60 with T2-equivalent gear.

A synthetic level above 60 may be used for historical comparison, but it must be labelled **non-canonical** and must not be mixed into normal balance targets.

## 3.2 Gear

Use the current imported gear data for the chosen tier.

Do not mix:

- T0.5 armor with a starter weapon;
- T2 armor with an unrelated low-level weapon;
- healer gear with DPS coefficients unless that is the intended build.

If the repository does not contain an appropriate weapon:

1. choose a named weapon from the intended content/tier;
2. record its item level, damage range, average damage, and relevant stats;
3. use the same source consistently across comparison runs.

**Never substitute a starter weapon for an endgame simulation.**

For range-damage weapons:

```text
average weapon damage = (minimum damage + maximum damage) / 2
```

For expected-value simulations, use average weapon damage rather than randomly rolling the range.

---

# 4. Standard encounter windows

## 4.1 Primary comparison window

Use **10 turns** for ordinary class/party comparisons.

Ten turns is long enough to include:

- periodic effects;
- ordinary cooldowns;
- one 10-turn cooldown use;
- resource pressure;
- most buff durations.

## 4.2 Boss sizing

If the purpose is to size boss health for a desired fight duration, simulate the **actual desired duration**.

Do not automatically multiply a 10-turn average by 18, 20, or another target duration when the longer encounter changes:

- cooldown reuse;
- execute availability;
- mana exhaustion;
- Rage/Energy flow;
- aura uptime;
- charge recharge;
- stacking effects.

For a Boss intended to last **10–15 turns**, simulate the actual target duration rather than extrapolating from a shorter window.

---

# 5. Action economy

Current default cooldown-channel interpretation:

| Channel | Default role | GCD |
|---:|---|---|
| 1 | Main Action | Yes |
| 2 | Bonus Action | Yes |
| 3 | Buff Action | Yes |
| 4 | Free Action | No |
| 5 | Reaction | Yes; usable off-turn |

The simulation must use the **runtime channel**, not the balance-action name in the authoring calculator.

Important rules:

- one Main Action cannot be replaced by several Main Actions in the same turn;
- Bonus Action usage must respect its channel GCD;
- Buff Action usage must respect its channel GCD;
- Free Action does not trigger its channel GCD;
- spell-specific cooldowns and conditions still apply;
- Reactions must only occur when their triggering circumstances exist.

### Basic-attack convention

For standard balance simulations, model the character's normal basic attack **once per turn** unless a current mechanic explicitly grants additional basic attacks.

This prevents unrestricted Free Action spam from being silently assumed.

If runtime behavior permits repeated basic attacks beyond the intended one-per-turn convention, report that separately as a system-level balance issue.

---

# 6. Raw damage model

## 6.1 Runtime base formula

Current direct damage resolution begins from:

```text
Raw authored amount
= Base Damage
+ (Weapon Damage × Weapon Coefficient)
+ Σ(Stat Value × Stat Coefficient)
```

Expected-value simulations should use variance = **1.0** unless variance itself is under investigation.

Spell Rank then applies to the complete authored magnitude:

```text
Ranked raw amount
= Raw authored amount × Rank Multiplier
```

## 6.2 Spell ranks

Current defaults:

```text
use_spell_ranks = true
spell_rank_effect_gain_percent = 5
rankInterval = 8 unless authored otherwise
```

Displayed rank:

```text
displayRank
= 1 + floor((level - learnLevel) / rankInterval)
```

Scaling rank:

```text
scalingRankOffset
= floor((learnLevel - 1) / rankInterval)

scalingRank
= displayRank + scalingRankOffset
```

Rank multiplier:

```text
rankMultiplier
= 1 + max(0, scalingRank - 1) × 0.05
```

At the normal level-60 endgame checkpoint, a level-1 spell with an 8-level interval reaches a **1.35×** rank multiplier.

Do not rank-scale spells with `usesRanks = false`.

Aura output applied by a ranked spell uses the cast's snapshotted rank multiplier where supported.

## 6.3 Critical strikes

Current default critical damage multiplier:

```text
2.0×
```

For expected-value calculations, if no special critical mechanic is involved:

```text
Expected crit multiplier
= 1 + CritChance × (CritMultiplier - 1)
```

With a 2.0× crit multiplier:

```text
Expected crit multiplier
= 1 + CritChance
```

Example:

```text
10% crit -> 1.10 expected multiplier
```

Do not fold critical-triggered effects into this multiplier. Model effects such as Ignite or Deep Wounds separately from the triggering hit.

## 6.4 Raw throughput definition

Unless otherwise specified, **raw damage** means:

- legal attacks are assumed to land;
- normal crit chance is averaged;
- proc chance is averaged;
- attacker-side damage bonuses are included;
- enemy Armor, resistances, Damage Reduction, critical mitigation, absorption, block, dodge, parry, and miss chance are excluded.

This mode is intended to compare offensive budgets without target-defense noise.

If hit/avoidance is being evaluated, report a separate **expected landed damage** result.

---

# 7. Periodic damage

RPE periodic effects use an intentionally asymmetric model.

For a standard periodic aura:

- flat base is divided across the duration;
- the full stat coefficient applies on every tick;
- the stat coefficient is **not divided by duration**.

Therefore:

```text
tick damage
= Base Per Tick
+ (Stat × Full Per-Tick Coefficient)
```

and:

```text
total periodic damage
= tick damage × actual number of ticks
```

Always model:

- initial application turn;
- refresh timing;
- whether refreshing replaces or preserves a pending tick;
- stack behavior;
- independent durations;
- aura expiry;
- rank snapshot.

Do not simply multiply tooltip damage by encounter duration if the aura cannot maintain 100% uptime.

---

# 8. Proc and reactive effects

For deterministic expected-value simulations:

```text
Expected proc count
= eligible trigger count × proc probability
```

```text
Expected proc damage
= expected proc count × expected damage per proc
```

Example:

```text
20 eligible ranged hits × 100% Hunter's Mark trigger
= 20 expected procs
```

For chained effects, identify the exact event that each component emits.

Do not assume that an effect triggers only from its owner if the authored combat event can also be emitted by other party members.

This is especially important in 10-player simulations: a debuff attached to an enemy may receive substantially more eligible trigger events from the larger roster.

Before using a proc-heavy effect in a raid simulation, inspect:

- `combatEventId`;
- `triggerTarget`;
- chance;
- damage type;
- whether the trigger can recursively activate itself;
- whether other players can trigger it;
- whether the aura has an internal cooldown or stack restriction.

---

# 9. Resource simulation

Every rotation must be resource-feasible.

Track resources turn by turn:

```text
Resource at end of turn
= Resource at start
+ regeneration
+ generated resource
+ proc resource
- spell costs
```

Include:

- starting resource behavior;
- normal regeneration;
- Resource Regeneration stat;
- resource-generating basic attacks;
- traits;
- incoming-attack resource generation;
- Bloodrage-style effects;
- spender costs;
- percent-of-base-resource costs;
- charge resources such as Holy Power or Arcane Charges.

Do not report a theoretical maximum rotation that spends more resource than the character can generate.

### Tanks

Tank resource generation often depends on **being attacked**.

For a standard single-boss tank simulation, explicitly state the boss attack cadence, for example:

```text
Boss makes one eligible auto attack against the active tank per turn.
```

If the boss attacks less often, tank Rage/reactive output must be reduced accordingly.

---

# 10. Buffs, debuffs, traits, and build modes

Use two clearly separated build modes when useful.

## 10.1 Baseline

Include:

- race/class progression;
- selected gear;
- weapon;
- always-on passive traits;
- required stance/form;
- ordinary class mechanics.

Exclude unless explicitly requested:

- optional talent traits;
- consumables;
- temporary encounter bonuses;
- external buffs not guaranteed by the roster.

## 10.2 Developed build

May additionally include:

- chosen traits/talents;
- group buffs;
- debuffs;
- set bonuses;
- consumables;
- encounter preparation.

Never apply an arbitrary percentage such as "+30% developed build" when the current mechanics can instead be modelled directly.

If an approximation is unavoidable, label it explicitly and keep it separate from the calculated baseline.

---

# 11. Five-player simulation procedure

For each of the five characters:

1. Resolve final stats.
2. Resolve weapon damage.
3. Resolve spell ranks.
4. List legal Main, Bonus, Buff, Free, and Reaction actions.
5. Build the 10-turn rotation.
6. Track resources each turn.
7. Track buffs/debuffs/auras each turn.
8. Count every direct hit.
9. Count every periodic tick.
10. Count expected procs.
11. Apply expected crit.
12. Sum raw damage.
13. If requested, run target mitigation separately.
14. Calculate threat separately.

Required party outputs:

| Output | Required |
|---|---|
| Damage by character | Yes |
| Damage per turn by character | Yes |
| Damage by source for each character | Yes |
| Party total damage | Yes |
| Party damage per turn | Yes |
| Resource feasibility | Yes |
| Threat by character when relevant | Yes |
| Assumptions/caveats | Yes |

---

# 12. Ten-player simulation procedure

Follow the same per-character process as the five-player simulation, but additionally audit group interactions.

## 12.1 Shared buffs

A group buff is applied once but may affect multiple players.

Do not:

- count its stat increase as damage by the caster;
- apply the same buff twice unless stacking is actually supported.

## 12.2 Enemy debuffs

Track shared debuffs globally.

Examples:

- Armor reductions;
- resistance reductions;
- vulnerability effects;
- Hunter's Mark-style trigger auras.

All eligible attackers may benefit from a target debuff if the runtime mechanic permits it.

## 12.3 Proc amplification

A 10-player roster may dramatically increase the number of eligible event triggers.

For each enemy aura with event-driven damage:

```text
eligible raid trigger count
= sum of eligible trigger events from every party member
```

Do not reuse the five-player proc count.

## 12.4 Tanks

For two-tank encounters, define:

- active-tank turns;
- swap turns;
- whether both tanks are attacked;
- which tank receives reactive Rage/procs;
- off-tank damage rotation.

Do not give both tanks full "being attacked every turn" resource generation unless the encounter actually does so.

## 12.5 Healers

Do not assume both healers contribute zero damage automatically.

Define expected healing load. If a healer can legally use Free Actions, Bonus Actions, DoTs, wands, or idle Main Actions while maintaining required healing, include that damage.

For damage-only boss sizing, report healer DPS separately so it can be included or excluded transparently.

---

# 13. Mitigated damage mode

Raw damage and realized damage must be separate outputs.

When mitigation is requested, use the actual target stats and current damage-school definitions.

Apply:

- Armor to Physical damage;
- relevant resistance to magical schools;
- target Damage Reduction;
- crit mitigation;
- absorption;
- other target-side modifiers.

Do not use one generic "15% physical mitigation" assumption if the target's authored Armor is available.

### Wand caveat

The current Core Wand spell is implemented as a spell attack but still carries a Physical damage-school reference.

For balance simulations, if the intended equipped wand is magical, explicitly state whether the simulation:

- follows current runtime behavior exactly; or
- treats Wand as its intended magical school for design calibration.

Never silently switch between the two.

---

# 14. Threat simulation

## 14.1 Direct damage threat

Current direct damage threat is based on **applied health damage**, not raw pre-mitigation damage.

Conceptually:

```text
Threat
= Applied Health Damage
× Effect Threat Coefficient
× (1 + Threat Generated / 100)
```

Therefore a real threat simulation must normally be run **after target mitigation**.

A "raw threat" figure based on raw damage may be useful for comparison, but it must be labelled theoretical.

## 14.2 Tank modifiers

Use the actual current stance/trait modifiers.

Example from the current Warrior dataset:

```text
Defensive Stance:
+80 Threat Generated
-10 Damage Done
```

Protection attacks may also carry elevated `threatCoefficient` values.

Do not compare tank and DPS threat using damage alone.

## 14.3 Periodic/proc threat caveat

Current periodic aura threat behavior is not identical to direct damage.

The aura damage path only generates threat when the aura damage effect explicitly has a `threatCoefficient`.

Therefore effects with no explicit periodic threat coefficient can deal damage while generating **zero threat**.

This must be audited for every simulation.

For every significant proc/DoT, report:

| Effect | Damage | Threat coefficient present? | Threat generated? |
|---|---:|---|---|

This is especially important for effects such as:

- Hunter's Mark;
- Rapid Fire;
- Serpent Sting;
- Seal procs;
- Expurgation;
- Fireball/Pyroblast periodic damage.

If the implementation changes, re-audit rather than carrying this assumption forward.

---

# 15. Healing and survival simulations

When simulating survivability, do not infer healing requirements only from boss HP.

Track:

- incoming boss damage per turn;
- tank mitigation;
- party-wide damage;
- avoidable/unavoidable damage;
- healer throughput;
- healer mana;
- absorption;
- defensive cooldowns;
- emergency healing;
- overheal if relevant.

Report at least:

```text
incoming raw damage
incoming realized damage
healing required
healing available
net health change
healer resource change
```

A boss can have an appropriate time-to-kill while still being impossible to heal, or trivial to heal.

---

# 16. Boss-health sizing

For a desired fight duration:

```text
Initial HP estimate
= expected realized party damage over the target duration
```

Then adjust for encounter mechanics such as:

- invulnerability;
- phase transitions;
- adds;
- target switching;
- forced downtime;
- execute phases;
- damage amplification;
- healing/reset mechanics.

Do not calculate boss HP from raw damage if the actual encounter will use meaningful Armor/resistance/DR.

For raw design comparisons, clearly call the result a **raw-equivalent HP budget**, not final boss HP.

---

# 17. Required result format

Every future party/raid simulation should begin with a short assumptions block.

Example:

```text
Branch/commit:
Party size:
Roster:
Level:
Gear:
Weapon sources:
Encounter duration:
Target count:
Simulation mode:
Traits:
External buffs:
Enemy mitigation:
Hit/avoidance:
Crit handling:
Proc handling:
```

Then provide a character summary:

| Character | Role | Raw damage | Raw DPT | Realized damage | Threat |
|---|---|---:|---:|---:|---:|

Then a source breakdown for each character:

| Source | Uses/Triggers | Damage per use | Total damage | Threat |
|---|---:|---:|---:|---:|

Then a party summary:

```text
Total raw damage:
Raw party DPT:
Total realized damage:
Realized party DPT:
Tank threat:
Highest non-tank threat:
Threat margin:
```

Finally list caveats and identified balance problems.

---

# 18. Validation checks

Before accepting a simulation, verify all of the following.

## Repository/data

- [ ] Current branch/commit was read.
- [ ] Current dataset versions were checked.
- [ ] Current coefficients were read from the dataset, not memory.
- [ ] Current ruleset values were checked.
- [ ] Correct gear tier was used.
- [ ] Correct endgame weapon was used.
- [ ] No starter weapon contaminated an endgame result.

## Rotation

- [ ] Cooldown channels are legal.
- [ ] Cooldowns are legal.
- [ ] Charges are legal.
- [ ] Resources never go below zero.
- [ ] Conditions are satisfied.
- [ ] Aura uptime is modelled turn by turn.
- [ ] Free Actions are not silently spammed beyond the calibration convention.

## Damage

- [ ] Rank multiplier is correct.
- [ ] Crit chance is correct.
- [ ] Proc probability is correct.
- [ ] Periodic coefficient is not incorrectly divided by duration.
- [ ] Every trigger source is counted.
- [ ] Shared raid triggers are audited.
- [ ] Raw and mitigated damage are not mixed.

## Threat

- [ ] Threat uses applied damage for realized calculations.
- [ ] Threat coefficients are read per effect.
- [ ] Threat Generated modifiers are included.
- [ ] Periodic/proc effects with missing threat coefficients are identified.
- [ ] Tank threat margin is reported against the highest-threat DPS.

---

# 19. Current known balance-sensitive areas

These are not permanent assumptions; re-check them before each future simulation.

1. **Spell Power damage scaling was recently rebalanced.**
   - Current authoring baseline is 1.00 SP for instant damage and 1.40 SP for 1-turn damage.
   - Do not use the old 0.50 / 0.70 SP damage guidance.

2. **Hunter's Mark can contribute a very large fraction of Hunter output.**
   - Its event semantics must be checked carefully in larger groups.

3. **Protection Warrior Shield Slam is currently expensive relative to its raw damage.**
   - Its threat coefficient is part of its budget.
   - Do not judge tank contribution from DPS alone.

4. **Aura/proc threat may be zero when no explicit `threatCoefficient` exists.**
   - Re-check after any threat-system changes.

5. **Wand damage-school behavior is currently a design/runtime mismatch.**
   - Record which interpretation a mitigated simulation uses.

---

# 20. Principle for future balance work

The simulation should answer:

> What can this roster legally do over this encounter, using the current authored data?

It should not answer:

> What would these classes do if every strong ability could be used whenever convenient?

The authoritative order is:

```text
current repository data
→ resolved character stats
→ legal turn sequence
→ resources/cooldowns/auras
→ raw output
→ target mitigation
→ applied damage
→ threat
→ encounter-level conclusions
```

Whenever the repository changes, the simulation must be recalculated from the affected step rather than carrying old totals forward.