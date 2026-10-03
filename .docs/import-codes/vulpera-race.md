# Vulpera Race Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import code for the Vulpera race in the Core dataset.

- Base attributes (STR / AGI / STA / INT / SPI): 17 / 22 / 20 / 23 / 18
- Race-specific trait import codes are included below.
- RPE deliberately uses the Goblin base-stat chassis as the closest existing small Horde-race baseline; this is an RPE balance mapping, not a historical WoW racial stat table.

Import the race-specific Traits below before importing the Race entry.


## Race-Specific Traits

### Fire Resistance

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
        icon = "interface/icons/spell_fire_sealoffire.blp",
        id = "vulfire15",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Fire Resistance",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:0w7c7p09",
                value = 15,
            },
        },
        unlockLevel = 1,
    },
}
```

### Nose for Trouble

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
        id = "vulnose1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Nose for Trouble",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:pu05li08",
                value = 1,
            },
        },
        unlockLevel = 1,
    },
}
```

### Make Camp

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
        icon = "interface/icons/inv_10_dungeonjewelry_explorer_trinket_1compass_color4.blp",
        id = "vulcamp5",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Make Camp",
        skillBonuses = {
            {
                skillRef = "f82db71a:0ybj39g9",
                value = 5,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Bag of Tricks

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
        id = "vultrik5",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Bag of Tricks",
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
        icon = "interface/icons/achievement_alliedrace_vulpera.blp",
        id = "vulpera1",
        name = "Vulpera",
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
            "f82db71a:vulfire15",
            "f82db71a:vulnose1",
            "f82db71a:vulcamp5",
            "f82db71a:vultrik5",
        },
    },
}
```
