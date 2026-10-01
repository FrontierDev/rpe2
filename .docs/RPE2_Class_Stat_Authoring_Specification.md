# RPE2 Class Stat Authoring Specification

**Status:** Authoring specification  
**Scope:** RPE2 class primary-stat and base-resource progression, levels 1–60  
**Reference:** `.docs/RPE2_WoW_Classic_Base_Stats_Reference.md`

This document defines how class base stats are authored in RPE2 datasets.

It is intentionally separate from spell balance. Class stat progression establishes the character chassis; spell coefficients and spell resource costs are governed by the spell authoring specification.

---

# 1. Class progression model

Each class may define:

- `statProgressions` for primary attributes;
- `resourceProgressions` for class base Health and, where appropriate, base Mana.

RPE2 currently uses a linearized level model:

```text
value(level) = initialValue + perLevelValue * (level - 1)
```

For the Classic-derived classes, `initialValue` is the class contribution at level 1 and `perLevelValue` is the average Classic growth coefficient.

Race base attributes are separate and are not duplicated into the class dataset.

---

# 2. Canonical Core references

Use the existing Core dataset references.

| Meaning | Reference |
|---|---|
| Strength | `f82db71a:zfqm8dxp` |
| Agility | `f82db71a:xqz0daz2` |
| Stamina | `f82db71a:ygjno50i` |
| Intellect | `f82db71a:75y3a8ib` |
| Spirit | `f82db71a:kec9rhli` |
| Health | `f82db71a:q2ktkztt` |
| Mana | `f82db71a:4c8mfm99` |

Do not create class-local duplicates of these stats or resources.

---

# 3. Required primary-stat progressions

A normal player class should define all five primary-stat progression entries:

- Strength;
- Agility;
- Stamina;
- Intellect;
- Spirit.

The ordering of entries is not semantically important, but all five references must be present.

Example shape:

```lua
statProgressions = {
    {
        initialValue = ...,
        perLevelValue = ...,
        statRef = "f82db71a:zfqm8dxp",
    },
    ...
}
```

Do not put racial base attributes into `initialValue`. For example, Warrior Strength uses `initialValue = 3`, not the Human total of 23.

---

# 4. Required base-resource progressions

Every class defines base Health.

Mana is included only when the class uses the Mana chassis.

Example:

```lua
resourceProgressions = {
    {
        initialValue = ...,
        perLevelValue = ...,
        resourceRef = "f82db71a:q2ktkztt",
    },
    {
        initialValue = ...,
        perLevelValue = ...,
        resourceRef = "f82db71a:4c8mfm99",
    },
}
```

Classes such as Warrior and Rogue omit Mana from this class base-resource progression.

Class-specific combat resources such as Rage, Energy, Chi, Fury, Runic Power, or similar mechanics are not substitutes for this table. They are authored through the normal RPE resource and class mechanics systems.

---

# 5. Canonical Classic-derived class values

| Class | STR init/gain | AGI init/gain | STA init/gain | INT init/gain | SPI init/gain | Health init/gain | Mana init/gain |
|---|---|---|---|---|---|---|---|
| Warrior | 3 / 1.64 | 0 / 1.02 | 2 / 1.49 | 0 / 0.17 | 0 / 0.42 | 20 / 28.29 | — |
| Paladin | 2 / 1.41 | 0 / 0.76 | 2 / 1.32 | 0 / 0.85 | 1 / 0.92 | 28 / 22.93 | 59 / 24.63 |
| Hunter | 0 / 0.59 | 3 / 1.73 | 1 / 1.17 | 0 / 0.76 | 1 / 0.83 | 26 / 24.42 | 63 / 28.08 |
| Rogue | 1 / 1.00 | 3 / 1.81 | 1 / 0.92 | 0 / 0.25 | 0 / 0.51 | 25 / 25.39 | — |
| Priest | 0 / 0.25 | 0 / 0.34 | 0 / 0.51 | 2 / 1.66 | 3 / 1.73 | 31 / 22.98 | 110 / 22.47 |
| Shaman | 1 / 1.08 | 0 / 0.59 | 1 / 1.25 | 1 / 1.17 | 2 / 1.32 | 27 / 21.24 | 53 / 24.86 |
| Mage | 0 / 0.17 | 0 / 0.25 | 0 / 0.42 | 3 / 1.73 | 2 / 1.66 | 31 / 22.53 | 100 / 19.88 |
| Warlock | 0 / 0.42 | 0 / 0.51 | 1 / 0.75 | 2 / 1.49 | 2 / 1.58 | 23 / 23.58 | 59 / 22.27 |
| Druid | 1 / 0.75 | 0 / 0.68 | 0 / 0.85 | 2 / 1.32 | 2 / 1.49 | 33 / 24.58 | 17 / 20.80 |

These values are the canonical RPE2 Classic-style authoring values for the original nine classes.

---

# 6. Post-Vanilla classes

Death Knight, Monk, Demon Hunter, and Evoker were not present in Vanilla / Classic Era. RPE2 therefore treats them as synthetic Classic-style classes.

Do **not** import later-expansion or Retail base-stat tables into this system unless the RPE design is explicitly changed.

Use direct archetype inheritance:

| Class | Authoring archetype | Stat progression | Base resources |
|---|---|---|---|
| Death Knight | Warrior | Copy Warrior | Copy Warrior |
| Monk | Druid | Copy Druid | Copy Druid |
| Demon Hunter | Rogue | Copy Rogue | Copy Rogue |
| Evoker | Mage | Copy Mage | Copy Mage |

This means:

| Class | STR init/gain | AGI init/gain | STA init/gain | INT init/gain | SPI init/gain | Health init/gain | Mana init/gain |
|---|---|---|---|---|---|---|---|
| Death Knight | 3 / 1.64 | 0 / 1.02 | 2 / 1.49 | 0 / 0.17 | 0 / 0.42 | 20 / 28.29 | — |
| Monk | 1 / 0.75 | 0 / 0.68 | 0 / 0.85 | 2 / 1.32 | 2 / 1.49 | 33 / 24.58 | 17 / 20.80 |
| Demon Hunter | 1 / 1.00 | 3 / 1.81 | 1 / 0.92 | 0 / 0.25 | 0 / 0.51 | 25 / 25.39 | — |
| Evoker | 0 / 0.17 | 0 / 0.25 | 0 / 0.42 | 3 / 1.73 | 2 / 1.66 | 31 / 22.53 | 100 / 19.88 |

## 6.1 Death Knight

Death Knight is authored on the Warrior chassis because both are Strength-based melee/tank classes.

Its class dataset therefore uses Warrior's five primary-stat progression entries and Warrior's Health progression. It does not receive a Mana progression.

Runic Power and any other Death Knight-specific resources are separate class mechanics.

## 6.2 Monk

Monk is authored on the Druid chassis because Druid is the closest Classic hybrid analogue capable of supporting damage, tanking, and healing from one class definition.

The class-level table remains shared across specializations. Specialization identity should come from traits, equipment, spell scaling, and class mechanics rather than separate base-stat progression tables.

Monk therefore receives Druid's Health and Mana progression. Energy/Chi remain separate class resources.

## 6.3 Demon Hunter

Demon Hunter is authored on the Rogue chassis because Rogue provides the intended Agility-heavy melee baseline.

It receives Rogue's Health progression and no Mana progression. Fury and other Demon Hunter-specific mechanics are separate resources.

## 6.4 Evoker

Evoker is authored on the Mage chassis because Mage provides the intended Intellect-caster baseline.

It receives Mage's Health and Mana progression.

---

# 7. Authoring rules

When creating or reviewing a class dataset:

1. Use the Core stat/resource references from section 2.
2. Include all five primary-stat progressions.
3. Include Health.
4. Include Mana only for classes using a Mana chassis.
5. Keep racial base attributes out of class `initialValue`.
6. Use the canonical values in this document unless the design explicitly calls for a new class chassis.
7. For post-Vanilla classes, use the mapping in section 6 rather than later-expansion historical data.
8. Put class-specific combat resources in their appropriate resource/class mechanics, not into primary-stat progression.
9. Do not silently average or interpolate two class archetypes. A new curve must be an explicit balance decision and documented here.
10. Any change to these values should update both this specification and the base-stat reference.

---

# 8. Validation expectations

A class-stat dataset test should verify that:

- all five primary-stat references are present;
- each `initialValue` is correct;
- each `perLevelValue` is correct;
- Health progression is present;
- Mana presence/absence matches the class chassis;
- post-Vanilla classes match their declared archetype unless an explicit design revision changes the mapping.

For direct mappings, tests should prefer equality against the canonical values rather than independently repeating a different derivation.

---

# 9. Relationship to player totals

These class values are not final character stats.

Conceptually:

```text
Primary Attribute =
    Race Base
    + Class Initial
    + Class Per-Level Growth
    + other bonuses
```

Health and Mana then combine class base-resource progression with the ruleset's Stamina/Intellect conversion and any further modifiers.

The detailed Classic and simplified RPE conversion formulas are maintained in:

```text
.docs/RPE2_WoW_Classic_Base_Stats_Reference.md
```

That document is the reference for numerical provenance; this document is the authoring contract.
