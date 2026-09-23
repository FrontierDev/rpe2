# Season of Discovery Warrior Tier 0.5 — Battlegear of Heroism RPE Import Codes

This folder contains standalone RPE dataset-entry import codes for all 16 Warrior Dungeon Set 2 / Tier 0.5 **Battlegear of Heroism** pieces from Season of Discovery:

- **Unstoppable** — melee DPS, 8 pieces.
- **Immoveable** — tank, 8 pieces.

The codes target the Warrior dataset `sb4b9ef3`, use the current `RPE_DATASET_ENTRY_V1` format, require level 60 and Warrior, and use the existing Core stat and equipment-slot references.

## RPE normalization

- Every RPE Heroism piece is normalized to item level **60**, as requested. Original SoD item levels vary between 55 and 66; their authored SoD stats are otherwise retained.
- Source rarity is retained: head, chest, hands, and feet are **epic**; legs, shoulders, waist, and wrists are **rare**.
- All pieces are plate, bind-on-pickup, require level 60 and Warrior, and support generic modifier key `mod` capped at **1**.
- No sockets are added.
- All 16 specialization variants use the shared RPE item-set key `t05_warrior_heroism`. Season of Discovery Heroism variants share the same set bonuses and can be freely mixed and matched.
- Source bonuses worded as applying to “all spells and attacks” are specialized for Warrior:
  - Hit maps to **Melee Hit Chance**.
  - Critical strike maps to **Melee Crit. Chance**.
  - Spell Hit, Spell Crit, Spell Power, and Healing Power are not added.
- Tank Defense bonuses map directly to RPE **Defense Rating**.
- RPE has **Block Chance** but no **Shield Block Value** stat. Chestguard of Heroism and Legguards of Heroism therefore receive **+1% Block Chance** as the established approximation for their source Shield Block Value bonuses.
- Handguards of Heroism already grants **+3% Block Chance** in SoD and retains that value directly.
- The original Heroism slot icon family is used for both specialization variants of each slot.

## Battlegear of Heroism set bonuses

The current SoD variants share these set bonuses. They are documented here for reference; the standalone item import codes do not separately author the set-bonus mechanics:

- **2 pieces:** +40 Attack Power.
- **4 pieces:** Chance on melee attack to heal the wearer for 88–132 and generate 10 Rage.
- **6 pieces:** +8 All Resistances.
- **8 pieces:** +200 Armor.

## Files

- `unstoppable-heroism-dps.md`
- `immoveable-heroism-tank.md`

## Reference sources

- Warcraft Wiki — Battlegear of Heroism: https://warcraft.wiki.gg/wiki/Battlegear_of_Heroism
- Warcraft Wiki — Unstoppable Boots, Legs, and Shoulders Set: https://warcraft.wiki.gg/wiki/Unstoppable_Boots,_Legs,_and_Shoulders_Set
- Warcraft Wiki — Immoveable Boots, Legs, and Shoulders Set: https://warcraft.wiki.gg/wiki/Immoveable_Boots,_Legs,_and_Shoulders_Set
- Wowhead — Season of Discovery Warrior DPS pre-raid gear: https://www.wowhead.com/classic/guide/season-of-discovery/classes/warrior/dps-pre-raid-bis-gear-pve
