# Season of Discovery Priest Tier 2 — RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for all 16 Priest Tier 2 **Draconic** pieces from Season of Discovery:

- **Dawn of Transcendence** — healer, 8 pieces.
- **Twilight of Transcendence** — Shadow DPS, 8 pieces.

The codes target the Priest dataset `cqblzgiw`, use the current `RPE_DATASET_ENTRY_V1` format, require level 60 and Priest, and use Core stat and equipment-slot references.

## RPE normalization

- All pieces are normalized to item level **75**.
- All pieces are epic, bind-on-pickup cloth armor.
- Every piece supports generic modifier key `mod`, capped at **1** via `maxGenericModificationCounts` / `maxModificationCounts`.
- Chest pieces have **3** gem sockets; heads have **2** including **1 meta** socket; legs have **2**; belts have **1**.
- Socket colours are restricted to **red, blue, and yellow**, with **meta** only on helms.
- Shadow DPS uses red/yellow sockets, emphasizing Spell Power and caster hit/critical/Intellect options.
- Healer uses red/yellow/blue sockets, giving access to Healing/Spell Power, Intellect/crit, and Healing/Stamina/Spirit gem families.
- Shadow-only spell damage is mapped to the general RPE **Spell Power** stat because the Core dataset has no school-specific Shadow Spell Power stat.
- WoW effects that improve critical strike chance for all spells and attacks are represented with both RPE **Spell Crit. Chance** and **Melee Crit. Chance**.
- **Mana per 5 seconds converts approximately 1:1 to RPE Resource Regeneration:** 1 MP5 ≈ +1% Resource Regeneration (`f82db71a:rgnrtg01`). The current Draconic SoD Tier 2 item versions listed by Warcraft Wiki/Wowhead do not contain MP5 item stats, so no Resource Regeneration stat is added to these 16 imports.

## Files

- `dawn-of-transcendence-healer.md`
- `twilight-of-transcendence-shadow.md`

## Reference sources

- Warcraft Wiki — Dawn of Transcendence: https://warcraft.wiki.gg/wiki/Dawn_of_Transcendence
- Warcraft Wiki — Twilight of Transcendence: https://warcraft.wiki.gg/wiki/Twilight_of_Transcendence
- Wowhead — Season of Discovery Tier 2 overview: https://www.wowhead.com/classic/guide/season-of-discovery/tier-2-sets-overview
