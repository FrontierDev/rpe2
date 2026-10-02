# Demon Hunter Trait Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for Demon Hunter class talents in dataset `dhunter1`.

Import **Burning Wound — Aura** before the Burning Wound Trait. All ten Trait entries are intended for the Demon Hunter class's `talentTraitRefs`.

## Balance basis

These values are normalized against the existing RPE class-trait budget rather than copied directly from retail:

- **Illidari Knowledge**: +6 Magic Resistance, matching Death Knight **Magic Suppression** and close to Priest **Spell Warding** (+5).
- **Will of the Illidari**: +10% Stamina, matching the normal single-primary/defensive-stat talent budget used by traits such as **Survivalist**, **Divine Strength**, **Divine Intellect**, **Mental Strength**, and **Toughness**.
- **Demon Blades**: 50% chance on an auto-attack hit to generate 10 Fury. This averages 5 Fury per successful auto-attack, deliberately below Warrior **Momentum** (10 Rage on every auto-attack hit) because Demon Hunter already has an active Fury generator.
- **Burning Wound**: 25% chance on an auto-attack or ranged hit to apply a non-stacking 3-turn Fire DoT. Its per-turn damage is one-half of **Deep Wounds** because it can proc from ordinary successful hits rather than only critical hits.
- **Demon Hide**: +3 Damage Done and +3 Damage Reduction. Global Damage Done/Reduction are more broadly valuable than primary stats, so this is kept below stance-level packages such as Blood Presence, Shadowform, and Monk stances.
- **Infernal Armor**: +10% Armor, matching Paladin/Warrior/Death Knight/Shaman **Toughness** rather than the previous +20%.
- **Fallout**: 10% chance when dealing Fire damage to generate 1 Soul Fragment. The reduced proc chance accounts for multi-target and repeated Fire damage events.
- **Soul Rending**: 20% chance on a melee or spell hit to restore 2% Max Health. This is intentionally modest per event but meaningful over sustained combat.
- **Gift of the Void**: +5 Spell Crit. Chance, matching the normal single-crit-stat trait budget.
- **Blind Focus**: +3 Damage Done. This remains below mutually exclusive stance/form bonuses because it is unconditional.

Trait `description` fields are intentionally empty so the generated Trait description reflects the authored bonuses and events.

# General

## Illidari Knowledge

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dhunter1",
    entry = {
        automaticAuras = { },
        category = "General",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/ability_demonhunter_eyebeam.blp",
        id = "dhillkn1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Illidari Knowledge",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:zs1nbz13",
                value = 6,
            },
        },
        unlockLevel = 1,
    },
}
```

## Will of the Illidari

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dhunter1",
    entry = {
        automaticAuras = { },
        category = "General",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/ability_demonhunter_metamorphasisdps.blp",
        id = "dhwill01",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Will of the Illidari",
        skillBonuses = { },
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

# Havoc

## Demon Blades

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dhunter1",
    entry = {
        automaticAuras = { },
        category = "Havoc",
        conditions = { },
        description = "",
        events = {
            {
                chance = 50,
                combatEventId = "on_auto_attack_hit",
                effects = {
                    {
                        amount = 10,
                        amountMode = "flat",
                        resourceRef = "f82db71a:fury0001",
                        type = "resource",
                    },
                },
                triggerTarget = "aura_caster",
            },
        },
        icon = "interface/icons/ability_demonhunter_demonsbite.blp",
        id = "dhdblads",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Demon Blades",
        skillBonuses = { },
        statBonuses = { },
        unlockLevel = 1,
    },
}
```

## Burning Wound — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dhunter1",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                amountMode = "flat",
                baseDamage = 14.08335,
                damageSchoolRefs = {
                    "f82db71a:esjguw6d",
                },
                statScaling = {
                    {
                        coefficient = 0.04375,
                        statRef = "f82db71a:u7b49vs9",
                    },
                },
                type = "damage",
            },
        },
        events = { },
        icon = "interface/icons/ability_demonhunter_immolation.blp",
        id = "dhbrnwau",
        maxStacks = 1,
        name = "Burning Wound",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
    },
}
```

## Burning Wound

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dhunter1",
    entry = {
        automaticAuras = { },
        category = "Havoc",
        conditions = { },
        description = "",
        events = {
            {
                chance = 25,
                combatEventId = "on_auto_attack_hit",
                effects = {
                    {
                        auraRef = "dhunter1:dhbrnwau",
                        basePower = 0,
                        duration = 3,
                        stacks = 1,
                        type = "apply_aura",
                    },
                },
                triggerTarget = "event_other",
            },
            {
                chance = 25,
                combatEventId = "on_ranged_hit",
                effects = {
                    {
                        auraRef = "dhunter1:dhbrnwau",
                        basePower = 0,
                        duration = 3,
                        stacks = 1,
                        type = "apply_aura",
                    },
                },
                triggerTarget = "event_other",
            },
        },
        icon = "interface/icons/ability_demonhunter_immolation.blp",
        id = "dhbrnwtr",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Burning Wound",
        skillBonuses = { },
        statBonuses = { },
        unlockLevel = 1,
    },
}
```

## Demon Hide

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dhunter1",
    entry = {
        automaticAuras = { },
        category = "Havoc",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/ability_demonhunter_blur.blp",
        id = "dhdhide1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Demon Hide",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:gj9wxb0x",
                value = 3,
            },
            {
                operation = "flat",
                statRef = "f82db71a:pu05li08",
                value = 3,
            },
        },
        unlockLevel = 1,
    },
}
```

# Vengeance

## Infernal Armor

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dhunter1",
    entry = {
        automaticAuras = { },
        category = "Vengeance",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/ability_demonhunter_demonspikes.blp",
        id = "dhinfarm",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Infernal Armor",
        skillBonuses = { },
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

## Fallout

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dhunter1",
    entry = {
        automaticAuras = { },
        category = "Vengeance",
        conditions = { },
        description = "",
        events = {
            {
                chance = 10,
                combatEventId = "on_damage_type",
                damageSchoolRef = "f82db71a:esjguw6d",
                effects = {
                    {
                        amount = 1,
                        amountMode = "flat",
                        resourceRef = "dhunter1:dhsoul01",
                        type = "resource",
                    },
                },
                triggerTarget = "aura_caster",
            },
        },
        icon = "interface/icons/ability_demonhunter_immolation.blp",
        id = "dhfallot",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Fallout",
        skillBonuses = { },
        statBonuses = { },
        unlockLevel = 1,
    },
}
```

## Soul Rending

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dhunter1",
    entry = {
        automaticAuras = { },
        category = "Vengeance",
        conditions = { },
        description = "",
        events = {
            {
                chance = 20,
                combatEventId = "on_melee_hit",
                effects = {
                    {
                        amountMode = "max_percent",
                        baseHealing = 2,
                        statScaling = { },
                        type = "heal",
                    },
                },
                triggerTarget = "aura_caster",
            },
            {
                chance = 20,
                combatEventId = "on_spell_hit",
                effects = {
                    {
                        amountMode = "max_percent",
                        baseHealing = 2,
                        statScaling = { },
                        type = "heal",
                    },
                },
                triggerTarget = "aura_caster",
            },
        },
        icon = "interface/icons/ability_demonhunter_soulcleave2.blp",
        id = "dhsrend1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Soul Rending",
        skillBonuses = { },
        statBonuses = { },
        unlockLevel = 1,
    },
}
```

# Devourer

## Gift of the Void

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dhunter1",
    entry = {
        automaticAuras = { },
        category = "Devourer",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/ability_demonhunter_eyebeam.blp",
        id = "dhgiftvd",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Gift of the Void",
        skillBonuses = { },
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

## Blind Focus

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "dhunter1",
    entry = {
        automaticAuras = { },
        category = "Devourer",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/inv_12_dh_void_ability_collapsingstar.blp",
        id = "dhblfoc1",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Blind Focus",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:gj9wxb0x",
                value = 3,
            },
        },
        unlockLevel = 1,
    },
}
```
