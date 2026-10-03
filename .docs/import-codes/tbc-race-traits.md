# TBC Race Trait Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for the two races introduced in The Burning Crusade: Draenei and Blood Elf.

These entries follow the same Core-race authoring approach as `.docs/import-codes/classic-race-traits.md`.

## Authoring rules applied

- Only passive racials that map cleanly onto mechanics supported by RPE are included.
- All crafting skill bonuses use +15; all non-combat skill bonuses use +5.
- Racial resistance bonuses are standardized at +15 for one school or +8/+8 when split across two schools.
- Active racial abilities are omitted.
- Draenei's original TBC Heroic Presence / Inspiring Presence class split is represented as one RPE **Heroic Presence** aura granting +1 Melee, Ranged, and Spell Hit Chance to all allies. This avoids introducing Core-to-class-dataset dependencies and preserves the intended party-wide hit benefit.
- The Heroic Presence aura has `maxStacks = 1`, so multiple Draenei do not stack the same racial aura.
- Draenei Gemcutting grants +15 Jewelcrafting.
- Draenei Shadow Resistance grants +15 Shadow Resistance.
- Blood Elf Arcane Affinity grants +15 Enchanting.
- Blood Elf Magic Resistance grants +1 Magic Resistance.

Import the supporting Aura first, then the racial Traits, then the Race entries:

- `.docs/import-codes/draenei-race.md`
- `.docs/import-codes/blood-elf-race.md`

## Supporting Aura

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

## Draenei

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

### Shadow Resistance

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
        id = "drshd010",
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

## Blood Elf

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
