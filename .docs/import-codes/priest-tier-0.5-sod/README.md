# Season of Discovery Priest Tier 0.5 — Vestments of the Virtuous RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for all 16 Priest Dungeon Set 2 / Tier 0.5 **Vestments of the Virtuous** pieces from Season of Discovery:

- **Dawn** — healer, 8 pieces.
- **Twilight** — Shadow DPS, 8 pieces.

The codes target the Priest dataset `cqblzgiw`, use the current `RPE_DATASET_ENTRY_V1` format, require level 60 and Priest, and use the existing Core stat and equipment-slot references.

## RPE normalization

- Every RPE Virtuous piece is normalized to item level **60**, as requested. Original SoD item levels vary between 55 and 66; their authored SoD stats are otherwise retained.
- Source rarity is retained: head, chest, hands, and feet are **epic**; legs, shoulders, waist, and wrists are **rare**.
- All pieces are cloth, bind-on-pickup, require level 60 and Priest, and support generic modifier key `mod` capped at **1**.
- No sockets are added.
- All 16 specialization variants use the shared RPE item-set key `t05_priest_virtuous`. Season of Discovery Virtuous variants share the same set bonuses and can be freely mixed and matched.
- Shadow-only spell-damage bonuses map to the general RPE **Spell Power** stat because Core has no school-specific Shadow Spell Power stat.
- Healing-only bonuses map directly to **Healing Power**; Spell Power is not invented where the source item grants healing only.
- Source effects that improve hit or critical chance for **all spells and attacks** are represented by both the matching RPE melee and spell stat, following the existing Priest Tier 2 import convention.
- **Mana per 5 seconds converts approximately 1:1 to RPE Resource Regeneration:** 1 MP5 ≈ +1% Resource Regeneration. Only **Virtuous Sandals** and **Virtuous Belt** have 4 MP5 in the SoD healer set, so only those two receive +4 Resource Regeneration.
- The original Virtuous slot icon family is used for both specialization variants of each slot.

## Vestments of the Virtuous set bonuses

The current SoD variants share these set bonuses. They are documented here for reference; the standalone item import codes do not separately author the set-bonus mechanics:

- **2 pieces:** Increases magical spell damage and healing by up to 23.
- **4 pieces:** Spellcasts have a 6% chance to restore 300 Mana.
- **6 pieces:** +8 All Resistances.
- **8 pieces:** +200 Armor.

## Files

- `dawn-virtuous-healer.md`
- `twilight-virtuous-shadow.md`

## Reference sources

- Warcraft Wiki — Vestments of the Virtuous: https://warcraft.wiki.gg/wiki/Vestments_of_the_Virtuous
- Wowhead — Season of Discovery Tier 0.5 sets overview: https://www.wowhead.com/classic/guide/season-of-discovery/tier-0-5-sets-overview
- Wowhead — Season of Discovery Tier 0.5 acquisition: https://www.wowhead.com/classic/news/how-to-acquire-dungeon-set-2-tier-0-5-in-season-of-discovery-phase-4-345224
