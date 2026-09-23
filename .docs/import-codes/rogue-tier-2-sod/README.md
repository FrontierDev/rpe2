# Season of Discovery Rogue Tier 2 — RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for all 16 Rogue Tier 2 **Draconic** pieces from Season of Discovery:

- **Bloodfang Thrill** — melee DPS, 8 pieces.
- **Bloodfang Battlearmor** — tank, 8 pieces.

The codes target the Rogue dataset `iectp9f1`, use the current `RPE_DATASET_ENTRY_V1` format, require level 60 and Rogue, and use Core stat and equipment-slot references.

## RPE normalization

- All pieces are normalized to item level **75**.
- All pieces are epic, bind-on-pickup leather armor.
- Every piece supports generic modifier key `mod`, capped at **1** via `maxGenericModificationCounts` / `maxModificationCounts`.
- Chest pieces have **3** gem sockets; heads have **2** including **1 meta** socket; legs have **2**; belts have **1**.
- Socket colours are restricted to **red, blue, and yellow**, with **meta** only on helms.
- Bloodfang Thrill uses red/yellow sockets; Bloodfang Battlearmor uses blue/yellow sockets.
- Source bonuses worded as applying to “all spells and attacks” are specialized for Rogue: hit and critical-strike bonuses map to **Melee Hit Chance** and **Melee Crit. Chance** only. No Rogue Tier 2 piece receives Spell Hit, Spell Crit, Spell Power, or Healing Power.
- Base Strength, Agility, Stamina, Armor, and resistances remain as authored on the Draconic source pieces.
- Bloodfang Battlearmor's Defense bonuses map directly to RPE **Defense Rating**.
- Effects not represented as ordinary RPE item stats, such as the DPS gloves' Disarm immunity, are omitted rather than written as unsupported descriptive text.

## Files

- `bloodfang-thrill-dps.md`
- `bloodfang-battlearmor-tank.md`

## Reference sources

- Warcraft Wiki — Bloodfang Thrill: https://warcraft.wiki.gg/wiki/Bloodfang_Thrill
- Warcraft Wiki — Bloodfang Battlearmor: https://warcraft.wiki.gg/wiki/Bloodfang_Battlearmor
- Wowhead — Season of Discovery Tier 2 overview: https://www.wowhead.com/classic/guide/season-of-discovery/tier-2-sets-overview
