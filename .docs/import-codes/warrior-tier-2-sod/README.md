# Season of Discovery Warrior Tier 2 — RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for all 16 Warrior Tier 2 **Draconic** pieces from Season of Discovery:

- **Unstoppable Wrath** — melee DPS, 8 pieces.
- **Immoveable Wrath** — tank, 8 pieces.

The codes target the Warrior dataset `sb4b9ef3`, use the current `RPE_DATASET_ENTRY_V1` format, require level 60 and Warrior, and use Core stat and equipment-slot references.

## RPE normalization

- All pieces are normalized to item level **75**.
- All pieces are epic, bind-on-pickup plate armor.
- Every piece supports generic modifier key `mod`, capped at **1** via `maxGenericModificationCounts` / `maxModificationCounts`.
- Chest pieces have **3** gem sockets; heads have **2** including **1 meta** socket; legs have **2**; belts have **1**.
- Socket colours are restricted to **red, blue, and yellow**, with **meta** only on helms.
- Unstoppable Wrath uses red/yellow sockets; Immoveable Wrath uses blue/yellow sockets.
- Source bonuses worded as applying to “all spells and attacks” are specialized for Warrior: hit and critical-strike bonuses map to **Melee Hit Chance** and **Melee Crit. Chance** only. No Warrior Tier 2 piece receives Spell Hit, Spell Crit, Spell Power, or Healing Power.
- Base attributes such as Strength, Agility, and Stamina remain as authored on the SoD source items.
- Tank Defense bonuses map directly to RPE **Defense Rating**.
- The source Draconic tank pieces used here do not carry Shield Block Value, so no Block Chance approximation is required.

## Files

- `unstoppable-wrath-dps.md`
- `immoveable-wrath-tank.md`

## Reference sources

- Warcraft Wiki — Unstoppable Wrath: https://warcraft.wiki.gg/wiki/Unstoppable_Wrath
- Warcraft Wiki — Immoveable Wrath: https://warcraft.wiki.gg/wiki/Immoveable_Wrath
- Wowhead — Season of Discovery Tier 2 overview: https://www.wowhead.com/classic/guide/season-of-discovery/tier-2-sets-overview
