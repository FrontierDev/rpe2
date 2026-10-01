# RPE2 WoW Classic Base Stat Reference

**Status:** Reference  
**Scope:** Vanilla / WoW Classic Era basis, extended with RPE synthetic class mappings, levels 1–60  
**Purpose:** provide race/class starting attributes, approximate class attribute growth, and class base Health/Mana progression for RPE2 authoring and balance work.

This document is a compact reference for the level-scaling model used by original WoW / Classic Era and for RPE2's Classic-style treatment of classes introduced after Vanilla.

Two distinctions are important:

1. WoW Classic does **not** use one constant integer stat gain every level. Attribute values are effectively defined for each race/class/level combination, so the per-level values below are average growth coefficients across levels 1–60.
2. Class base Health and Mana are separate from the Health/Mana contributed by Stamina and Intellect.

Death Knight, Monk, Demon Hunter, and Evoker did **not** exist in Vanilla / Classic Era. Their values in this document are therefore **RPE design mappings**, not historical WoW Classic data. They deliberately inherit the Classic-style progression of an existing archetype:

| RPE class | Classic archetype | Rationale |
|---|---|---|
| Death Knight | Warrior | Strength-based melee/tank |
| Monk | Druid | Hybrid Agility DPS/tank/healer |
| Demon Hunter | Rogue | Agility-based melee DPS/tank baseline |
| Evoker | Mage | Intellect-based caster |

Unless a later RPE design explicitly overrides one of these classes, its starting modifiers, attribute growth, and base Health/Mana progression should match the mapped archetype.

---

# 1. Race base attributes

These are the underlying racial values before class starting modifiers and percentage racial bonuses.

| Race | STR | AGI | STA | INT | SPI |
|---|---:|---:|---:|---:|---:|
| Human | 20 | 20 | 20 | 20 | 20 |
| Dwarf | 22 | 16 | 23 | 19 | 19 |
| Night Elf | 17 | 25 | 19 | 20 | 20 |
| Gnome | 15 | 23 | 19 | 23 | 20 |
| Orc | 23 | 17 | 22 | 17 | 23 |
| Undead | 19 | 18 | 21 | 18 | 25 |
| Tauren | 25 | 15 | 22 | 15 | 22 |
| Troll | 21 | 22 | 21 | 16 | 21 |

Relevant racial attribute modifiers:

- Human: +5% Spirit.
- Gnome: +5% Intellect.

These modifiers are applied after the underlying class/level contribution.

---

# 2. Class starting modifiers

Add these values to the race base attributes at level 1.

| Class | STR | AGI | STA | INT | SPI | Basis |
|---|---:|---:|---:|---:|---:|---|
| Warrior | +3 | +0 | +2 | +0 | +0 | Classic |
| Paladin | +2 | +0 | +2 | +0 | +1 | Classic |
| Hunter | +0 | +3 | +1 | +0 | +1 | Classic |
| Rogue | +1 | +3 | +1 | +0 | +0 | Classic |
| Priest | +0 | +0 | +0 | +2 | +3 | Classic |
| Shaman | +1 | +0 | +1 | +1 | +2 | Classic |
| Mage | +0 | +0 | +0 | +3 | +2 | Classic |
| Warlock | +0 | +0 | +1 | +2 | +2 | Classic |
| Druid | +1 | +0 | +0 | +2 | +2 | Classic |
| Death Knight | +3 | +0 | +2 | +0 | +0 | Warrior-derived |
| Monk | +1 | +0 | +0 | +2 | +2 | Druid-derived |
| Demon Hunter | +1 | +3 | +1 | +0 | +0 | Rogue-derived |
| Evoker | +0 | +0 | +0 | +3 | +2 | Mage-derived |

Example:

```text
Orc base:       23 STR / 17 AGI / 22 STA / 17 INT / 23 SPI
Warrior bonus:  +3 STR / +0 AGI / +2 STA / +0 INT / +0 SPI
Level 1 result: 26 STR / 17 AGI / 24 STA / 17 INT / 23 SPI
```

A Death Knight uses the same class contribution as Warrior. A Monk uses Druid's contribution, a Demon Hunter uses Rogue's, and an Evoker uses Mage's.

---

# 3. Average attribute gain per level

These are useful linearized growth coefficients for a simplified RPG implementation.

They are calculated from the total class-driven change over the 59 level-ups between level 1 and level 60:

```text
average gain per level = (level 60 value - level 1 value) / 59
```

They should **not** be interpreted as the exact integer increase granted by WoW on every individual level-up.

| Class | STR / level | AGI / level | STA / level | INT / level | SPI / level | Basis |
|---|---:|---:|---:|---:|---:|---|
| Warrior | 1.64 | 1.02 | 1.49 | 0.17 | 0.42 | Classic |
| Paladin | 1.41 | 0.76 | 1.32 | 0.85 | 0.92 | Classic |
| Hunter | 0.59 | 1.73 | 1.17 | 0.76 | 0.83 | Classic |
| Rogue | 1.00 | 1.81 | 0.92 | 0.25 | 0.51 | Classic |
| Priest | 0.25 | 0.34 | 0.51 | 1.66 | 1.73 | Classic |
| Shaman | 1.08 | 0.59 | 1.25 | 1.17 | 1.32 | Classic |
| Mage | 0.17 | 0.25 | 0.42 | 1.73 | 1.66 | Classic |
| Warlock | 0.42 | 0.51 | 0.75 | 1.49 | 1.58 | Classic |
| Druid | 0.75 | 0.68 | 0.85 | 1.32 | 1.49 | Classic |
| Death Knight | 1.64 | 1.02 | 1.49 | 0.17 | 0.42 | Warrior-derived |
| Monk | 0.75 | 0.68 | 0.85 | 1.32 | 1.49 | Druid-derived |
| Demon Hunter | 1.00 | 1.81 | 0.92 | 0.25 | 0.51 | Rogue-derived |
| Evoker | 0.17 | 0.25 | 0.42 | 1.73 | 1.66 | Mage-derived |

For a simplified linear implementation:

```text
attribute(level) =
    starting attribute
    + average gain per level * (level - 1)
```

The final value can then be rounded according to the ruleset's preferred convention.

---

# 4. Total class attribute growth from level 1 to 60

This table shows the corresponding total increase over 59 level-ups.

| Class | ΔSTR | ΔAGI | ΔSTA | ΔINT | ΔSPI | Basis |
|---|---:|---:|---:|---:|---:|---|
| Warrior | +97 | +60 | +88 | +10 | +25 | Classic |
| Paladin | +83 | +45 | +78 | +50 | +54 | Classic |
| Hunter | +35 | +102 | +69 | +45 | +49 | Classic |
| Rogue | +59 | +107 | +54 | +15 | +30 | Classic |
| Priest | +15 | +20 | +30 | +98 | +102 | Classic |
| Shaman | +64 | +35 | +74 | +69 | +78 | Classic |
| Mage | +10 | +15 | +25 | +102 | +98 | Classic |
| Warlock | +25 | +30 | +44 | +88 | +93 | Classic |
| Druid | +44 | +40 | +50 | +78 | +88 | Classic |
| Death Knight | +97 | +60 | +88 | +10 | +25 | Warrior-derived |
| Monk | +44 | +40 | +50 | +78 | +88 | Druid-derived |
| Demon Hunter | +59 | +107 | +54 | +15 | +30 | Rogue-derived |
| Evoker | +10 | +15 | +25 | +102 | +98 | Mage-derived |

Minor one-point differences can appear in exact in-game values because the original game uses integer race/class/level records and racial percentage modifiers rather than these linearized coefficients.

For the four synthetic classes, the values are deliberately copied from their RPE archetype rather than reconstructed from later-expansion WoW tables.

---

# 5. Class base Health and Mana

Class base Health and base Mana are stored separately from Stamina and Intellect contributions.

The values below show level 1 and level 60 endpoints together with the average increase across the 59 intervening level-ups.

| Class | Base HP L1 | Base HP L60 | Avg HP / level | Base Mana L1 | Base Mana L60 | Avg Mana / level | Basis |
|---|---:|---:|---:|---:|---:|---:|---|
| Warrior | 20 | 1689 | 28.29 | 0 | 0 | 0 | Classic |
| Paladin | 28 | 1381 | 22.93 | 59 | 1512 | 24.63 | Classic |
| Hunter | 26 | 1467 | 24.42 | 63 | 1720 | 28.08 | Classic |
| Rogue | 25 | 1523 | 25.39 | 0 | 0 | 0 | Classic |
| Priest | 31 | 1387 | 22.98 | 110 | 1436 | 22.47 | Classic |
| Shaman | 27 | 1280 | 21.24 | 53 | 1520 | 24.86 | Classic |
| Mage | 31 | 1360 | 22.53 | 100 | 1273 | 19.88 | Classic |
| Warlock | 23 | 1414 | 23.58 | 59 | 1373 | 22.27 | Classic |
| Druid | 33 | 1483 | 24.58 | 17 | 1244 | 20.80 | Classic |
| Death Knight | 20 | 1689 | 28.29 | 0 | 0 | 0 | Warrior-derived |
| Monk | 33 | 1483 | 24.58 | 17 | 1244 | 20.80 | Druid-derived |
| Demon Hunter | 25 | 1523 | 25.39 | 0 | 0 | 0 | Rogue-derived |
| Evoker | 31 | 1360 | 22.53 | 100 | 1273 | 19.88 | Mage-derived |

As with attributes, the original game's base HP and Mana progression is not perfectly linear. The average values are suitable for simplified interpolation, but exact Classic replication requires a level-by-level lookup table.

For the post-Vanilla classes, RPE uses the mapped archetype's linearized Classic progression by design.

---

# 6. Synthetic class authoring rules

The four post-Vanilla classes are authored as Classic-style RPE classes using the following canonical mappings:

## Death Knight

Use **Warrior** values for:

- class starting modifiers;
- all five primary-stat progression coefficients;
- base Health;
- no base Mana progression.

This keeps Death Knight on the Strength-based melee/tank chassis.

## Monk

Use **Druid** values for:

- class starting modifiers;
- all five primary-stat progression coefficients;
- base Health;
- base Mana.

This is the closest Classic hybrid chassis for a class that must support Agility-oriented damage/tanking and Intellect-oriented healing without creating specialization-specific base-stat tables.

## Demon Hunter

Use **Rogue** values for:

- class starting modifiers;
- all five primary-stat progression coefficients;
- base Health;
- no base Mana progression.

This gives Demon Hunter an Agility-heavy melee chassis while leaving its class-specific combat resources to the normal RPE resource system.

## Evoker

Use **Mage** values for:

- class starting modifiers;
- all five primary-stat progression coefficients;
- base Health;
- base Mana.

This gives Evoker the intended Intellect-caster baseline.

These mappings are authoring defaults. If RPE later introduces a deliberate class-balance reason to separate one of these classes from its archetype, the change should be documented here rather than silently using later-retail WoW values.

---

# 7. Classic Stamina and Intellect conversion

In Classic, the first 20 points of Stamina and Intellect are treated differently from subsequent points.

Health contributed by Stamina:

```text
HP from STA =
    min(20, STA)
    + 10 * (STA - min(20, STA))
```

Mana contributed by Intellect:

```text
Mana from INT =
    min(20, INT)
    + 15 * (INT - min(20, INT))
```

Therefore:

- each point of Stamina above 20 contributes 10 Health;
- each point of Intellect above 20 contributes 15 Mana.

Total player pools are then conceptually:

```text
Health = class base Health + Health from Stamina
Mana   = class base Mana   + Mana from Intellect
```

---

# 8. Simplified RPE interpretation

For RPE2, a simpler model may deliberately use the post-threshold conversions from the first point:

```text
Health = class base Health + (Stamina * 10)
Mana   = class base Mana   + (Intellect * 15)
```

This is **not an exact reproduction of Classic's first-20-stat treatment**, but it is simple, predictable, and preserves the intended relative class/race scaling.

For a Human Warrior:

```text
Level 1:
  Base Health = 20
  Stamina     = 20 racial + 2 Warrior = 22

  Health = 20 + (22 * 10)
         = 240
```

Using the linear Warrior Stamina growth:

```text
Level 60 Stamina ≈ 22 + (1.49 * 59)
                 ≈ 109.91

Level 60 Health ≈ 1689 + (109.91 * 10)
                ≈ 2788
```

Thus the simplified RPE model gives approximately:

| Level | Human Warrior Stamina | Base HP | Simplified total HP |
|---|---:|---:|---:|
| 1 | 22 | 20 | 240 |
| 60 | ~109.9 | 1689 | ~2788 |

The exact level-60 value depends on how fractional attribute growth is rounded.

A Human Death Knight uses the same values under the synthetic mapping and therefore has the same baseline Health progression before class-specific effects, equipment, talents, or other bonuses.

---

# 9. Implementation guidance

For an RPE ruleset intended to reproduce the **shape** of Classic progression without maintaining 60 rows per race/class combination:

1. Store race base attributes.
2. Store class starting modifiers.
3. Store the five average class attribute-growth coefficients.
4. Store class base HP/Mana endpoints or an equivalent class growth model.
5. Apply racial percentage modifiers after class/level attribute growth.
6. Apply the ruleset's Health/Mana conversion from Stamina/Intellect.
7. Use one explicit rounding convention consistently.
8. For Death Knight, Monk, Demon Hunter, and Evoker, use the synthetic archetype mappings in section 6 unless an explicit RPE balance revision replaces them.

For exact Classic replication of the original nine classes, replace the average-growth approximation with race/class/level lookup data.

There is no exact Classic lookup table for the four post-Vanilla classes because they were not present in Vanilla.

---

# 10. Reference basis

The original-class values in this document are based on Vanilla / WoW Classic Era (1–60) stat progression data and the 1.12-style class-level database model.

Useful external references:

- CMaNGOS Classic database: `cmangos/mangos-classic`
- Vanilla WoW race/base-stat references
- Warcraft Wiki documentation for base Mana and primary-stat resource conversion

The Death Knight, Monk, Demon Hunter, and Evoker rows are **RPE-authored synthetic extensions** based on the archetype mappings defined in this document. They must not be cited as historical Vanilla / Classic class data.
