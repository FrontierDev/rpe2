# Troll Race Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import code for the Troll race in the Core dataset.

The base attributes come from `.docs/RPE2_WoW_Classic_Base_Stats_Reference.md`.

- Base attributes (STR / AGI / STA / INT / SPI): 21 / 22 / 21 / 16 / 21
- Race-specific trait import codes are included below.
- Human and Dwarf are intentionally not modified by this import sheet.

Import the race-specific Traits below before importing the Race entry.


## Race-Specific Traits

### Beast Slaying

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
        icon = "interface/icons/spell_nature_focusedmind.blp",
        id = "trbeast5",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Beast Slaying",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:vgzlnifw",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

### Bow Specialisation

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
        icon = "interface/icons/inv_weapon_bow_02.blp",
        id = "racbow05",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Bow Specialisation",
        skillBonuses = {
            {
                skillRef = "f82db71a:jn4qbjhu",
                value = 5,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Throwing Specialisation

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
        icon = "interface/icons/inv_throwingknife_02.blp",
        id = "racthr05",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Throwing Specialisation",
        skillBonuses = {
            {
                skillRef = "f82db71a:2s4jy7yc",
                value = 5,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Regeneration

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
        icon = "interface/icons/spell_shadow_burningspirit.blp",
        id = "trregen5",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Regeneration",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:kec9rhli",
                value = 5,
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
        icon = "interface/icons/achievement_character_troll_male.blp",
        id = "troll001",
        name = "Troll",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 21,
                perLevelValue = 0,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 22,
                perLevelValue = 0,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 21,
                perLevelValue = 0,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 16,
                perLevelValue = 0,
                statRef = "f82db71a:75y3a8ib",
            },
            {
                initialValue = 21,
                perLevelValue = 0,
                statRef = "f82db71a:kec9rhli",
            },
        },
        traitRefs = {
            "f82db71a:trbeast5",
            "f82db71a:racbow05",
            "f82db71a:racthr05",
            "f82db71a:trregen5",
        },
    },
}
```
