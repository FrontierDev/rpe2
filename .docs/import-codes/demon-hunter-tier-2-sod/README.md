# Demon Hunter Tier 2 — Felbane Battlegear — RPE Import Codes

This folder contains three invented level-60 Demon Hunter Tier 2 variants using the shared **Felbane Battlegear** item family:

- **Felbane Onslaught — Havoc DPS** — 8 pieces.
- **Felbane Aegis — Vengeance Tank** — 8 pieces.
- **Felbane Hunger — Devourer DPS** — 8 pieces.

The shared eight-slot RPE Tier 2 family consists of **Felbane Harness, Treads, Grips, Cowl, Legguards, Spaulders, Girdle, and Wristguards**.

## RPE normalization

- Dataset: `dhunter1`
- Class: `dhunter1:dhclass1`
- Required level: **60**
- Item level: **75**
- Quality: **Epic**
- Binding: **Bind on Pickup**
- Armor weight: **Leather**
- Havoc set key: `t2_dh_havoc`
- Vengeance set key: `t2_dh_vengeance`
- Devourer set key: `t2_dh_devourer`
- Every piece supports generic modifier key `mod`, capped at **1**.
- DPS chest pieces use 2 red + 1 yellow socket; DPS helms use 1 meta + 1 red; DPS legs use 1 red + 1 yellow; DPS belts use 1 yellow.
- Vengeance chest uses 2 blue + 1 yellow; helm uses 1 meta + 1 blue; legs use 1 blue + 1 yellow; belt uses 1 blue.
- **Havoc** reproduces the existing Rogue **Bloodfang Thrill** Tier 2 leather melee-DPS armor, primary-stat, resistance, Melee Crit, and Melee Hit budget slot-for-slot.
- **Vengeance** reproduces the existing Rogue **Bloodfang Battlearmor** Tier 2 leather-tank armor, primary-stat, resistance, Melee Hit, and Defense Rating budget slot-for-slot.
- **Devourer** reproduces the Bloodfang Thrill primary-stat, armor, resistance, and socket budget slot-for-slot. Its existing +6 Melee Crit and +6 Melee Hit are reassigned one-for-one to +6 Spell Crit and +6 Spell Hit because the Devourer spell kit resolves primarily through magical attacks while retaining Demon Hunter's Agility/Melee Attack Power chassis.
- No additional item-budget points are introduced by the Devourer redistribution.
- No set-bonus mechanics are embedded in item descriptions.

## Full-set totals

### Havoc
- Armor: **1292**
- Strength: **88**
- Agility: **208**
- Stamina: **116**
- Nature Resistance: **50**
- Frost Resistance: **50**
- Melee Crit. Chance: **6**
- Melee Hit Chance: **6**

### Vengeance
- Armor: **1292**
- Strength: **8**
- Agility: **139**
- Stamina: **226**
- Nature Resistance: **50**
- Frost Resistance: **50**
- Melee Hit Chance: **5**
- Defense Rating: **84**

### Devourer
- Armor: **1292**
- Strength: **88**
- Agility: **208**
- Stamina: **116**
- Nature Resistance: **50**
- Frost Resistance: **50**
- Spell Crit. Chance: **6**
- Spell Hit Chance: **6**

## Files

- `felbane-onslaught-havoc.md`
- `felbane-aegis-vengeance.md`
- `felbane-hunger-devourer.md`

## RPE source basis

- Rogue Tier 2: `.docs/import-codes/rogue-tier-2-sod/bloodfang-thrill-dps.md`
- Rogue Tier 2 tank: `.docs/import-codes/rogue-tier-2-sod/bloodfang-battlearmor-tank.md`
- Hunter Tier 2 melee/ranged variants were used as a cross-check for role-specific offensive-stat emphasis, not as the Demon Hunter armor budget because Hunter Tier 2 is mail.
