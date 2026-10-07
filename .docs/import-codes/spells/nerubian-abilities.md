# Nerubian Ability Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for Nerubian-specific Core NPC abilities.

Import the entries in this order:

1. Venomous Strike aura
2. Crypt Scarabs
3. Venomous Strike
4. Shadow Nova

## Crypt Scarabs

Crypt Scarabs is the Nerubian Fiend's ranged Shadow attack. It intentionally mirrors the current Warlock Shadow Bolt damage model: a 1-turn cast dealing `135 + 1.4 × Spell Power` Shadow damage.

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
        castTime = 1,
        casterEvents = {
            "on_spell_hit",
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
                    applyAura = false,
                    auraStacks = 1,
                    baseDamage = 135,
                    damageSchoolRefs = {
                        "f82db71a:1ggt4t3v",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 1.4,
                            statRef = "f82db71a:7t7xgzcx",
                        },
                    },
                    targetEvents = {
                        "on_spell_taken",
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0,
                    weaponDamageMode = "none",
                },
                key = "nrbscdmg",
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
        icon = "interface/icons/spell_shadow_shadowbolt.blp",
        id = "nrbscrb1",
        cooldownChannel = 1,
        learnMode = "unavailable",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Crypt Scarabs",
        range = 0,
        resourceCosts = {
            {
                amount = 6.8,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = true,
        spellbookCategory = "",
        tags = {
            "npc",
            "nerubian",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Deal {DAMAGE_1} Shadow damage to an enemy.",
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

## Venomous Strike aura

Venomous Strike applies a 3-turn Nature DoT and reduces Healing Received by 25% for the same duration.

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
                baseDamage = 18.7778,
                damageSchoolRefs = {
                    "f82db71a:qtr10qyj",
                },
                statScaling = {
                    {
                        coefficient = 0.08,
                        statRef = "f82db71a:u7b49vs9",
                    },
                },
                type = "damage",
            },
            {
                baseAmount = -25,
                operation = "flat",
                statRef = "f82db71a:ok80ohz3",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/ability_creature_poison_06.blp",
        id = "nrbvenau",
        maxStacks = 1,
        name = "Venomous Strike",
        stackBehavior = "refresh_duration",
        tags = {
            "poison",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Deals {AURA_DAMAGE_1} Nature damage each turn and reduces Healing Received by 25%.",
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

## Venomous Strike

The initial strike deals Physical damage, then applies the Venomous Strike aura for 3 turns.

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
                    applyAura = false,
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
                key = "nrbvendm",
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
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "f82db71a:nrbvenau",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "nrbvenap",
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
        icon = "interface/icons/ability_creature_poison_06.blp",
        id = "nrbven01",
        cooldownChannel = 1,
        learnMode = "unavailable",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Venomous Strike",
        range = 0,
        resourceCosts = {  },
        seedNPCSpell = true,
        spellbookCategory = "",
        tags = {
            "npc",
            "nerubian",
            "poison",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "f82db71a:nrbvenau",
                    datasetId = "f82db71a",
                    descriptionText = "Deals {AURA_DAMAGE_1} Nature damage each turn and reduces Healing Received by 25%.",
                    duration = 3,
                    icon = "interface/icons/ability_creature_poison_06.blp",
                    nameText = "Venomous Strike",
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
            mainText = "Deal {DAMAGE_1} Physical damage to an enemy and apply Venomous Strike for 3 turns.",
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

## Shadow Nova

Shadow Nova is an instant Main Action that deals Shadow damage to up to five enemies.

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
            "on_spell_hit",
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
                    applyAura = false,
                    auraStacks = 1,
                    baseDamage = 45,
                    damageSchoolRefs = {
                        "f82db71a:1ggt4t3v",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.45,
                            statRef = "f82db71a:7t7xgzcx",
                        },
                    },
                    targetEvents = {
                        "on_spell_taken",
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0,
                    weaponDamageMode = "none",
                },
                key = "nrbnovdm",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 5,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "enemy",
                    type = "multi",
                },
            },
        },
        conditions = {  },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_shadow_shadowfury.blp",
        id = "nrbnova1",
        cooldownChannel = 1,
        learnMode = "unavailable",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Shadow Nova",
        range = 0,
        resourceCosts = {
            {
                amount = 10,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = true,
        spellbookCategory = "",
        tags = {
            "npc",
            "nerubian",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Deal {DAMAGE_1} Shadow damage to up to 5 enemies.",
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
