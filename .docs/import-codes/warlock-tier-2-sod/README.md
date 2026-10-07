# Season of Discovery Warlock Tier 2 — RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for all 16 Warlock Tier 2 Draconic pieces from Season of Discovery:

- **Corrupted Nemesis** — DPS, 8 pieces.
- **Wicked Nemesis** — tank, 8 pieces.

The codes target the Warlock dataset `e8f3b2c6`, use `RPE_DATASET_ENTRY_V1`, require level 60 and Warlock class ref `e8f3b2c6:warlock1`, and use existing Core stat and equipment-slot references.

## RPE normalization

- All pieces are normalized to RPE item level **75**, following the existing Tier 2 import convention.
- All pieces are epic, bind-on-pickup cloth armor.
- Every piece supports generic modifier key `mod`, capped at **1**.
- Chest pieces have **3** sockets; heads have **2** including **1 meta**; legs have **2**; belts have **1**.
- Corrupted Nemesis uses red/yellow sockets.
- Wicked Nemesis uses blue/yellow sockets.
- WoW bonuses that improve hit or critical chance with all spells and attacks are specialized to RPE **Spell Hit Chance** / **Spell Crit. Chance** for Warlock.
- WoW “damage and healing” bonuses are represented as RPE **Spell Power** only.
- Wicked Nemesis “Defense” is represented directly as RPE **Defense Rating**.
- Item-set keys are `t2_warlock_dps` and `t2_warlock_tank`.
