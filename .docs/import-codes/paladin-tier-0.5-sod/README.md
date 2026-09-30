# Season of Discovery Paladin Tier 0.5 — Soulforge RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for all 24 Paladin Dungeon Set 2 / Tier 0.5 **Soulforge Armor** pieces from Season of Discovery:

- **Retribution / Radiant rewards** — 8 pieces.
- **Holy / Merciful rewards** — 8 pieces.
- **Protection / Divine Will rewards** — 8 pieces.

The codes target the Paladin dataset `b0211ab3`, use the current `RPE_DATASET_ENTRY_V1` format, require level 60 and Paladin, and use the existing Core stat and equipment-slot references.

## Translation notes

- Every RPE Soulforge piece is normalized to item level **60**, as requested. Original SoD item levels vary between 55 and 66; their authored SoD stats are otherwise retained.
- Source rarity is retained: head, chest, hands, and feet are **epic**; legs, shoulders, waist, and wrists are **rare**.
- All pieces are plate, bind-on-pickup, require level 60 and Paladin, and support generic modifier key `mod` capped at **1**.
- No sockets are added.
- All 24 specialization variants use the shared RPE item-set key `t05_pala_soulforge`. SoD Soulforge specialization variants share the same set bonuses and can be freely mixed and matched.
- Bonuses that increase hit or critical chance for **all spells and attacks** are specialized by intended RPE role:
  - Retribution uses **Melee Hit Chance** / **Melee Crit. Chance**.
  - Holy uses **Spell Hit Chance** / **Spell Crit. Chance**.
  - Protection retains both melee and spell hit where the source item grants generic hit, matching the existing Paladin protection import convention.
- Holy-only healing bonuses map directly to RPE **Healing Power**. Spell Power is not invented where the SoD item grants healing only.
- RPE has **Block Chance** and **Defense Rating**, but no **Shield Block Value**. Protection pieces with Shield Block Value and no native Block Chance receive **+1% Block Chance** as the same approximation used by the Paladin Tier 2 protection imports.
- The base Soulforge slot icon family is used for all three specialization variants of the corresponding slot.

## Soulforge set bonuses

The current SoD Soulforge variants share these set bonuses. They are documented here for reference; these item import codes do not separately author the set-bonus mechanics:

- **2 pieces:** +40 Attack Power and up to +40 healing from spells.
- **4 pieces:** 6% chance on melee autoattack and 4% chance on spellcast to increase magical damage and healing by up to 95 for 10 seconds.
- **6 pieces:** +8 All Resistances.
- **8 pieces:** +200 Armor.

## Files

- `soulforge-retribution.md`
- `soulforge-holy.md`
- `soulforge-protection.md`

## Reference sources

- Warcraft Wiki — Soulforge Armor: https://warcraft.wiki.gg/wiki/Soulforge_Armor
- Wowhead — Dungeon Set 2 / Tier 0.5 in Season of Discovery Phase 4: https://www.wowhead.com/classic/news/how-to-acquire-dungeon-set-2-tier-0-5-in-season-of-discovery-phase-4-345224
- Wowhead — Soulforge item listings: https://www.wowhead.com/classic/items/name:soulforge
