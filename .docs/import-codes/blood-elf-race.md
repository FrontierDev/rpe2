# Blood Elf Race Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import code for the Blood Elf race in the Core dataset.

- Base attributes (STR / AGI / STA / INT / SPI): 17 / 22 / 18 / 24 / 19
- Race-specific trait import codes are included below.
- Active racial abilities are intentionally omitted.

Import the race-specific Traits below before importing the Race entry.

## Race-Specific Traits

### Arcane Affinity

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
        icon = "interface/icons/inv_10_specialization_professionbook_enchanting_color1.blp",
        id = "bearc010",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Arcane Affinity",
        skillBonuses = {
            {
                skillRef = "f82db71a:4keh3nf1",
                value = 15,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Magic Resistance

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
        id = "bemagic5",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Magic Resistance",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:zs1nbz13",
                value = 1,
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
        icon = "interface/icons/achievement_character_bloodelf_male.blp",
        id = "bloodelf",
        name = "Blood Elf",
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
                initialValue = 18,
                perLevelValue = 0,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 24,
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
            "f82db71a:bearc010",
            "f82db71a:bemagic5",
        },
    },
}
```
