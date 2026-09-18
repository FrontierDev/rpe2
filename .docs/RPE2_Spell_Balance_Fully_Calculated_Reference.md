# RPE2 Spell Balance — Formula Reference

This document records the balance formulas used for the default RPE2 class datasets. The spreadsheet is the source of the numeric modifiers.

## Direct effects

For a direct effect:

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

```text
Stat Coefficient
= Base Stat Coefficient
× Action Modifier
× Per-Target Modifier
× Cooldown Modifier
× Secondary-Effect Modifier
× Role Effect Modifier
```

### Core modifiers

| Parameter | Value |
|---|---:|
| Instant damage cast | 1.00 |
| 1-turn damage cast | 1.35 |
| 1-turn healing cast | 1.45 |
| Action | 1.00 |
| Bonus Action | 0.65 |
| Spender | 2.25 |
| Secondary effect | 0.85 |
| 1 target | 1.00 |
| 2 targets | 0.75 / target |
| 3 targets | 0.60 / target |
| 4 targets | 0.50 / target |
| 5 targets | 0.45 / target |
| No cooldown | 1.00 |
| 1 turn | 1.05 |
| 2 turns | 1.15 |
| 3 turns | 1.30 |
| 4 turns | 1.45 |
| 5 turns | 1.60 |
| 6+ turns | 1.85 |

### Instant scaling coefficients

| Stat | Coefficient |
|---|---:|
| Melee AP | 0.35 |
| Ranged AP | 0.35 |
| Spell Power | 0.50 |
| Healing Power | 0.60 |

### Role effect modifiers

| Role profile | Damage | Healing |
|---|---:|---:|
| DPS | 1.00 | 0.50 |
| Healer | 0.70 | 1.00 |
| Tank | 0.80 | 0.55 |

## Periodic damage and healing

Periodic effects use the spreadsheet approximately as an **Instant Bonus Action whose cooldown-equivalent is the aura duration**.

The periodic **base amount** is a total spell budget spread across the aura's ticks.

The periodic **stat coefficient is not divided by duration**. Each tick uses the full coefficient calculated from the spreadsheet modifiers.

RPE2 top-level aura effects tick once per owner turn, so an aura with duration `N` has `N` ticks.

### Base amount

```text
Periodic Total Base
= 100
× 1.00                       [Instant]
× 0.65                       [Bonus Action]
× CooldownModifier(Duration)
× Secondary Modifier
× Role Effect Modifier

Base / Tick
= Periodic Total Base / Duration
```

### Stat scaling

```text
Stat Coefficient / Tick
= Instant Base Stat Coefficient
× 0.65
× CooldownModifier(Duration)
× Secondary Modifier
× Role Effect Modifier
```

**Do not divide the stat coefficient by duration.**

### Worked example — Shadow Word: Pain

Shadow Word: Pain is a 5-turn, single-target DPS-role DoT with no secondary-output penalty.

Base damage:

```text
Total base damage
= 100 × 0.65 × 1.60
= 104

Base damage / turn
= 104 / 5
= 20.8
```

Spell Power scaling:

```text
Spell Power coefficient / turn
= 0.50 × 0.65 × 1.60
= 0.52
```

Therefore:

```text
Shadow Word: Pain
= 20.8 + (Spell Power × 0.52) damage each turn
```

### Default-class periodic values

| Class | Effect | Duration | Base / turn | Scaling / turn |
|---|---|---:|---:|---:|
| Mage | Fireball DoT | 5 | 17.68 | 0.442 Spell Power |
| Mage | Pyroblast DoT | 5 | 17.68 | 0.442 Spell Power |
| Paladin | Expurgation | 3 | 23.9417 | 0.2514 Melee AP |
| Priest | Renew | 5 | 20.8 | 0.624 Healing Power |
| Priest | Holy Fire DoT | 3 | 16.7592 | 0.2514 Spell Power |
| Priest | Shadow Word: Pain | 5 | 20.8 | 0.52 Spell Power |
| Priest | Vampiric Touch | 5 | 17.68 | 0.442 Spell Power |
| Priest | Vampiric Regeneration | 5 | 8.84 | 0.221 Spell Power |
| Rogue | Rupture | 5 | 20.8 | 0.364 Melee AP |
| Rogue | Garrote | 2 | 31.7688 | 0.2224 Melee AP |
| Warrior | Rend | 5 | 20.8 | 0.364 Melee AP |

Triggered event procs such as Deep Wounds and Paladin seal events are not treated as ordinary once-per-turn periodic auras because their proc frequency is event-driven.

## Resource-cost policy for existing default datasets

The calculator's resource formula is a design guide. Existing authored resource identities are preserved unless resource cost is explicitly being redesigned.

- Rogue Energy costs remain at their authored values.
- Warrior Rage costs remain at their authored values.
- Pyroblast remains at 31.8% base Mana.
- Greater Heal remains at 31.8% base Mana.
- Long-duration caster group buffs use 10% base Mana:
  - Blessing of Might
  - Blessing of Kings
  - Blessing of Sanctuary
  - Blessing of Wisdom
  - Blessing of Light
  - Arcane Intellect
  - Divine Spirit
  - Prayer of Fortitude
  - Prayer of Shadow Protection
