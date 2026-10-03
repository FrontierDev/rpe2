# Mechagnome Race Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import code for the Mechagnome race in the Core dataset.

- Base attributes (STR / AGI / STA / INT / SPI): 15 / 23 / 19 / 23 / 20
- Race-specific trait import codes are included below.
- RPE deliberately uses the Gnome base-stat chassis for this allied-race variant.

Import the race-specific Traits below before importing the Race entry.


## Race-Specific Traits

### Combat Analysis

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
        icon = "interface/icons/ability_dualwieldspecialization.blp",
        id = "mgcombat",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Combat Analysis",
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

### Mastercraft

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
        icon = "interface/icons/inv_10_specialization_professionbook_engineering_color1.blp",
        id = "mgmast15",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Mastercraft",
        skillBonuses = {
            {
                skillRef = "f82db71a:xprqs3y1",
                value = 15,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Emergency Failsafe

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
        icon = "interface/icons/ability_dualwieldspecialization.blp",
        id = "mgfails5",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Emergency Failsafe",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:ok80ohz3",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

### Skeleton Pinkie

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
        icon = "interface/icons/inv_misc_bag_11.blp",
        id = "mgpinkie",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Skeleton Pinkie",
        skillBonuses = {
            {
                skillRef = "f82db71a:gwgzj5kg",
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
        icon = "interface/icons/achievement_alliedrace_mechagnome.blp",
        id = "mechagnm",
        name = "Mechagnome",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 15,
                perLevelValue = 0,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 23,
                perLevelValue = 0,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 19,
                perLevelValue = 0,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 23,
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
            "f82db71a:mgcombat",
            "f82db71a:mgmast15",
            "f82db71a:mgfails5",
            "f82db71a:mgpinkie",
        },
    },
}
```
