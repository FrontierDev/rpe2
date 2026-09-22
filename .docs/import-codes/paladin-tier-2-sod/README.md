# Season of Discovery Paladin Tier 2 — RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for all 24 Paladin Tier 2 **Draconic** pieces from Season of Discovery:

- **Radiant Judgement** — Retribution, 8 pieces.
- **Merciful Judgement** — Holy, 8 pieces.
- **Wilfull Judgement** — Protection, 8 pieces.

The codes target the Paladin dataset `b0211ab3`, use the current RPE `RPE_DATASET_ENTRY_V1` format, require level 60 and Paladin, and use the existing Core stat and equipment-slot references.

## Translation notes

- Source items are item level **76**, epic, bind-on-pickup plate.
- WoW effects that increase hit or critical chance for **all spells and attacks** are represented by both the RPE melee and spell hit/critical stats.
- Holy-set healing bonuses use RPE **Healing Power**; their damage component uses RPE **Spell Power**.
- Retribution's Holy-only spell-damage bonuses use RPE **Spell Power**, because RPE currently has no school-specific Holy Spell Power stat.
- RPE currently has **Block Chance** and **Defense Rating**, but no **Shield Block Value** stat. Protection pieces that have Block Value but no existing Block Chance receive **+1% Block Chance** as the RPE approximation. Pieces that already have Block Chance keep their authored Block Chance. Unsupported Shield Block Value text is omitted rather than preserved in item descriptions.
- No sockets have been added. Season of Discovery Tier 2 does not natively have RPE's socket system; socketing can be authored separately if desired.
- Existing RPE item-set keys are retained where already established: `t2_pala_dps` and `t2_pala_tank`. Holy uses `t2_pala_healer`.

## Files

- `radiant-judgement-retribution.md`
- `merciful-judgement-holy.md`
- `wilfull-judgement-protection.md`

## Reference sources

- Warcraft Wiki — Radiant Judgement: https://warcraft.wiki.gg/wiki/Radiant_Judgement
- Warcraft Wiki — Merciful Judgement: https://warcraft.wiki.gg/wiki/Merciful_Judgement
- Warcraft Wiki — Wilfull Judgement: https://warcraft.wiki.gg/wiki/Wilfull_Judgement
- Wowhead — Season of Discovery Tier 2 overview: https://www.wowhead.com/classic/guide/season-of-discovery/tier-2-sets-overview
