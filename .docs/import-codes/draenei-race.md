# Draenei Race Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import code for the Draenei race in the Core dataset.

- Base attributes (STR / AGI / STA / INT / SPI): 21 / 17 / 19 / 21 / 22
- Shared trait import codes: `.docs/import-codes/shared-race-traits.md`
- Race-specific trait and supporting Aura import codes are included below.
- Active racial abilities are intentionally omitted.

Import **Shadow Resistance** from `.docs/import-codes/shared-race-traits.md`, then import the supporting entries and race-specific Traits below, then import the Race entry.


## Supporting Auras

### Heroic Presence

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "f82db71a",
    entry = {
        description = "",
        duration = 9999,
        effects = {
            {
                baseAmount = 1,
                operation = "flat",
                statRef = "f82db71a:wbj4zuf3",
                statScaling = {  },
                type = "stat",
            },
            {
                baseAmount = 1,
                operation = "flat",
                statRef = "f82db71a:dd88li4c",
                statScaling = {  },
                type = "stat",
            },
            {
                baseAmount = 1,
                operation = "flat",
                statRef = "f82db71a:v2g0tw0o",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/spell_holy_fanaticism.blp",
        id = "drheroa1",
        maxStacks = 1,
        name = "Heroic Presence",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = false,
    },
}
```

## Race-Specific Traits

### Heroic Presence

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "f82db71a",
    entry = {
        automaticAuras = {
            {
                auraRef = "f82db71a:drheroa1",
                powerLevel = 0,
                stacks = 1,
                targetScope = "all_allies",
                turns = 9999,
            },
        },
        category = "",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/spell_holy_fanaticism.blp",
        id = "drhero01",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Heroic Presence",
        skillBonuses = {  },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Gemcutting

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
        icon = "interface/icons/inv_10_specialization_professionbook_jewelcrafting_color1.blp",
        id = "drgem005",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Gemcutting",
        skillBonuses = {
            {
                skillRef = "f82db71a:fxp3vo4o",
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
        icon = "interface/icons/achievement_character_draenei_male.blp",
        id = "draenei1",
        name = "Draenei",
        resourceProgressions = {  },
        skillBonuses = {  },
        statProgressions = {
            {
                initialValue = 21,
                perLevelValue = 0,
                statRef = "f82db71a:zfqm8dxp",
            },
            {
                initialValue = 17,
                perLevelValue = 0,
                statRef = "f82db71a:xqz0daz2",
            },
            {
                initialValue = 19,
                perLevelValue = 0,
                statRef = "f82db71a:ygjno50i",
            },
            {
                initialValue = 21,
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
            "f82db71a:drhero01",
            "f82db71a:drgem005",
            "f82db71a:racshd10",
        },
    },
}
```
