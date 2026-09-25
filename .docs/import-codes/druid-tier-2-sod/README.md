# Season of Discovery Druid Tier 2 — RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for all 32 Druid Tier 2 **Draconic** pieces from Season of Discovery:

- **Eclipse of Stormrage** — Balance DPS, 8 pieces.
- **Cunning of Stormrage** — Feral DPS, 8 pieces.
- **Fury of Stormrage** — Feral Tank, 8 pieces.
- **Bounty of Stormrage** — Restoration healer, 8 pieces.

The codes target the Druid dataset `6e4d2a91`, use the current `RPE_DATASET_ENTRY_V1` format, require level 60 and Druid class ref `6e4d2a91:drdcls01`, and use Core stat and equipment-slot references.

## RPE normalization

- All pieces are normalized to item level **75**, matching the existing RPE Season of Discovery Tier 2 convention.
- All pieces are epic, bind-on-pickup **leather** armor.
- Every piece supports generic modifier key `mod`, capped at **1** via `maxGenericModificationCounts` / `maxModificationCounts`.
- Chest pieces have **3** gem sockets; heads have **2** including **1 meta** socket; legs have **2**; belts have **1**.
- Socket colours are restricted to **red, blue and yellow**, with **meta** only on helms.
- Eclipse and Cunning use red/yellow sockets; Fury uses blue/yellow; Bounty uses red/yellow/blue.
- Bonuses worded as applying to “all spells and attacks” are specialized by intended RPE role:
  - **Eclipse** maps hit/critical bonuses to Spell Hit Chance and Spell Crit. Chance.
  - **Cunning** maps hit/critical bonuses to Melee Hit Chance and Melee Crit. Chance.
  - **Fury** maps the single offensive hit bonus to Melee Hit Chance and maps source Defense directly to RPE Defense Rating.
  - **Bounty** maps critical-strike bonuses to Spell Crit. Chance only.
- Eclipse source “damage and healing” bonuses are represented as **Spell Power only** to keep the Balance set role-pure.
- Bounty keeps both source **Healing Power** and **Spell Power** values because the source pieces explicitly provide different healing and damage magnitudes.
- Base Strength, Agility, Stamina, Intellect, Spirit, Armor, Nature Resistance and Frost Resistance are retained from the Draconic source items.
- No unsupported set-bonus mechanics are written into item descriptions. Set mechanics can be authored separately if/when the item-set system represents them.

## Files

- `eclipse-of-stormrage-balance.md`
- `cunning-of-stormrage-feral-dps.md`
- `fury-of-stormrage-feral-tank.md`
- `bounty-of-stormrage-restoration.md`

## Reference sources

- Warcraft Wiki — Eclipse of Stormrage: https://warcraft.wiki.gg/wiki/Eclipse_of_Stormrage
- Warcraft Wiki — Cunning of Stormrage: https://warcraft.wiki.gg/wiki/Cunning_of_Stormrage
- Warcraft Wiki — Fury of Stormrage: https://warcraft.wiki.gg/wiki/Fury_of_Stormrage_(set)
- Warcraft Wiki — Bounty of Stormrage: https://warcraft.wiki.gg/wiki/Bounty_of_Stormrage
- Wowhead — Season of Discovery Tier 2 overview: https://www.wowhead.com/classic/guide/season-of-discovery/tier-2-sets-overview
