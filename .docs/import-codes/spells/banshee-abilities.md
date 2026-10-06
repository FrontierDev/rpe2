# Banshee Ability Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for the Banshee-specific Core NPC abilities.

Import the entries in this order:

1. Banshee Curse aura
2. Anti-Magic Shield aura
3. Banshee Curse
4. Anti-Magic Shield

## Banshee Curse aura

Reduces Melee Hit Chance and Ranged Hit Chance by 25% for 2 turns.

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "f82db71a",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                baseAmount = -25,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:wbj4zuf3",
                statScaling = {  },
                type = "stat",
            },
            {
                baseAmount = -25,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:dd88li4c",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/spell_shadow_curseofmannoroth.blp",
        id = "bancursa1",
        maxStacks = 1,
        name = "Banshee Curse",
        stackBehavior = "refresh_duration",
        tags = {
            "curse",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Reduces Melee Hit Chance and Ranged Hit Chance by 25%.",
            bodyTokens = {  },
            stackingText = "",
            stackingTokens = {  },
            version = 1,
        },
    },
}
```

## Anti-Magic Shield aura

Absorbs Fire, Frost, Nature, Arcane, Shadow and Holy damage for 2 turns. Physical damage is not absorbed.

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "f82db71a",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                amountMode = "flat",
                baseAbsorption = 104,
                damageSchoolRefs = {
                    "f82db71a:esjguw6d",
                    "f82db71a:hx7pnwv4",
                    "f82db71a:qtr10qyj",
                    "f82db71a:dtxhglqg",
                    "f82db71a:1ggt4t3v",
                    "f82db71a:wwctys5s",
                },
                statScaling = {
                    {
                        coefficient = 0.52,
                        statRef = "f82db71a:7t7xgzcx",
                    },
                },
                type = "absorb",
            },
        },
        events = {  },
        icon = "interface/icons/spell_shadow_antishadow.blp",
        id = "banamsau1",
        maxStacks = 1,
        name = "Anti-Magic Shield",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Absorbs {AURA_ABSORB_1} magic damage.",
            bodyTokens = {
                {
                    applyMode = "absorb_amount",
                    baseField = "baseAbsorption",
                    effectIndex = 1,
                    key = "AURA_ABSORB_1",
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

## Banshee Curse

Main Action curse that applies Banshee Curse to one enemy for 2 turns.

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
                    auraRef = "f82db71a:bancursa1",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "bancursc1",
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
        icon = "interface/icons/spell_shadow_curseofmannoroth.blp",
        id = "bancurse1",
        cooldownChannel = 1,
        learnMode = "unavailable",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Banshee Curse",
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
            "banshee",
            "curse",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "f82db71a:bancursa1",
                    datasetId = "f82db71a",
                    descriptionText = "Reduces Melee Hit Chance and Ranged Hit Chance by 25%.",
                    duration = 2,
                    icon = "interface/icons/spell_shadow_curseofmannoroth.blp",
                    nameText = "Banshee Curse",
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
            mainText = "Curse an enemy for 2 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Anti-Magic Shield

Buff Action self-shield. Absorbs magic damage for 2 turns and has a 5-turn cooldown.

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
                    auraRef = "f82db71a:banamsau1",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "banamsc1",
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
        cooldown = 5,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        doesNotRevealCaster = false,
        icon = "interface/icons/spell_shadow_antishadow.blp",
        id = "banams01",
        cooldownChannel = 3,
        learnMode = "unavailable",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Anti-Magic Shield",
        range = 0,
        resourceCosts = {
            {
                amount = 15,
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
            "banshee",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "f82db71a:banamsau1",
                    datasetId = "f82db71a",
                    descriptionText = "Absorbs {AURA_ABSORB_1} magic damage.",
                    duration = 2,
                    icon = "interface/icons/spell_shadow_antishadow.blp",
                    nameText = "Anti-Magic Shield",
                    powerLevel = 0,
                    spellDatasetId = "f82db71a",
                    stacks = 1,
                    targetContext = {
                        object = "you",
                        possessive = "your",
                        reflexive = "yourself",
                        subject = "you",
                    },
                    tokens = {
                        {
                            applyMode = "absorb_amount",
                            baseField = "baseAbsorption",
                            effectIndex = 1,
                            key = "AURA_ABSORB_1",
                            tokenType = "aura_amount",
                        },
                    },
                },
            },
            mainText = "Shield yourself from magic damage for 2 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
