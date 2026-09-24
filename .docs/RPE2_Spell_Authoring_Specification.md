# RPE2 Spell Authoring & Balance Specification

**Purpose:** this is the authoritative implementation guide for adding or rebalancing RPE2 spells in the default datasets.

A Codex task should be able to say things such as:

- "Add a single-target 3-turn-cooldown Main Action damage spell that scales with Spell Power."
- "Add a 5-turn Bonus Action DoT."
- "Add a two-target healer spell."
- "Add a melee weapon spender with a secondary debuff."
- "Add a 5-turn HoT."
- "Add a group stat buff."

and use this document to determine the correct numeric budget and implementation conventions.

Do not use old generated balance tables or WoW retail/classic coefficients as substitutes for this specification. The constants originate from the RPE balance model, but the rules below define how they are interpreted for this turn-based system.

---

## 1. Mandatory Codex workflow

When adding or changing a spell:

1. **Read the current dataset file first.** Never work from an old PDD, old diff, or remembered schema.
2. Identify the spell's:
   - role profile: **DPS**, **Healer**, or **Tank**;
   - balance action: **Action**, **Bonus Action**, or **Spender**;
   - runtime cooldown channel;
   - cast time;
   - target count;
   - runtime cooldown;
   - scaling stat;
   - whether it uses weapon damage;
   - whether it has a meaningful secondary effect;
   - resource and resource type.
3. Choose the formula from this document.
4. Calculate the values before editing the Lua.
5. Find the closest current spell/aura in the repository and copy its **schema shape**, not its numbers.
6. Resolve all stat, resource, damage-school, aura, condition, targeter, and other refs from the current datasets. Never guess a ref.
7. Generate unique IDs/keys using the repository's current convention. Check for collisions.
8. Keep tooltip templates synchronized with the actual components/aura effects.
9. Do not rebalance unrelated spells while implementing a new one.
10. Bump the modified packaged dataset's **top-level dataset wrapper version** exactly once.
11. Do not modify nested tooltip/template `version = 1` fields when bumping a dataset.
12. Review the final diff for accidental changes and recalculate every numeric output in the new spell.

If the requested mechanic is explicitly outside this document's balance model, use a current same-mechanic analogue or an explicit value from the task. **Do not invent a new balancing rule.**

---

# 2. Concepts that must not be conflated

## 2.1 Balance action vs cooldown channel

The calculator has three balance actions:

| Balance action | Power modifier | Threat modifier | Mana-cost modifier |
|---|---:|---:|---:|
| Action | 1.00 | 1.00 | 1.00 |
| Bonus Action | 0.65 | 0.75 | 1.25 |
| Spender | 2.25 | 1.00 | 0.75 |

The default ruleset has runtime cooldown channels:

| Channel | Default name | GCD | Off-turn |
|---:|---|---|---|
| 1 | Main Action | Yes | No |
| 2 | Bonus Action | Yes | No |
| 3 | Buff Action | Yes | No |
| 4 | Free Action | No | No |
| 5 | Reaction | Yes | Yes |

These are **not the same system**.

Default interpretation:

- a normal Main Action spell uses the **Action** balance profile;
- a normal Bonus Action spell uses the **Bonus Action** balance profile;
- a **Spender** uses the Spender balance profile regardless of which runtime channel it occupies;
- pure Buff Action utility spells follow their utility/buff rule rather than pretending there is a fourth calculator action;
- Free Action and Reaction do not have independent spreadsheet power multipliers.

If an output-bearing Buff/Free/Reaction spell has no named existing analogue and the task does not specify an Action/Bonus/Spender-equivalent power budget, do **not** silently invent a multiplier.

## 2.2 Role profile vs effect type

A healing component is not automatically "Healer" and a damage component is not automatically "DPS".

The role profile describes the intended archetype of the spell/kit.

Examples:

- a dedicated healer's primary heal: **Healer + Healing**;
- a DPS spell that also self-heals: **DPS + Healing**;
- a tank damage/threat attack: **Tank + Damage**.

If the task does not explicitly state the role, use the role of the closest existing spell in that class/category.

---

# 3. Core power constants

## 3.1 Cast modifiers for base output

| Effect | Instant | 1-turn cast |
|---|---:|---:|
| Damage | 1.00 | 1.35 |
| Healing | 1.00 | 1.45 |
| Generic absorption | 1.00 | 1.45 |

The calculator only defines instant and 1-turn casts. Do not extrapolate a new cast-time multiplier for longer casts without an explicit design instruction.

## 3.2 Base stat coefficients

| Damage scaling stat | Instant | 1-turn cast |
|---|---:|---:|
| Melee Attack Power | 0.35 | 0.50 |
| Ranged Attack Power | 0.35 | 0.50 |
| Spell Power | 1.00 | 1.40 |

| Healing scaling stat | Instant | 1-turn cast |
|---|---:|---:|
| Healing Power | 0.60 | 0.80 |

The 1.00 / 1.40 Spell Power values are **damage coefficients only**. Existing heals, absorption effects, stat effects and other non-damage mechanics that intentionally scale from Spell Power are not automatically doubled. They retain their existing balance basis unless separately recalibrated. Absorption effects retain their existing non-damage Spell Power basis.

**Important:** the cast benefit is already represented by choosing the Instant or 1-turn coefficient. Do not multiply the stat coefficient by the base-output cast modifier again.

## 3.3 Target modifiers

| Maximum targets | Per-target modifier | Total-target modifier |
|---:|---:|---:|
| 1 | 1.00 | 1.00 |
| 2 | 0.75 | 1.50 |
| 3 | 0.60 | 1.80 |
| 4 | 0.50 | 2.00 |
| 5 | 0.45 | 2.25 |

Use the spell's **maximum possible target count** for balance.

The per-target modifier affects output and coefficients.

The total-target modifier is used for resource tiering.

For an output spell capable of hitting more than five targets, the calculator has no additional row. Use the 5-target band unless the task explicitly defines a different balance treatment.

Raid-marker restrictions, target-selection UX, and other targeting mechanics do not themselves add a power modifier.

## 3.4 Cooldown modifiers

| Cooldown | Modifier |
|---|---:|
| None / 0 turns | 1.00 |
| 1 turn | 1.05 |
| 2 turns | 1.15 |
| 3 turns | 1.30 |
| 4 turns | 1.45 |
| 5 turns | 1.60 |
| 6+ turns | 1.85 |

For ordinary direct spells, use the runtime spell cooldown.

Cooldown groups do not create an additional multiplier.

For standard periodic spells, see the separate periodic rule: aura duration is used as the cooldown-equivalent for the periodic budget.

## 3.5 Secondary-effect modifier

A meaningful secondary effect applies:

```text
Secondary modifier = 0.85
```

Examples of meaningful secondary effects include:

- applying a DoT/HoT in addition to a direct effect;
- applying a stat debuff;
- applying control;
- generating/restoring an additional resource;
- providing a secondary heal;
- providing another separately useful effect.

A pure damage spell with no additional utility uses 1.00.

For a spell with multiple independently useful numerical output components, each component being independently budgeted uses the 0.85 secondary modifier unless the task explicitly defines a different split.

## 3.6 Role output modifiers

| Role profile | Damage | Healing | Generic absorption |
|---|---:|---:|---:|
| DPS | 1.00 | 0.50 | 1.00 |
| Healer | 0.70 | 1.00 | 1.00 |
| Tank | 0.80 | 0.55 | 1.00 |

Absorption is treated as full defensive output rather than using the healing reduction.

## 3.7 Role threat modifiers

| Role profile | Threat modifier |
|---|---:|
| DPS | 1.00 |
| Healer | 0.50 |
| Tank | 2.00 |

---

# 4. Direct damage and healing

## 4.1 Base output

For one direct damage or healing component:

```text
Base Effect / Target
= 100
× Cast Modifier
× Action Power Modifier
× Per-Target Modifier
× Cooldown Modifier
× Secondary Modifier
× Role Effect Modifier
```

Use the role's Damage or Healing column as appropriate.

## 4.2 Stat coefficient

```text
Stat Coefficient / Target
= Base Stat Coefficient for the cast time
× Action Power Modifier
× Per-Target Modifier
× Cooldown Modifier
× Secondary Modifier
× Role Effect Modifier
```

Do **not** multiply by the base-output Cast Modifier again.

## 4.3 Threat coefficient

Where the effect schema has an explicit threat coefficient:

```text
Threat Coefficient
= Role Threat Modifier
× Action Threat Modifier
```

Do not multiply threat by cast time, cooldown, target count, or the secondary-effect modifier unless a specific mechanic says otherwise.

For schemas that do not support an explicit threat field, do not invent one.

---

# 5. Weapon attacks

A direct effect that includes weapon damage uses the normal direct formula, with the following additional rules.

## 5.1 Flat base reduction

```text
Weapon-attack Flat Base
= Normal Direct Base × 0.75
```

This leaves part of the budget for weapon damage.

## 5.2 Stat coefficient

Use the normal direct stat-coefficient formula. Do not multiply it by 0.75.

## 5.3 Weapon coefficient

```text
Weapon Damage Coefficient
= 1.00
× Action Power Modifier
× Per-Target Modifier
× Cooldown Modifier
× Secondary Modifier
× Role Effect Modifier
```

There is no extra cast multiplier in the weapon coefficient.

If `weaponDamageMode = "none"`, `weaponDamageCoefficient` must be 0.

Do not give an Aura periodic effect a made-up weapon coefficient: the current Aura schema does not provide the same generic periodic weapon-damage model. Use the requested supported scaling model or an existing analogue instead.

## 5.4 Example — basic Main Action weapon strike

Instant, one target, DPS, no cooldown, no secondary effect:

```text
Flat base = 100 × 1.00 × 1.00 × 1.00 × 1.00 × 1.00 × 1.00 × 0.75
          = 75

Melee AP coefficient = 0.35

Weapon coefficient = 1.00
```

If the same attack also has a meaningful secondary effect:

```text
Flat base = 63.75
Melee AP coefficient = 0.2975
Weapon coefficient = 0.85
```

---

# 6. Periodic damage and healing

This section is intentionally explicit because periodic effects use an asymmetric RPE rule.

## 6.1 Standard periodic archetype

For an ordinary DoT or HoT:

- model the periodic effect approximately as an **Instant Bonus Action**;
- use the **aura duration as the cooldown-equivalent**;
- calculate the periodic total **base** budget;
- divide the **base amount only** across the aura ticks;
- calculate the stat coefficient using the same Bonus Action / duration-equivalent modifiers;
- apply the **full calculated stat coefficient on every tick**;
- **do not divide the stat coefficient by duration**.

RPE2 top-level aura effects tick once per owner turn.

Therefore an aura with duration `N` has `N` ticks.

This rule is intentionally asymmetric.

The total flat base is budgeted across the duration, but the scaling coefficient repeats at full strength on each tick.

**Do not "correct" or normalize this asymmetry.**

## 6.2 Periodic base amount

```text
Periodic Total Base / Target
= 100
× 1.00                          [Instant]
× 0.65                          [Bonus Action]
× Per-Target Modifier
× CooldownModifier(Duration)
× Secondary Modifier
× Role Effect Modifier

Periodic Base / Tick / Target
= Periodic Total Base / Duration
```

## 6.3 Periodic stat coefficient

```text
Periodic Stat Coefficient / Tick / Target
= Instant Base Stat Coefficient
× 0.65                          [Bonus Action]
× Per-Target Modifier
× CooldownModifier(Duration)
× Secondary Modifier
× Role Effect Modifier
```

There is **no division by duration** in this coefficient formula.

## 6.4 Runtime cooldown vs duration-equivalent cooldown

A standard DoT/HoT may have runtime `cooldown = 0`.

That does not mean its periodic budget uses the no-cooldown multiplier.

For the periodic component, use:

```text
CooldownModifier(aura duration)
```

as the balance surrogate.

Do not multiply by both the duration-equivalent modifier and the runtime cooldown unless the task explicitly defines a separate cooldown-based power increase.

## 6.5 Example — Shadow Word: Pain

Five turns, one target, DPS, primary DoT, Spell Power:

```text
Periodic total flat base
= 100 × 0.65 × 1.60
= 104

Flat base per tick
= 104 / 5
= 20.8
```

```text
Spell Power damage coefficient per tick
= 1.00 × 0.65 × 1.60
= 1.04
```

Correct result:

```text
20.8 + (Spell Power × 1.04) damage each turn for 5 turns
```

The full-duration flat base is 104.

The full-duration scaling contribution is five applications of the 1.04 coefficient. This is intentional.

## 6.6 Example — 2-turn secondary melee DoT

Two turns, one target, DPS, Melee AP, meaningful secondary effect:

```text
Total flat base
= 100 × 0.65 × 1.15 × 0.85
= 63.5375

Flat base / tick
= 31.76875
≈ 31.7688
```

```text
Melee AP coefficient / tick
= 0.35 × 0.65 × 1.15 × 0.85
= 0.22238125
≈ 0.2224
```

## 6.7 Current default periodic reference values

These are useful regression examples of the formula, not special overrides:

| Class | Effect | Duration | Base / turn | Coefficient / turn |
|---|---|---:|---:|---:|
| Mage | Fireball DoT | 5 | 17.68 | 0.884 Spell Power |
| Mage | Pyroblast DoT | 5 | 17.68 | 0.884 Spell Power |
| Paladin | Expurgation | 3 | 23.9417 | 0.2514 Melee AP |
| Priest | Renew | 5 | 20.8 | 0.624 Healing Power |
| Priest | Holy Fire DoT | 3 | 16.7592 | 0.5028 Spell Power |
| Priest | Shadow Word: Pain | 5 | 20.8 | 1.04 Spell Power |
| Priest | Vampiric Touch | 5 | 17.68 | 0.884 Spell Power |
| Priest | Vampiric Regeneration | 5 | 8.84 | 0.221 Spell Power |
| Rogue | Rupture | 5 | 20.8 | 0.364 Melee AP |
| Rogue | Garrote | 2 | 31.7688 | 0.2224 Melee AP |
| Warrior | Rend | 5 | 20.8 | 0.364 Melee AP |

---

# 7. Absorption

Absorption is a shield pool, not a HoT.

Do **not** divide absorption by aura duration.

For generic absorb effects:

```text
Base Absorption / Target
= 100
× Cast Modifier
× Action Power Modifier
× Per-Target Modifier
× Cooldown Modifier
× Secondary Modifier
× 1.00
```

Generic Spell Power scaling:

```text
Absorb Coefficient / Target
= Spell Power Base Coefficient for the cast time
× Action Power Modifier
× Per-Target Modifier
× Cooldown Modifier
× Secondary Modifier
× 1.00
```

If the task explicitly specifies another scaling stat, use that stat's appropriate coefficient instead.

### Example — instant Bonus Action shield

One target, no cooldown, no secondary effect:

```text
Base absorption = 100 × 0.65 = 65
Non-damage Spell Power absorption coefficient = 0.50 × 0.65 = 0.325
```

That matches the generic Power Word: Shield-style budget.

Bespoke effects such as shields scaling from unusual stats are not forcibly converted to this generic formula.

---

# 8. Resource costs

Resource handling is deliberately split by resource type.

- **Mana** is an RPE-balanced resource and uses the calculator below.
- **Energy and Rage are not calculator-derived.** For abilities based on a WoW ability with a known Energy/Rage cost, author the actual WoW cost. If the RPE ability is original or materially different and has no authoritative historical cost, use an explicit design value or the closest current same-resource analogue.
- Do **not** increase or decrease an authentic Energy/Rage cost merely because the generic output formula would place the spell in a different Mana tier.
- Do **not** back-solve Energy/Rage from target count, cooldown, action type, or role.

Damage/healing output and Energy/Rage cost are therefore separate authoring inputs. When an authentic Energy/Rage cost is unusually cheap or expensive relative to the proposed RPE output, review the output against current same-resource abilities and adjust the output if necessary. Do not apply a universal `actual cost / calculated cost` damage multiplier: the current Warrior/Rogue kits intentionally contain different efficiencies based on mechanics, cooldowns, requirements, target count and role.

## 8.1 Mana power ratio

Mana tiering uses:

```text
Power Ratio
= Cast Power Modifier
× Action Power Modifier
× Total-Target Modifier
× Cooldown Modifier
× Secondary Modifier
```

Do not include the role output modifier in the power ratio.

For a standard periodic spell, use:

- Cast = Instant = 1.00;
- Action = Bonus Action = 0.65;
- Cooldown = CooldownModifier(Duration).

## 8.2 Mana tiers

For damage, weapon attacks, and non-instant healing:

| Power ratio | Tier |
|---|---|
| < 1.15 | Cheap |
| 1.15 to < 1.75 | Standard |
| >= 1.75 | Expensive |

For **instant healing and instant absorption**, there is no Cheap tier:

| Power ratio | Tier |
|---|---|
| < 1.75 | Standard |
| >= 1.75 | Expensive |

This rule also applies to an instant HoT spell for Mana-cost purposes.

## 8.3 Base Mana costs

| Tier | Base Mana |
|---|---:|
| Cheap | 4% |
| Standard | 8% |
| Expensive | 14.5% |

Mana costs use `amountMode = "base_percent"`.

## 8.4 Mana cast/resource modifier

| Spell type | Modifier |
|---|---:|
| Normal instant spell | 1.25 |
| 1-turn spell | 0.85 |
| Instant healing/absorption | 1.50 |

For instant healing/absorption Mana, use 1.50 **instead of** the normal instant 1.25.

## 8.5 Mana action-cost modifier

| Balance action | Mana-cost modifier |
|---|---:|
| Action | 1.00 |
| Bonus Action | 1.25 |
| Spender | 0.75 |

## 8.6 Final Mana cost

```text
Final Mana Cost
= Tier Base Mana
× Cast/Resource Modifier
× Action Mana-Cost Modifier
```

Round Base Mana percentage to the nearest 0.1%.

Explicit Mana values in the task override calculated Mana cost.

## 8.7 Energy and Rage authoring

For Energy/Rage abilities:

1. Identify the originating WoW ability and verify its actual resource cost from an authoritative reference.
2. Author that Energy/Rage cost unchanged unless the task explicitly defines an RPE-specific replacement.
3. Balance damage/healing separately using the normal RPE output model and current same-resource analogues.
4. If the resulting output is clearly inconsistent with current abilities at a similar cost, adjust the **output**, not the authentic resource cost.
5. Preserve bespoke mechanics that explain unusual efficiency: cooldowns, target restrictions, combo-point requirements, stealth/form requirements, reaction requirements, conditional availability, threat role, and similar constraints.
6. Resource-generation abilities and resource-conversion abilities remain outside the direct numerical calculator and require an explicit/current analogue.

Examples of current same-resource reference points include:

- Warrior Heroic Strike: 15 Rage;
- Warrior Cleave: 20 Rage;
- Warrior Whirlwind: 25 Rage;
- Warrior Shield Slam: 30 Rage;
- Rogue/Druid Energy attacks retain their authored WoW Energy costs rather than being converted to generic RPE tiers.

## 8.8 Example — 5-turn single-target DoT Mana cost

A primary DPS DoT:

```text
Power ratio
= 1.00 × 0.65 × 1.00 × 1.60 × 1.00
= 1.04
```

That is Cheap.

```text
Mana cost
= 4% × 1.25 × 1.25
= 6.25%
≈ 6.3% base Mana
```

## 8.9 Example — instant Bonus Action absorb Mana cost

Power ratio:

```text
1.00 × 0.65 = 0.65
```

Instant absorption cannot use Cheap, so it uses Standard.

```text
Mana cost
= 8% × 1.50 × 1.25
= 15% base Mana
```

---

# 9. Standard long-duration group buffs

Long-duration caster group buffs are a special convention rather than direct-output calculator spells.

Default convention:

- targeter: all allies;
- runtime channel: **Buff Action**;
- cost: **10% base Mana**;
- use the aura/stat value defined by the design or a current analogue;
- do not invent damage/healing output to justify the cost.

Current examples include:

- Blessing of Might;
- Blessing of Kings;
- Blessing of Sanctuary;
- Blessing of Wisdom;
- Blessing of Light;
- Arcane Intellect;
- Divine Spirit;
- Prayer of Fortitude;
- Prayer of Shadow Protection.

---

# 10. Worked direct-spell examples

## 10.1 Instant Main Action single-target DPS spell

No cooldown, Spell Power, no secondary effect:

```text
Base damage = 100
Spell Power damage coefficient = 1.00
Threat coefficient = 1.00
Power ratio = 1.00
```

For Mana:

```text
Cheap Mana cost = 4% × 1.25 × 1.00 = 5.0%
```

## 10.2 1-turn Main Action single-target DPS spell

No cooldown, Spell Power, no secondary effect:

```text
Base damage = 100 × 1.35 = 135
Spell Power damage coefficient = 1.40
Threat coefficient = 1.00
Power ratio = 1.35 -> Standard
Mana cost = 8% × 0.85 = 6.8%
```

## 10.3 Instant Bonus Action, 5-turn cooldown DPS spell

One target, Spell Power, no secondary effect:

```text
Base damage
= 100 × 0.65 × 1.60
= 104

Spell Power damage coefficient
= 1.00 × 0.65 × 1.60
= 1.04

Threat coefficient
= 1.00 × 0.75
= 0.75
```

Power ratio = 1.04 -> Cheap.

Mana cost = 4% × 1.25 × 1.25 = 6.25% -> 6.3%.

## 10.4 Instant single-target Spender

DPS, Spell Power, no cooldown, no secondary effect:

```text
Base damage = 225
Spell Power damage coefficient = 2.25
Threat coefficient = 1.00
Power ratio = 2.25 -> Expensive
```

Calculated Mana cost for a new spell:

```text
Mana = 14.5% × 1.25 × 0.75 = 13.59375% -> 13.6%
```

For an Energy/Rage spender, use the ability's authoritative WoW cost or an explicit RPE design value; do not derive Energy/Rage from this Mana tier.

## 10.5 Three-target instant healer spell with 2-turn cooldown

Healer role, Healing Power, Main Action, no secondary effect:

```text
Base healing / target
= 100 × 1.00 × 1.00 × 0.60 × 1.15 × 1.00 × 1.00
= 69

Healing Power coefficient / target
= 0.60 × 1.00 × 0.60 × 1.15
= 0.414

Threat coefficient
= 0.50 × 1.00
= 0.50

Power ratio
= 1.00 × 1.00 × 1.80 × 1.15
= 2.07
-> Expensive
```

Instant healing Mana cost:

```text
14.5% × 1.50 × 1.00
= 21.75%
-> 21.8% base Mana
```

---

# 11. Choosing scaling stats

Default conventions:

- melee physical weapon/attack spell -> **Melee Attack Power**;
- ranged physical attack -> **Ranged Attack Power**;
- magical damage -> **Spell Power**;
- conventional healing -> **Healing Power**.

Hybrid or bespoke spells may deliberately use a different stat. Follow the explicit design or a current analogue.

Current Core refs:

| Object | Ref |
|---|---|
| Melee Attack Power | `f82db71a:u7b49vs9` |
| Ranged Attack Power | `f82db71a:v2rs9cpy` |
| Spell Power | `f82db71a:7t7xgzcx` |
| Healing Power | `f82db71a:hj6d4kvy` |
| Mana | `f82db71a:4c8mfm99` |
| Energy | `f82db71a:c3gaf7dd` |
| Rage | `f82db71a:e2tfklq7` |

These refs are documented here for orientation, but Codex must still verify them against the current Core dataset before writing.

---

# 12. Mechanics not covered by the numerical calculator

Do not force the direct/periodic formulas onto mechanics for which the model has no frequency/value rule.

This includes:

- reactive `aura.events` procs;
- damage/healing triggered by being hit, blocking, dodging, critting, etc.;
- pure stat buffs/debuffs;
- control-only effects;
- resource-generation-only effects;
- unusual resource conversions;
- bespoke shields/scaling mechanics;
- proc chance/frequency;
- utility with no direct numerical output.

For these:

1. use explicit values in the task, or
2. copy the balance of a named/current same-mechanic analogue.

Do not treat an event-driven proc as an ordinary once-per-turn DoT.

---

# 13. Schema-authoring rules

This document defines balance values, not permission to invent Lua schema.

When implementing:

- inspect a current spell with the same component type;
- inspect a current aura with the same effect type;
- copy the current field shape;
- use supported targeters/conditions/effects only;
- do not add speculative compatibility/fallback fields;
- if something required by the design is unsupported, implement or raise the missing mechanic rather than silently degrading it.

Common conventions:

- `castTime = 0` for instant;
- `castTime = 1` for one-turn cast;
- `cooldown` is in turns;
- `cooldownChannel` is the runtime action-economy channel;
- resource cost is paid at the current spell's established cast phase;
- periodic top-level aura effects tick once per owner turn;
- the spell's apply-aura duration and the aura's intended duration must agree;
- `auraRef` must point to the correct dataset ID and aura ID;
- target disposition and targeter must match the text/mechanic;
- `weaponDamageCoefficient = 0` when `weaponDamageMode = "none"`.

---

# 14. Tooltip rules

All new default spells should use the current templated tooltip system.

Do not hard-code resolved damage/healing numbers into prose when the current schema provides a token.

Verify:

- each token references the correct component/effect index;
- aura sections reference the correct aura;
- target count wording matches `maxTargets`;
- cooldown/duration wording matches runtime values;
- weapon requirements/conditions are represented consistently with current analogues;
- the tooltip describes all meaningful effects and does not describe effects the spell does not actually perform.

---

# 15. Dataset versioning

Whenever a packaged default dataset is modified:

- increment that dataset registration's **top-level wrapper version** by exactly 1;
- do this once for the completed change;
- do not increment nested tooltip/template `version = 1` fields;
- do not bump unrelated ruleset package versions unless ruleset content also changed.

Helper files that are incorporated into another registered dataset do not acquire independent dataset versions merely because they are Lua files.

---

# 16. Closure checklist for Codex

Before considering a spell task complete, verify all of the following:

- [ ] Current source was read before editing.
- [ ] Role profile is identified.
- [ ] Balance action is identified separately from cooldown channel.
- [ ] Cast modifier is correct.
- [ ] Per-target modifier uses maximum targets.
- [ ] Cooldown modifier is correct.
- [ ] Secondary modifier is correctly applied.
- [ ] Role output modifier is correct.
- [ ] Scaling stat and cast-specific base coefficient are correct.
- [ ] Stat coefficient was **not** multiplied by the cast base-output modifier twice.
- [ ] Weapon base/weapon coefficient rules are correct where applicable.
- [ ] Periodic base was divided by duration.
- [ ] Periodic stat coefficient was **not** divided by duration.
- [ ] Periodic balance uses duration as the cooldown-equivalent.
- [ ] Absorption was not divided by duration.
- [ ] Mana power ratio uses total-target, not per-target, modifier.
- [ ] Instant heal/absorb minimum Standard Mana tier is respected.
- [ ] Energy/Rage costs were verified against the authoritative WoW ability or an explicit RPE design value.
- [ ] Damage/healing output was reviewed separately against current same-resource analogues rather than back-solving Energy/Rage from the calculator.
- [ ] Explicit resource-cost exceptions/overrides were preserved.
- [ ] Group caster buffs use the 10% base-Mana convention where applicable.
- [ ] No reactive proc was misclassified as a normal DoT/HoT.
- [ ] Runtime refs exist.
- [ ] IDs/keys are unique.
- [ ] Tooltip tokens match implementation.
- [ ] Dataset wrapper version was bumped exactly once.
- [ ] Final diff contains no unrelated architectural or data changes.
