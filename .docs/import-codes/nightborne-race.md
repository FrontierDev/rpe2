# Nightborne Race Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import code for the Nightborne race in the Core dataset.

- Base attributes (STR / AGI / STA / INT / SPI): 17 / 25 / 19 / 20 / 20
- Shared trait import codes: `.docs/import-codes/shared-race-traits.md`
- Race-specific trait import codes are included below.
- RPE deliberately uses the Night Elf base-stat chassis because the Nightborne are a direct kaldorei offshoot.

Import **Arcane Resistance** from `.docs/import-codes/shared-race-traits.md`, then import the race-specific Traits below, then import the Race entry.


## Race-Specific Traits

### Ancient History

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
        icon = "interface/icons/inv_10_specialization_professionbook_inscription_color1.blp",
        id = "nbanc15",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Ancient History",
        skillBonuses = {
            {
                skillRef = "f82db71a:8gf2axb6",
                value = 15,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Magical Affinity

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
        icon = "interface/icons/spell_arcane_arcane04.blp",
        id = "nbmagic1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Magical Affinity",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:gj9wxb0x",
                value = 1,
            },
        },
        unlockLevel = 1,
    },
}
```

### Cantrips

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
        icon = "interface/icons/spell_arcane_arcane02.blp",
        id = "nbcantr5",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Cantrips",
        skillBonuses = {
            {
                skillRef = "f82db71a:m6jng4hl",
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
        icon = "interface/icons/achievement_alliedrace_nightborne.blp",
        id = "nightbrn",
        name = "Nightborne",
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
            "f82db71a:nbanc15",
            "f82db71a:nbmagic1",
            "f82db71a:racarc10",
            "f82db71a:nbcantr5",
        },
    },
}
```
