# Worgen Race Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import code for the Worgen race in the Core dataset.

- Base attributes (STR / AGI / STA / INT / SPI): 23 / 22 / 20 / 16 / 19
- Race-specific trait import codes are included below.
- Active or unsupported racial mechanics are intentionally omitted.

Import the race-specific Traits below before importing the Race entry.


## Race-Specific Traits

### Viciousness

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
        icon = "interface/icons/ability_worgen_viciousness.blp",
        id = "worgcrit",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Viciousness",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:jslmczbi",
                value = 1,
            },
            {
                operation = "flat",
                statRef = "f82db71a:fercjhm5",
                value = 1,
            },
            {
                operation = "flat",
                statRef = "f82db71a:69hfqhne",
                value = 1,
            },
        },
        unlockLevel = 1,
    },
}
```

### Aberration

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
        icon = "interface/icons/ability_racial_cannibalize.blp",
        id = "worgaber",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Aberration",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:pg0ytacb",
                value = 8,
            },
            {
                operation = "flat",
                statRef = "f82db71a:itpo751d",
                value = 8,
            },
        },
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
        icon = "interface/icons/achievement_character_worgen_male.blp",
        id = "worgen01",
        name = "Worgen",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 23,
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
                initialValue = 16,
                perLevelValue = 0,
                statRef = "f82db71a:75y3a8ib",
            },
            {
                initialValue = 19,
                perLevelValue = 0,
                statRef = "f82db71a:kec9rhli",
            },
        },
        traitRefs = {
            "f82db71a:worgcrit",
            "f82db71a:worgaber",
        },
    },
}
```
