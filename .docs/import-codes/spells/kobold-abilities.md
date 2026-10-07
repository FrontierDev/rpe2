# Kobold Ability Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for Kobold-specific Core NPC abilities.

Import the entries in this order:

1. Puncture Armor aura
2. Fire Shield aura
3. Puncture Armor
4. Fire Shield

## Puncture Armor aura

NPC-only armor debuff. Reduces Armor by 25% for 5 turns. It does not stack; reapplication refreshes the duration.

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "f82db71a",
    entry = {
        description = "",
        duration = 5,
        effects = {
            {
                baseAmount = -25,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:v42albuv",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/ability_warrior_sunder.blp",
        id = "kobpunau",
        maxStacks = 1,
        name = "Puncture Armor",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Reduces Armor by 25%.",
            bodyTokens = {  },
            stackingText = "",
            stackingTokens = {  },
            version = 1,
        },
    },
}
```

## Fire Shield aura

NPC version of Lightning Shield using Fire damage. Applies 3 charges for 10 turns. Each melee hit taken deals Fire damage to the attacker and removes one stack.

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "f82db71a",
    entry = {
        description = "",
        duration = 10,
        effects = {  },
        events = {
            {
                chance = 100,
                combatEventId = "on_melee_taken",
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 28.1667,
                        damageSchoolRefs = {
                            "f82db71a:esjguw6d",
                        },
                        scaleWithRank = false,
                        statScaling = {
                            {
                                coefficient = 0.845,
                                statRef = "f82db71a:7t7xgzcx",
                            },
                        },
                        type = "damage",
                    },
                },
                triggerTarget = "event_source",
            },
            {
                chance = 100,
                combatEventId = "on_melee_taken",
                effects = {
                    {
                        auraRef = "f82db71a:kobfirau",
                        stacks = 1,
                        type = "remove_aura",
                    },
                },
                triggerTarget = "aura_target",
            },
        },
        icon = "interface/icons/spell_fire_immolation.blp",
        id = "kobfirau",
        maxStacks = 3,
        name = "Fire Shield",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "When the affected unit is hit by a melee attack, deal {AURA_EVENT_DAMAGE_1} Fire damage to the attacker and remove 1 stack.",
            bodyTokens = {
                {
                    applyMode = "damage_amount",
                    baseField = "baseDamage",
                    effectIndex = 1,
                    eventIndex = 1,
                    key = "AURA_EVENT_DAMAGE_1",
                    tokenType = "aura_amount",
                },
            },
            stackingText = "Applies {AURA_APPLIED_STACKS_1} stacks. Stacks up to {AURA_MAX_STACKS_1} times.",
            stackingTokens = {
                {
                    applyMode = "applied_stacks",
                    key = "AURA_APPLIED_STACKS_1",
                    tokenType = "aura_stacks",
                },
                {
                    applyMode = "max_stacks",
                    key = "AURA_MAX_STACKS_1",
                    tokenType = "aura_stacks",
                },
            },
            version = 1,
        },
    },
}
```

## Puncture Armor

NPC-only Main Action. Applies the 1-stack Puncture Armor debuff to one enemy for 5 turns.

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
        canTargetHiddenUnits = false,
        castTime = 0,
        casterEvents = {  },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "f82db71a:kobpunau",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "kobpunc1",
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
        doesNotRevealCaster = false,
        icon = "interface/icons/ability_warrior_sunder.blp",
        id = "kobpun01",
        cooldownChannel = 1,
        learnMode = "unavailable",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Puncture Armor",
        range = 0,
        resourceCosts = {  },
        seedNPCSpell = true,
        spellbookCategory = "",
        tags = {
            "npc",
            "kobold",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "f82db71a:kobpunau",
                    datasetId = "f82db71a",
                    descriptionText = "Reduces Armor by 25%.",
                    duration = 5,
                    icon = "interface/icons/ability_warrior_sunder.blp",
                    nameText = "Puncture Armor",
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
            mainText = "Puncture an enemy's armor, reducing its Armor by 25% for 5 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Fire Shield

NPC-only Buff Action. Mirrors Lightning Shield but retaliates with Fire damage.

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
        canTargetHiddenUnits = false,
        castTime = 0,
        casterEvents = {  },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "f82db71a:kobfirau",
                    basePower = 0,
                    duration = 10,
                    stacks = 3,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "kobfirc1",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 0,
                    minTargets = 0,
                    requiresTarget = false,
                    targetDisposition = "ally",
                    type = "caster",
                },
            },
        },
        conditions = {  },
        cooldown = 1,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        doesNotRevealCaster = false,
        icon = "interface/icons/spell_fire_immolation.blp",
        id = "kobfire1",
        cooldownChannel = 3,
        learnMode = "unavailable",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Fire Shield",
        range = 0,
        resourceCosts = {
            {
                amount = 5,
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
            "kobold",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "f82db71a:kobfirau",
                    datasetId = "f82db71a",
                    descriptionText = "When the affected unit is hit by a melee attack, deal {AURA_EVENT_DAMAGE_1} Fire damage to the attacker and remove 1 stack.",
                    duration = 10,
                    icon = "interface/icons/spell_fire_immolation.blp",
                    nameText = "Fire Shield",
                    powerLevel = 0,
                    spellDatasetId = "f82db71a",
                    stacks = 3,
                    targetContext = {
                        object = "you",
                        possessive = "your",
                        reflexive = "yourself",
                        subject = "you",
                    },
                    tokens = {
                        {
                            applyMode = "damage_amount",
                            baseField = "baseDamage",
                            effectIndex = 1,
                            eventIndex = 1,
                            key = "AURA_EVENT_DAMAGE_1",
                            tokenType = "aura_amount",
                        },
                    },
                },
            },
            mainText = "Apply 3 stacks of Fire Shield to yourself for 10 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
