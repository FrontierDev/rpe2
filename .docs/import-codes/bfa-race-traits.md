# Battle for Azeroth Race Trait Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for Dark Iron Dwarf and Mechagnome racial passives in the Core dataset.

## Authoring rules applied

- Aim for four meaningful racial passives where RPE can represent the racial identity without adding unsupported runtime systems.
- All crafting skill bonuses use +15.
- All non-combat skill bonuses use +5.
- Racial resistance bonuses are standardized at +15 for one school or +8/+8 when split across two schools.
- Percentage-point combat stats use flat bonuses.
- Active racial abilities may be converted into a passive only when the conversion preserves the race's identity and uses an existing RPE mechanic.

### Dark Iron Dwarf conversions

- **Dungeon Delver**: +5 Investigation.
- **Forged in Flames**: +1 Damage Reduction. RPE does not currently have a physical-only damage-reduction stat, so the 1% physical reduction is generalized.
- **Mass Production**: +15 Blacksmithing.
- **Fireblood**: represented as +15 Fire Resistance. This is an RPE passive adaptation of the active racial, chosen to preserve the Dark Iron fire-resistance identity while maintaining the four-passive target.
- **Mole Machine** is not authored because it is a travel utility with no meaningful RPE combat/non-combat stat analogue.

### Mechagnome conversions

- **Combat Analysis**: +1 Damage Done and +1 Healing Done. This represents the racial's role-dependent primary-stat increase without needing class-specific primary-stat resolution or stacking-in-combat runtime state.
- **Mastercraft**: +15 Engineering.
- **Emergency Failsafe**: +5 Healing Received. This represents the self-repair theme without introducing a health-threshold trigger plus internal cooldown.
- **Skeleton Pinkie**: +5 Sleight of Hand.
- **Hyper Organic Light Originator** is active and is not authored.

Import these Traits before the corresponding Race entries:

- `.docs/import-codes/dark-iron-dwarf-race.md`
- `.docs/import-codes/mechagnome-race.md`

## Dark Iron Dwarf

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

## Mechagnome

### Combat Analysis

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
        id = "mgcombat",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Combat Analysis",
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

### Mastercraft

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
        id = "mgmast15",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Mastercraft",
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

### Emergency Failsafe

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
        id = "mgfails5",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Emergency Failsafe",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:ok80ohz3",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

### Skeleton Pinkie

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
        icon = "interface/icons/inv_misc_bag_11.blp",
        id = "mgpinkie",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Skeleton Pinkie",
        skillBonuses = {
            {
                skillRef = "f82db71a:gwgzj5kg",
                value = 5,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```
