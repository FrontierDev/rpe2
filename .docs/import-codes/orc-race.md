# Orc Race Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import code for the Orc race in the Core dataset.

The base attributes come from `.docs/RPE2_WoW_Classic_Base_Stats_Reference.md`.

- Base attributes (STR / AGI / STA / INT / SPI): 23 / 17 / 22 / 17 / 23
- Race-specific trait import codes are included below.
- Human and Dwarf are intentionally not modified by this import sheet.

Import the race-specific Traits below before importing the Race entry.


## Race-Specific Traits

### Axe Specialisation

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
        icon = "interface/icons/inv_axe_04.blp",
        id = "racaxe05",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Axe Specialisation",
        skillBonuses = {
            {
                skillRef = "f82db71a:jeeso2wd",
                value = 5,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Hardiness

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
        icon = "interface/icons/ability_warrior_criticalblock.blp",
        id = "orchrd10",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Hardiness",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:0wyp78x9",
                value = 10,
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
        icon = "interface/icons/achievement_character_orc_male.blp",
        id = "orc00001",
        name = "Orc",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 23,
                perLevelValue = 0,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 17,
                perLevelValue = 0,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 22,
                perLevelValue = 0,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 17,
                perLevelValue = 0,
                statRef = "f82db71a:75y3a8ib",
            },
            {
                initialValue = 23,
                perLevelValue = 0,
                statRef = "f82db71a:kec9rhli",
            },
        },
        traitRefs = {
            "f82db71a:racaxe05",
            "f82db71a:orchrd10",
        },
    },
}
```
