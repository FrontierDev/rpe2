# Demon Hunter Tier 0.5 — Felbound Battlegear — RPE Import Codes

This folder contains three invented level-60 Demon Hunter Dungeon Set 2 / Tier 0.5 variants under the shared **Felbound Battlegear** family:

- **Felbound Battlegear — Havoc DPS** — 8 pieces.
- **Felbound Battlegear — Vengeance Tank** — 8 pieces.
- **Felbound Battlegear — Devourer DPS** — 8 pieces.

The shared eight-slot family consists of **Felbound Harness, Treads, Grips, Visor, Legguards, Spaulders, Girdle, and Wristguards**.

## RPE normalization

- Dataset: `dhunter1`
- Class: `dhunter1:dhclass1`
- Required level: **60**
- Item level: **60**
- Armor weight: **Leather**
- Binding: **Bind on Pickup**
- Shared item-set key: `t05_dh_felbound`
- Chest, feet, hands and head are **Epic**.
- Legs, shoulders, waist and wrists are **Rare**.
- No sockets are added, matching the existing RPE Tier 0.5 convention.
- Every piece supports generic modifier key `mod`, capped at **1**.
- **Havoc** copies the existing Rogue **Darkmantle DPS** armor and stat budget slot-for-slot.
- **Vengeance** copies the existing Rogue **Darkmantle tank** armor and stat budget slot-for-slot.
- **Devourer** copies the Darkmantle DPS primary-stat and armor budget slot-for-slot, but reassigns the existing +4 Melee Hit and +2 Melee Crit one-for-one to +4 Spell Hit and +2 Spell Crit.
- No additional stat-budget points are introduced by the Devourer redistribution.
- No set-bonus mechanics are embedded in item descriptions.
- `Felbound Battlegear` is an invented Demon Hunter Tier 0.5 set name and is not presented as a canonical Blizzard set.

## Full-set totals

### Havoc
- Armor: **1047**
- Strength: **63**
- Agility: **186**
- Stamina: **85**
- Melee Hit Chance: **4**
- Melee Crit. Chance: **2**

### Vengeance
- Armor: **1047**
- Agility: **113**
- Stamina: **194**
- Melee Hit Chance: **4**
- Defense Rating: **33**

### Devourer
- Armor: **1047**
- Strength: **63**
- Agility: **186**
- Stamina: **85**
- Spell Hit Chance: **4**
- Spell Crit. Chance: **2**

## Files

- `felbound-havoc-dps.md`
- `felbound-vengeance-tank.md`
- `felbound-devourer-dps.md`

## RPE source basis

- Rogue Tier 0.5 DPS: `.docs/import-codes/rogue-tier-0.5-sod/darkmantle-dps.md`
- Rogue Tier 0.5 tank: `.docs/import-codes/rogue-tier-0.5-sod/darkmantle-tank.md`
- The same post-vanilla-class normalization pattern is already used by the Monk and Death Knight Tier 0.5 import folders.
