# Season of Discovery Druid Tier 0.5 — Feralheart RPE Import Codes

This folder currently contains the **Balance DPS** and **Feral DPS** variants of the Druid Dungeon Set 2 / Tier 0.5 **Feralheart Raiment** from Season of Discovery.

- **Balance / Astral rewards** — 8 pieces.
- **Feral DPS / Feline rewards** — 8 pieces.

The codes target the Druid dataset `6e4d2a91`, use the current `RPE_DATASET_ENTRY_V1` format, require level 60 and Druid class ref `6e4d2a91:drdcls01`, and use the existing Core stat and equipment-slot references.

## Translation notes

- Every piece is normalized to item level **60**, matching the existing RPE Tier 0.5 import convention.
- Source rarity is retained: head, chest, hands, and feet are **epic**; legs, shoulders, waist, and wrists are **rare**.
- All pieces are leather, bind-on-pickup, require level 60 and Druid, and support generic modifier key `mod` capped at **1**.
- No sockets are added.
- All pieces use the shared RPE item-set key `t05_druid_feralheart`.
- SoD effects that improve hit or critical chance for **all spells and attacks** are specialized by intended RPE role, matching the existing Druid Tier 2 convention:
  - Balance maps them to **Spell Hit Chance** / **Spell Crit. Chance**.
  - Feral DPS maps them to **Melee Hit Chance** / **Melee Crit. Chance**.
- Source damage-and-healing bonuses are represented as **Spell Power** for the Balance set.
- The original Feralheart slot icon family is used.

## Feralheart set bonuses

The Season of Discovery Feralheart variants share these set bonuses. They are documented here for reference; the item import codes do not separately author the set-bonus mechanics:

- **2 pieces:** +40 Attack Power, up to +23 spell damage, and up to +44 healing.
- **4 pieces:** Resource-return proc appropriate to Mana, Energy, or Rage.
- **6 pieces:** +8 All Resistances.
- **8 pieces:** +200 Armor.

## Files

- `feralheart-balance.md`
- `feralheart-feral-dps.md`

## Reference sources

- Warcraft Wiki — Season of Discovery Feralheart item pages.
- Wowhead — Dungeon Set 2 / Tier 0.5 in Season of Discovery Phase 4: https://www.wowhead.com/classic/news/how-to-acquire-dungeon-set-2-tier-0-5-in-season-of-discovery-phase-4-345224
- Wowhead — SoD Balance Feralheart item IDs 226772–226779.
- Wowhead / Warcraft Wiki — SoD Feral DPS Feralheart item IDs 226788–226795.
