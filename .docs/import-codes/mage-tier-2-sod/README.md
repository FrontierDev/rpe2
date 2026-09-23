# Season of Discovery Mage Tier 2 — RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for all 16 Mage Tier 2 Draconic pieces from Season of Discovery:

- **Netherwind Insight** — spell DPS, 8 pieces.
- **Netherwind Moment** — healer, 8 pieces.

## RPE normalization

- All pieces are item level **75**, epic, bind-on-pickup cloth.
- Every piece supports generic modifier `mod`, capped at **1**.
- Chest: **3** sockets; head: **2** including **1 meta**; legs: **2**; belt: **1**.
- Socket colours are restricted to **red, blue, yellow**, plus the helm meta.
- Netherwind Insight uses red/yellow sockets; Netherwind Moment uses red/yellow/blue.
- “All spells and attacks” hit/crit bonuses are specialized to **Spell Hit Chance** and **Spell Crit. Chance** only. No melee offensive stats are added.
- For Netherwind Insight, combined “damage and healing” bonuses are represented as **Spell Power only** to keep the DPS set role-pure.
- For Netherwind Moment, combined “damage and healing” bonuses are represented as both **Spell Power** and **Healing Power**, because Mage healing uses offensive Arcane casting as part of its healing loop.
- The Draconic Mage Tier 2 pieces used here do not carry MP5, so no Resource Regeneration conversion is required.

## Files

- `netherwind-insight-dps.md`
- `netherwind-moment-healer.md`
