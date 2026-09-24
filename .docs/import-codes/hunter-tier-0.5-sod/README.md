# Season of Discovery Hunter Tier 0.5 — Beastmaster Armor RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for all 16 role-specific Hunter Dungeon Set 2 / Tier 0.5 **Beastmaster Armor** pieces from Season of Discovery:

- **Pursuer** — ranged DPS, 8 pieces.
- **Prowler** — melee DPS, 8 pieces.

The codes target the Hunter dataset `a93f7c12`, use the current `RPE_DATASET_ENTRY_V1` format, require level 60 and Hunter, and use the existing Core stat and equipment-slot references.

## RPE normalization

- Every RPE Beastmaster piece is normalized to item level **60**. Original SoD item levels vary between 55 and 66; their authored SoD stats are otherwise retained.
- Source rarity is retained: head, chest, hands, and feet are **epic**; legs, shoulders, waist, and wrists are **rare**.
- All pieces are mail, bind-on-pickup, require level 60 and Hunter, and support generic modifier key `mod` capped at **1**.
- No sockets are added.
- All 16 specialization variants use the shared RPE item-set key `t05_hunter_beastmaster`. Season of Discovery Beastmaster variants share the same set bonuses and can be freely mixed and matched.
- The separate SoD original-stat Beastmaster variants are not duplicated here, matching the approach used for the other Tier 0.5 class import folders.
- Source bonuses worded as applying to “all spells and attacks” are specialized for Hunter:
  - **Pursuer** hit/critical bonuses map to **Ranged Hit Chance** / **Ranged Crit. Chance**.
  - **Prowler** hit/critical bonuses map to **Melee Hit Chance** / **Melee Crit. Chance**.
- Strength, Agility, Intellect, Stamina, and Armor are retained exactly from the corresponding SoD source items.
- No Spell Hit, Spell Crit, Spell Power, Healing Power, or invented attack-power bonuses are added.
- The same Hunter mail slot icon family is used across both variants.

## Beastmaster Armor set bonuses

The Season of Discovery variants share these set bonuses. They are documented here for reference; the standalone item import codes do not separately author the set-bonus mechanics:

- **2 pieces:** +40 Attack Power.
- **4 pieces:** Melee and ranged autoattacks have a 6% chance to restore 300 Mana.
- **6 pieces:** +8 All Resistances.
- **8 pieces:** +200 Armor.

## Files

- `beastmaster-pursuer-ranged.md`
- `beastmaster-prowler-melee.md`

## Reference sources

- Warcraft Wiki — Beastmaster Armor: https://warcraft.wiki.gg/wiki/Beastmaster_Armor
- Warcraft Wiki — individual Season of Discovery Beastmaster item pages.
- Wowhead — Season of Discovery Tier 0.5 sets overview: https://www.wowhead.com/classic/guide/season-of-discovery/tier-0-5-sets-overview
