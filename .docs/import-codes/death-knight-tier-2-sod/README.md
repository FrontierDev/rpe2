# Death Knight Tier 2 — Pale Rider's Eternal Armor — RPE Import Codes

This folder contains three level-60 Death Knight Tier 2 variants using the canonical **Pale Rider's Eternal Armor** appearance family:

- **Pale Rider's Eternal Armor — Blood Tank** — 8 pieces.
- **Pale Rider's Eternal Armor — Frost DPS** — 8 pieces.
- **Pale Rider's Eternal Armor — Unholy DPS** — 8 pieces.

The canonical Anniversary Death Knight Tier 2 appearance contains **Pale Rider's Eternal Breastplate, Sabatons, Gloves, Helm, Leggings, Pauldrons, Girdle, and Vambraces** (plus a cosmetic cloak outside the eight-slot RPE Tier 2 convention).

## RPE normalization

- Dataset: `dknight1`
- Class: `dknight1:dkclass1`
- Required level: **60**
- Item level: **75**
- Quality: **Epic**
- Binding: **Bind on Pickup**
- Armor weight: **Plate**
- Blood set key: `t2_dk_blood`
- Frost set key: `t2_dk_frost`
- Unholy set key: `t2_dk_unholy`
- Every piece supports generic modifier key `mod`, capped at **1**.
- Chest pieces use 3 sockets; helms use 2 including 1 meta socket; legs use 2; waist pieces use 1.
- Frost and Unholy retain the existing Warrior Tier 2 DPS primary-stat/armor budget.
- Blood retains the existing Warrior Tier 2 tank primary-stat/armor/Defense Rating budget.
- Because current RPE Death Knight spells include both melee and spell attack resolution, existing hit-budget points are redistributed rather than increased:
  - **Frost:** 2 Melee Hit, 1 Spell Hit, 1 Melee Crit across the full set.
  - **Unholy:** 1 Melee Hit, 2 Spell Hit, 1 Melee Crit across the full set.
  - **Blood:** 3 Melee Hit, 2 Spell Hit, 82 Defense Rating across the full set.
- No additional offensive or defensive stat budget is introduced by the redistribution.
- No set-bonus mechanics are embedded in item descriptions.

## Full-set totals

### Frost
- Armor: **4925**
- Strength: **231**
- Agility: **135**
- Stamina: **115**
- Nature Resistance: **50**
- Frost Resistance: **50**
- Melee Hit Chance: **2**
- Spell Hit Chance: **1**
- Melee Crit. Chance: **1**

### Unholy
- Armor: **4925**
- Strength: **231**
- Agility: **135**
- Stamina: **115**
- Nature Resistance: **50**
- Frost Resistance: **50**
- Melee Hit Chance: **1**
- Spell Hit Chance: **2**
- Melee Crit. Chance: **1**

### Blood
- Armor: **4925**
- Strength: **124**
- Agility: **61**
- Stamina: **213**
- Nature Resistance: **50**
- Frost Resistance: **50**
- Melee Hit Chance: **3**
- Spell Hit Chance: **2**
- Defense Rating: **82**

## Files

- `pale-rider-blood-tank.md`
- `pale-rider-frost-dps.md`
- `pale-rider-unholy-dps.md`

## Reference sources

- Blizzard — 20th Anniversary Celebration: Death Knight appearance set **Pale Rider's Eternal Armor**.
- Wowhead — Death Knight Tier 2 Eternal Armor Set.
