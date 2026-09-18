# RPE2 Spell Balance — Formula Reference

This document is the authoritative balance reference for the default RPE2 class datasets.

It is deliberately formula-first rather than an enormous Cartesian-product dump. Every combination is calculated directly from the same factors used by the balance spreadsheet. This avoids hiding the design logic inside thousands of generated rows.

## 1. Core direct-effect formulas

For a direct damage or healing effect:

```text
Base Effect / Target
= 100
× Cast Modifier
× Action Modifier
× Per-Target Modifier
× Cooldown Modifier
× Secondary-Effect Modifier
× Role Effect Modifier
```

For a damage effect that includes weapon damage:

```text
Base Effect / Target with weapon
= Base Effect / Target × 0.75
```

Stat scaling:

```text
Stat Coefficient
= Base Stat Coefficient
× Action Modifier
× Per-Target Modifier
× Cooldown Modifier
× Secondary-Effect Modifier
× Role Effect Modifier
```

Weapon scaling:

```text
Weapon Damage Coefficient
= 1.0
× Action Modifier
× Per-Target Modifier
× Cooldown Modifier
× Secondary-Effect Modifier
× Role Effect Modifier
```

Threat:

```text
Threat Coefficient
= Role Threat Modifier × Action Threat Modifier
```

Power ratio used for resource-cost tiering:

```text
Power Ratio
= Cast Modifier
× Action Modifier
× Total-Target Modifier
× Cooldown Modifier
× Secondary-Effect Modifier
```

## 2. Cast modifiers

| Effect | Instant | 1-turn cast |
|---|---:|---:|
| Damage | 1.00 | 1.35 |
| Healing | 1.00 | 1.45 |

For generic absorption, use the healing cast convention when a cast-time distinction is required.

## 3. Action modifiers

| Balance action | Effect modifier | Threat modifier | Resource-cost modifier |
|---|---:|---:|---:|
| Action | 1.00 | 1.00 | 1.00 |
| Bonus Action | 0.65 | 0.75 | 1.25 |
| Spender | 2.25 | 1.00 | 0.75 |

These are **balance categories**, not a literal mapping from cooldown-channel ID.

## 4. Target modifiers

| Targets | Per-target modifier | Total-target modifier |
|---:|---:|---:|
| 1 | 1.00 | 1.00 |
| 2 | 0.75 | 1.50 |
| 3 | 0.60 | 1.80 |
| 4 | 0.50 | 2.00 |
| 5 | 0.45 | 2.25 |

## 5. Cooldown modifiers

| Cooldown | Modifier |
|---|---:|
| None | 1.00 |
| 1 turn | 1.05 |
| 2 turns | 1.15 |
| 3 turns | 1.30 |
| 4 turns | 1.45 |
| 5 turns | 1.60 |
| 6+ turns | 1.85 |

## 6. Secondary effects

A spell/effect that is intentionally reduced because the spell also provides another meaningful effect uses:

```text
Secondary-Effect Modifier = 0.85
```

This multiplies base output, stat coefficients, and weapon coefficients.

| Value before secondary reduction | With secondary effect |
|---:|---:|
| 100 base effect | 85 |
| 0.35 coefficient | 0.2975 |
| 0.50 coefficient | 0.4250 |
| 0.60 coefficient | 0.5100 |
| 1.00 weapon coefficient | 0.8500 |

## 7. Role effect and threat modifiers

| Role profile | Damage effect | Healing effect | Threat |
|---|---:|---:|---:|
| DPS | 1.00 | 0.50 | 1.00 |
| Healer | 0.70 | 1.00 | 0.50 |
| Tank | 0.80 | 0.55 | 2.00 |

Generic absorption is treated as full defensive output rather than applying the healing-role reduction.

## 8. Base stat coefficients

| Scaling stat | Instant | 1-turn cast |
|---|---:|---:|
| Melee Attack Power | 0.35 | 0.50 |
| Ranged Attack Power | 0.35 | 0.50 |
| Spell Power | 0.50 | 0.70 |
| Healing Power | 0.60 | 0.80 |

## 9. Weapon contribution

| Parameter | Value |
|---|---:|
| Base weapon coefficient | 1.00 |
| Base-effect modifier when weapon damage is included | 0.75 |

The current Aura schema does not provide a generic periodic weapon-damage field. Periodic weapon-style class effects therefore use their relevant attack-power scaling unless/until the schema gains periodic weapon scaling.

---

# 10. Periodic damage and healing — authoritative rule

**Do not divide periodic output by aura duration.**

RPE2 is turn-based. A 5-turn DoT or HoT is not a direct spell budget spread across five turns. Each tick is an actual turn of output.

For the default balance model, a standard periodic tick is budgeted approximately as:

- **Bonus Action**
- **5-turn cooldown**
- **Instant stat-coefficient column**
- the appropriate role modifier
- the normal 0.85 secondary-effect modifier where applicable

Aura duration determines **how many times the effect ticks**. It does **not** divide the calculated tick value.

The common pre-role, pre-secondary periodic multiplier is therefore:

```text
Bonus Action × 5-turn cooldown
= 0.65 × 1.60
= 1.04
```

So:

```text
Periodic Base / Tick
= 100 × 1.04 × Secondary × Role Effect
```

and:

```text
Periodic Stat Coefficient / Tick
= Instant Base Stat Coefficient × 1.04 × Secondary × Role Effect
```

## 10.1 Damage per turn

| Role | No secondary effect | With secondary effect |
|---|---:|---:|
| DPS | 104.00 | 88.40 |
| Healer | 72.80 | 61.88 |
| Tank | 83.20 | 70.72 |

### Spell Power coefficient per damage tick

| Role | No secondary effect | With secondary effect |
|---|---:|---:|
| DPS | 0.5200 | 0.4420 |
| Healer | 0.3640 | 0.3094 |
| Tank | 0.4160 | 0.3536 |

### Melee/Ranged AP coefficient per damage tick

| Role | No secondary effect | With secondary effect |
|---|---:|---:|
| DPS | 0.3640 | 0.3094 |
| Healer | 0.2548 | 0.2166 |
| Tank | 0.2912 | 0.2475 |

## 10.2 Healing per turn

| Role | No secondary effect | With secondary effect |
|---|---:|---:|
| DPS | 52.00 | 44.20 |
| Healer | 104.00 | 88.40 |
| Tank | 57.20 | 48.62 |

### Healing Power coefficient per healing tick

| Role | No secondary effect | With secondary effect |
|---|---:|---:|
| DPS | 0.3120 | 0.2652 |
| Healer | 0.6240 | 0.5304 |
| Tank | 0.3432 | 0.2917 |

If a healing effect intentionally scales from another stat, use that stat's Instant base coefficient in the same formula. For example, a DPS-role secondary heal scaling from Spell Power uses:

```text
0.50 × 1.04 × 0.85 × 0.50 = 0.221
```

## 10.3 Standard default-class periodic values

These are the values currently intended for the existing periodic class effects after applying the rule above.

| Class | Aura | Per-turn base | Per-turn scaling | Notes |
|---|---|---:|---:|---|
| Mage | Fireball | 88.40 damage | 0.4420 Spell Power | Secondary periodic effect |
| Mage | Pyroblast | 88.40 damage | 0.4420 Spell Power | Secondary periodic effect |
| Paladin | Expurgation | 88.40 damage | 0.3094 Melee AP | Secondary periodic effect |
| Priest | Renew | 104.00 healing | 0.6240 Healing Power | Primary HoT |
| Priest | Holy Fire | 61.88 damage | 0.3094 Spell Power | Healer-role secondary damage |
| Priest | Shadow Word: Pain | 104.00 damage | 0.5200 Spell Power | Primary DoT |
| Priest | Vampiric Touch | 88.40 damage | 0.4420 Spell Power | Secondary/multi-effect spell |
| Priest | Vampiric Regeneration | 44.20 healing | 0.2210 Spell Power | DPS-role secondary healing |
| Rogue | Rupture | 104.00 damage | 0.3640 Melee AP | Primary DoT |
| Rogue | Garrote | 88.40 damage | 0.3094 Melee AP | Secondary-effect spell |
| Warrior | Rend | 104.00 damage | 0.3640 Melee AP | Primary DoT |

Triggered proc auras such as Deep Wounds and Paladin seal event effects are not automatically forced into this periodic-spell model. They require a separate proc-frequency budget because they are event-triggered rather than one tick per owner turn.

## 10.4 Worked example: Shadow Word: Pain

Shadow Word: Pain is a DPS-role primary periodic spell with no secondary-output reduction.

```text
Base damage / turn
= 100 × 0.65 × 1.60 × 1.00
= 104
```

```text
Spell Power coefficient / turn
= 0.50 × 0.65 × 1.60 × 1.00
= 0.52
```

Therefore the intended tick is:

```text
104 + (Spell Power × 0.52) Shadow damage each turn
```

A 5-turn duration means five such ticks. It does not mean dividing 104 or 0.52 by five.

---

# 11. Generic absorption

Absorption is a shield pool, not periodic healing. Do not divide it by aura duration.

The current generic examples validate the full defensive-output convention:

| Example | Base absorption | Spell Power coefficient |
|---|---:|---:|
| Power Word: Shield | 65 | 0.325 |
| Fire Ward / Frost Ward | 104 | 0.520 |

Bespoke effects such as Templar's Bulwark are not forced into this generic model.

---

# 12. Resource-cost tiers

Power-ratio thresholds:

| Power Ratio | Tier |
|---|---|
| < 1.15 | Cheap |
| 1.15 to < 1.75 | Standard |
| >= 1.75 | Expensive |

Instant healing/defensive effects do not use the Cheap mana tier in the calculator convention.

Base costs:

| Tier | Base Mana | Energy | Rage |
|---|---:|---:|---:|
| Cheap | 4% | 25 | 12 |
| Standard | 8% | 40 | 25 |
| Expensive | 14.5% | 60 | 43 |

Cast/resource modifiers:

| Case | Modifier |
|---|---:|
| Instant normal spell | 1.25 |
| 1-turn cast normal spell | 0.85 |
| Instant healing/defensive Base Mana | 1.50 |

Then multiply by the action resource-cost modifier from section 3.

## 12.1 Default-dataset resource-cost policy

The calculator resource-cost formula is a design guide. Rebalancing existing default datasets must preserve authored resource identities unless the cost itself is explicitly being redesigned.

Current policy:

- **Do not automatically replace existing Rogue Energy costs.**
- **Do not automatically replace existing Warrior Rage costs.**
- Pyroblast retains its intentionally high **31.8% base Mana** cost.
- Greater Heal retains its intentionally high **31.8% base Mana** cost.
- Standard long-duration group buffs use **10% base Mana**:
  - Blessing of Might
  - Blessing of Kings
  - Blessing of Sanctuary
  - Blessing of Wisdom
  - Blessing of Light
  - Arcane Intellect
  - Divine Spirit
  - Prayer of Fortitude
  - Prayer of Shadow Protection

Resource-generating secondary components, combo-point costs, and other nonstandard resource mechanics are not overwritten by this table.

---

# 13. Rebalance checklist

When applying this reference to an existing class spell:

1. Identify the role profile: DPS, Healer, or Tank.
2. Identify the balance action: Action, Bonus Action, or Spender.
3. Apply target-count and cooldown modifiers.
4. Apply the 0.85 modifier to effects intentionally reduced because the spell has meaningful secondary output.
5. Use the correct scaling-stat base coefficient.
6. Apply the weapon modifier only when the runtime effect actually uses weapon damage.
7. For DoTs/HoTs, use the periodic per-turn rule in section 10. **Never divide by duration.**
8. Preserve authored Energy/Rage and explicit Mana exceptions unless resource costs are specifically in scope.
9. Keep triggered proc auras separate from turn-periodic effects unless a proc-frequency model has been defined.
