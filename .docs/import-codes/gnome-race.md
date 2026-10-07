# Gnome Race Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import code for the Gnome race in the Core dataset.

The base attributes come from `.docs/RPE2_WoW_Classic_Base_Stats_Reference.md`.

- Base attributes (STR / AGI / STA / INT / SPI): 15 / 23 / 19 / 23 / 20
- Shared trait import codes: `.docs/import-codes/shared-race-traits.md`
- Race-specific trait import codes are included below.
- Human and Dwarf are intentionally not modified by this import sheet.

Import **Arcane Resistance** from `.docs/import-codes/shared-race-traits.md`, then import the race-specific Traits below, then import the Race entry.


## Race-Specific Traits

### Expansive Mind

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
        icon = "interface/icons/spell_holy_arcaneintellect.blp",
        id = "gnexp005",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Expansive Mind",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:75y3a8ib",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

### Engineering Specialisation

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
        id = "gneng015",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Engineering Specialisation",
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
        icon = "interface/icons/achievement_character_gnome_male.blp",
        id = "gnome001",
        name = "Gnome",
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
            "f82db71a:gnexp005",
            "f82db71a:racarc10",
            "f82db71a:gneng015",
        },
    },
}
```
