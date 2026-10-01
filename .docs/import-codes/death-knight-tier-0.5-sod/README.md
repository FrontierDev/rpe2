# Death Knight Tier 0.5 — Runebound Battlegear — RPE Import Codes

This folder contains three invented level-60 Death Knight Dungeon Set 2 / Tier 0.5 variants under the shared **Runebound Battlegear** family:

- **Runebound Battlegear — Blood Tank** — 8 pieces.
- **Runebound Battlegear — Frost DPS** — 8 pieces.
- **Runebound Battlegear — Unholy DPS** — 8 pieces.

## RPE normalization

- Dataset: `dknight1`
- Class: `dknight1:dkclass1`
- Required level: **60**
- Item level: **60**
- Armor weight: **Plate**
- Binding: **Bind on Pickup**
- Shared item-set key: `t05_dk_runebound`
- Chest, feet, hands and head are **Epic**.
- Legs, shoulders, waist and wrists are **Rare**.
- No sockets are added, matching the existing RPE Tier 0.5 convention.
- Every piece supports generic modifier key `mod`, capped at **1**.
- **Frost** and **Unholy** retain the Battlegear of Heroism DPS armor/primary-stat budget.
- The DPS hit budget is redistributed without increasing it:
  - **Frost:** 3 Melee Hit, 1 Spell Hit.
  - **Unholy:** 2 Melee Hit, 2 Spell Hit.
- **Blood** uses the Soulforge Protection armor/Strength/Stamina/Defense budget because it better represents a Strength-based hybrid Death Knight tank than the shield-focused Warrior variant.
- Soulforge Protection's **5 Block** is converted one-for-one to **5 Parry Chance**, since Death Knights do not use shield blocking.
- Blood otherwise retains the source hybrid hit budget: **2 Melee Hit, 2 Spell Hit**.
- No set-bonus mechanics are embedded in item descriptions.
- `Runebound Battlegear` is an invented Death Knight Tier 0.5 name and is not presented as a canonical Blizzard set.

## Full-set totals

### Frost
- Armor: **3887**
- Strength: **172**
- Agility: **45**
- Stamina: **109**
- Melee Hit Chance: **3**
- Spell Hit Chance: **1**
- Melee Crit. Chance: **3**

### Unholy
- Armor: **3887**
- Strength: **172**
- Agility: **45**
- Stamina: **109**
- Melee Hit Chance: **2**
- Spell Hit Chance: **2**
- Melee Crit. Chance: **3**

### Blood
- Armor: **3887**
- Strength: **82**
- Stamina: **174**
- Melee Hit Chance: **2**
- Spell Hit Chance: **2**
- Defense Rating: **72**
- Parry Chance: **5**

## Files

- `runebound-blood-tank.md`
- `runebound-frost-dps.md`
- `runebound-unholy-dps.md`
