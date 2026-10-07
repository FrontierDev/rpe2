# Abomination Ability Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for the Abomination's Core NPC ability.

Import the **Poison Cloud Aura** before the **Poison Cloud Spell**.

## Poison Cloud

Poison Cloud is an instant Main Action that affects up to five enemies and applies a 5-turn Nature damage-over-time effect.

The single-target five-turn periodic reference is reduced by the standard five-target per-target modifier:

- Base damage per turn: `20.8 × 0.45 = 9.36`
- MAP coefficient per turn: `0.15 × 0.45 = 0.0675`

At 750 Melee Attack Power this is approximately 60 Nature damage per affected target per turn before challenge, difficulty and mitigation modifiers.

### Poison Cloud Aura

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
                amountMode = "flat",
                baseDamage = 9.36,
                damageSchoolRefs = {
                    "f82db71a:qtr10qyj",
                },
                statScaling = {
                    {
                        coefficient = 0.0675,
                        statRef = "f82db71a:u7b49vs9",
                    },
                },
                type = "damage",
            },
        },
        events = {  },
        icon = "interface/icons/spell_nature_abolishmagic.blp",
        id = "psncldau",
        maxStacks = 1,
        name = "Poison Cloud",
        stackBehavior = "refresh_duration",
        tags = {
            "poison",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Deals {AURA_DAMAGE_1} Nature damage each turn.",
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

### Poison Cloud Spell

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
        casterEvents = {  },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "f82db71a:psncldau",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "psncldc1",
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
        icon = "interface/icons/spell_nature_abolishmagic.blp",
        id = "psncld01",
        cooldownChannel = 1,
        learnMode = "unavailable",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Poison Cloud",
        range = 0,
        resourceCosts = {  },
        seedNPCSpell = true,
        spellbookCategory = "",
        tags = {
            "npc",
            "poison",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "f82db71a:psncldau",
                    datasetId = "f82db71a",
                    descriptionText = "Deals {AURA_DAMAGE_1} Nature damage each turn.",
                    duration = 5,
                    icon = "interface/icons/spell_nature_abolishmagic.blp",
                    nameText = "Poison Cloud",
                    powerLevel = 0,
                    spellDatasetId = "f82db71a",
                    stacks = 1,
                    targetContext = {
                        object = "the affected enemies",
                        possessive = "the affected enemies'",
                        reflexive = "themselves",
                        subject = "the affected enemies",
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
            mainText = "Apply Poison Cloud to up to 5 enemies for 5 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
