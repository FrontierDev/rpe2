# Dark Iron Dwarf Race Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import code for the Dark Iron Dwarf race in the Core dataset.

- Base attributes (STR / AGI / STA / INT / SPI): 22 / 16 / 23 / 19 / 19
- Race-specific trait import codes are included below.
- RPE deliberately uses the Dwarf base-stat chassis for this allied-race variant.

Import the race-specific Traits below before importing the Race entry.


## Race-Specific Traits

### Dungeon Delver

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
        id = "didung05",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Dungeon Delver",
        skillBonuses = {
            {
                skillRef = "f82db71a:2eaj9uvp",
                value = 5,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Forged in Flames

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
        id = "diforge1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Forged in Flames",
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

### Mass Production

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
        icon = "interface/icons/inv_10_specialization_professionbook_blacksmithing_orig.blp",
        id = "dimass15",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Mass Production",
        skillBonuses = {
            {
                skillRef = "f82db71a:6hydytdf",
                value = 15,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Fireblood

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
        id = "difire15",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Fireblood",
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
        icon = "interface/icons/achievement_alliedrace_darkirondwarf.blp",
        id = "darkiron",
        name = "Dark Iron Dwarf",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 22,
                perLevelValue = 0,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 16,
                perLevelValue = 0,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 23,
                perLevelValue = 0,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 19,
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
            "f82db71a:didung05",
            "f82db71a:diforge1",
            "f82db71a:dimass15",
            "f82db71a:difire15",
        },
    },
}
```
