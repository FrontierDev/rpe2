# Season of Discovery Shaman Tier 2 — RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for all 32 Shaman Tier 2 **Draconic** pieces from Season of Discovery:

- **Eruption of the Ten Storms** — Elemental DPS, 8 pieces.
- **Impact of the Ten Storms** — Enhancement DPS, 8 pieces.
- **Relief of the Ten Storms** — Restoration healer, 8 pieces.
- **Resolve of the Ten Storms** — tank, 8 pieces.

The codes target the Shaman dataset `c4a91e7d`, use the current `RPE_DATASET_ENTRY_V1` format, require level 60 and Shaman class ref `c4a91e7d:shaman01`, and use existing Core stat and equipment-slot references.

## RPE normalization

- All pieces are normalized to item level **75**, matching the existing RPE Season of Discovery Tier 2 convention.
- All pieces are epic, bind-on-pickup **mail** armor.
- Every piece supports generic modifier key `mod`, capped at **1**.
- Chest pieces have **3** sockets; heads have **2** including **1 meta**; legs have **2**; belts have **1**.
- Eruption and Impact use red/yellow sockets; Relief uses red/yellow/blue; Resolve uses blue/yellow.
- **Eruption** specializes generic hit/critical bonuses to RPE **Spell Hit Chance** and **Spell Crit. Chance**. Combined magical damage/healing is represented as **Spell Power** only.
- **Impact** specializes generic hit/critical bonuses to **Melee Hit Chance** and **Melee Crit. Chance**.
- **Relief** specializes generic critical bonuses to **Spell Crit. Chance** and retains the source item's separate **Healing Power** and **Spell Power** magnitudes.
- **Resolve** maps source Defense directly to **Defense Rating** and source block chance to **Block Chance**. Generic hit is represented with both **Melee Hit Chance** and **Spell Hit Chance**, matching the hybrid tank treatment used elsewhere in the RPE Tier 2 imports. Source magical damage/healing on tank pieces is represented as **Spell Power**.
- Base Strength, Agility, Stamina, Intellect, Armor, Nature Resistance and Frost Resistance are retained where present on the source item.
- No unsupported set-bonus mechanics are written into item descriptions.

## Files

- `eruption-of-the-ten-storms-elemental.md`
- `impact-of-the-ten-storms-enhancement.md`
- `relief-of-the-ten-storms-restoration.md`
- `resolve-of-the-ten-storms-tank.md`

## Reference source

- Wowhead — Season of Discovery Tier 2 overview and linked Shaman item pages: https://www.wowhead.com/classic/guide/season-of-discovery/tier-2-sets-overview
