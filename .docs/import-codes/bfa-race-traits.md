# Allied Race Trait Import Codes (Legion / Battle for Azeroth)

Standalone `RPE_DATASET_ENTRY_V1` import codes for Dark Iron Dwarf, Mechagnome, Nightborne, and Vulpera racial passives in the Core dataset.

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


## Nightborne conversions

- **Ancient History**: +15 Inscription, following the RPE crafting-skill convention.
- **Magical Affinity**: +1 Damage Done. RPE does not currently expose a magic-only percentage damage stat, so the 1% magical damage bonus is generalized to Damage Done.
- **Arcane Resistance**: +15 Arcane Resistance, following the single-school racial resistance convention.
- **Cantrips**: +5 Arcana. The original racial is an active magical utility ability; RPE converts that utility identity into a non-combat skill bonus.
- **Arcane Pulse** is not authored because it is an active combat ability.

## Vulpera conversions

- **Fire Resistance**: +15 Fire Resistance, following the single-school racial resistance convention.
- **Nose for Trouble**: +1 Damage Reduction. The original effect reduces the first damaging hit from an enemy; RPE generalizes this into a small persistent defensive bonus rather than adding first-hit-per-enemy state.
- **Make Camp**: +5 Survival.
- **Bag of Tricks**: +5 Sleight of Hand. This translates the racial's improvised bag-of-tricks identity into an existing non-combat skill.
- **Alpaca Saddlebags** is not authored because Core has no inventory-capacity stat.
- **Rummage Your Bag** and **Return to Camp** are active utility abilities and are not authored separately.

Import these additional Race entries after their Traits:

- `.docs/import-codes/nightborne-race.md`
- `.docs/import-codes/vulpera-race.md`

## Nightborne

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

### Arcane Resistance

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
        id = "nbarc15",
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

## Vulpera

### Fire Resistance

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
        id = "vulfire15",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Fire Resistance",
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

### Nose for Trouble

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
        id = "vulnose1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Nose for Trouble",
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

### Make Camp

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
        icon = "interface/icons/inv_10_dungeonjewelry_explorer_trinket_1compass_color4.blp",
        id = "vulcamp5",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Make Camp",
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

### Bag of Tricks

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
        id = "vultrik5",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Bag of Tricks",
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
