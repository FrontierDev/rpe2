# Night Elf Race Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import code for the Night Elf race in the Core dataset.

The base attributes come from `.docs/RPE2_WoW_Classic_Base_Stats_Reference.md`.

- Base attributes (STR / AGI / STA / INT / SPI): 17 / 25 / 19 / 20 / 20
- Shared trait import codes: `.docs/import-codes/shared-race-traits.md`
- Race-specific trait import codes are included below.
- Human and Dwarf are intentionally not modified by this import sheet.

Import **Nature Resistance** from `.docs/import-codes/shared-race-traits.md`, then import the race-specific Traits below, then import the Race entry.


## Race-Specific Traits

### Quickness

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
        icon = "interface/icons/spell_shadow_shadowward.blp",
        id = "nequick1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Quickness",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:o6113cir",
                value = 1,
            },
        },
        unlockLevel = 1,
    },
}
```

### Elusiveness

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
        icon = "interface/icons/ability_stealth.blp",
        id = "neelus05",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Elusiveness",
        skillBonuses = {
            {
                skillRef = "f82db71a:muuwon1r",
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
        icon = "interface/icons/achievement_character_nightelf_male.blp",
        id = "nightelf",
        name = "Night Elf",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 17,
                perLevelValue = 0,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 25,
                perLevelValue = 0,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 19,
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
            "f82db71a:nequick1",
            "f82db71a:racnat10",
            "f82db71a:neelus05",
        },
    },
}
```
