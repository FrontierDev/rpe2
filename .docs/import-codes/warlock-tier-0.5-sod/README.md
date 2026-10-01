# Season of Discovery Warlock Tier 0.5 — Deathmist Raiment RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for all 16 role-specific Warlock Dungeon Set 2 / Tier 0.5 **Deathmist Raiment** pieces from Season of Discovery:

- **Warlock DPS / Corrupted reward line** — 8 pieces.
- **Warlock Tank / Wicked reward line** — 8 pieces.

The codes target the Warlock dataset `e8f3b2c6`, use the current `RPE_DATASET_ENTRY_V1` format, require level 60 and Warlock class ref `e8f3b2c6:warlock1`, and use the existing Core stat and equipment-slot references.

## RPE normalization

- Every RPE Deathmist piece is normalized to item level **60**. Original SoD item levels vary between 55 and 66; their authored SoD stats are otherwise retained.
- Source rarity follows the existing Tier 0.5 convention: head, chest, hands, and feet are **epic**; legs, shoulders, waist, and wrists are **rare**.
- All pieces are cloth, bind-on-pickup, require level 60 and Warlock, and support generic modifier key `mod` capped at **1**.
- No sockets are added.
- All 16 role variants use the shared RPE item-set key `t05_warlock_deathmist`, because the SoD variants belong to the same Deathmist Raiment set and share its set bonuses.
- Bonuses to hit or critical strike chance for “all spells and attacks” are represented as RPE **Spell Hit Chance** or **Spell Crit. Chance** only.
- On the DPS pieces, combined “damage and healing” bonuses are represented as RPE **Spell Power** only.
- On the tank pieces, SoD **Defense** is represented directly as RPE **Defense Rating**. Finalized tank pieces that no longer carry spell damage do not receive Spell Power.
- The original Deathmist visual icon family is retained for both role variants.

## Deathmist Raiment set bonuses

The current SoD role variants share these set bonuses. They are documented here for reference; the standalone item import codes do not separately author the set-bonus mechanics:

- **2 pieces:** Increases damage and healing done by magical spells and effects by up to 23.
- **4 pieces:** Melee autoattacks and spellcasts have a 6% chance to heal the wearer for 270 to 330 health.
- **6 pieces:** +8 All Resistances.
- **8 pieces:** +200 Armor.

## Files

- `deathmist-dps.md`
- `deathmist-tank.md`

## Reference sources

- Wowhead — Season of Discovery Tier 0.5 set and item data: https://www.wowhead.com/classic/guide/season-of-discovery/tier-0-5-sets-overview
- Wowhead — Deathmist Raiment item pages for the SoD Corrupted and Wicked variants.
- AtlasLootClassic Era SoD collection data — Warlock Tier 0.5 item IDs and variant names: https://github.com/Aleks1015/AtlasLootClassic_Era/blob/2ef1d09b2288a60f8b77f981b4d4c0c189384632/AtlasLootClassic_Collections/data-sod.lua
