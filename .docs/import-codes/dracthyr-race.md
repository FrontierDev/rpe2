# Dracthyr Race Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import code for the Dracthyr race in the Core dataset.

- Base attributes (STR / AGI / STA / INT / SPI): 20 / 20 / 20 / 20 / 20
- Race-specific trait import codes are included below.
- RPE deliberately uses the balanced Human base-stat chassis for Dracthyr. Modern WoW does not provide a comparable pre-6.0 five-stat racial table for Dracthyr, so this is an explicit RPE balance mapping rather than a historical racial stat record.

Import the race-specific Traits below before importing the Race entry.


## Race-Specific Traits

### Awakened

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
        icon = "interface/icons/inv_enchant_essencemagiclarge.blp",
        id = "drctawak",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Awakened",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:gj9wxb0x",
                value = 1,
            },
            {
                operation = "flat",
                statRef = "f82db71a:5pxmfw02",
                value = 1,
            },
        },
        unlockLevel = 1,
    },
}
```

### Discerning Eye

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
        icon = "interface/icons/inv_professions_inscription_scribesmagnifyingglass_gold.blp",
        id = "drcteye5",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Discerning Eye",
        skillBonuses = {
            {
                skillRef = "f82db71a:b0sh5zo7",
                value = 5,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Glide

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
        icon = "interface/icons/ability_heroicleap.blp",
        id = "drctglid",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Glide",
        skillBonuses = {
            {
                skillRef = "f82db71a:65v0ycbw",
                value = 5,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Visage

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
        icon = "interface/icons/inv_mask_01.blp",
        id = "drctvis5",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Visage",
        skillBonuses = {
            {
                skillRef = "f82db71a:8188fykv",
                value = 5,
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
        icon = "interface/icons/achievement_character_dracthyr_male.blp",
        id = "dracthyr",
        name = "Dracthyr",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 20,
                perLevelValue = 0,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 20,
                perLevelValue = 0,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 20,
                perLevelValue = 0,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 20,
                perLevelValue = 0,
                statRef = "f82db71a:75y3a8ib",
            },
            {
                initialValue = 20,
                perLevelValue = 0,
                statRef = "f82db71a:kec9rhli",
            },
        },
        traitRefs = {
            "f82db71a:drctawak",
            "f82db71a:drcteye5",
            "f82db71a:drctglid",
            "f82db71a:drctvis5",
        },
    },
}
```
