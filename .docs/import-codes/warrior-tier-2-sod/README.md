# Season of Discovery Warrior Tier 2 — RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for all 16 Warrior Tier 2 **Draconic** pieces from Season of Discovery, plus two separate Item Set bonus entries:

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

## Item Set bonuses

The 8-piece armor sets each unlock **2-, 4-, and 6-piece** bonuses (there is no SoD 8-piece bonus). The two Item Set entries below match the existing armor `itemSetKey` values. They are **not armor pieces** and must be imported once each into the same Warrior dataset.

These bonuses are **functional RPE adaptations** rather than exact copies of SoD spell mechanics. In particular, the current Item Set event model cannot filter by a specific triggering spell, reset spell cooldowns, support three-swing attack-speed Flurry, or enforce per-target 30-second retaliation cooldowns. The adaptation and original source effects are documented beside each code block.

**Compatibility:** The `dev` branch's game runtime does not yet contain the `itemSets` collection/import support present on `main`. These import codes use the supported `itemSets` schema from `main`; merging that implementation into `dev` (or importing into an equivalent build) is required before the codes will run. Do not mistake adding these documentation files for adding runtime support.

## Files

- `unstoppable-wrath-dps.md` — eight DPS armor pieces
- `immoveable-wrath-tank.md` — eight tank armor pieces
- `unstoppable-wrath-set-bonuses.md` — **one DPS Item Set import**
- `immoveable-wrath-set-bonuses.md` — **one tank Item Set import**

## Reference sources

- Warcraft Wiki — Unstoppable Wrath: https://warcraft.wiki.gg/wiki/Unstoppable_Wrath
- Warcraft Wiki — Immoveable Wrath: https://warcraft.wiki.gg/wiki/Immoveable_Wrath
- Wowhead — Season of Discovery Tier 2 overview: https://www.wowhead.com/classic/guide/season-of-discovery/tier-2-sets-overview
