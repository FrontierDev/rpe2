# Druid Trait Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for Druid class passives and class talents in dataset `6e4d2a91`.

## Authoring notes

- **Force of Nature** is a class passive. After importing it, add `6e4d2a91:drfornat` to the Druid class's `passiveTraitRefs`.
- **Cat Form**, **Bear Form**, **Moonkin Form**, and **Tree of Life Form** are class talents. Add their refs to the Druid class's `talentTraitRefs`.
- The four forms are mutually exclusive through `mutuallyExclusiveTraitRefs`, preventing their stat packages from stacking.
- Trait `description` fields are intentionally empty. The trait tooltip generator must derive the displayed description from `statBonuses`.
- Percentage-point stats such as Melee Crit. Chance, Spell Crit. Chance, Threat Generated, Healing Done, and Damage vs. Mechanical use `operation = "flat"`.
- Multiplicative increases to Melee Attack Power, Armor, Stamina, Spirit, Intellect, Strength, and Movement Speed use `operation = "percent"`.
- Percentage-point stats such as Dodge Chance, Damage Done, Resource Regeneration, Threat Generated, and Healing Done use `operation = "flat"`.
- Event-driven resource traits use the existing trait event/resource-effect schema; their descriptions also remain empty so the tooltip generator describes the trigger and resource gain.
- **Thick Hide** reuses the packaged Druid trait ID `drthick01` rather than creating a duplicate trait.

## Class Passive

### Force of Nature

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Class Passive",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/ability_druid_forceofnature.blp",
        id = "drfornat",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Force of Nature",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:k66l7jr4",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

## Feral

### Cat Form

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Feral",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/ability_druid_catform.blp",
        id = "drcatfrm",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {
            "6e4d2a91:drbearfm",
            "6e4d2a91:drmoonkn",
            "6e4d2a91:drtreelf",
        },
        name = "Cat Form",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:u7b49vs9",
                value = 10,
            },
            {
                operation = "flat",
                statRef = "f82db71a:jslmczbi",
                value = 3,
            },
        },
        unlockLevel = 1,
    },
}
```

### Bear Form

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Feral",
        conditions = {  },
        description = "",
        events = {
            {
                combatEventId = "on_auto_attack_hit",
                effects = {
                    {
                        amount = 10,
                        amountMode = "flat",
                        resourceRef = "f82db71a:e2tfklq7",
                        type = "resource",
                    },
                },
                triggerTarget = "aura_caster",
            },
            {
                combatEventId = "on_auto_attack_taken",
                effects = {
                    {
                        amount = 2,
                        amountMode = "flat",
                        resourceRef = "f82db71a:e2tfklq7",
                        type = "resource",
                    },
                },
                triggerTarget = "aura_caster",
            },
        },
        icon = "interface/icons/ability_racial_bearform.blp",
        id = "drbearfm",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {
            "6e4d2a91:drcatfrm",
            "6e4d2a91:drmoonkn",
            "6e4d2a91:drtreelf",
        },
        name = "Bear Form",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:u7b49vs9",
                value = 5,
            },
            {
                operation = "percent",
                statRef = "f82db71a:v42albuv",
                value = 180,
            },
            {
                operation = "percent",
                statRef = "f82db71a:ygjno50i",
                value = 20,
            },
            {
                operation = "flat",
                statRef = "f82db71a:j8n012e6",
                value = 80,
            },
        },
        unlockLevel = 1,
    },
}
```

## Balance

### Moonkin Form

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Balance",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/spell_nature_forceofnature.blp",
        id = "drmoonkn",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {
            "6e4d2a91:drcatfrm",
            "6e4d2a91:drbearfm",
            "6e4d2a91:drtreelf",
        },
        name = "Moonkin Form",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:v42albuv",
                value = 360,
            },
            {
                operation = "flat",
                statRef = "f82db71a:69hfqhne",
                value = 3,
            },
            {
                operation = "flat",
                statRef = "f82db71a:j8n012e6",
                value = -10,
            },
        },
        unlockLevel = 1,
    },
}
```

## Restoration

### Tree of Life Form

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Restoration",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/ability_druid_treeoflife.blp",
        id = "drtreelf",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {
            "6e4d2a91:drcatfrm",
            "6e4d2a91:drbearfm",
            "6e4d2a91:drmoonkn",
        },
        name = "Tree of Life Form",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:5pxmfw02",
                value = 10,
            },
            {
                operation = "flat",
                statRef = "f82db71a:j8n012e6",
                value = -10,
            },
            {
                operation = "percent",
                statRef = "f82db71a:kec9rhli",
                value = 25,
            },
            {
                operation = "percent",
                statRef = "f82db71a:v42albuv",
                value = 200,
            },
        },
        unlockLevel = 1,
    },
}
```


## Additional Feral Traits

### Thick Hide

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Feral",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/ability_druid_thickhide.blp",
        id = "drthick01",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Thick Hide",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:v42albuv",
                value = 10,
            },
        },
        unlockLevel = 1,
    },
}
```

### Blood Frenzy

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Feral",
        conditions = {  },
        description = "",
        events = {
            {
                combatEventId = "on_critical_hit",
                effects = {
                    {
                        amount = 1,
                        amountMode = "flat",
                        resourceRef = "f82db71a:1h7yfxff",
                        type = "resource",
                    },
                },
                triggerTarget = "aura_caster",
            },
        },
        icon = "interface/icons/ability_druid_ravage.blp",
        id = "drbldfrz",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Blood Frenzy",
        skillBonuses = {  },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Primal Fury

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Feral",
        conditions = {  },
        description = "",
        events = {
            {
                combatEventId = "on_critical_hit",
                effects = {
                    {
                        amount = 5,
                        amountMode = "flat",
                        resourceRef = "f82db71a:e2tfklq7",
                        type = "resource",
                    },
                },
                triggerTarget = "aura_caster",
            },
        },
        icon = "interface/icons/ability_racial_cannibalize.blp",
        id = "drprmfur",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Primal Fury",
        skillBonuses = {  },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Feline Swiftness

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Feral",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/spell_nature_spiritwolf.blp",
        id = "drfelswf",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Feline Swiftness",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:s1mt6jh9",
                value = 30,
            },
            {
                operation = "flat",
                statRef = "f82db71a:o6113cir",
                value = 4,
            },
        },
        unlockLevel = 1,
    },
}
```

### Heart of the Wild

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Feral",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/spell_holy_blessingofagility.blp",
        id = "drhrtwld",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Heart of the Wild",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:ygjno50i",
                value = 3,
            },
            {
                operation = "percent",
                statRef = "f82db71a:75y3a8ib",
                value = 3,
            },
            {
                operation = "percent",
                statRef = "f82db71a:zfqm8dxp",
                value = 3,
            },
        },
        unlockLevel = 1,
    },
}
```

## Additional Balance Traits

### Natural Weapons

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Balance",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/inv_staff_01.blp",
        id = "drnatwpn",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Natural Weapons",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:gj9wxb0x",
                value = 10,
            },
        },
        unlockLevel = 1,
    },
}
```

## Additional Restoration Traits

### Reflection

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Restoration",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/spell_frost_windwalkon.blp",
        id = "drreflct",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Reflection",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:rgnrtg01",
                value = 15,
            },
        },
        unlockLevel = 1,
    },
}
```

### Subtlety

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Restoration",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/ability_eyeoftheowl.blp",
        id = "drsubtly",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Subtlety",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:j8n012e6",
                value = -20,
            },
        },
        unlockLevel = 1,
    },
}
```

### Gift of Nature

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "6e4d2a91",
    entry = {
        automaticAuras = {  },
        category = "Restoration",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/spell_nature_protectionformnature.blp",
        id = "drgifnat",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Gift of Nature",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:5pxmfw02",
                value = 10,
            },
        },
        unlockLevel = 1,
    },
}
```
