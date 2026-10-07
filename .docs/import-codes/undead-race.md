# Undead Race Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import code for the Undead race in the Core dataset.

The base attributes come from `.docs/RPE2_WoW_Classic_Base_Stats_Reference.md`.

- Base attributes (STR / AGI / STA / INT / SPI): 19 / 18 / 21 / 18 / 25
- Shared trait import codes: `.docs/import-codes/shared-race-traits.md`
- Race-specific trait import codes are included below.
- Human and Dwarf are intentionally not modified by this import sheet.

Import **Shadow Resistance** from `.docs/import-codes/shared-race-traits.md`, then import the race-specific Traits below, then import the Race entry.


## Race-Specific Traits

### Touch of the Grave

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "f82db71a",
    entry = {
        automaticAuras = {  },
        category = "",
        conditions = {  },
        description = "",
        events = {
            {
                chance = 10,
                combatEventId = "on_melee_hit",
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 0,
                        damageSchoolRefs = {
                            "f82db71a:1ggt4t3v",
                        },
                        statScaling = {
                            {
                                coefficient = 0.5,
                                statRef = "f82db71a:ygjno50i",
                            },
                        },
                        type = "damage",
                    },
                },
                triggerTarget = "event_other",
            },
            {
                chance = 10,
                combatEventId = "on_auto_attack_hit",
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 0,
                        damageSchoolRefs = {
                            "f82db71a:1ggt4t3v",
                        },
                        statScaling = {
                            {
                                coefficient = 0.5,
                                statRef = "f82db71a:ygjno50i",
                            },
                        },
                        type = "damage",
                    },
                },
                triggerTarget = "event_other",
            },
        },
        icon = "interface/icons/spell_shadow_lifedrain02.blp",
        id = "udtouch1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Touch of the Grave",
        skillBonuses = {  },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

## Race

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "races",
    datasetId = "f82db71a",
    entry = {
        description = "",
        icon = "interface/icons/achievement_character_undead_male.blp",
        id = "undead01",
        name = "Undead",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 19,
                perLevelValue = 0,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 18,
                perLevelValue = 0,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 21,
                perLevelValue = 0,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 18,
                perLevelValue = 0,
                statRef = "f82db71a:75y3a8ib",
            },
            {
                initialValue = 25,
                perLevelValue = 0,
                statRef = "f82db71a:kec9rhli",
            },
        },
        traitRefs = {
            "f82db71a:racshd10",
            "f82db71a:udtouch1",
        },
    },
}
```
