# Shared Race Trait Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for racial traits shared by more than one race in the Core dataset.

Only traits used by multiple races belong in this document. Race-specific traits belong in the corresponding `*-race.md` document.

## Authoring conventions

- All crafting skill bonuses use +15.
- All non-combat skill bonuses use +5.
- Racial resistance bonuses use +15 for one school or +8/+8 when split across two schools.
- Percentage-point combat stats use flat bonuses.

## Nature Resistance

Used by: Night Elf, Tauren.

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
        icon = "interface/icons/spell_nature_abolishmagic.blp",
        id = "racnat10",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Nature Resistance",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:pg0ytacb",
                value = 15,
            },
        },
        unlockLevel = 1,
    },
}
```

## Arcane Resistance

Used by: Gnome, Nightborne.

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
        icon = "interface/icons/spell_arcane_blast.blp",
        id = "racarc10",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Arcane Resistance",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:954yunb9",
                value = 15,
            },
        },
        unlockLevel = 1,
    },
}
```

## Shadow Resistance

Used by: Undead, Draenei.

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
        icon = "interface/icons/spell_shadow_antishadow.blp",
        id = "racshd10",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Shadow Resistance",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:itpo751d",
                value = 15,
            },
        },
        unlockLevel = 1,
    },
}
```

