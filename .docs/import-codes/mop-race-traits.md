# Mists of Pandaria Race Trait Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for Pandaren racial passives in the Core dataset.

## Authoring rules applied

- Aim for four meaningful racial passives where RPE can represent the racial identity without adding unsupported runtime systems.
- All crafting skill bonuses use +15.
- All non-combat skill bonuses use +5.
- Racial resistance bonuses, where used, are standardized at +15 for one school or +8/+8 when split across two schools.
- Active racial abilities are omitted.
- Pandaren **Gourmand** grants +15 Cooking.
- Pandaren **Bouncy** is represented as +5 Acrobatics.
- Pandaren **Inner Peace** is represented as +5 Insight.
- Pandaren **Epicurean** is represented as +5 Survival.
- These three non-combat skill adaptations preserve the themes of reduced falling harm, inner balance, and food/outdoor expertise without introducing unsupported fall-damage, rested-XP, or Well Fed multiplier systems.
- **Quaking Palm** is active and therefore is not included.

Import these Traits before importing `.docs/import-codes/pandaren-race.md`.

## Pandaren

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
