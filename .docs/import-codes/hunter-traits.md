# Hunter Trait Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for Hunter traits in dataset `a93f7c12`.

## Authoring notes

- Categories use **Beast Mastery**, **Class Passive**, **Survival**, and **Marksmanship**.
- The three Aspects are mutually exclusive through `mutuallyExclusiveTraitRefs`, so only one can be selected at a time.
- Percentage-point combat stats such as Dodge, Parry, Hit, Crit, Damage Done, Resource Regeneration, and creature-type damage use flat stat bonuses because the Core stats already interpret each point as one percentage point.
- Primary/derived numeric stats that are explicitly described as percentage increases—Stamina, Agility, and Ranged Attack Power—use `operation = "percent"`.
- **Aspect of the Hawk** uses a separate proc aura. Its `on_auto_attack_hit` event has a 5% chance to apply +30 Ranged Crit. Chance to the Hunter for 1 turn.
- **Monsterslaying** implements only the requested +3% damage against Beasts, Dragonkin, and Giants. It does not add Classic's separate creature-type critical-damage bonus.
- After importing, wire `a93f7c12:monslay1` into the Hunter class's `passiveTraitRefs`; the other ten trait refs belong in `talentTraitRefs`.

## Beast Mastery

### Aspect of the Monkey

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "a93f7c12",
    entry = {
        automaticAuras = {  },
        category = "Beast Mastery",
        conditions = {  },
        description = "Increases Dodge Chance by 11%.",
        events = {  },
        icon = "interface/icons/ability_hunter_aspectofthemonkey.blp",
        id = "aspmonk1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {
            "a93f7c12:aspvipr1",
            "a93f7c12:asphawk1",
        },
        name = "Aspect of the Monkey",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:o6113cir",
                value = 11,
            },
        },
        unlockLevel = 1,
    },
}
```

### Aspect of the Viper

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "a93f7c12",
    entry = {
        automaticAuras = {  },
        category = "Beast Mastery",
        conditions = {  },
        description = "Reduces Damage Done by 20% and increases Resource Regeneration by 80%.",
        events = {  },
        icon = "interface/icons/ability_hunter_aspectoftheviper.blp",
        id = "aspvipr1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {
            "a93f7c12:aspmonk1",
            "a93f7c12:asphawk1",
        },
        name = "Aspect of the Viper",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:gj9wxb0x",
                value = -20,
            },
            {
                operation = "flat",
                statRef = "f82db71a:rgnrtg01",
                value = 80,
            },
        },
        unlockLevel = 1,
    },
}
```

### Aspect of the Hawk

#### Proc Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "a93f7c12",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                baseAmount = 30,
                operation = "flat",
                statRef = "f82db71a:fercjhm5",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/spell_nature_ravenform.blp",
        id = "hawkpcr1",
        maxStacks = 1,
        name = "Aspect of the Hawk",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Ranged Crit. Chance by 30%.",
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
    datasetId = "a93f7c12",
    entry = {
        automaticAuras = {  },
        category = "Beast Mastery",
        conditions = {  },
        description = "Increases Ranged Attack Power by 10%. On auto attack hit, has a 5% chance to increase Ranged Crit. Chance by 30% for 1 turn.",
        events = {
            {
                chance = 5,
                combatEventId = "on_auto_attack_hit",
                effects = {
                    {
                        auraRef = "a93f7c12:hawkpcr1",
                        basePower = 0,
                        duration = 1,
                        stacks = 1,
                        type = "apply_aura",
                    },
                },
                triggerTarget = "aura_caster",
            },
        },
        icon = "interface/icons/spell_nature_ravenform.blp",
        id = "asphawk1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {
            "a93f7c12:aspmonk1",
            "a93f7c12:aspvipr1",
        },
        name = "Aspect of the Hawk",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:v2rs9cpy",
                value = 10,
            },
        },
        unlockLevel = 1,
    },
}
```

## Class Passive

### Monsterslaying

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "a93f7c12",
    entry = {
        automaticAuras = {  },
        category = "Class Passive",
        conditions = {  },
        description = "Increases damage against Beasts, Dragonkin, and Giants by 3%.",
        events = {  },
        icon = "interface/icons/spell_nature_focusedmind.blp",
        id = "monslay1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Monsterslaying",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:vgzlnifw",
                value = 3,
            },
            {
                operation = "flat",
                statRef = "f82db71a:8mwchweb",
                value = 3,
            },
            {
                operation = "flat",
                statRef = "f82db71a:x1lxi8cf",
                value = 3,
            },
        },
        unlockLevel = 1,
    },
}
```

## Survival

### Deflection

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "a93f7c12",
    entry = {
        automaticAuras = {  },
        category = "Survival",
        conditions = {  },
        description = "Increases Parry Chance by 5%.",
        events = {  },
        icon = "interface/icons/ability_parry.blp",
        id = "deflect1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Deflection",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:tcn0s8kx",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

### Survivalist

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "a93f7c12",
    entry = {
        automaticAuras = {  },
        category = "Survival",
        conditions = {  },
        description = "Increases Stamina by 10%.",
        events = {  },
        icon = "interface/icons/spell_nature_unyeildingstamina.blp",
        id = "survlist",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Survivalist",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:ygjno50i",
                value = 10,
            },
        },
        unlockLevel = 1,
    },
}
```

### Surefooted

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "a93f7c12",
    entry = {
        automaticAuras = {  },
        category = "Survival",
        conditions = {  },
        description = "Increases Melee Hit Chance by 3%.",
        events = {  },
        icon = "interface/icons/ability_kick.blp",
        id = "sureft01",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Surefooted",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:wbj4zuf3",
                value = 3,
            },
        },
        unlockLevel = 1,
    },
}
```

### Killer Instinct

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "a93f7c12",
    entry = {
        automaticAuras = {  },
        category = "Survival",
        conditions = {  },
        description = "Increases Melee Crit. Chance by 3%.",
        events = {  },
        icon = "interface/icons/ability_hunter_killcommand.blp",
        id = "killinst",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Killer Instinct",
        skillBonuses = {  },
        statBonuses = {
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

### Lightning Reflexes

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "a93f7c12",
    entry = {
        automaticAuras = {  },
        category = "Survival",
        conditions = {  },
        description = "Increases Agility by 15%.",
        events = {  },
        icon = "interface/icons/spell_holy_blessingofagility.blp",
        id = "lghtrefx",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Lightning Reflexes",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:xqz0daz2",
                value = 15,
            },
        },
        unlockLevel = 1,
    },
}
```

## Marksmanship

### Lethal Shots

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "a93f7c12",
    entry = {
        automaticAuras = {  },
        category = "Marksmanship",
        conditions = {  },
        description = "Increases Ranged Crit. Chance by 5%.",
        events = {  },
        icon = "interface/icons/ability_hunter_criticalshot.blp",
        id = "lethshot",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Lethal Shots",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:fercjhm5",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

### Ranged Weapon Specialisation

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "a93f7c12",
    entry = {
        automaticAuras = {  },
        category = "Marksmanship",
        conditions = {  },
        description = "Increases Ranged Attack Power by 5%.",
        events = {  },
        icon = "interface/icons/ability_marksmanship.blp",
        id = "rngspec1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Ranged Weapon Specialisation",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:v2rs9cpy",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```
