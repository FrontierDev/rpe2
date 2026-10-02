# Evoker Tier 0.5 — Wyrmbound Raiment — RPE Import Codes

This folder contains two invented level-60 Evoker Dungeon Set 2 / Tier 0.5 variants under the shared **Wyrmbound Raiment** family:

- **Wyrmbound Raiment — Devastation / Augmentation** — 8 pieces.
- **Wyrmbound Raiment — Preservation** — 8 pieces.

The shared eight-slot family consists of **Wyrmbound Hauberk, Greaves, Gauntlets, Crown, Legguards, Mantle, Girdle, and Bracers**.

## RPE normalization

- Dataset: `evokdata`
- Class: `f82db71a:evoker01`
- Required level: **60**
- Item level: **60**
- Armor weight: **Mail**
- Binding: **Bind on Pickup**
- Shared item-set key: `t05_evoker_wyrmbound`
- Chest, feet, hands and head are **Epic**.
- Legs, shoulders, waist and wrists are **Rare**.
- No sockets are added, matching the existing RPE Tier 0.5 convention.
- Every piece supports generic modifier key `mod`, capped at **1**.
- **Devastation and Augmentation share the same caster set.** It reproduces the Shaman **The Five Thunders — Elemental** Tier 0.5 armor and stat budget slot-for-slot.
- **Preservation** reproduces the Shaman **The Five Thunders — Restoration** Tier 0.5 armor and stat budget slot-for-slot.
- Resource Regeneration is retained from the source sets. In current RPE this improves ordinary resource regeneration such as Mana, but does not modify special-resource regeneration such as Essence.
- No additional stat-budget points are introduced.
- No set-bonus mechanics are embedded in item descriptions.
- `Wyrmbound Raiment` is an invented Evoker Tier 0.5 set name and is not presented as a canonical Blizzard set.

## Full-set totals

### Devastation / Augmentation
- Armor: **2196**
- Intellect: **102**
- Stamina: **99**
- Spell Power: **184**
- Spell Hit Chance: **5**
- Spell Crit. Chance: **2**
- Resource Regeneration: **4**

### Preservation
- Armor: **2196**
- Intellect: **118**
- Stamina: **109**
- Healing Power: **306**
- Spell Crit. Chance: **1**
- Resource Regeneration: **24**

## Files

- `wyrmbound-caster.md`
- `wyrmbound-preservation.md`

## RPE source basis

- Shaman Tier 0.5 Elemental: `.docs/import-codes/shaman-tier-0.5-sod/five-thunders-elemental.md`
- Shaman Tier 0.5 Restoration: `.docs/import-codes/shaman-tier-0.5-sod/five-thunders-restoration.md`
