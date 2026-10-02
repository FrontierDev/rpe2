# Evoker Tier 2 — Wyrmforged Regalia — RPE Import Codes

This folder contains two invented level-60 Evoker Tier 2 variants under the shared **Wyrmforged Regalia** appearance family:

- **Wyrmforged Fury — Devastation / Augmentation** — 8 pieces.
- **Wyrmforged Grace — Preservation** — 8 pieces.

The shared eight-slot RPE Tier 2 family consists of **Wyrmforged Hauberk, Sabatons, Grips, Crown, Legguards, Mantle, Girdle, and Bracers**.

## RPE normalization

- Dataset: `evokdata`
- Class: `f82db71a:evoker01`
- Required level: **60**
- Item level: **75**
- Quality: **Epic**
- Binding: **Bind on Pickup**
- Armor weight: **Mail**
- Shared Devastation/Augmentation caster set key: `t2_evoker_caster`
- Preservation set key: `t2_evoker_preservation`
- Every piece supports generic modifier key `mod`, capped at **1**.
- **Wyrmforged Fury** is shared by **Devastation and Augmentation** and reproduces the existing Shaman **Eruption of the Ten Storms** Elemental Tier 2 budget slot-for-slot. Augmentation does not receive a separate gear variant because it uses the same Intellect/Spell Power caster itemization in RPE.
- **Preservation** reproduces the existing Shaman **Relief of the Ten Storms** Restoration Tier 2 budget slot-for-slot.
- Wyrmforged Fury uses the Elemental socket pattern: chest 2 red + 1 yellow; helm 1 meta + 1 red; legs 1 red + 1 yellow; belt 1 yellow.
- Preservation uses the Restoration socket pattern: chest red + yellow + blue; helm meta + red; legs red + blue; belt blue.
- Nature and Frost Resistance placement is retained exactly from the source sets.
- No additional item-budget points are introduced.
- No set-bonus mechanics are embedded in item descriptions.
- `Wyrmforged Regalia` and its variant names are invented RPE names rather than canonical Blizzard set names.

## Full-set totals

### Devastation / Augmentation
- Armor: **2773**
- Stamina: **105**
- Intellect: **126**
- Nature Resistance: **50**
- Frost Resistance: **50**
- Spell Crit. Chance: **6**
- Spell Hit Chance: **3**
- Spell Power: **240**

### Preservation
- Armor: **2773**
- Stamina: **126**
- Intellect: **127**
- Nature Resistance: **50**
- Frost Resistance: **50**
- Spell Crit. Chance: **7**
- Healing Power: **438**
- Spell Power: **150**


## Files

- `wyrmforged-fury-caster.md`
- `wyrmforged-grace-preservation.md`

## RPE source basis

- Shaman Tier 2 Elemental: `.docs/import-codes/shaman-tier-2-sod/eruption-of-the-ten-storms-elemental.md`
- Shaman Tier 2 Restoration: `.docs/import-codes/shaman-tier-2-sod/relief-of-the-ten-storms-restoration.md`
- Hunter Tier 2 mail armor values were cross-checked against the same 2773 full-set mail armor budget.
