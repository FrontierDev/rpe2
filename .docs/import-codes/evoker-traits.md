# Evoker Trait Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for the synthetic Classic-style Evoker class talents in dataset `evokdata`.

Import **Burning Adrenaline — Aura** before the Burning Adrenaline trait. All ten Trait entries are intended for the Evoker class's `talentTraitRefs`.

## Balance basis

These values are normalized against the existing default-dataset trait budget:

- **Draconic Knowledge**: +10% Intellect, matching Paladin **Divine Intellect**, Priest **Mental Strength**, and Shaman **Ancestral Knowledge**.
- **Obsidian Constitution**: +10% Stamina, matching Hunter **Survivalist**.
- **Innate Essence**: 50% chance on a critical hit to restore 1 Essence. This is deliberately below Rogue **Seal Fate** (1 Combo Point on every critical hit) because Essence already regenerates naturally and Evoker spenders cost 3 Essence. RPE currently exposes `on_critical_hit`, not a distinct critical-spell-hit event, so other critical-hit sources that publish the same event can also trigger it.
- **Scintillation**: +5 Spell Crit. Chance, matching the normal single-crit-stat budget used by default traits.
- **Burning Adrenaline**: 5% chance when dealing Fire damage to gain +5 Damage Done for 1 turn. The 5% proc rate matches Mage **Impact**'s school-damage trigger budget, while the temporary global Damage Done bonus is deliberately kept modest.
- **Arcane Instinct**: 5% chance when dealing Arcane damage to restore 1 Essence. The low proc rate accounts for repeated and multi-target Arcane damage events.
- **Life-Binder**: +10% Healing Power, matching Priest **Spiritual Healing**.
- **Golden Hour**: every critical heal additionally restores 3% of the healed target's maximum health. This is intentionally below the strength of default critical-heal talents such as **Inspiration/Ancestral Healing** and **Illumination**.
- **Temporal Clarity**: every critical heal restores 5% Base Mana to the Evoker, exactly half of Paladin **Illumination**'s 10% Base Mana return.
- **Draconic Fortitude**: +6 Magic Resistance, matching Death Knight **Magic Suppression**.

Trait `description` fields are intentionally empty so the generated Trait description reflects the authored bonuses and events.

# General

## Draconic Knowledge

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "evokdata",
    entry = {
        automaticAuras = { },
        category = "General",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/classicon_evoker.blp",
        id = "evdrknow",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Draconic Knowledge",
        skillBonuses = { },
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

## Obsidian Constitution

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "evokdata",
    entry = {
        automaticAuras = { },
        category = "General",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/ability_evoker_obsidianscales.blp",
        id = "evobscon",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Obsidian Constitution",
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

## Innate Essence

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "evokdata",
    entry = {
        automaticAuras = { },
        category = "General",
        conditions = { },
        description = "",
        events = {
            {
                chance = 50,
                combatEventId = "on_critical_hit",
                effects = {
                    {
                        amount = 1,
                        amountMode = "flat",
                        resourceRef = "f82db71a:essence1",
                        type = "resource",
                    },
                },
                triggerTarget = "aura_caster",
            },
        },
        icon = "interface/icons/ability_evoker_disintegrate.blp",
        id = "evinnate",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Innate Essence",
        skillBonuses = { },
        statBonuses = { },
        unlockLevel = 1,
    },
}
```

# Devastation

## Scintillation

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "evokdata",
    entry = {
        automaticAuras = { },
        category = "Devastation",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/ability_evoker_eternitysurge.blp",
        id = "evscinti",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Scintillation",
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

## Burning Adrenaline — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "evokdata",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                baseAmount = 5,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:gj9wxb0x",
                statScaling = { },
                type = "stat",
            },
        },
        events = { },
        icon = "interface/icons/ability_evoker_dragonrage2.blp",
        id = "evbrnada",
        maxStacks = 1,
        name = "Burning Adrenaline",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
    },
}
```

## Burning Adrenaline

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "evokdata",
    entry = {
        automaticAuras = { },
        category = "Devastation",
        conditions = { },
        description = "",
        events = {
            {
                chance = 5,
                combatEventId = "on_damage_type",
                damageSchoolRef = "f82db71a:esjguw6d",
                effects = {
                    {
                        auraRef = "evokdata:evbrnada",
                        basePower = 0,
                        duration = 1,
                        stacks = 1,
                        type = "apply_aura",
                    },
                },
                triggerTarget = "aura_caster",
            },
        },
        icon = "interface/icons/ability_evoker_dragonrage2.blp",
        id = "evburnad",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Burning Adrenaline",
        skillBonuses = { },
        statBonuses = { },
        unlockLevel = 1,
    },
}
```

## Arcane Instinct

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "evokdata",
    entry = {
        automaticAuras = { },
        category = "Devastation",
        conditions = { },
        description = "",
        events = {
            {
                chance = 5,
                combatEventId = "on_damage_type",
                damageSchoolRef = "f82db71a:dtxhglqg",
                effects = {
                    {
                        amount = 1,
                        amountMode = "flat",
                        resourceRef = "f82db71a:essence1",
                        type = "resource",
                    },
                },
                triggerTarget = "aura_caster",
            },
        },
        icon = "interface/icons/ability_evoker_azurestrike.blp",
        id = "evarcins",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Arcane Instinct",
        skillBonuses = { },
        statBonuses = { },
        unlockLevel = 1,
    },
}
```

# Preservation

## Life-Binder

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "evokdata",
    entry = {
        automaticAuras = { },
        category = "Preservation",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/ability_evoker_dreambreath.blp",
        id = "evlifebn",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Life-Binder",
        skillBonuses = { },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:hj6d4kvy",
                value = 10,
            },
        },
        unlockLevel = 1,
    },
}
```

## Golden Hour

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "evokdata",
    entry = {
        automaticAuras = { },
        category = "Preservation",
        conditions = { },
        description = "",
        events = {
            {
                chance = 100,
                combatEventId = "on_critical_heal",
                effects = {
                    {
                        amountMode = "max_percent",
                        baseHealing = 3,
                        statScaling = { },
                        type = "heal",
                    },
                },
                triggerTarget = "event_other",
            },
        },
        icon = "interface/icons/ability_evoker_reversion.blp",
        id = "evgoldhr",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Golden Hour",
        skillBonuses = { },
        statBonuses = { },
        unlockLevel = 1,
    },
}
```

## Temporal Clarity

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "evokdata",
    entry = {
        automaticAuras = { },
        category = "Preservation",
        conditions = { },
        description = "",
        events = {
            {
                chance = 100,
                combatEventId = "on_critical_heal",
                effects = {
                    {
                        amount = 5,
                        amountMode = "base_percent",
                        resourceRef = "f82db71a:4c8mfm99",
                        type = "resource",
                    },
                },
                triggerTarget = "event_source",
            },
        },
        icon = "interface/icons/ability_evoker_spiritbloom.blp",
        id = "evtmclar",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Temporal Clarity",
        skillBonuses = { },
        statBonuses = { },
        unlockLevel = 1,
    },
}
```

# Augmentation

## Draconic Fortitude

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "evokdata",
    entry = {
        automaticAuras = { },
        category = "Augmentation",
        conditions = { },
        description = "",
        events = { },
        icon = "interface/icons/spell_sarkareth.blp",
        id = "evdrfort",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = { },
        name = "Draconic Fortitude",
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
