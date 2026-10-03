# Goblin Race Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import code for the Goblin race in the Core dataset.

- Base attributes (STR / AGI / STA / INT / SPI): 17 / 22 / 20 / 23 / 18
- Race-specific trait import codes are included below.
- Active or unsupported racial mechanics are intentionally omitted.

Import the race-specific Traits below before importing the Race entry.


## Race-Specific Traits

### Better Living Through Chemistry

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
        events = {  },
        icon = "interface/icons/trade_alchemy.blp",
        id = "gobalch15",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Better Living Through Chemistry",
        skillBonuses = {
            {
                skillRef = "f82db71a:pdyzyudy",
                value = 15,
            },
        },
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
        icon = "interface/icons/achievement_character_goblin_male.blp",
        id = "goblin01",
        name = "Goblin",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 17,
                perLevelValue = 0,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 22,
                perLevelValue = 0,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 20,
                perLevelValue = 0,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 23,
                perLevelValue = 0,
                statRef = "f82db71a:75y3a8ib",
            },
            {
                initialValue = 18,
                perLevelValue = 0,
                statRef = "f82db71a:kec9rhli",
            },
        },
        traitRefs = {
            "f82db71a:gobalch15",
        },
    },
}
```
