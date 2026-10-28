# Unstoppable Wrath — Tier 2 melee DPS Item Set bonus import

This is **one standalone Item Set entry** (not an armor-piece import). Paste the complete code block into RPE's dataset-entry importer.

- Target dataset: `7bbb4cb9` (the Warrior dataset used by the item import files here).
- Collection: `itemSets`.
- Matching key: `t2_warrior_dps` (already present on the eight DPS armor entries).
- Unlocks: **2, 4, and 6 pieces**. No 8-piece bonus exists on the SoD source set.

**RPE adaptations, not exact Season of Discovery mechanics:** SoD gives Rend-duration refresh specifically on critical Overpower (2), +25% damage to Heroic Strike, Slam and Overpower (4), and Slam-triggered cooldown resets (6). The Item Set equipment-bonus event model cannot currently filter by the triggering spell or reset spell cooldowns. To keep **all three imported tiers functional** without claiming those unsupported mechanics, this entry instead gives a low-chance Rend application/refresh on any critical hit (2), +5% general Damage Done (4), and a chance to restore Rage on melee hit (6). These are deliberately different from the original effects.

## Item Set import code

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "itemSets",
    datasetId = "7bbb4cb9",
    entry = {
        id = "t2_warrior_dps",
        key = "t2_warrior_dps",
        name = "Unstoppable Wrath",
        description = "Tier 2 Warrior melee DPS armor set. RPE-adapted bonuses.",
        icon = "interface/icons/inv_chest_plate16.blp",
        bonuses = {
            {
                requiredPieces = 2,
                statBonuses = {},
                skillBonuses = {},
                equipmentBonuses = {
                    {
                        name = "Unstoppable Rend",
                        description = "Critical hits have a 20% chance to apply or refresh Rend on the target for 5 turns.",
                        events = {
                            {
                                combatEventId = "on_critical_hit",
                                chance = 20,
                                triggerTarget = "event_other",
                                effects = {
                                    {
                                        type = "apply_aura",
                                        auraRef = "7bbb4cb9:jkptpqlh",
                                        stacks = 1,
                                        duration = 5,
                                        basePower = 0,
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
                        statRef = "f82db71a:gj9wxb0x",
                        value = 5,
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
                        name = "Unstoppable Momentum",
                        description = "Melee hits have a 20% chance to restore 10 Rage.",
                        events = {
                            {
                                combatEventId = "on_melee_hit",
                                chance = 20,
                                triggerTarget = "event_source",
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
        },
    },
}
```

Sources for the **original SoD effects** (not the adaptations): [Warcraft Wiki](https://warcraft.wiki.gg/wiki/Unstoppable_Wrath), [Wowhead set](https://www.wowhead.com/classic/item-set=1823/unstoppable-wrath).
