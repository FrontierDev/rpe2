# Season of Discovery Shaman Tier 0.5 — The Five Thunders RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for all 32 role-specific Shaman Dungeon Set 2 / Tier 0.5 **The Five Thunders** pieces from Season of Discovery:

- **Elemental DPS / Eruption rewards** — 8 pieces.
- **Enhancement DPS / Impact rewards** — 8 pieces.
- **Restoration healer / Relief rewards** — 8 pieces.
- **Enhancement tank / Resolve rewards** — 8 pieces.

The separate **Original Stats** item versions are intentionally excluded.

The codes target the Shaman dataset `c4a91e7d`, use the current `RPE_DATASET_ENTRY_V1` format, require level 60 and Shaman class ref `c4a91e7d:shaman01`, and use existing Core stat and equipment-slot references.

## RPE normalization

- Every RPE Five Thunders piece is normalized to item level **60**. Original SoD item levels vary between 55 and 66; the authored SoD role-specific stats are otherwise retained.
- Source rarity follows the existing Tier 0.5 convention: head, chest, hands, and feet are **epic**; legs, shoulders, waist, and wrists are **rare**.
- All pieces are mail, bind-on-pickup, require level 60 and Shaman, and support generic modifier key `mod` capped at **1**.
- No sockets are added.
- All 32 specialization variants use the shared RPE item-set key `t05_shaman_five_thunders`, because the SoD variants belong to the same The Five Thunders item set and share its set bonuses.
- **Elemental** specializes generic hit/critical-strike bonuses to **Spell Hit Chance** / **Spell Crit. Chance**. Combined magical damage/healing is represented as **Spell Power**.
- **Enhancement** specializes generic hit/critical-strike bonuses to **Melee Hit Chance** / **Melee Crit. Chance**. Spell Power is retained where explicitly present on the source item.
- **Restoration** specializes generic critical-strike bonuses to **Spell Crit. Chance**. Healing-only bonuses map to **Healing Power** without inventing Spell Power.
- **Mana per 5 seconds converts approximately 1:1 to RPE Resource Regeneration:** 1 MP5 ≈ +1% Resource Regeneration (`f82db71a:rgnrtg01`), matching the existing Tier 0.5 import convention.
- **Resolve** maps Defense directly to **Defense Rating** and native shield block chance directly to **Block Chance**. Generic hit maps to both **Melee Hit Chance** and **Spell Hit Chance**, matching the existing hybrid-tank import convention.
- Obsolete PTR shield-block-value effects are not approximated; the finalized SoD Resolve pieces use Defense instead.
- The shared Five Thunders appearance icon family is used across the role variants.

## The Five Thunders set bonuses

The SoD variants share these set bonuses. They are documented here for reference; the standalone item import codes do not separately author the set-bonus mechanics:

- **2 pieces:** +40 Attack Power, up to +23 magical spell damage, and up to +44 healing.
- **4 pieces:** Main-hand autoattacks and spellcasts can temporarily increase magical damage and healing by up to 95.
- **6 pieces:** +8 All Resistances.
- **8 pieces:** +200 Armor.

## Files

- `five-thunders-elemental.md`
- `five-thunders-enhancement.md`
- `five-thunders-restoration.md`
- `five-thunders-tank.md`

## Reference sources

- Wowhead — Season of Discovery Dungeon Set 2 / Tier 0.5 overview and linked Shaman item pages: https://www.wowhead.com/classic/news/how-to-acquire-dungeon-set-2-tier-0-5-in-season-of-discovery-phase-4-345224
- Warcraft Wiki — The Five Thunders and Season of Discovery specialization item pages: https://warcraft.wiki.gg/wiki/The_Five_Thunders
- AtlasLootClassic Era SoD collection data — specialization item IDs and variant ordering: https://github.com/Aleks1015/AtlasLootClassic_Era/blob/2ef1d09b2288a60f8b77f981b4d4c0c189384632/AtlasLootClassic_Collections/data-sod.lua
