## Purpose

Apply the finalized Spell progression metadata to the existing Spells shipped in the default datasets.

This issue is the **content/data migration** for the Spell Rank system and depends on #379.

Canonical design document:

`docs/PDD-Spell-Ranks.md`

Do not implement a separate rank-scaling formula in this issue. #379 owns the distinction between:

- displayed Spell rank;
- hidden scaling offset/intercept;
- runtime `spellRankMultiplier`.

This issue only authors the correct Spell metadata.

---

## Required fields

Every existing Spell in the affected registered default datasets must explicitly contain:

```lua
learnLevel = <value>,
usesRanks = <true|false>,
rankInterval = 8,
```

The current shipped default interval is **8 for every existing default Spell**.

Even Spells with:

```lua
usesRanks = false
```

must explicitly retain:

```lua
rankInterval = 8
```

for canonical dataset consistency. The interval is ignored at runtime for unranked Spells.

---

## Progression semantics

### learnLevel

Controls when the Spell first becomes available.

A newly learned ranked Spell displays **Rank 1**, regardless of the hidden multiplier offset introduced by #379.

No default class Spell may have:

```text
learnLevel > 60
```

because the RPE level cap is 60.

Later-expansion abilities that historically appeared above level 60 are deliberately redistributed through levels 50–60.

### usesRanks

Set to `true` when the current RPE Spell has magnitude-bearing output that should improve with Spell-rank scaling:

- damage;
- healing;
- absorption;
- magnitude-bearing Aura output;
- periodic damage/healing;
- other supported scalable numeric output.

Set to `false` for static behaviour such as:

- interrupts;
- taunts;
- pure control;
- fixed major cooldown percentages;
- basic weapon/pet actions already scaling through other systems;
- item-use effects whose authored item Spell defines their strength.

A Spell may have `usesRanks = true` while its direct Resource component remains fixed. Direct Resource scaling remains separately controlled by:

```lua
scaleWithRank = false
```

by default.

### rankInterval

All current default Spells use:

```lua
rankInterval = 8
```

Do not infer or omit the field simply because 8 is the schema default. The packaged defaults should state it explicitly.

---


## Core

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

## Mage

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

## Paladin

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

## Priest

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

## Rogue

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

## Warrior

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


---

## Alchemy

File:

`data/default/professions/alchemy.lua`

All **35 existing Spell records** in the Alchemy `spells` table are item-use effects.

For every Alchemy Spell set:

```lua
learnLevel = 1,
usesRanks = false,
rankInterval = 8,
```

This applies to:

- Minor Healing Potion
- Minor Mana Potion
- Minor Rejuvenation Potion
- Discolored Healing Potion
- Lesser Healing Potion
- Rage Potion
- Healing Potion
- Lesser Mana Potion
- Elixir of Giant Growth
- Minor Magic Resistance Potion
- Greater Healing Potion
- Mana Potion
- Great Rage Potion
- Greater Mana Potion
- Superior Healing Potion
- Wildvine Potion
- Magic Resistance Potion
- Lesser Stoneshield Potion
- Mighty Rage Potion
- Superior Mana Potion
- Major Healing Potion
- Greater Stoneshield Potion
- Major Mana Potion
- Shadow Protection Potion
- Fire Protection Potion
- Frost Protection Potion
- Nature Protection Potion
- Greater Arcane Protection Potion
- Greater Fire Protection Potion
- Greater Frost Protection Potion
- Greater Nature Protection Potion
- Greater Shadow Protection Potion
- Limited Invulnerability Potion
- Mageblood Potion
- Major Rejuvenation Potion

Their owning item controls access. Character level must not independently rank potion potency.

---

## Engineering

File:

`data/default/professions/engineering.lua`

All **25 existing Spell records** in the Engineering `spells` table are item/on-use effects.

For every Engineering Spell set:

```lua
learnLevel = 1,
usesRanks = false,
rankInterval = 8,
```

This applies to:

- Rough Dynamite
- Rough Copper Bomb
- Coarse Dynamite
- EZ-Thro Dynamite
- Large Copper Bomb
- Small Bronze Bomb
- Heavy Dynamite
- Big Bronze Bomb
- Flame Deflector
- Ice Deflector
- Solid Dynamite
- Iron Grenade
- Big Iron Bomb
- EZ-Thro Dynamite II
- Goblin Sapper Charge
- Mithril Frag Bomb
- Flash Bomb
- Hi-Explosive Bomb
- Thorium Grenade
- Dark Iron Bomb
- Gyrofreeze Ice Reflector
- Hyper-Radiant Flame Reflector
- Major Recombobulator
- Ultra-Flash Shadow Reflector
- Arcane Bomb

Item requirements govern availability and item-authored values govern strength.

---

## Default datasets with no Spell changes

The following current registered default datasets contain no Spell records requiring this migration:

- `data/default/professions/blacksmithing.lua`
- `data/default/professions/enchanting.lua`
- `data/default/professions/fishing.lua`
- `data/default/professions/inscription.lua`
- `data/default/professions/jewelcrafting.lua`
- `data/default/professions/leatherworking.lua`
- `data/default/professions/misc.lua`
- `data/default/professions/tailoring.lua`

Do not add placeholder Spell records to them.

`data/default/spells_to_add.lua` is not the canonical registered default dataset source and must not be edited instead of the class/default dataset files above.

---

## Packaged dataset versions

Every modified packaged default dataset must have its version incremented from the value present when implementation begins.

Expected affected datasets:

- Core
- Mage
- Paladin
- Priest
- Rogue
- Warrior
- Alchemy
- Engineering

Do not hard-code an old version number from this issue if another commit has already advanced a dataset version.

Updating a packaged default dataset must not reactivate it if the user deliberately deactivated that dataset.

---

## Implementation constraints

Do not:

- create separate Spell definitions for individual ranks;
- alter Spell IDs;
- alter Aura IDs or references;
- change `learnMode`;
- change class spell-list references;
- author a scaling offset/intercept field—the offset is derived by #379;
- use any interval other than 8 in the current default migration;
- opt Resource effects into `scaleWithRank = true` unless separately required;
- hand-write rank-specific tooltip descriptions;
- rebalance base damage/healing merely to compensate for displayed rank.

Keep the three progression fields together near the existing Spell learning metadata where practical:

```lua
learnMode = "...",
learnLevel = ...,
usesRanks = ...,
rankInterval = 8,
spellbookCategory = "...",
```

---

## Validation

Static validation must confirm:

- [ ] Every Spell in Core, Mage, Paladin, Priest, Rogue, Warrior, Alchemy, and Engineering has an explicit positive-integer `learnLevel`.
- [ ] Every Spell in those datasets has an explicit boolean `usesRanks`.
- [ ] Every Spell in those datasets has explicit `rankInterval = 8`.
- [ ] No default class Spell has `learnLevel > 60`.
- [ ] Every Core Spell is unranked.
- [ ] Every Alchemy and Engineering item-use Spell has `learnLevel = 1`, `usesRanks = false`, `rankInterval = 8`.
- [ ] Spell IDs are unchanged.
- [ ] Aura IDs/references are unchanged.
- [ ] `learnMode` values are unchanged.
- [ ] Direct Resource effects are not accidentally opted into rank scaling.
- [ ] All affected packaged dataset versions are incremented.

Runtime smoke checks after #379 is present:

1. A level-1 / interval-8 ranked Spell displays Rank 5 at level 40 and uses x1.20.
2. A level-30 / interval-8 ranked Spell displays Rank 2 at level 40 and also uses x1.20.
3. A newly unlocked later-level Spell displays Rank 1 at its `learnLevel`.
4. An unranked Spell such as Counterspell/Taunt/Hammer of Justice remains x1.00.
5. A potion or engineering item-use Spell remains x1.00 regardless of character level.
6. Level gating correctly adds/removes always-learned class Spells from effective availability.
7. No default class Spell becomes inaccessible because its `learnLevel` exceeds the level cap.

---

## Relationship to #378

This issue supersedes the default-dataset migration scope in #378.

Use this issue plus #379 as the implementation authority because they reflect the finalized separation between displayed rank and scaling multiplier and explicitly require `rankInterval` on every existing default Spell.
