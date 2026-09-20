# RPE2 NPC Variant Data

This document defines reusable NPC balance data around the Core **Human** NPC baseline.

Base Human Unit: `f82db71a:7i40epa5`

All level-scaled values use:

`resolved = initialValue + ((level - 1) * perLevelValue)`

All values below are authored values before event difficulty and player-count scaling.

---


## Unit Variant Schema Notes

### Preset challenge-level override

A Unit preset may optionally define its own `challengeLevel`.

- Omitted: inherit the base Unit challenge level.
- Explicit values: `swarm`, `minor`, `normal`, `elite`, or `boss`.
- Runtime challenge-specific behaviour must use the effective preset challenge level.

The Human role presets below do not implicitly change challenge level unless one is explicitly authored.

### Unit extension across datasets

A Unit entry may extend another Unit through `extendsUnitRef`.

Example:

```lua
{
    id = "campaignHuman",
    extendsUnitRef = "f82db71a:7i40epa5",
    presets = {
        -- campaign-specific Human presets
    },
}
```

The extending Unit keeps its own registry ref. The parent is not mutated.

Inherited presets are resolved first and child presets append afterwards. This allows another dataset to reuse the Core Human baseline and contribute additional presets without copying the full Unit definition.

See GitHub issues #386 and #387 for the implementation requirements.

---

## 1. Base Human — Normal

| Field | Initial | Per Level | Level 60 |
|---|---:|---:|---:|
| Health | 208 | 29.63 | 1,956.17 |
| Armor | 25 | 25 | 1,500 |
| Melee Attack Power | 65 | 4 | 301 |
| Ranged Attack Power | 65 | 4 | 301 |
| Spell Power | 0 | 5.08 | 299.72 |
| Healing Power | 0 | 5 | 295 |
| Melee Hit Chance | 0 | 0 | 0 |
| Ranged Hit Chance | 0 | 0 | 0 |
| Spell Hit Chance | 0 | 0 | 0 |
| Melee Crit Chance | 5 | 0 | 5 |
| Ranged Crit Chance | 5 | 0 | 5 |
| Spell Crit Chance | 5 | 0 | 5 |
| Parry Chance | 0 | 0 | 0 |
| Dodge Chance | 0 | 0 | 0 |
| Block Chance | 0 | 0 | 0 |
| Magic Resistance | 0 | 0 | 0 |
| Fire Resistance | 0 | 0 | 0 |
| Frost Resistance | 0 | 0 | 0 |
| Nature Resistance | 0 | 0 | 0 |
| Arcane Resistance | 0 | 0 | 0 |
| Shadow Resistance | 0 | 0 | 0 |
| Holy Resistance | 0 | 0 | 0 |
| Resource Regeneration | 0 | 0 | 0 |
| Movement Speed | 30 | 0 | 30 |

Challenge level: `normal`

The following are **not** baseline seeded NPC stats:

- Damage Done
- Damage Reduction
- Healing Done
- Healing Received
- Threat Generated
- Defense Rating
- creature-type damage bonuses

They may still be added explicitly by a Unit or preset when required.

---

## 2. Challenge-Level Templates

The Human Normal baseline is the reference point. Offensive AP/SP progression remains the same across tiers; challenge tiers alter durability, hit/crit reliability and an explicit Damage Done modifier.

| Challenge | Health Initial | Health / Level | Health L60 | Armor Initial | Armor / Level | Armor L60 | Hit Bonus | Crit Bonus | Damage Done |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Swarm | 24 | 3.41 | 225.19 | 0 | 0 | 0 | 0 | 0 | -50% |
| Minor | 56 | 7.90 | 522.10 | 8.33 | 8.33 | 499.80 | 0 | 2 | -25% |
| Normal | 208 | 29.63 | 1,956.17 | 25 | 25 | 1,500 | 0 | 5 | 0% |
| Elite | 370 | 52.68 | 3,478.12 | 41.67 | 41.67 | 2,500.20 | 3 | 7 | +10% |
| Boss | 691 | 98.45 | 6,499.55 | 58.33 | 58.33 | 3,499.80 | 5 | 10 | +20% |

### Challenge-tier offensive stats

Use these values for all three relevant attack modes unless the NPC is role-specialised.

| Challenge | Melee AP | Ranged AP | Spell Power | Healing Power |
|---|---|---|---|---|
| Swarm | 65 + 4/level | 65 + 4/level | 0 + 5.08/level | 0 + 5/level |
| Minor | 65 + 4/level | 65 + 4/level | 0 + 5.08/level | 0 + 5/level |
| Normal | 65 + 4/level | 65 + 4/level | 0 + 5.08/level | 0 + 5/level |
| Elite | 65 + 4/level | 65 + 4/level | 0 + 5.08/level | 0 + 5/level |
| Boss | 65 + 4/level | 65 + 4/level | 0 + 5.08/level | 0 + 5/level |

For Swarm, Minor, Elite and Boss Units, add **Damage Done** explicitly to the Unit rather than making it a seeded stat.

Damage Reduction is not part of the generic challenge template.

---

## 3. Human Combat-Role Presets

These are preset modifiers applied on top of whichever challenge-level Unit they belong to.

All percentage modifiers use `percentBonus`. Hit, crit, avoidance, resistance and Damage Done use `flatBonus`.

### Human Footman

General defensive melee infantry.

| Target | Modifier |
|---|---:|
| Health | +15% |
| Armor | +35% |
| Block Chance | +10 |
| Parry Chance | +3 |
| Melee Attack Power | +5% |

Equipment:
- One-handed sword or mace
- Shield

Primary attacks:
- Main Hand Attack
- Defensive/control melee abilities as appropriate

---

### Human Berserker

High melee pressure with reduced durability.

| Target | Modifier |
|---|---:|
| Health | +10% |
| Armor | -25% |
| Melee Attack Power | +20% |
| Melee Crit Chance | +5 |
| Damage Done | +10 |

Equipment:
- Two-handed melee weapon or dual wield

Primary attacks:
- Main Hand Attack
- Heavy weapon attacks
- Enrage-style abilities

---

### Human Archer

Dedicated ranged physical attacker.

| Target | Modifier |
|---|---:|
| Health | -15% |
| Armor | -25% |
| Ranged Attack Power | +20% |
| Ranged Hit Chance | +5 |
| Ranged Crit Chance | +5 |

Equipment:
- Bow, crossbow or gun

Primary attacks:
- Shoot
- Ranged physical abilities

---

### Human Assassin

Fragile melee burst attacker.

| Target | Modifier |
|---|---:|
| Health | -20% |
| Armor | -35% |
| Melee Attack Power | +15% |
| Melee Hit Chance | +5 |
| Melee Crit Chance | +10 |
| Dodge Chance | +10 |

Equipment:
- Dagger or other light one-handed weapon

Primary attacks:
- Main Hand Attack
- Backstab/Ambush-style attacks
- Evasion/escape abilities

---

### Human Mage

Fragile offensive spellcaster.

| Target | Modifier |
|---|---:|
| Health | -25% |
| Armor | -60% |
| Spell Power | +25% |
| Spell Hit Chance | +5 |
| Spell Crit Chance | +5 |
| Magic Resistance | +5 |

Equipment:
- Staff, wand or caster weapon

Primary attacks:
- Direct-damage spells
- Crowd control
- Defensive magical cooldowns

---

### Human Priest

Healing/support spellcaster.

| Target | Modifier |
|---|---:|
| Health | -20% |
| Armor | -45% |
| Healing Power | +30% |
| Spell Power | +10% |
| Spell Hit Chance | +5 |
| Spell Crit Chance | +5 |
| Magic Resistance | +5 |

Equipment:
- Staff, mace or caster weapon

Primary actions:
- Direct healing
- Support/defensive spells
- Basic offensive spell

---

### Human Battlemage

Durable hybrid spellcaster.

| Target | Modifier |
|---|---:|
| Health | +5% |
| Armor | +25% |
| Spell Power | +15% |
| Spell Hit Chance | +3 |
| Spell Crit Chance | +3 |
| Magic Resistance | +10 |
| Melee Attack Power | +10% |

Equipment:
- One-handed weapon and shield, or staff

Primary actions:
- Main Hand Attack
- Direct-damage spells
- Defensive magic

---

### Human Commander

Support-oriented martial leader.

| Target | Modifier |
|---|---:|
| Health | +30% |
| Armor | +20% |
| Melee Attack Power | +10% |
| Melee Hit Chance | +3 |
| Parry Chance | +5 |
| Threat Generated | +25 |
| Damage Done | +5 |

Equipment:
- One-handed or two-handed martial weapon

Primary actions:
- Main Hand Attack
- Buffs/debuffs
- Taunt/threat abilities
- Party-support abilities

---

## 4. Role Preset Modifier Data

Stat refs used by the role presets:

| Stat | Ref |
|---|---|
| Armor | `f82db71a:v42albuv` |
| Melee Hit Chance | `f82db71a:wbj4zuf3` |
| Ranged Hit Chance | `f82db71a:dd88li4c` |
| Spell Hit Chance | `f82db71a:v2g0tw0o` |
| Parry Chance | `f82db71a:tcn0s8kx` |
| Dodge Chance | `f82db71a:o6113cir` |
| Block Chance | `f82db71a:p8syz5ba` |
| Magic Resistance | `f82db71a:zs1nbz13` |
| Melee Attack Power | `f82db71a:u7b49vs9` |
| Ranged Attack Power | `f82db71a:v2rs9cpy` |
| Spell Power | `f82db71a:7t7xgzcx` |
| Melee Crit Chance | `f82db71a:jslmczbi` |
| Ranged Crit Chance | `f82db71a:fercjhm5` |
| Spell Crit Chance | `f82db71a:69hfqhne` |
| Healing Power | `f82db71a:hj6d4kvy` |
| Damage Done | `f82db71a:gj9wxb0x` |
| Threat Generated | `f82db71a:j8n012e6` |

Health resource ref:

`f82db71a:q2ktkztt`

---

## 5. Preset Modifier Summary

| Variant | Health | Armor | Primary Power | Hit | Crit | Avoidance / Resistance | Damage Done |
|---|---:|---:|---:|---:|---:|---:|---:|
| Footman | +15% | +35% | Melee AP +5% | — | — | Block +10, Parry +3 | — |
| Berserker | +10% | -25% | Melee AP +20% | — | Melee +5 | — | +10 |
| Archer | -15% | -25% | Ranged AP +20% | Ranged +5 | Ranged +5 | — | — |
| Assassin | -20% | -35% | Melee AP +15% | Melee +5 | Melee +10 | Dodge +10 | — |
| Mage | -25% | -60% | Spell Power +25% | Spell +5 | Spell +5 | Magic Resistance +5 | — |
| Priest | -20% | -45% | Healing +30%, SP +10% | Spell +5 | Spell +5 | Magic Resistance +5 | — |
| Battlemage | +5% | +25% | SP +15%, Melee AP +10% | Spell +3 | Spell +3 | Magic Resistance +10 | — |
| Commander | +30% | +20% | Melee AP +10% | Melee +3 | — | Parry +5 | +5 |
