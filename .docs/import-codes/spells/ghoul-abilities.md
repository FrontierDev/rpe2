# Ghoul Ability Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for the Ghoul NPC abilities used by the Core Ghoul variants.

Import each **Aura** before its associated **Spell**. All entries target the Core dataset (`f82db71a`), use Main Action cooldown channel 1, are unlearnable by players, and are seeded for NPC authoring.

## Balance summary

- **Diseased Bite:** no cooldown; `85 + 0.2975 × MAP` Shadow damage plus a 20-turn -40% Strength/-40% Agility debuff.
- **Leap:** 4-turn cooldown; `123.25 + 0.431375 × MAP` Shadow damage plus a 1-turn Hammer-of-Justice-style stun.
- **Thrash:** no cooldown; `85 + 0.2975 × MAP` Physical damage plus a 3-turn bleed dealing `28.1667 + 0.15 × MAP` Physical damage per turn.

# Auras

## Diseased Bite Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "f82db71a",
    entry = {
        description = "",
        duration = 20,
        effects = {
            {
                baseAmount = -40,
                operation = "percent",
                statRef = "f82db71a:zfqm8dxp",
                statScaling = {  },
                type = "stat",
            },
            {
                baseAmount = -40,
                operation = "percent",
                statRef = "f82db71a:xqz0daz2",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/ability_ghoulfrenzy.blp",
        id = "ghdisau1",
        maxStacks = 1,
        name = "Diseased Bite",
        stackBehavior = "refresh_duration",
        tags = {
            "disease",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Modifies Strength by {AURA_STAT_1}% and Agility by {AURA_STAT_2}%.",
            bodyTokens = {
                {
                    applyMode = "stat_amount",
                    baseField = "baseAmount",
                    effectIndex = 1,
                    key = "AURA_STAT_1",
                    tokenType = "aura_amount",
                },
                {
                    applyMode = "stat_amount",
                    baseField = "baseAmount",
                    effectIndex = 2,
                    key = "AURA_STAT_2",
                    tokenType = "aura_amount",
                },
            },
            stackingText = "",
            stackingTokens = {  },
            version = 1,
        },
    },
}
```

## Leap Stun Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "f82db71a",
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
        icon = "interface/icons/ability_heroicleap.blp",
        id = "ghleapau",
        maxStacks = 1,
        name = "Leap",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
            bodyTokens = {  },
            stackingText = "",
            stackingTokens = {  },
            version = 1,
        },
    },
}
```

## Thrash Bleed Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "f82db71a",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                amountMode = "flat",
                baseDamage = 28.1667,
                damageSchoolRefs = {
                    "f82db71a:v1azo4j6",
                },
                statScaling = {
                    {
                        coefficient = 0.15,
                        statRef = "f82db71a:u7b49vs9",
                    },
                },
                type = "damage",
            },
        },
        events = {  },
        icon = "interface/icons/ability_backstab.blp",
        id = "ghthrrau",
        maxStacks = 1,
        name = "Thrash",
        stackBehavior = "refresh_duration",
        tags = {
            "bleed",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Deals {AURA_DAMAGE_1} Physical damage each turn.",
            bodyTokens = {
                {
                    applyMode = "damage_amount",
                    baseField = "baseDamage",
                    effectIndex = 1,
                    key = "AURA_DAMAGE_1",
                    tokenType = "aura_amount",
                },
            },
            stackingText = "",
            stackingTokens = {  },
            version = 1,
        },
    },
}
```

# Spells

## Diseased Bite

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "f82db71a",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = {
            "on_melee_hit",
            "on_critical_hit",
        },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    alwaysHits = false,
                    amountMode = "flat",
                    applyAura = true,
                    auraRef = "f82db71a:ghdisau1",
                    auraStacks = 1,
                    baseDamage = 85,
                    damageSchoolRefs = {
                        "f82db71a:1ggt4t3v",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.2975,
                            statRef = "f82db71a:u7b49vs9",
                        },
                    },
                    targetEvents = {
                        "on_melee_taken",
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0,
                    weaponDamageMode = "none",
                },
                key = "ghdiscmp",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 1,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "enemy",
                    type = "single",
                },
            },
        },
        conditions = {  },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_ghoulfrenzy.blp",
        id = "ghdisbit",
        cooldownChannel = 1,
        learnMode = "unavailable",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Diseased Bite",
        range = 0,
        resourceCosts = {  },
        seedNPCSpell = true,
        spellbookCategory = "",
        tags = {
            "npc",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "f82db71a:ghdisau1",
                    datasetId = "f82db71a",
                    descriptionText = "Modifies Strength by {AURA_STAT_1}% and Agility by {AURA_STAT_2}%.",
                    duration = 20,
                    icon = "interface/icons/ability_ghoulfrenzy.blp",
                    nameText = "Diseased Bite",
                    powerLevel = 0,
                    spellDatasetId = "f82db71a",
                    stacks = 1,
                    targetContext = {
                        object = "the affected enemy",
                        possessive = "the affected enemy's",
                        reflexive = "itself",
                        subject = "the affected enemy",
                    },
                    tokens = {
                        {
                            applyMode = "stat_amount",
                            baseField = "baseAmount",
                            effectIndex = 1,
                            key = "AURA_STAT_1",
                            tokenType = "aura_amount",
                        },
                        {
                            applyMode = "stat_amount",
                            baseField = "baseAmount",
                            effectIndex = 2,
                            key = "AURA_STAT_2",
                            tokenType = "aura_amount",
                        },
                    },
                },
            },
            mainText = "Deal {DAMAGE_1} Shadow damage to an enemy and apply Diseased Bite for 20 turns.",
            tokens = {
                {
                    applyMode = "damage_range",
                    componentIndex = 1,
                    key = "DAMAGE_1",
                    tokenType = "spell_damage_range",
                },
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Leap

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "f82db71a",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = {
            "on_melee_hit",
            "on_critical_hit",
        },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    alwaysHits = false,
                    amountMode = "flat",
                    applyAura = true,
                    auraRef = "f82db71a:ghleapau",
                    auraStacks = 1,
                    baseDamage = 123.25,
                    damageSchoolRefs = {
                        "f82db71a:1ggt4t3v",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.431375,
                            statRef = "f82db71a:u7b49vs9",
                        },
                    },
                    targetEvents = {
                        "on_melee_taken",
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0,
                    weaponDamageMode = "none",
                },
                key = "ghleapcp",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 1,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "enemy",
                    type = "single",
                },
            },
        },
        conditions = {  },
        cooldown = 4,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_heroicleap.blp",
        id = "ghleap01",
        cooldownChannel = 1,
        learnMode = "unavailable",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Leap",
        range = 0,
        resourceCosts = {  },
        seedNPCSpell = true,
        spellbookCategory = "",
        tags = {
            "npc",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "f82db71a:ghleapau",
                    datasetId = "f82db71a",
                    descriptionText = "Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                    duration = 1,
                    icon = "interface/icons/ability_heroicleap.blp",
                    nameText = "Leap",
                    powerLevel = 0,
                    spellDatasetId = "f82db71a",
                    stacks = 1,
                    targetContext = {
                        object = "the affected enemy",
                        possessive = "the affected enemy's",
                        reflexive = "itself",
                        subject = "the affected enemy",
                    },
                    tokens = {  },
                },
            },
            mainText = "Deal {DAMAGE_1} Shadow damage to an enemy and stun it for 1 turn.",
            tokens = {
                {
                    applyMode = "damage_range",
                    componentIndex = 1,
                    key = "DAMAGE_1",
                    tokenType = "spell_damage_range",
                },
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Thrash

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "f82db71a",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = {
            "on_melee_hit",
            "on_critical_hit",
        },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    alwaysHits = false,
                    amountMode = "flat",
                    applyAura = true,
                    auraRef = "f82db71a:ghthrrau",
                    auraStacks = 1,
                    baseDamage = 85,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.2975,
                            statRef = "f82db71a:u7b49vs9",
                        },
                    },
                    targetEvents = {
                        "on_melee_taken",
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0,
                    weaponDamageMode = "none",
                },
                key = "ghthrcmp",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 1,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "enemy",
                    type = "single",
                },
            },
        },
        conditions = {  },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_backstab.blp",
        id = "ghthrash",
        cooldownChannel = 1,
        learnMode = "unavailable",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Thrash",
        range = 0,
        resourceCosts = {  },
        seedNPCSpell = true,
        spellbookCategory = "",
        tags = {
            "npc",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "f82db71a:ghthrrau",
                    datasetId = "f82db71a",
                    descriptionText = "Deals {AURA_DAMAGE_1} Physical damage each turn.",
                    duration = 3,
                    icon = "interface/icons/ability_backstab.blp",
                    nameText = "Thrash",
                    powerLevel = 0,
                    spellDatasetId = "f82db71a",
                    stacks = 1,
                    targetContext = {
                        object = "the affected enemy",
                        possessive = "the affected enemy's",
                        reflexive = "itself",
                        subject = "the affected enemy",
                    },
                    tokens = {
                        {
                            applyMode = "damage_amount",
                            baseField = "baseDamage",
                            effectIndex = 1,
                            key = "AURA_DAMAGE_1",
                            tokenType = "aura_amount",
                        },
                    },
                },
            },
            mainText = "Deal {DAMAGE_1} Physical damage to an enemy and apply Thrash for 3 turns.",
            tokens = {
                {
                    applyMode = "damage_range",
                    componentIndex = 1,
                    key = "DAMAGE_1",
                    tokenType = "spell_damage_range",
                },
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
