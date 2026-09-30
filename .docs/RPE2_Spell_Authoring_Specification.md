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

For standard periodic spells, see the separate periodic rule: aura duration is used as the cooldown-equivalent for the **periodic flat-base budget**. DoT stat coefficients use the separate per-tick/lifetime guidance in section 6 rather than inheriting that modifier mechanically.

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

Periodic effects tick once per owner turn. An aura with duration `N` therefore has `N` ticks.

Runtime stat evaluation and authored coefficient budgeting are separate concerns:

- MAP/RAP/SP/Healing Power is resolved on every tick using the current runtime stat value;
- the coefficient stored on the aura is a **per-tick authored coefficient**;
- runtime does not snapshot the stat contribution at application time;
- the authored coefficient must already account for the intended lifetime budget of the effect.

Do not assume that a full duration-adjusted direct-spell coefficient belongs on every tick.

## 6.1 Periodic flat base

For an ordinary active DoT or HoT, the standard flat-base starting point remains approximately an **Instant Bonus Action**, with aura duration used as the cooldown-equivalent:

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

A standard periodic spell may still have runtime `cooldown = 0`. That does not remove the duration-equivalent modifier from the periodic flat-base budget.

Do not multiply by both aura duration and an unrelated runtime cooldown unless the design explicitly gives the periodic component both benefits.

## 6.2 Periodic damage stat coefficients

There is **no universal DoT coefficient formula** that turns the direct-spell coefficient into the authored per-tick coefficient.

The previous rule that calculated a duration-adjusted coefficient and repeated that whole coefficient on every tick is obsolete.

For a DoT:

```text
Lifetime Stat Coefficient
= Per-Tick Authored Coefficient × Duration
```

Choose the per-tick coefficient from the intended total spell budget and the closest current analogue.

When budgeting a DoT, distinguish at minimum:

1. **Pure active DoT** — may have strong lifetime scaling because all output is delayed.
2. **Hybrid direct + DoT** — allocate less scaling to the DoT because the parent spell already has immediate output.
3. **Passive proc DoT** — substantially lower budget because it adds damage without consuming another action.
4. **Stacking DoT** — balance around realistic/max stack state, not one stack in isolation.
5. **Multi-target DoT** — account for maximum target count in the lifetime budget.
6. **Spender/restricted opener DoT** — may retain stronger scaling when gated by Combo Points, Stealth, a special resource, or comparable restrictions.

Do **not** simply divide an old coefficient by duration. First choose an appropriate lifetime budget; then author the corresponding per-tick coefficient.

Do **not** reuse the ordinary direct-damage Spell Power coefficient table mechanically for DoTs.

## 6.3 Periodic healing stat coefficients

The DoT rebalance above does not automatically apply to HoTs.

Current ordinary HoTs retain their existing healing-specific balance. For example, the current five-turn **Renew** archetype is:

```text
20.8 base healing per tick
+ 0.624 × Healing Power per tick
```

Its 0.624 coefficient corresponds to the current Healing Power HoT convention and is intentionally evaluated on every tick.

For a new HoT:

- use the healing coefficients and a current HoT analogue;
- account for target count, duration, action economy, secondary effects and role;
- do not copy a DoT coefficient merely because both effects are periodic;
- bespoke/hybrid healing effects such as Vampiric Regeneration must use their current same-mechanic analogue or an explicit design value.

## 6.4 Current default DoT regression values

These are the current authored per-tick values enforced by `tests/PeriodicAuraAuthoringTest.lua`. They are reference points, not a new universal formula.

| Class | Effect | Duration | Base / tick | Coefficient / tick | Lifetime coefficient |
|---|---|---:|---:|---:|---:|
| Hunter | Serpent Sting | 5 | 20.8 | 0.150 RAP | 0.750 RAP |
| Hunter | Explosive Shot | 2 | 19.06125 | 0.080 RAP | 0.160 RAP |
| Mage | Fireball DoT | 5 | 17.68 | 0.220 SP | 1.100 SP |
| Mage | Ignite | 3 | 28.1667 | 0.250 SP | 0.750 SP |
| Mage | Pyroblast DoT | 5 | 17.68 | 0.260 SP | 1.300 SP |
| Paladin | Consecration | 3 | 11.2667 | 0.140 SP | 0.420 SP / target |
| Paladin | Expurgation | 3 | 23.9417 | 0.100 MAP | 0.300 MAP |
| Priest | Holy Fire DoT | 3 | 16.7592 | 0.180 SP | 0.540 SP |
| Priest | Shadow Word: Pain | 5 | 20.8 | 0.420 SP | 2.100 SP |
| Priest | Vampiric Touch | 5 | 17.68 | 0.320 SP | 1.600 SP |
| Rogue | Rupture | 5 | 20.8 | 0.200 MAP | 1.000 MAP |
| Rogue | Garrote | 2 | 31.7688 | 0.2224 MAP | 0.4448 MAP |
| Rogue | Deadly Poison | 5 | 4.16 | 0.030 MAP / stack | 0.150 MAP / stack |
| Warrior | Rend | 5 | 20.8 | 0.150 MAP | 0.750 MAP |
| Warrior | Deep Wounds | 3 | 28.1667 | 0.0875 MAP | 0.2625 MAP |

### Reference interpretations

- **Shadow Word: Pain** is a pure active single-target Bonus Action DoT and therefore retains a comparatively large lifetime coefficient.
- **Fireball**, **Pyroblast**, **Holy Fire**, **Explosive Shot** and **Expurgation** are hybrid spells; their periodic coefficient is deliberately only one part of the total spell budget.
- **Ignite** and **Deep Wounds** are passive proc DoTs and therefore use much smaller lifetime budgets.
- **Deadly Poison** is both passive and stacking; evaluate its effective output at realistic/high stacks.
- **Consecration** is multi-target; its per-target coefficient must be assessed together with its maximum target count.
- **Garrote** remains at 0.2224 MAP/tick because its two-tick duration, Stealth requirement, Energy cost and Combo Point generation already constrain it.

## 6.5 Reactive aura damage is not a DoT

Damage in `aura.events` that triggers because the owner is hit, blocks, dodges, crits, auto-attacks, casts, or satisfies another event is not an ordinary periodic effect.

Examples include retaliation effects, seals, Hunter's Mark-style triggered damage and similar event procs.

Do not apply the DoT table or duration-based periodic budget to those effects. Use the explicit design or a current same-mechanic event analogue.

---

# 7. Absorption

Absorption is a shield pool, not a HoT.

Do **not** divide absorption by aura duration.

For a generic absorb effect:

```text
Base Absorption / Target
= 100
× Cast Modifier
× Action Power Modifier
× Per-Target Modifier
× Balance-Window Modifier
× Secondary Modifier
× 1.00
```

The balance-window modifier is applied **once**:

- if the spell has a meaningful runtime cooldown, use that cooldown;
- if it has no runtime cooldown but is a persistent shield whose duration is intentionally its balancing window, a current same-mechanic analogue may use aura duration as the cooldown-equivalent;
- never multiply by both runtime cooldown and aura duration unless the design explicitly calls for two separate power increases.

For stat scaling, absorption is non-damage output:

- conventional protective/healer shields may scale from **Healing Power** using the healing coefficient appropriate to the cast time;
- Spell Power shields retain the established **non-damage Spell Power** basis rather than using the doubled direct-damage Spell Power coefficients;
- unusual-stat shields are bespoke and must use an explicit design or current analogue.

## 7.1 Current Power Word: Shield reference

Current Priest **Power Word: Shield** is an instant Bonus Action, five-turn shield with no runtime spell cooldown.

Its current authored balance uses the five-turn aura as the balance window:

```text
Base absorption
= 100 × 0.65 × 1.60
= 104

Healing Power coefficient
= 0.60 × 0.65 × 1.60
= 0.624
```

Current result:

```text
104 + (Healing Power × 0.624) absorption
```

It costs **15% base Mana**, matching the instant-absorption Mana rule.

Do not use the obsolete `65 + 0.325 × Spell Power` example as the Power Word: Shield budget.

## 7.2 Current ward reference

Current Mage **Fire Ward** and **Frost Ward** are established Spell Power shield analogues:

```text
104 base absorption
+ 0.52 × Spell Power
```

They use a five-turn runtime cooldown and the established non-damage Spell Power basis.

Use these as the reference for a comparable Spell Power ward; do not replace their non-damage scaling with the direct-damage Spell Power coefficient.

## 7.3 Bespoke absorption

Shields based on unusual stats, percent-health values, encounter mechanics or other bespoke sources are not forced into the generic formula.

Use the explicit design or a current same-mechanic analogue, and keep the tooltip tokenized from the actual aura data.

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

## 10.6 Current shipped direct-output exceptions

The generic direct formulas describe the normal authoring baseline. Several current default spells intentionally or historically sit outside that exact formula.

Treat these as **explicit current exceptions**, not as alternative universal formulas. Do not opportunistically normalize them while making unrelated changes.

| Spell | Current authored output | Important constraint |
|---|---|---|
| Warrior Cleave | 75 + 0.35 MAP + 1.00 weapon per target; up to 2 targets; 20 Rage | Retains full basic weapon-strike coefficients despite two-target targeting. |
| Hunter Carve | 75 + 0.35 MAP + 1.00 weapon per target; up to 2 targets | Mirrors the current Cleave output shape. |
| Hunter Kill Shot | 225 + 1.125 RAP; 13.6% Mana | Execute-style restricted attack; its RAP coefficient is not produced by the normal instant Action table. |
| Rogue Envenom | 236.25 + 0.826875 MAP; 15 Energy + 5 Combo Points | Restricted finisher requiring the Deadly Poison state; includes an explicit premium over the ordinary spender baseline. |
| Priest Flash Heal | 100 + 0.60 Healing Power; 1-turn cast; 12% Mana | Current fast-heal exception: its output follows the instant-heal-sized profile despite `castTime = 1`. |

When creating a new spell, use the normal formula unless:

1. the task explicitly names one of these as the analogue;
2. the mechanic has the same gating and intended balance role; or
3. the task explicitly defines another exception.

If an existing exception is being edited for an unrelated reason, preserve its current balance unless the task is specifically a rebalance.

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

Do not force the direct formulas or ordinary periodic guidance onto mechanics for which the model has no frequency/value rule.

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
- [ ] Periodic flat base was divided by duration where the standard periodic archetype applies.
- [ ] A DoT's authored coefficient is a deliberate **per-tick** value and its lifetime coefficient was checked as `perTick × duration`.
- [ ] No DoT repeats the old full duration-adjusted direct coefficient on every tick merely because it is periodic.
- [ ] Pure, hybrid, passive-proc, stacking, spender/restricted, and multi-target DoTs were budgeted against the appropriate current analogue.
- [ ] HoT coefficients were not mechanically replaced with DoT coefficient rules.
- [ ] Periodic flat-base balance uses duration as the cooldown-equivalent where applicable.
- [ ] Absorption was not divided by duration.
- [ ] Absorption uses one balance-window modifier; runtime cooldown and aura duration were not accidentally multiplied together.
- [ ] Mana power ratio uses total-target, not per-target, modifier.
- [ ] Instant heal/absorb minimum Standard Mana tier is respected.
- [ ] Energy/Rage costs were verified against the authoritative WoW ability or an explicit RPE design value.
- [ ] Damage/healing output was reviewed separately against current same-resource analogues rather than back-solving Energy/Rage from the calculator.
- [ ] Explicit resource-cost exceptions/overrides were preserved.
- [ ] Current shipped direct-output exceptions were preserved unless the task explicitly rebalances them.
- [ ] Group caster buffs use the 10% base-Mana convention where applicable.
- [ ] No reactive proc was misclassified as a normal DoT/HoT.
- [ ] Runtime refs exist.
- [ ] IDs/keys are unique.
- [ ] Tooltip tokens match implementation.
- [ ] Dataset wrapper version was bumped exactly once.
- [ ] Final diff contains no unrelated architectural or data changes.
