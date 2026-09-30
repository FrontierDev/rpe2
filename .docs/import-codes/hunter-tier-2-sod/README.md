# Season of Discovery Hunter Tier 2 — RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for all 16 Hunter Tier 2 **Draconic** pieces from Season of Discovery:

- **Dragonstalker's Pursuit** — ranged DPS, 8 pieces.
- **Dragonstalker's Prowess** — melee DPS, 8 pieces.

The codes target the Hunter dataset `a93f7c12`, use the current `RPE_DATASET_ENTRY_V1` format, require level 60 and Hunter, and use Core stat and equipment-slot references.

## RPE normalization

- All pieces are normalized to item level **75**, matching the existing RPE Season of Discovery Tier 2 import convention.
- All pieces are epic, bind-on-pickup **mail** armor.
- Every piece supports generic modifier key `mod`, capped at **1** via `maxGenericModificationCounts` / `maxModificationCounts`.
- Chest pieces have **3** gem sockets; heads have **2** including **1 meta** socket; legs have **2**; belts have **1**.
- Both Hunter DPS variants use red/yellow sockets.
- Source bonuses worded as applying to “all spells and attacks” are specialized by role:
  - **Dragonstalker's Pursuit** maps hit and critical-strike bonuses to **Ranged Hit Chance** and **Ranged Crit. Chance**.
  - **Dragonstalker's Prowess** maps them to **Melee Hit Chance** and **Melee Crit. Chance**.
- Base Strength, Agility, Intellect, Stamina, Armor, Nature Resistance and Frost Resistance are retained exactly from the Season of Discovery Draconic source items.
- No Spell Hit, Spell Crit, Spell Power, Healing Power, or invented attack-power bonuses are added.

## Files

- `dragonstalkers-pursuit-ranged.md`
- `dragonstalkers-prowess-melee.md`

## Reference sources

- Warcraft Wiki — Dragonstalker's Pursuit: https://warcraft.wiki.gg/wiki/Dragonstalker%27s_Pursuit
- Warcraft Wiki — Dragonstalker's Prowess: https://warcraft.wiki.gg/wiki/Dragonstalker%27s_Prowess
- Wowhead — Season of Discovery Tier 2 overview: https://www.wowhead.com/classic/guide/season-of-discovery/tier-2-sets-overview
