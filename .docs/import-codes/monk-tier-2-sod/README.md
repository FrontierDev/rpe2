# Monk Tier 2 — August Acolyte — RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for three invented level-60 Monk Tier 2 variants using the canonical **August Acolyte** naming and visual theme:

- **August Acolyte — Windwalker DPS** — 8 pieces.
- **August Acolyte — Brewmaster Tank** — 8 pieces.
- **August Acolyte — Mistweaver Healer** — 8 pieces.

The canonical Anniversary Monk Tier 2 appearance uses the piece family **Helm / Spaulders / Vest / Bindings / Grips / Cord / Pants / Talons of the August Acolyte**. The RPE role variants retain the August Acolyte set name while using role-specific item nouns where useful to distinguish the three stat variants.

## RPE normalization

- Dataset: `monkdata`
- Class: `monkdata:monk0001`
- Required level: **60**
- Item level: **75**
- Quality: **Epic**
- Binding: **Bind on Pickup**
- Armor weight: **Leather**
- Windwalker set key: `t2_monk_dps`
- Brewmaster set key: `t2_monk_tank`
- Mistweaver set key: `t2_monk_healer`
- Every piece supports generic modifier key `mod`, capped at **1**.
- Chest pieces use 3 sockets; helms use 2 including 1 meta socket; legs use 2; belts/waists use 1.
- **Windwalker** uses the existing Bloodfang Thrill DPS stat budget and red/yellow DPS socket layout.
- **Brewmaster** uses the existing Bloodfang Battlearmor tank stat budget and blue/yellow tank socket layout.
- **Mistweaver** uses the existing Bounty of Stormrage healer stat budget and red/yellow/blue healer socket layout.
- Armor and resistance distributions are preserved from those role-equivalent Tier 2 templates.
- No set-bonus mechanics are embedded in the item descriptions.

## Full-set totals

### Windwalker
- Armor: **1292**
- Strength: **88**
- Agility: **208**
- Stamina: **116**
- Nature Resistance: **50**
- Frost Resistance: **50**
- Melee Crit. Chance: **6**
- Melee Hit Chance: **6**

### Brewmaster
- Armor: **1292**
- Strength: **8**
- Agility: **139**
- Stamina: **226**
- Nature Resistance: **50**
- Frost Resistance: **50**
- Melee Hit Chance: **5**
- Defense Rating: **84**

### Mistweaver
- Armor: **1292**
- Intellect: **114**
- Stamina: **100**
- Spirit: **75**
- Nature Resistance: **50**
- Frost Resistance: **50**
- Spell Crit. Chance: **7**
- Healing Power: **398**
- Spell Power: **134**

## Files

- `august-acolyte-windwalker-dps.md`
- `august-acolyte-brewmaster-tank.md`
- `august-acolyte-mistweaver-healer.md`
