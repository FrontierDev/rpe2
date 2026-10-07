# Pandaren Race Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import code for the Pandaren race in the Core dataset.

- Base attributes (STR / AGI / STA / INT / SPI): 20 / 18 / 21 / 19 / 22
- Race-specific trait import codes are included below.
- Active or unsupported racial mechanics are intentionally omitted or translated into supported non-combat skills.

Import the race-specific Traits below before importing the Race entry.


## Race-Specific Traits

### Gourmand

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
        icon = "interface/icons/ability_racial_pandaren_gourmand.blp",
        id = "pangrm15",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Gourmand",
        skillBonuses = {
            {
                skillRef = "f82db71a:l9sc8rji",
                value = 15,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Bouncy

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
        icon = "interface/icons/ability_racial_pandaren_bouncy.blp",
        id = "panboun5",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Bouncy",
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

### Inner Peace

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
        icon = "interface/icons/ability_racial_pandaren_innerpeace.blp",
        id = "paninr05",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Inner Peace",
        skillBonuses = {
            {
                skillRef = "f82db71a:axfdnyb4",
                value = 5,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Epicurean

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
        icon = "interface/icons/ability_racial_pandaren_epicurean.blp",
        id = "panepic5",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Epicurean",
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
        icon = "interface/icons/achievement_character_pandaren_male.blp",
        id = "pandaren",
        name = "Pandaren",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 20,
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
                initialValue = 19,
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
            "f82db71a:pangrm15",
            "f82db71a:panboun5",
            "f82db71a:paninr05",
            "f82db71a:panepic5",
        },
    },
}
```
