# Dragonflight Race Trait Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for Dracthyr racial passives in the Core dataset.

## Authoring rules applied

- Aim for four meaningful racial passives where RPE can preserve the racial identity without introducing unsupported runtime systems.
- All crafting skill bonuses use +15.
- All non-combat skill bonuses use +5.
- Racial resistance bonuses, where used, are standardized at +15 for one school or +8/+8 when split across two schools.
- Percentage-point combat stats use flat bonuses.
- Active or utility racial abilities may be converted into passive RPE traits when the conversion has a clear thematic analogue.

### Dracthyr conversions

- **Awakened**: +1 Damage Done and +1 Healing Done. The retail racial grants Mastery, but Core does not currently expose a Mastery stat; this is the closest broad RPE analogue without adding class- or specialization-specific logic.
- **Discerning Eye**: +5 Perception.
- **Glide**: +5 Acrobatics. This converts the aerial-control utility into an existing non-combat skill.
- **Visage**: +5 Deception. This converts the ability to assume a humanoid visage into an existing social/non-combat skill.
- **Soar**, **Wing Buffet**, and **Chosen Identity** are not authored separately because they are active travel/combat/form-management abilities.

Import these Traits before importing `.docs/import-codes/dracthyr-race.md`.

## Dracthyr

### Awakened

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
        icon = "interface/icons/inv_enchant_essencemagiclarge.blp",
        id = "drctawak",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Awakened",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:gj9wxb0x",
                value = 1,
            },
            {
                operation = "flat",
                statRef = "f82db71a:5pxmfw02",
                value = 1,
            },
        },
        unlockLevel = 1,
    },
}
```

### Discerning Eye

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
        id = "drcteye5",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Discerning Eye",
        skillBonuses = {
            {
                skillRef = "f82db71a:b0sh5zo7",
                value = 5,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Glide

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
        icon = "interface/icons/ability_heroicleap.blp",
        id = "drctglid",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Glide",
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

### Visage

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
        icon = "interface/icons/inv_mask_01.blp",
        id = "drctvis5",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Visage",
        skillBonuses = {
            {
                skillRef = "f82db71a:8188fykv",
                value = 5,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```
