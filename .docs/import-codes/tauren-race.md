# Tauren Race Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import code for the Tauren race in the Core dataset.

The base attributes come from `.docs/RPE2_WoW_Classic_Base_Stats_Reference.md`.

- Base attributes (STR / AGI / STA / INT / SPI): 25 / 15 / 22 / 15 / 22
- Shared trait import codes: `.docs/import-codes/shared-race-traits.md`
- Race-specific trait import codes are included below.
- Human and Dwarf are intentionally not modified by this import sheet.

Import **Nature Resistance** from `.docs/import-codes/shared-race-traits.md`, then import the race-specific Traits below, then import the Race entry.


## Race-Specific Traits

### Endurance

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
        icon = "interface/icons/spell_nature_unyeildingstamina.blp",
        id = "taend005",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Endurance",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:ygjno50i",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

### Brawn

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
        icon = "interface/icons/petbattle_attack.blp",
        id = "tabrawn1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Brawn",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:wbj4zuf3",
                value = 1,
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
        icon = "interface/icons/achievement_character_tauren_male.blp",
        id = "tauren01",
        name = "Tauren",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 25,
                perLevelValue = 0,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 15,
                perLevelValue = 0,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 22,
                perLevelValue = 0,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 15,
                perLevelValue = 0,
                statRef = "f82db71a:75y3a8ib",
            },
            {
                initialValue = 22,
                perLevelValue = 0,
                statRef = "f82db71a:kec9rhli",
            },
        },
        traitRefs = {
            "f82db71a:taend005",
            "f82db71a:racnat10",
            "f82db71a:tabrawn1",
        },
    },
}
```
