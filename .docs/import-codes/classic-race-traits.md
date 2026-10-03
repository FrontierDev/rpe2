# Classic Race Trait Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for the additional Vanilla / WoW Classic races in the Core dataset.

These entries cover **Night Elf, Gnome, Orc, Undead, Tauren, and Troll only**. The current Human and Dwarf implementations are intentionally not changed.

Import these Traits before the corresponding Race entries:

- `.docs/import-codes/night-elf-race.md`
- `.docs/import-codes/gnome-race.md`
- `.docs/import-codes/orc-race.md`
- `.docs/import-codes/undead-race.md`
- `.docs/import-codes/tauren-race.md`
- `.docs/import-codes/troll-race.md`

## Authoring rules applied

- Only passives that map to mechanics currently supported by RPE are authored.
- All crafting skill bonuses use +15; all non-combat skill bonuses use +5. Weapon-skill bonuses retain their explicitly authored values.
- Weapon and profession specialisations use `skillBonuses`.
- Primary-stat percentage bonuses use `operation = "percent"`.
- Percentage-point combat stats such as Dodge Chance, Melee Hit Chance, and Damage vs. Beasts use `operation = "flat"`.
- Resistance and Defense Rating bonuses use flat stat bonuses.
- Night Elf increased Stealth is represented as +5 Stealth skill.
- Orc Hardiness is represented as +10 Defense Rating.
- Undead Touch of the Grave has a 10% chance on a successful melee ability hit or melee auto-attack hit to deal Shadow damage equal to `0.5 × Stamina`.
- Tauren receives +1 Melee Hit Chance in addition to Endurance and Nature Resistance.
- Troll Regeneration uses the agreed RPE implementation of +5% Spirit, matching The Human Spirit mechanically.
- Unsupported or active Classic racials are not included.

## Shared traits

### Nature Resistance

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
                value = 10,
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
        id = "racarc10",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Arcane Resistance",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:954yunb9",
                value = 10,
            },
        },
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
        id = "racshd10",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Shadow Resistance",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:itpo751d",
                value = 10,
            },
        },
        unlockLevel = 1,
    },
}
```

### Axe Specialisation

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
        icon = "interface/icons/inv_axe_04.blp",
        id = "racaxe05",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Axe Specialisation",
        skillBonuses = {
            {
                skillRef = "f82db71a:jeeso2wd",
                value = 5,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Bow Specialisation

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
        icon = "interface/icons/inv_weapon_bow_02.blp",
        id = "racbow05",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Bow Specialisation",
        skillBonuses = {
            {
                skillRef = "f82db71a:jn4qbjhu",
                value = 5,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

### Throwing Specialisation

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
        icon = "interface/icons/inv_throwingknife_02.blp",
        id = "racthr05",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Throwing Specialisation",
        skillBonuses = {
            {
                skillRef = "f82db71a:2s4jy7yc",
                value = 5,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

## Night Elf

### Quickness

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
        icon = "interface/icons/spell_shadow_shadowward.blp",
        id = "nequick1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Quickness",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:o6113cir",
                value = 1,
            },
        },
        unlockLevel = 1,
    },
}
```

### Elusiveness

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
        icon = "interface/icons/ability_stealth.blp",
        id = "neelus05",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Elusiveness",
        skillBonuses = {
            {
                skillRef = "f82db71a:muuwon1r",
                value = 5,
            },
        },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

## Gnome

### Expansive Mind

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
        icon = "interface/icons/spell_holy_arcaneintellect.blp",
        id = "gnexp005",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Expansive Mind",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:75y3a8ib",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

### Engineering Specialisation

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
        id = "gneng015",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Engineering Specialisation",
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

## Orc

### Hardiness

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
        icon = "interface/icons/ability_warrior_criticalblock.blp",
        id = "orchrd10",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Hardiness",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:0wyp78x9",
                value = 10,
            },
        },
        unlockLevel = 1,
    },
}
```

## Undead

### Touch of the Grave

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
        events = {
            {
                chance = 10,
                combatEventId = "on_melee_hit",
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 0,
                        damageSchoolRefs = {
                            "f82db71a:1ggt4t3v",
                        },
                        statScaling = {
                            {
                                coefficient = 0.5,
                                statRef = "f82db71a:ygjno50i",
                            },
                        },
                        type = "damage",
                    },
                },
                triggerTarget = "event_other",
            },
            {
                chance = 10,
                combatEventId = "on_auto_attack_hit",
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 0,
                        damageSchoolRefs = {
                            "f82db71a:1ggt4t3v",
                        },
                        statScaling = {
                            {
                                coefficient = 0.5,
                                statRef = "f82db71a:ygjno50i",
                            },
                        },
                        type = "damage",
                    },
                },
                triggerTarget = "event_other",
            },
        },
        icon = "interface/icons/spell_shadow_lifedrain02.blp",
        id = "udtouch1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Touch of the Grave",
        skillBonuses = {  },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
```

## Tauren

### Endurance

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
        icon = "interface/icons/spell_nature_unyeildingstamina.blp",
        id = "taend005",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Endurance",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:ygjno50i",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

### Brawn

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
        icon = "interface/icons/petbattle_attack.blp",
        id = "tabrawn1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Brawn",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:wbj4zuf3",
                value = 1,
            },
        },
        unlockLevel = 1,
    },
}
```

## Troll

### Beast Slaying

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
        icon = "interface/icons/spell_nature_focusedmind.blp",
        id = "trbeast5",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Beast Slaying",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:vgzlnifw",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```

### Regeneration

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
        icon = "interface/icons/spell_shadow_burningspirit.blp",
        id = "trregen5",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Regeneration",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:kec9rhli",
                value = 5,
            },
        },
        unlockLevel = 1,
    },
}
```
