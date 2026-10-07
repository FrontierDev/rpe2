# Shaman Trait Import Codes

Dataset: `c4a91e7d` (Shaman)

Import the supporting **Aura** entries before the triggered **Trait** entries that reference them. All 14 requested traits are talent traits and should be added to the Shaman class's `talentTraitRefs` after import.

Authoring conventions:

- Percentage-point stats (crit chance, hit chance, block chance, dodge chance, Healing Done, Threat Generated) use flat bonuses.
- Multiplicative primary/derived stat increases (Intellect, Armor, Melee Attack Power) use `operation = "percent"`.
- Elemental Warding gives flat +30 Fire, Frost, and Nature Resistance.
- Elemental Devastation and Flurry trigger on `on_critical_hit` and buff the Shaman.
- Ancestral Healing copies the established Priest Inspiration trigger shape: `on_critical_heal`, buffing the healed target for 3 turns.
- Weapon Mastery gives +6 to the existing Axes, Maces, and Fist Weapons skills.

## Elemental

### Elemental Warding

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "c4a91e7d",
    entry = {
        automaticAuras = {  },
        category = "Elemental",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/spell_nature_spiritarmor.blp",
        id = "shelward",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Elemental Warding",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:0w7c7p09",
                value = 30,
            },
            {
                operation = "flat",
                statRef = "f82db71a:jjn0my8k",
                value = 30,
            },
            {
                operation = "flat",
                statRef = "f82db71a:pg0ytacb",
                value = 30,
            },
        },
        unlockLevel = 1,
    },
}
```

### Elemental Devastation

#### Proc Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                baseAmount = 5,
                operation = "flat",
                statRef = "f82db71a:69hfqhne",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/spell_fire_elementaldevastation.blp",
        id = "sheldvau",
        maxStacks = 1,
        name = "Elemental Devastation",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Spell Crit. Chance by 5%.",
            bodyTokens = {  },
            stackingText = "",
            stackingTokens = {  },
            version = 1,
        },
    },
}
```

#### Trait

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "c4a91e7d",
    entry = {
        automaticAuras = {  },
        category = "Elemental",
        conditions = {  },
        description = "",
        events = {
            {
                chance = 100,
                combatEventId = "on_critical_hit",
                effects = {
                    {
                        auraRef = "c4a91e7d:sheldvau",
                        basePower = 0,
                        duration = 1,
                        stacks = 1,
                        type = "apply_aura",
                    },
                },
                triggerTarget = "aura_caster",
            },
        },
        icon = "interface/icons/spell_fire_elementaldevastation.blp",
        id = "sheldevt",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Elemental Devastation",
        skillBonuses = {  },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

## Enhancement

### Ancestral Knowledge

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "c4a91e7d",
    entry = {
        automaticAuras = {  },
        category = "Enhancement",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/spell_shadow_grimward.blp",
        id = "shancnow",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Ancestral Knowledge",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:75y3a8ib",
                value = 10,
            },
        },
        unlockLevel = 1,
    },
}
```

### Thundering Strikes

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "c4a91e7d",
    entry = {
        automaticAuras = {  },
        category = "Enhancement",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/ability_thunderbolt.blp",
        id = "shthstrk",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Thundering Strikes",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:jslmczbi",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

### Shield Specialisation

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "c4a91e7d",
    entry = {
        automaticAuras = {  },
        category = "Enhancement",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/inv_shield_06.blp",
        id = "shshspec",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Shield Specialisation",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:p8syz5ba",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

### Anticipation

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "c4a91e7d",
    entry = {
        automaticAuras = {  },
        category = "Enhancement",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/spell_nature_mirrorimage.blp",
        id = "shantici",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Anticipation",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:o6113cir",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

### Flurry

#### Proc Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                baseAmount = 10,
                operation = "percent",
                statRef = "f82db71a:u7b49vs9",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/ability_ghoulfrenzy.blp",
        id = "shflryau",
        maxStacks = 1,
        name = "Flurry",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Melee Attack Power by 10%.",
            bodyTokens = {  },
            stackingText = "",
            stackingTokens = {  },
            version = 1,
        },
    },
}
```

#### Trait

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "c4a91e7d",
    entry = {
        automaticAuras = {  },
        category = "Enhancement",
        conditions = {  },
        description = "",
        events = {
            {
                chance = 100,
                combatEventId = "on_critical_hit",
                effects = {
                    {
                        auraRef = "c4a91e7d:shflryau",
                        basePower = 0,
                        duration = 2,
                        stacks = 1,
                        type = "apply_aura",
                    },
                },
                triggerTarget = "aura_caster",
            },
        },
        icon = "interface/icons/ability_ghoulfrenzy.blp",
        id = "shflurry",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Flurry",
        skillBonuses = {  },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Toughness

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "c4a91e7d",
    entry = {
        automaticAuras = {  },
        category = "Enhancement",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/spell_holy_devotion.blp",
        id = "shtoughn",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Toughness",
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

### Weapon Mastery

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "c4a91e7d",
    entry = {
        automaticAuras = {  },
        category = "Enhancement",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/ability_hunter_swiftstrike.blp",
        id = "shwepmst",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Weapon Mastery",
        skillBonuses = {
            {
                skillRef = "f82db71a:jeeso2wd",
                value = 6,
            },
            {
                skillRef = "f82db71a:rv0tmq5b",
                value = 6,
            },
            {
                skillRef = "f82db71a:tbvqz1rq",
                value = 6,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

## Restoration

### Ancestral Healing

#### Proc Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                baseAmount = 25,
                operation = "percent",
                statRef = "f82db71a:v42albuv",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/spell_nature_undyingstrength.blp",
        id = "shanchea",
        maxStacks = 1,
        name = "Ancestral Healing",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Armor by 25%.",
            bodyTokens = {  },
            stackingText = "",
            stackingTokens = {  },
            version = 1,
        },
    },
}
```

#### Trait

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "c4a91e7d",
    entry = {
        automaticAuras = {  },
        category = "Restoration",
        conditions = {  },
        description = "",
        events = {
            {
                chance = 100,
                combatEventId = "on_critical_heal",
                effects = {
                    {
                        auraRef = "c4a91e7d:shanchea",
                        basePower = 0,
                        duration = 3,
                        stacks = 1,
                        type = "apply_aura",
                    },
                },
                triggerTarget = "event_other",
            },
        },
        icon = "interface/icons/spell_nature_undyingstrength.blp",
        id = "shanchel",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Ancestral Healing",
        skillBonuses = {  },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Nature's Guidance

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "c4a91e7d",
    entry = {
        automaticAuras = {  },
        category = "Restoration",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/spell_frost_stun.blp",
        id = "shnatgui",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Nature's Guidance",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:wbj4zuf3",
                value = 3,
            },
            {
                operation = "flat",
                statRef = "f82db71a:v2g0tw0o",
                value = 3,
            },
        },
        unlockLevel = 1,
    },
}
```

### Healing Grace

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "c4a91e7d",
    entry = {
        automaticAuras = {  },
        category = "Restoration",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/spell_nature_healingtouch.blp",
        id = "shhealgr",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Healing Grace",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:j8n012e6",
                value = -15,
            },
        },
        unlockLevel = 1,
    },
}
```

### Tidal Mastery

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "c4a91e7d",
    entry = {
        automaticAuras = {  },
        category = "Restoration",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/spell_nature_tranquility.blp",
        id = "shtidmas",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Tidal Mastery",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:69hfqhne",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

### Purification

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "c4a91e7d",
    entry = {
        automaticAuras = {  },
        category = "Restoration",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/spell_frost_wizardmark.blp",
        id = "shpurify",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Purification",
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
