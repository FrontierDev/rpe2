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

The user-facing Spell rank remains relative to the Spell's own `learnLevel`:

```text
displayRank = 1 + floor((level - learnLevel) / rankInterval)
```

Effect scaling uses the derived hidden scaling offset:

```text
scalingRankOffset = floor((learnLevel - 1) / rankInterval)
scalingRank = displayRank + scalingRankOffset
rankMultiplier = 1 + max(0, scalingRank - 1) * 0.05
```

The hidden `scalingRank` is never shown to the player.

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
- arbitrary numeric fields merely because they are numeric;
- fixed utility magnitudes on hybrid Spells unless that specific effect is intentionally rank-scaled.

For hybrid Spells, ranking the Spell's damage must not implicitly increase unrelated fixed utility. Examples include Mortal Strike's healing-reduction Aura and Holy Shield's Block Chance bonus.

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

Individual numeric Aura effects may opt out of the Aura's snapshotted Spell-rank multiplier:

```lua
scaleWithRank = false
```

The default is `true`, preserving existing ranked-Aura behaviour.

This is required for hybrid Auras where one magnitude should rank while another remains fixed. Examples:

- Ice Armor: Armor percentage ranks; Frost Resistance remains fixed.
- Molten Armor: retaliation damage ranks; Spell Crit. Chance remains fixed.
- Mortal Strike: damage can rank while its healing-reduction magnitude remains fixed.
- Holy Shield: retaliation damage can rank while Block Chance remains fixed.

---



# 11. Rank eligibility policy for default Spells

`usesRanks` is based on the current RPE mechanics, not on whether some historical WoW version displayed a textual "Rank N".

Use ranks for Spells whose existing RPE output should become numerically stronger with level progression.

Do not use ranks for static utility/control/action-economy behaviour such as:

- interrupts;
- taunts;
- pure crowd control;
- fixed major cooldown percentages;
- **group-wide buffs in the Paladin, Mage, Warrior and Priest datasets**;
- basic weapon/pet actions already scaling through weapons/stats;
- item-use effects whose power is authored by the item Spell.

The current default group buffs treated as unranked are:

- Mage: `Arcane Intellect`;
- Paladin: `Blessing of Might`, `Blessing of Kings`, `Blessing of Sanctuary`, `Blessing of Wisdom`, `Blessing of Light`, `Blessing of Salvation`;
- Priest: `Divine Spirit`, `Prayer of Fortitude`, `Prayer of Shadow Protection`;
- Warrior: `Battle Shout`, `Commanding Shout`.

Additionally, `Judgement of Wisdom` and `Mage Armor` are unranked, while `Seal of Fury` is ranked.

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
| Arcane Intellect | 1 | false | 8 |
| Frostbolt | 4 | true | 8 |
| Frost Nova | 10 | true | 8 |
| Deep Freeze | 60 | false | 8 |
| Ice Lance | 54 | true | 8 |
| Cone of Cold | 26 | true | 8 |
| Glacial Spike | 58 | true | 8 |
| Ice Armor | 30 | true | 8 |
| Molten Armor | 50 | true | 8 |
| Mage Armor | 34 | false | 8 |
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
| Seal of Fury | 16 | true | 8 |
| Judgement of Fury | 16 | true | 8 |
| Light of the Martyr | 20 | true | 8 |
| Lay on Hands | 10 | true | 8 |
| Consecration | 20 | true | 8 |
| Blessing of Might | 4 | false | 8 |
| Blessing of Kings | 20 | false | 8 |
| Blessing of Sanctuary | 30 | false | 8 |
| Blessing of Wisdom | 14 | false | 8 |
| Blessing of Light | 40 | false | 8 |
| Blessing of Salvation | 26 | false | 8 |
| Judgement of the Righteous | 4 | true | 8 |
| Seal of Righteousness | 1 | true | 8 |
| Judgement of Command | 20 | true | 8 |
| Seal of Command | 20 | true | 8 |
| Judgement of the Light | 30 | true | 8 |
| Seal of Light | 30 | true | 8 |
| Judgement of Wisdom | 38 | false | 8 |
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
| Divine Spirit | 30 | false | 8 |
| Prayer of Fortitude | 48 | false | 8 |
| Prayer of Shadow Protection | 56 | false | 8 |
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
| Battle Shout | 1 | false | 8 |
| Commanding Shout | 54 | false | 8 |
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


## 12.10 High-cost, special-resource and hybrid damage review

The following Spells were reviewed separately because their damage budget is affected by high resource cost, special-resource expenditure, multi-targeting, repeated procs/ticks, or fixed utility carried by the same Spell.

The formulas below are the current authored values before downstream mitigation/critical handling and before the Spell-rank multiplier.

| Spell / effect | Cost / constraint | Current damage component | Decision |
|---|---|---|---|
| Bladestorm | 30 Rage; 10-turn cooldown; up to 4 marked targets | `93.656 + 0.4625 × Melee Attack Power + 0.925 × Main-Hand damage` per target | **Keep.** It is materially stronger than Whirlwind, but the 10-turn cooldown and 30-Rage cost justify that premium. |
| Mortal Strike | 30 Rage; 4-turn cooldown; applies −50% Healing Received | `92.438 + 0.4314 × Melee Attack Power + 1.2325 × Main-Hand damage` | **Keep the damage.** The −50% Healing Received Aura is fixed utility and must not become stronger merely because the damage ranks. |
| Seal of Righteousness proc | Seal costs 5% Base Mana; guaranteed on basic attacks | `28.1667 + 0.4225 × Spell Power` per proc | **Aligned to the existing damage scale.** Uses the same per-proc magnitude as one Ignite tick, but as guaranteed basic-attack bonus damage. |
| Seal of Fury proc | Seal costs 5% Base Mana; guaranteed on basic attacks; also applies Righteous Indignation on melee hits | `28.1667 + 0.29575 × Melee Attack Power` per proc | **Aligned to the existing damage scale.** Uses the same per-proc magnitude as one Deep Wounds tick. Fury remains the defensive seal because it also applies Righteous Indignation. |
| Seal of Command proc | Seal costs 5% Base Mana; 70% chance on basic-attack hit | `55.25 + 0.4225 × Melee Attack Power` per successful proc | **Aligned to the existing damage scale.** Deliberately burstier than Righteousness/Fury. At 70% proc chance its expected AP contribution is `0.29575 × AP` per basic hit, matching the Deep Wounds/Fury AP coefficient while retaining a higher expected base-damage contribution. |
| Molten Armor retaliation | 5% Base Mana; 10-turn self Aura; triggers when hit by melee; also grants fixed +5 Spell Crit. Chance | `28.1667 + 0.4225 × Spell Power` per trigger | **Rebalanced to the existing damage scale.** Uses the same per-trigger damage as one Ignite tick. The damage is rank-scaled; the +5 Spell Crit. Chance is explicitly fixed. |
| Ice Armor | 5% Base Mana; 10-turn self Aura; retaliatory Chilled application; fixed +30 Frost Resistance | `30% Armor` authored base, multiplied by the Spell-rank multiplier | **Ranked defensive scaling.** Only the Armor percentage scales with rank; Frost Resistance remains +30. |
| Holy Shield proc | 5% Base Mana; 3-turn Aura; +30 Block Chance; proc on successful block | `96 + 0.20 × Spell Power` per successful block | **Do not change the number yet.** The balance risk is repeated proc frequency, not the one-shot coefficient. Fixed +30 Block Chance must remain fixed when the proc damage ranks. |
| Templar's Verdict | 3 Holy Power | `168.75 + 0.7875 × Melee Attack Power + 2.25 × Main-Hand damage` | **Keep.** It is the single-target Holy-Power finisher. |
| Divine Storm | 3 Holy Power; up to 3 marked targets | `101.25 + 0.4725 × Melee Attack Power + 1.35 × Main-Hand damage` per target | **Keep.** Each target receives exactly 60% of Templar's Verdict's authored damage coefficients, giving a clear single-target/AoE trade. |
| Eviscerate | 15 Energy + 5 Combo Points | `225 + 0.7875 × Melee Attack Power` | **Keep.** The high immediate damage is appropriate for a full Combo Point finisher. |
| Rupture | 15 Energy + 5 Combo Points; 5-turn DoT | `20.8 + 0.364 × Melee Attack Power` per turn for 5 turns | **Keep for now.** It provides the sustained-damage alternative to Eviscerate; periodic coefficient semantics should be reviewed globally rather than changing Rupture alone. |
| Ambush | 60 Energy; requires Stealth and a dagger; generates 2 Combo Points | `143.438 + 0.6694 × Melee Attack Power + 1.9125 × Main-Hand damage` | **Keep.** Its damage coefficients are exactly 2.25× Sinister Strike's, with meaningful positional/resource gating. |
| Pyroblast | 31.8% Base Mana; direct hit plus 5-turn DoT | Direct: `258.188 + 1.3388 × Spell Power`; DoT: `17.68 + 0.442 × Spell Power` per turn | **Keep the direct hit. Review the DoT convention globally.** The DoT coefficient is applied on every tick, so the full five-turn spell has much larger total Spell Power scaling than the direct component alone suggests. Do not alter Pyroblast in isolation while other DoTs use the same per-turn convention. |
| Arcane Barrage | 4 Arcane Charges | `191.25 + 0.9563 × Spell Power` | **Keep.** It is a true special-resource spender and also enables Arcane Missiles. |
| Arcane Surge | 100% Max Mana; 10-turn cooldown; restores 8% Max Mana per turn for 10 turns | `353.813 + 1.7691 × Spell Power` | **Keep.** The up-front cost is extreme, but up to 80% Max Mana is returned over the Aura duration. |
| Shield Slam | 30 Rage; requires shield; threat coefficient 2 | `104 + 0.364 × Melee Attack Power` | **Keep.** A substantial part of the 30-Rage budget is the doubled threat generation rather than raw damage. |
| Shadow Word: Death | 13.6% Base Mana; target must be at or below 20% health | `225 + 1.125 × Spell Power` | **Keep.** The execute gate justifies the higher damage relative to ordinary Priest nukes. |

Other relatively expensive damage Spells do not presently require special treatment:

- `Frost Nova` and `Cone of Cold`: their cost pays for control/AoE utility as well as damage.
- `Holy Wrath`: the mana premium is tied to multi-target damage.
- `Whirlwind`: already sits below Bladestorm in per-target damage and has the shorter cooldown.
- ordinary builders that generate Holy Power, Combo Points or Arcane Charges are not treated as special-resource spenders simply because they create a special resource.

### Hybrid-Aura implementation requirement

The intended data semantics are:

- rank-scaled damage/healing can increase;
- fixed control/utility magnitudes remain fixed unless explicitly opted in.

The current Aura runtime stores one `rankMultiplier` on the entire applied Aura and `AuraManager:ResolveEffectAmount()` multiplies resolved Aura effect amounts by it. That is too coarse for hybrid Auras such as Mortal Strike and Holy Shield.

Do **not** solve this by making those whole Spells unranked, because their damage is intended to rank. The implementation needs effect-level control (or an equivalent explicit exclusion) before hybrid Aura ranking is fully correct.

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
10. the Ruleset default gain is 5%;
11. Aura numeric effects default to `scaleWithRank = true`, while explicit `false` effects remain at authored magnitude;
12. Ice Armor scales only its Armor percentage and Molten Armor scales only its retaliation damage.

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
displayRank = 1 + floor((level - learnLevel) / rankInterval)
scalingRankOffset = floor((learnLevel - 1) / rankInterval)
scalingRank = displayRank + scalingRankOffset
multiplier = 1 + (scalingRank - 1) * 0.05
```

The default datasets must explicitly author each Spell's unlock level, rank eligibility, and interval according to this document.
