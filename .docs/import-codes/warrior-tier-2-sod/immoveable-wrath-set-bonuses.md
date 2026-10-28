# Immoveable Wrath — Tier 2 tank Item Set bonus import

This is **one standalone Item Set entry** (not an armor-piece import). Paste the complete code block into RPE's dataset-entry importer.

- Target dataset: `7bbb4cb9` (the Warrior dataset used by the item import files here).
- Collection: `itemSets`.
- Matching key: `t2_warrior_tank` (already present on the eight tank armor entries).
- Unlocks: **2, 4, and 6 pieces**. No 8-piece bonus exists on the SoD source set.

**RPE adaptations, not exact Season of Discovery mechanics:** SoD grants +10 Rage when parrying **or having an attack parried** (2), Revenge-triggered 30% attack-speed Flurry for three swings (4), and 200%-weapon-damage retaliation against enemies that parry your attacks with a 30-second per-target cooldown (6). The current RPE equipment-bonus model can respond to **your own successful Parry**, but it does not express the other parry direction, Revenge-specific attack-speed effects, or per-target 30-second internal cooldowns. This entry implements the supported 2-piece Parry trigger, replaces Flurry with +35 Melee Attack Power, and converts Retaliate into a **20%-chance Physical counterattack on your own Parry**, without a hidden cooldown.

## Item Set import code

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "itemSets",
    datasetId = "7bbb4cb9",
    entry = {
        id = "t2_warrior_tank",
        key = "t2_warrior_tank",
        name = "Immoveable Wrath",
        description = "Tier 2 Warrior tank armor set. RPE-adapted bonuses.",
        icon = "interface/icons/inv_chest_plate16.blp",
        bonuses = {
            {
                requiredPieces = 2,
                statBonuses = {},
                skillBonuses = {},
                equipmentBonuses = {
                    {
                        name = "Immoveable Resolve",
                        description = "Restore 10 Rage when you successfully Parry an attack.",
                        events = {
                            {
                                combatEventId = "on_defence",
                                defenceStatRef = "f82db71a:tcn0s8kx",
                                chance = 100,
                                triggerTarget = "event_other",
                                effects = {
                                    {
                                        type = "resource",
                                        resourceRef = "f82db71a:e2tfklq7",
                                        amountMode = "flat",
                                        amount = 10,
                                    },
                                },
                            },
                        },
                    },
                },
            },
            {
                requiredPieces = 4,
                statBonuses = {
                    {
                        statRef = "f82db71a:u7b49vs9",
                        value = 35,
                    },
                },
                skillBonuses = {},
                equipmentBonuses = {},
            },
            {
                requiredPieces = 6,
                statBonuses = {},
                skillBonuses = {},
                equipmentBonuses = {
                    {
                        name = "Immoveable Retaliation",
                        description = "Successfully Parrying an attack has a 20% chance to counterattack the attacker for Physical damage.",
                        events = {
                            {
                                combatEventId = "on_defence",
                                defenceStatRef = "f82db71a:tcn0s8kx",
                                chance = 20,
                                triggerTarget = "event_source",
                                effects = {
                                    {
                                        type = "damage",
                                        baseDamage = 100,
                                        amountMode = "flat",
                                        damageSchoolRefs = {
                                            "f82db71a:v1azo4j6",
                                        },
                                        statScaling = {
                                            {
                                                statRef = "f82db71a:u7b49vs9",
                                                coefficient = 0.20,
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    },
}
```

Sources for the **original SoD effects** (not the adaptations): [Warcraft Wiki](https://warcraft.wiki.gg/wiki/Immoveable_Wrath), [Wowhead set](https://www.wowhead.com/classic/item-set=1822/immoveable-wrath).
