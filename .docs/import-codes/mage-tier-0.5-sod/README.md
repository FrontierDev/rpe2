# Season of Discovery Mage Tier 0.5 — Sorcerer's Regalia RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for all 16 Mage Dungeon Set 2 / Tier 0.5 **Sorcerer's Regalia** pieces from Season of Discovery:

- **Mage DPS** — 8 pieces.
- **Mage Healer** — 8 pieces.

The codes target the Mage dataset `vtrjl3l2`, use the current `RPE_DATASET_ENTRY_V1` format, require level 60 and Mage, and use the existing Core stat and equipment-slot references.

## RPE normalization

- Every RPE Sorcerer's piece is normalized to item level **60**, as requested. Original SoD item levels vary between 55 and 66; their authored SoD stats are otherwise retained.
- Source rarity is retained: head, chest, hands, and feet are **epic**; legs, shoulders, waist, and wrists are **rare**.
- All pieces are cloth, bind-on-pickup, require level 60 and Mage, and support generic modifier key `mod` capped at **1**.
- No sockets are added.
- All 16 specialization variants use the shared RPE item-set key `t05_mage_sorcerers`. The SoD variants share the same set bonuses.
- Following the existing Mage Tier 2 import convention, bonuses to hit or critical strike chance for “all spells and attacks” are represented as **Spell Hit Chance** or **Spell Crit. Chance** only.
- On the DPS pieces, combined “damage and healing” bonuses are represented as **Spell Power only** to keep the set role-pure.
- On the healer pieces, combined “damage and healing” bonuses are represented as both **Spell Power** and **Healing Power**, because Mage healing uses offensive Arcane spellcasting as part of its healing loop.
- The healer **Sorcerer's Chest** also reduces the magical resistances of spell targets by 20 in the source item. RPE currently has no direct Spell Penetration / target-resistance-reduction equipment stat, so that effect is omitted rather than replaced with an unrelated stat.
- None of these pieces carries MP5, so no Resource Regeneration is added.
- The original Sorcerer's Regalia slot icon family is used for both variants.

## Sorcerer's Regalia set bonuses

The current SoD variants share these set bonuses. They are documented here for reference; the standalone item import codes do not separately author the set-bonus mechanics:

- **2 pieces:** Increases damage and healing done by magical spells and effects by up to 23.
- **4 pieces:** Spellcasts have a 6% chance to restore 300 Mana.
- **6 pieces:** +8 All Resistances.
- **8 pieces:** +200 Armor.

## Files

- `sorcerers-dps.md`
- `sorcerers-healer.md`

## Reference sources

- Warcraft Wiki — Sorcerer's Regalia: https://warcraft.wiki.gg/wiki/Sorcerer%27s_Regalia
- Wowhead — Season of Discovery Tier 0.5 sets overview: https://www.wowhead.com/classic/guide/season-of-discovery/tier-0-5-sets-overview
- AtlasLootClassic Era SoD collection data — Mage Tier 0.5 item IDs and variant names: https://github.com/Aleks1015/AtlasLootClassic_Era/blob/2ef1d09b2288a60f8b77f981b4d4c0c189384632/AtlasLootClassic_Collections/data-sod.lua
