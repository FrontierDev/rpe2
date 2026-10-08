# Harpy Ability Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for Harpy-specific Core NPC abilities.

Import the entries in this order:

1. Screech aura
2. Screech

## Screech aura

NPC-only debuff. Reduces Melee, Ranged and Spell Hit Chance by 10 for 2 turns. It does not stack; reapplication refreshes the duration.

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
                baseAmount = -10,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:wbj4zuf3",
                statScaling = {  },
                type = "stat",
            },
            {
                baseAmount = -10,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:dd88li4c",
                statScaling = {  },
                type = "stat",
            },
            {
                baseAmount = -10,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:v2g0tw0o",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/ability_hunter_pet_bat.blp",
        id = "harscrau",
        maxStacks = 1,
        name = "Screech",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Reduces Melee Hit Chance by {AURA_STAT_1}, Ranged Hit Chance by {AURA_STAT_2}, and Spell Hit Chance by {AURA_STAT_3}.",
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
                {
                    applyMode = "stat_amount",
                    baseField = "baseAmount",
                    effectIndex = 3,
                    key = "AURA_STAT_3",
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

## Screech

NPC-only Main Action. Applies Screech to up to five enemies for 2 turns.

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
                    auraRef = "f82db71a:harscrau",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "harscrc1",
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
        cooldown = 3,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        doesNotRevealCaster = false,
        icon = "interface/icons/ability_hunter_pet_bat.blp",
        id = "harscr01",
        cooldownChannel = 1,
        learnMode = "unavailable",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Screech",
        range = 0,
        resourceCosts = {  },
        seedNPCSpell = true,
        spellbookCategory = "",
        tags = {
            "npc",
            "harpy",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "f82db71a:harscrau",
                    datasetId = "f82db71a",
                    descriptionText = "Reduces Melee, Ranged and Spell Hit Chance by 10.",
                    duration = 2,
                    icon = "interface/icons/ability_hunter_pet_bat.blp",
                    nameText = "Screech",
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
            mainText = "Screech at up to 5 enemies, reducing their Hit Chance for 2 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
