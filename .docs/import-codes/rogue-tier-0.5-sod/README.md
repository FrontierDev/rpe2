# Season of Discovery Rogue Tier 0.5 — Darkmantle Armor RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for all 16 role-specific Rogue Dungeon Set 2 / Tier 0.5 **Darkmantle Armor** pieces from Season of Discovery:

- **Rogue DPS / Thrill rewards** — 8 pieces.
- **Rogue Tank / Battle rewards** — 8 pieces.

The codes target the Rogue dataset `iectp9f1`, use the current `RPE_DATASET_ENTRY_V1` format, require level 60 and Rogue, and use the existing Core stat and equipment-slot references.

## RPE normalization

- Every RPE Darkmantle piece is normalized to item level **60**, as requested. Original SoD item levels vary between 55 and 66; their authored SoD stats are otherwise retained.
- Source rarity is retained: head, chest, hands, and feet are **epic**; legs, shoulders, waist, and wrists are **rare**.
- All pieces are leather, bind-on-pickup, require level 60 and Rogue, and support generic modifier key `mod` capped at **1**.
- No sockets are added.
- All 16 role-specific variants use the shared RPE item-set key `t05_rogue_darkmantle`. Season of Discovery Darkmantle variants share the same set bonuses and can be freely mixed and matched.
- The separate SoD "original stats" Darkmantle variants are not duplicated here, matching the approach used for the other Tier 0.5 class import folders.
- Source bonuses worded as applying to “all spells and attacks” are specialized for Rogue:
  - Hit maps to **Melee Hit Chance**.
  - Critical strike maps to **Melee Crit. Chance**.
  - Spell Hit, Spell Crit, Spell Power, and Healing Power are not added.
- Tank Defense bonuses map directly to RPE **Defense Rating**.
- **Darkmantle Footpads** increase effective stealth level in SoD. RPE has no ordinary equipment stat representing stealth level, so this effect is documented but omitted rather than replaced with an unrelated stat.
- The original Darkmantle slot icon family is used for both role variants.

## Darkmantle Armor set bonuses

The SoD Darkmantle variants share these set bonuses. They are documented here for reference; the standalone item import codes do not separately author the set-bonus mechanics:

- **2 pieces:** +40 Attack Power.
- **4 pieces:** Chance on melee attack to restore 35 Energy.
- **6 pieces:** +8 All Resistances.
- **8 pieces:** +200 Armor.

## Files

- `darkmantle-dps.md`
- `darkmantle-tank.md`

## Reference sources

- Warcraft Wiki — Darkmantle Armor: https://warcraft.wiki.gg/wiki/Darkmantle_Armor
- Warcraft Wiki — Darkmantle Cap (DPS): https://warcraft.wiki.gg/wiki/Darkmantle_Cap_(Season_of_Discovery)
- Warcraft Wiki — Darkmantle Faceguard (tank): https://warcraft.wiki.gg/wiki/Darkmantle_Faceguard
- Wowhead — Season of Discovery Tier 0.5 acquisition and role variants: https://www.wowhead.com/classic/news/how-to-acquire-dungeon-set-2-tier-0-5-in-season-of-discovery-phase-4-345224
- AtlasLootClassic Era SoD collection data — Darkmantle role/original-stat item IDs: https://github.com/Aleks1015/AtlasLootClassic_Era/blob/2ef1d09b2288a60f8b77f981b4d4c0c189384632/AtlasLootClassic_Collections/data-sod.lua
