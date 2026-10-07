# Warlock Trait Import Codes

Standalone RPE_DATASET_ENTRY_V1 import codes for Warlock class talents in dataset e8f3b2c6.

## Authoring notes

- All five entries are Warlock class talents. After importing them, add their refs to the Warlock class's talentTraitRefs.
- Percentage-point combat stats such as Spell Hit Chance, Melee Crit. Chance, and Spell Crit. Chance use operation = "flat".
- Multiplicative primary-stat changes such as Stamina and Spirit use operation = "percent".
- **Dance of the Wicked** restores **2% of Max Mana** on on_critical_hit; it deliberately uses amountMode = "max_percent", not base_percent.
- **Aftermath** copies Mage **Impact** mechanically: dealing Fire damage has a 5% chance to stun the damaged unit for 1 turn. The supporting Aura is Warlock-owned so the trait does not depend on the Mage dataset.
- Trait description fields are intentionally empty so the trait description generator derives their behavior from authored stat bonuses and events.

## Affliction

### Suppression

~~~text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "e8f3b2c6",
    entry = {
        automaticAuras = {  },
        category = "Affliction",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/spell_shadow_shadowbolt.blp",
        id = "wlsuppr6",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Suppression",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:v2g0tw0o",
                value = 6,
            },
        },
        unlockLevel = 1,
    },
}
~~~

## Demonology

### Demonic Embrace

~~~text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "e8f3b2c6",
    entry = {
        automaticAuras = {  },
        category = "Demonology",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/spell_shadow_ragingscream.blp",
        id = "wldembr15",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Demonic Embrace",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "percent",
                statRef = "f82db71a:ygjno50i",
                value = 15,
            },
            {
                operation = "percent",
                statRef = "f82db71a:kec9rhli",
                value = -15,
            },
        },
        unlockLevel = 1,
    },
}
~~~

### Dance of the Wicked

~~~text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "e8f3b2c6",
    entry = {
        automaticAuras = {  },
        category = "Demonology",
        conditions = {  },
        description = "",
        events = {
            {
                combatEventId = "on_critical_hit",
                effects = {
                    {
                        amount = 2,
                        amountMode = "max_percent",
                        resourceRef = "f82db71a:4c8mfm99",
                        type = "resource",
                    },
                },
                triggerTarget = "event_source",
            },
        },
        icon = "interface/icons/spell_shadow_burningspirit.blp",
        id = "wldance2",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Dance of the Wicked",
        skillBonuses = {  },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
~~~

### Demonic Tactics

~~~text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "e8f3b2c6",
    entry = {
        automaticAuras = {  },
        category = "Demonology",
        conditions = {  },
        description = "",
        events = {  },
        icon = "interface/icons/spell_shadow_gathershadows.blp",
        id = "wldemtac3",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Demonic Tactics",
        skillBonuses = {  },
        statBonuses = {
            {
                operation = "flat",
                statRef = "f82db71a:jslmczbi",
                value = 3,
            },
            {
                operation = "flat",
                statRef = "f82db71a:69hfqhne",
                value = 3,
            },
        },
        unlockLevel = 1,
    },
}
~~~

## Destruction

### Aftermath supporting Aura

~~~text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "e8f3b2c6",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                cancelOnDamage = false,
                forceAutoHitAgainstTarget = true,
                movementRangeOverride = 0,
                preventCasting = true,
                statScaling = {  },
                type = "control",
            },
        },
        events = {  },
        icon = "interface/icons/spell_fire_meteorstorm.blp",
        id = "wlaftrma",
        maxStacks = 1,
        name = "Aftermath",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = false,
    },
}
~~~

### Aftermath

~~~text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "traits",
    datasetId = "e8f3b2c6",
    entry = {
        automaticAuras = {  },
        category = "Destruction",
        conditions = {  },
        description = "",
        events = {
            {
                chance = 5,
                combatEventId = "on_damage_type",
                damageSchoolRef = "f82db71a:esjguw6d",
                effects = {
                    {
                        auraRef = "e8f3b2c6:wlaftrma",
                        basePower = 0,
                        duration = 1,
                        stacks = 1,
                        type = "apply_aura",
                    },
                },
                triggerTarget = "event_other",
            },
        },
        icon = "interface/icons/spell_fire_meteorstorm.blp",
        id = "wlaftrmt",
        isEnvironmental = false,
        mutuallyExclusiveTraitRefs = {  },
        name = "Aftermath",
        skillBonuses = {  },
        statBonuses = {  },
        unlockLevel = 1,
    },
}
~~~
