# RPE 2 — Spell Ranks and Default Spell Progression
## Product Design Document

**Status:** Current design  
**Target branch:** `dev`  
**Level cap:** 60  
**Default rank interval:** 8 levels  
**Default gain per additional rank:** 5%

---

# 1. Purpose

RPE 2 supports optional, level-derived Spell ranks without creating separate Spell definitions for Rank 1, Rank 2, Rank 3, and so on.

A Spell remains one canonical dataset object. Its current rank is derived from:

- the Spell's `learnLevel`;
- the Spell's `rankInterval`;
- whether the Spell has `usesRanks = true`;
- the authoritative caster level;
- the active Ruleset's Spell-rank settings.

This document is also the canonical progression specification for all Spell records currently shipped in the default datasets.

---

# 2. Final product decisions

The finalized baseline is:

```lua
use_spell_ranks = true
spell_rank_effect_gain_percent = 5
```

Each Spell has:

```lua
learnLevel = 1
rankInterval = 8
usesRanks = true
```

unless explicitly authored otherwise.

The RPE character level cap is **60**.

Current default-dataset Spells use an explicit `rankInterval = 8`. No default Spell currently requires a custom rank interval.

For `usesRanks = false` Spells, `rankInterval` remains authored as 8 for schema consistency but is ignored by rank scaling and presentation.

Rank is derived state and is never stored on the character Profile.

---

# 3. Spell data model

## 3.1 learnLevel

`learnLevel` is the minimum character/event level at which the Spell is available through its normal acquisition path.

It is independent of `learnMode`.

Examples:

- `always_learned`: appears automatically once `learnLevel` is reached;
- `trainer` / `book`: cannot be acquired below `learnLevel`;
- `unavailable`: remains unavailable through the spellbook learning system even though the field is still valid metadata.

A stored Spell reference must not be deleted merely because a dataset update raises its `learnLevel`. It becomes temporarily unavailable until the requirement is met.

## 3.2 rankInterval

`rankInterval` is the number of levels between successive ranks.

Default and current shipped-dataset value:

```text
8
```

It must be a positive integer.

## 3.3 usesRanks

`usesRanks` controls whether the Spell receives level-derived rank scaling.

Default:

```text
true
```

When false:

- `learnLevel` still applies;
- the Spell's effective multiplier is always 1.0;
- no current-rank or next-rank presentation is shown;
- any Aura applied by the Spell receives a rank multiplier of 1.0;
- `rankInterval` is retained but ignored.

---

# 4. Rank formula

For a ranked Spell:

```text
L = authoritative caster level
S = learnLevel
N = rankInterval
```

If:

```text
L < S
```

the Spell is unavailable.

Otherwise:

```text
rank = 1 + floor((L - S) / N)
```

Example for `learnLevel = 1`, `rankInterval = 8`:

| Level | Rank |
|---:|---:|
| 1–8 | 1 |
| 9–16 | 2 |
| 17–24 | 3 |
| 25–32 | 4 |
| 33–40 | 5 |
| 41–48 | 6 |
| 49–56 | 7 |
| 57–60 | 8 |

There is no separate stored rank cap. The effective RPE cap arises from the character level cap of 60.

---

# 5. Rank effect multiplier

The active Ruleset defines:

```lua
spell_rank_effect_gain_percent = 5
```

For resolved rank `R`:

```text
bonusRanks = max(0, R - 1)
rankMultiplier = 1 + bonusRanks * 0.05
```

The increase is **linear**, not compounded.

| Rank | Bonus | Multiplier |
|---:|---:|---:|
| 1 | 0% | 1.00 |
| 2 | 5% | 1.05 |
| 3 | 10% | 1.10 |
| 4 | 15% | 1.15 |
| 5 | 20% | 1.20 |
| 6 | 25% | 1.25 |
| 7 | 30% | 1.30 |
| 8 | 35% | 1.35 |

The 5% value is Ruleset data, not an architectural constant.

When `use_spell_ranks = false`, all rank multipliers resolve to 1.0.

---

# 6. Authoritative caster level

Rank resolution must use one canonical effective-caster-level path.

For player casts:

```text
effective level = authoritative player/Profile level
```

For host-controlled NPC and autopilot casts:

```text
effective level = current eventState.level
```

NPC Spell rank must not depend on an unrelated local player level and must not invent an independent NPC level unless the architecture later adds one explicitly.

UI previews must use the same resolver where an authoritative level context exists.

---

# 7. Cast-time snapshot

Rank is resolved once when the cast becomes authoritative.

The cast context carries:

```lua
context.spellRank
context.spellRankMultiplier
```

Every component, projectile, channel tick, delayed effect, and Aura application originating from that cast uses the same snapshot.

A level or Ruleset change during an already-started cast must not cause different components of that cast to use different ranks.

---

# 8. What Spell rank scales

For `usesRanks = true`, rank scaling applies to supported magnitude-bearing Spell output.

This includes:

- direct damage;
- direct healing;
- supported magnitude-bearing Aura effects applied by the Spell;
- periodic damage/healing carried by an applied Aura;
- absorption and other supported numeric Aura output.

The multiplier applies to the complete resolved authored magnitude, including applicable stat/weapon contribution, before downstream systems such as mitigation or healing-received modifiers.

Rank scaling must not automatically scale:

- resource costs;
- cast time;
- cooldown;
- cooldown groups/channels;
- charges;
- range;
- target count;
- stack count;
- Aura duration;
- crowd-control duration;
- hit chance;
- critical chance;
- projectile speed;
- taunt behaviour;
- interrupt behaviour;
- arbitrary numeric fields merely because they are numeric.

---

# 9. Direct Resource effects

Direct Spell Resource effects are a separate opt-in.

Each Resource effect has:

```lua
scaleWithRank = false
```

by default.

Therefore:

- `usesRanks = true` does **not** automatically scale a direct Resource effect;
- `scaleWithRank = true` applies the Spell's resolved rank multiplier exactly once;
- percentage-based direct Resource effects follow the same opt-in;
- resource costs never scale;
- an unranked Spell with `scaleWithRank = true` still has multiplier 1.0.

This setting applies only to direct Spell Resource effects.

Aura Resource effects are governed by the Aura's snapshotted `rankMultiplier`.

---

# 10. Aura propagation

When a ranked Spell applies an Aura, the application snapshots:

```lua
rankMultiplier = context.spellRankMultiplier or 1
```

The existing Aura `powerLevel` remains a separate additive concept.

Conceptually:

```text
(base Aura effect + powerLevel + stat scaling)
* rankMultiplier
then percentage conversion
then stacks
then downstream handling
```

An active Aura does not silently become stronger when the caster later gains a level.

Refreshing/reapplying it through a new cast uses the new cast's rank multiplier.

Aura apply, sync, batch, deduplication/signature, and persistence paths that carry effect strength must preserve `rankMultiplier`.

Legacy or non-Spell Aura sources default to 1.0.

---

# 11. Rank eligibility policy for default Spells

`usesRanks` is based on the current RPE mechanics, not on whether some historical WoW version displayed a textual "Rank N".

Use ranks for Spells whose existing RPE output should become numerically stronger with level progression.

Do not use ranks for static utility/control/action-economy behaviour such as:

- interrupts;
- taunts;
- pure crowd control;
- fixed major cooldown percentages;
- basic weapon/pet actions already scaling through weapons/stats;
- item-use effects whose power is authored by the item Spell.

A Spell with both scalable damage/healing and a fixed Resource component can have `usesRanks = true` while the Resource component remains `scaleWithRank = false`.

---

# 12. Default dataset progression

All entries below must be authored explicitly with the listed `learnLevel`, `usesRanks`, and `rankInterval`.

The standard `rankInterval` is **8 for every current shipped Spell**.

## 12.1 Core

File: `data/default/core.lua`

| Spell | learnLevel | usesRanks | rankInterval |
|---|---:|:---:|---:|
| Main Hand Attack | 1 | false | 8 |
| Mounted Attack | 1 | false | 8 |
| Pet Attack | 1 | false | 8 |
| Summon Pet | 1 | false | 8 |
| Shoot | 1 | false | 8 |
| Throw | 1 | false | 8 |
| Wand | 1 | false | 8 |
| Off Hand Attack | 1 | false | 8 |

Core basic actions are unranked because their power already comes from weapon/stat/pet state.

## 12.2 Mage

File: `data/default/classes/mage.lua`

| Spell | learnLevel | usesRanks | rankInterval |
|---|---:|:---:|---:|
| Fireball | 1 | true | 8 |
| Pyroblast | 20 | true | 8 |
| Fire Blast | 6 | true | 8 |
| Scorch | 22 | true | 8 |
| Combustion | 40 | false | 8 |
| Flamestrike | 16 | true | 8 |
| Arcane Explosion | 14 | true | 8 |
| Fire Ward | 20 | true | 8 |
| Frost Ward | 22 | true | 8 |
| Arcane Blast | 52 | true | 8 |
| Arcane Barrage | 60 | true | 8 |
| Arcane Missiles | 8 | true | 8 |
| Arcane Surge | 60 | true | 8 |
| Evocation | 20 | false | 8 |
| Counterspell | 24 | false | 8 |
| Arcane Intellect | 1 | true | 8 |
| Frostbolt | 4 | true | 8 |
| Frost Nova | 10 | true | 8 |
| Deep Freeze | 60 | false | 8 |
| Ice Lance | 54 | true | 8 |
| Cone of Cold | 26 | true | 8 |
| Glacial Spike | 58 | true | 8 |
| Ice Armor | 30 | true | 8 |
| Molten Armor | 50 | true | 8 |
| Mage Armor | 34 | true | 8 |
| Polymorph | 8 | false | 8 |

Late-game RPE mappings are deliberately kept within the level-60 cap:

- Molten Armor: 50
- Arcane Blast: 52
- Ice Lance: 54
- Glacial Spike: 58
- Arcane Barrage, Deep Freeze, Arcane Surge: 60

## 12.3 Paladin

File: `data/default/classes/paladin.lua`

| Spell | learnLevel | usesRanks | rankInterval |
|---|---:|:---:|---:|
| Seal of the Crusader | 6 | true | 8 |
| Judgement of the Crusader | 6 | true | 8 |
| Seal of Fury | 16 | false | 8 |
| Judgement of Fury | 16 | true | 8 |
| Light of the Martyr | 20 | true | 8 |
| Lay on Hands | 10 | true | 8 |
| Consecration | 20 | true | 8 |
| Blessing of Might | 4 | true | 8 |
| Blessing of Kings | 20 | false | 8 |
| Blessing of Sanctuary | 30 | false | 8 |
| Blessing of Wisdom | 14 | true | 8 |
| Blessing of Light | 40 | true | 8 |
| Blessing of Salvation | 26 | false | 8 |
| Judgement of the Righteous | 4 | true | 8 |
| Seal of Righteousness | 1 | true | 8 |
| Judgement of Command | 20 | true | 8 |
| Seal of Command | 20 | true | 8 |
| Judgement of the Light | 30 | true | 8 |
| Seal of Light | 30 | true | 8 |
| Judgement of Wisdom | 38 | true | 8 |
| Seal of Wisdom | 38 | true | 8 |
| Crusader Strike | 50 | true | 8 |
| Templar's Verdict | 10 | true | 8 |
| Hammer of the Righteous | 60 | true | 8 |
| Shield of the Righteous | 54 | true | 8 |
| Holy Shield | 40 | true | 8 |
| Divine Protection | 6 | false | 8 |
| Holy Light | 1 | true | 8 |
| Flash of Light | 20 | true | 8 |
| Divine Favor | 30 | false | 8 |
| Exorcism | 20 | true | 8 |
| Holy Wrath | 50 | true | 8 |
| Divine Storm | 60 | true | 8 |
| Blade of Wrath | 50 | true | 8 |
| Hand of Reckoning | 16 | false | 8 |
| Rebuke | 54 | false | 8 |
| Word of Glory | 9 | true | 8 |
| Light of the Protector | 50 | true | 8 |
| Guardian of Ancient Kings | 58 | false | 8 |
| Hammer of Justice | 8 | false | 8 |
| Avenging Wrath | 56 | false | 8 |
| Templar's Bulwark | 40 | true | 8 |
| Repentance | 40 | false | 8 |

Late-game RPE mappings include:

- Crusader Strike, Holy Wrath, Blade of Wrath, Light of the Protector: 50
- Shield of the Righteous, Rebuke: 54
- Avenging Wrath: 56
- Guardian of Ancient Kings: 58
- Hammer of the Righteous and Divine Storm: 60

Fixed utility/control cooldowns remain unranked even when learned late.

## 12.4 Priest

File: `data/default/classes/priest.lua`

| Spell | learnLevel | usesRanks | rankInterval |
|---|---:|:---:|---:|
| Heal | 16 | true | 8 |
| Power Word: Shield | 6 | true | 8 |
| Greater Heal | 40 | true | 8 |
| Lesser Heal | 1 | true | 8 |
| Binding Heal | 52 | true | 8 |
| Flash Heal | 20 | true | 8 |
| Renew | 8 | true | 8 |
| Smite | 1 | true | 8 |
| Holy Fire | 20 | true | 8 |
| Pain Suppression | 50 | false | 8 |
| Divine Spirit | 30 | true | 8 |
| Prayer of Fortitude | 48 | true | 8 |
| Prayer of Shadow Protection | 56 | true | 8 |
| Psychic Scream | 14 | false | 8 |
| Psychic Horror | 50 | false | 8 |
| Shadow Word: Pain | 4 | true | 8 |
| Vampiric Touch | 50 | true | 8 |
| Mind Blast | 10 | true | 8 |
| Mind Spike | 44 | true | 8 |
| Mind Flay | 20 | true | 8 |
| Shadow Word: Death | 50 | true | 8 |

Late-game RPE mappings include:

- Pain Suppression, Psychic Horror, Vampiric Touch, Shadow Word: Death: 50
- Binding Heal: 52
- Prayer of Shadow Protection: 56

## 12.5 Rogue

File: `data/default/classes/rogue.lua`

| Spell | learnLevel | usesRanks | rankInterval |
|---|---:|:---:|---:|
| Sinister Strike | 1 | true | 8 |
| Ambush | 18 | true | 8 |
| Stealth | 1 | false | 8 |
| Backstab | 4 | true | 8 |
| Eviscerate | 1 | true | 8 |
| Mutilate | 50 | true | 8 |
| Evasion | 8 | false | 8 |
| Adrenaline Rush | 40 | false | 8 |
| Slice and Dice | 10 | false | 8 |
| Ghostly Strike | 20 | true | 8 |
| Hemmorhage | 30 | true | 8 |
| Rupture | 20 | true | 8 |
| Garrote | 14 | true | 8 |
| Kick | 12 | false | 8 |
| Gouge | 6 | false | 8 |
| Kidney Shot | 30 | false | 8 |
| Cold Blood | 30 | false | 8 |

The existing dataset spelling `Hemmorhage` is preserved here; spelling cleanup is outside the Spell-rank migration.

## 12.6 Warrior

File: `data/default/classes/warrior.lua`

| Spell | learnLevel | usesRanks | rankInterval |
|---|---:|:---:|---:|
| Overpower | 12 | true | 8 |
| Heroic Strike | 1 | true | 8 |
| Cleave | 20 | true | 8 |
| Mortal Strike | 40 | true | 8 |
| Slam | 30 | true | 8 |
| Sunder Armor | 10 | true | 8 |
| Shield Slam | 40 | true | 8 |
| Shield Bash | 12 | true | 8 |
| Taunt | 10 | false | 8 |
| Bloodrage | 10 | false | 8 |
| Inner Rage | 56 | false | 8 |
| Rend | 4 | true | 8 |
| Whirlwind | 36 | true | 8 |
| Bladestorm | 60 | true | 8 |
| Knockdown | 20 | false | 8 |
| Intimidating Shout | 22 | false | 8 |
| Shield Block | 16 | false | 8 |
| Bloodthirst | 40 | true | 8 |
| Revenge | 14 | true | 8 |
| Battle Shout | 1 | true | 8 |
| Commanding Shout | 54 | true | 8 |
| Shield Wall | 28 | false | 8 |
| Intervene | 56 | false | 8 |

Late-game RPE mappings include:

- Commanding Shout: 54
- Inner Rage and Intervene: 56
- Bladestorm: 60

## 12.7 Alchemy item-use Spells

File: `data/default/professions/alchemy.lua`

These Spells are item-cast effects. Their owning item governs access and their authored Spell values govern strength. They must not gain character Spell ranks.

| Spell | learnLevel | usesRanks | rankInterval |
|---|---:|:---:|---:|
| Minor Healing Potion | 1 | false | 8 |
| Minor Mana Potion | 1 | false | 8 |
| Minor Rejuvenation Potion | 1 | false | 8 |
| Discolored Healing Potion | 1 | false | 8 |
| Lesser Healing Potion | 1 | false | 8 |
| Rage Potion | 1 | false | 8 |
| Healing Potion | 1 | false | 8 |
| Lesser Mana Potion | 1 | false | 8 |
| Elixir of Giant Growth | 1 | false | 8 |
| Minor Magic Resistance Potion | 1 | false | 8 |
| Greater Healing Potion | 1 | false | 8 |
| Mana Potion | 1 | false | 8 |
| Great Rage Potion | 1 | false | 8 |
| Greater Mana Potion | 1 | false | 8 |
| Superior Healing Potion | 1 | false | 8 |
| Wildvine Potion | 1 | false | 8 |
| Magic Resistance Potion | 1 | false | 8 |
| Lesser Stoneshield Potion | 1 | false | 8 |
| Mighty Rage Potion | 1 | false | 8 |
| Superior Mana Potion | 1 | false | 8 |
| Major Healing Potion | 1 | false | 8 |
| Greater Stoneshield Potion | 1 | false | 8 |
| Major Mana Potion | 1 | false | 8 |
| Shadow Protection Potion | 1 | false | 8 |
| Fire Protection Potion | 1 | false | 8 |
| Frost Protection Potion | 1 | false | 8 |
| Nature Protection Potion | 1 | false | 8 |
| Greater Arcane Protection Potion | 1 | false | 8 |
| Greater Fire Protection Potion | 1 | false | 8 |
| Greater Frost Protection Potion | 1 | false | 8 |
| Greater Nature Protection Potion | 1 | false | 8 |
| Greater Shadow Protection Potion | 1 | false | 8 |
| Limited Invulnerability Potion | 1 | false | 8 |
| Mageblood Potion | 1 | false | 8 |
| Major Rejuvenation Potion | 1 | false | 8 |

## 12.8 Engineering item-use Spells

File: `data/default/professions/engineering.lua`

These Spells are item/on-use effects and therefore remain unranked.

| Spell | learnLevel | usesRanks | rankInterval |
|---|---:|:---:|---:|
| Rough Dynamite | 1 | false | 8 |
| Rough Copper Bomb | 1 | false | 8 |
| Coarse Dynamite | 1 | false | 8 |
| EZ-Thro Dynamite | 1 | false | 8 |
| Large Copper Bomb | 1 | false | 8 |
| Small Bronze Bomb | 1 | false | 8 |
| Heavy Dynamite | 1 | false | 8 |
| Big Bronze Bomb | 1 | false | 8 |
| Flame Deflector | 1 | false | 8 |
| Ice Deflector | 1 | false | 8 |
| Solid Dynamite | 1 | false | 8 |
| Iron Grenade | 1 | false | 8 |
| Big Iron Bomb | 1 | false | 8 |
| EZ-Thro Dynamite II | 1 | false | 8 |
| Goblin Sapper Charge | 1 | false | 8 |
| Mithril Frag Bomb | 1 | false | 8 |
| Flash Bomb | 1 | false | 8 |
| Hi-Explosive Bomb | 1 | false | 8 |
| Thorium Grenade | 1 | false | 8 |
| Dark Iron Bomb | 1 | false | 8 |
| Gyrofreeze Ice Reflector | 1 | false | 8 |
| Hyper-Radiant Flame Reflector | 1 | false | 8 |
| Major Recombobulator | 1 | false | 8 |
| Ultra-Flash Shadow Reflector | 1 | false | 8 |
| Arcane Bomb | 1 | false | 8 |

## 12.9 Default datasets with no Spell records

The following current default datasets contain no Spell records requiring progression fields:

- `data/default/professions/blacksmithing.lua`
- `data/default/professions/enchanting.lua`
- `data/default/professions/fishing.lua`
- `data/default/professions/inscription.lua`
- `data/default/professions/jewelcrafting.lua`
- `data/default/professions/leatherworking.lua`
- `data/default/professions/misc.lua`
- `data/default/professions/tailoring.lua`

Do not add placeholder Spell data to them.

---

# 13. Spell inspector authoring

The Spell inspector Learning page must expose:

- Uses Ranks;
- Learn Level;
- Rank Interval.

Expected defaults:

```text
Uses Ranks: true
Learn Level: 1
Rank Interval: 8
```

When `Uses Ranks` is false, Rank Interval may be disabled/visually inactive but the stored value remains intact.

The Resource-effect inspector separately exposes:

```text
Scale With Rank
```

defaulting to false.

---

# 14. Ruleset authoring

The Ruleset Character section exposes:

```text
Use Spell Ranks
Spell Rank Effect Gain (%)
```

Defaults:

```text
Use Spell Ranks: enabled
Spell Rank Effect Gain: 5%
```

The gain accepts a finite non-negative number.

Changing the active value affects future rank resolution and rank-dependent tooltip previews.

Active Aura snapshots do not retroactively change.

---

# 15. Tooltip and spellbook presentation

When ranks are enabled and the Spell uses ranks, presentation should show the resolved current rank and next rank where meaningful.

Example:

```text
Fireball
Rank 3
...
Next rank at level 25
```

Below `learnLevel`, show the required level instead of presenting the Spell as available.

For `usesRanks = false`, do not display a misleading "Rank 1".

Tokenized tooltip generation remains authoritative for effect descriptions and amounts.

Do not introduce handwritten duplicate descriptions.

---

# 16. Serialization and compatibility

Legacy Spell records that omit rank fields normalize to:

```lua
learnLevel = 1
rankInterval = 8
usesRanks = true
```

Legacy direct Resource effects that omit the opt-in normalize to:

```lua
scaleWithRank = false
```

Canonical export should include normalized rank fields so newly saved Spell definitions are explicit.

No Profile rank migration is required because rank is derived state.

---

# 17. Default dataset update requirements

When implementing the progression table:

- modify the canonical registered default dataset files, not `data/default/spells_to_add.lua`;
- add explicit `learnLevel`, `usesRanks`, and `rankInterval = 8` to every affected Spell;
- do not alter Spell IDs;
- do not alter Aura IDs or Aura references;
- do not change `learnMode`;
- do not create per-rank Spell definitions;
- do not opt direct Resource effects into rank scaling unless separately required;
- increment the packaged version of every modified default dataset.

Updating a packaged default dataset must not reactivate a dataset the user deliberately deactivated.

---

# 18. Validation requirements

Static validation must prove:

1. every Spell in Core, Mage, Paladin, Priest, Rogue, Warrior, Alchemy, and Engineering has an explicit positive `learnLevel`;
2. every such Spell has an explicit boolean `usesRanks`;
3. every such Spell has explicit `rankInterval = 8`;
4. no default class Spell has `learnLevel > 60`;
5. every Core, Alchemy, and Engineering Spell has `usesRanks = false`;
6. Alchemy and Engineering item-use Spells have `learnLevel = 1`;
7. direct Resource effects remain `scaleWithRank = false` unless separately authored;
8. Spell/Aura IDs and references remain unchanged;
9. modified packaged dataset versions are incremented;
10. the Ruleset default gain is 5%.

Runtime checks must cover:

- level-gated always-learned Spells;
- ranked damage/healing at several levels;
- an unranked control Spell;
- a ranked Spell containing a fixed direct Resource gain;
- Aura rank propagation;
- NPC/autopilot rank resolution from `eventState.level`;
- an Alchemy or Engineering item-use Spell remaining unchanged across character levels;
- Rank 8 at level 60 for a level-1 / interval-8 ranked Spell producing a 1.35 multiplier.

---

# 19. Non-goals

This design does not:

- create independent Spell records for each rank;
- store Spell rank on Profiles;
- automatically scale every numeric field;
- scale cooldowns or crowd-control duration;
- give item-use Spells character progression;
- introduce custom per-Spell rank intervals in the current default datasets;
- change the level cap above 60.

---

# 20. Summary

The canonical defaults are:

```text
Level cap: 60
Spell ranks enabled: yes
Gain per additional rank: 5%
Default/current shipped rank interval: 8 levels
```

Ranked Spell progression is:

```text
rank = 1 + floor((level - learnLevel) / rankInterval)
multiplier = 1 + (rank - 1) * 0.05
```

The default datasets must explicitly author each Spell's unlock level, rank eligibility, and interval according to this document.
