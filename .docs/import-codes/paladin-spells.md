# Paladin Spell Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for the Paladin class dataset (`b0211ab3`).

Import each listed **Aura** before its associated **Spell**. All entries use the current RPE2 `dev` spell/aura schema and cooldown channels.

## Authoring notes

- These spells form the **Templar** specialisation: a reactive off-tank built around **Parry Chance** rather than absorbs or passive Damage Reduction.
- Templar uses **Energy** (`f82db71a:c3gaf7dd`) for every spell. Costs are flat Energy costs:
  - Holy Strike: 40 Energy
  - Seal of Warding: 15 Energy
  - Judgement of Warding: 30 Energy
  - Ardent Defender: 30 Energy
  - Light and Steel: 30 Energy
- Main Action = cooldown channel 1; Bonus Action = channel 2; Buff Action = channel 3.
- **Holy Strike** copies the current Crusader Strike damage, cooldown, charges, main-hand requirement and 1 Holy Power generation, but uses Energy and the requested icon.
- **Seal of Warding** follows the normal Paladin seal structure: 3-turn duration, Buff Action, 1-turn seal cooldown, `seal` cooldown group/tag, and a main-hand requirement. Each basic attack hit deals Holy damage and adds one 3-turn **Warding** stack to the caster. Warding grants +1 Parry Chance per stack, refreshes duration when stacked, and caps at 10 stacks.
- Seal of Warding's Holy proc uses the current Seal of Righteousness proc budget: `28.1667 + 0.4225 × Spell Power`.
- **Judgement of Warding** follows the normal Paladin judgement contract: it requires Seal of Warding, consumes the seal, uses the `judgement` cooldown group, deals the current Judgement of the Righteous Holy damage budget, and applies a fixed -10 Spell Hit Chance debuff for 2 turns.
- **Ardent Defender** uses the unrestricted `multi` targeter for up to 3 enemies, taunts them for 1 turn, and grants the caster +25 Parry Chance for 1 turn. It is a Bonus Action with a 3-turn cooldown.
- **Light and Steel** is a Buff Action granting +25 Parry Chance for 2 turns.
- Fixed Parry/Spell Hit modifiers do not scale with rank. Damage-bearing Holy Strike, Seal of Warding and Judgement of Warding use ranks with the standard 8-level interval.

## Templar

### Holy Strike

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "b0211ab3",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = {
            "on_melee_hit",
            "on_critical_hit",
        },
        charges = 2,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    alwaysHits = false,
                    amountMode = "flat",
                    applyAura = false,
                    auraStacks = 1,
                    baseDamage = 82.875,
                    damageSchoolRefs = {
                        "f82db71a:wwctys5s",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.3868,
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
                    weaponDamageCoefficient = 1.105,
                    weaponDamageMode = "main_hand",
                },
                key = "thlydmg1",
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
                    amount = 1,
                    amountMode = "flat",
                    resourceRef = "f82db71a:cbjzgaby",
                    targetEvents = {  },
                    type = "resource",
                },
                key = "thlyhp01",
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
        conditions = {
            {
                invert = false,
                showOnTooltip = true,
                slotKey = "mainhand",
                tooltipTextOverride = "Requires main hand",
                type = "item_equipped",
                weaponTypeRefs = {  },
            },
        },
        cooldown = 3,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/inv_sword_08.blp",
        id = "thlystrk",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Holy Strike",
        range = 0,
        resourceCosts = {
            {
                amount = 40,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:c3gaf7dd",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Templar",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Deal {DAMAGE_1} Holy damage to an enemy. Restore {RESOURCE_AMOUNT_1} Holy Power to yourself.",
            tokens = {
                {
                    applyMode = "damage_range",
                    componentIndex = 1,
                    key = "DAMAGE_1",
                    tokenType = "spell_damage_range",
                },
                {
                    applyMode = "resource_gain_amount",
                    componentIndex = 2,
                    key = "RESOURCE_AMOUNT_1",
                    tokenType = "spell_resource_amount",
                },
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = true,
    },
}
```

### Seal of Warding

#### Warding Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "b0211ab3",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                baseAmount = 1,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:tcn0s8kx",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/ability_priest_soulwarding.blp",
        id = "twrdpry1",
        maxStacks = 10,
        name = "Warding",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Parry Chance by {AURA_STAT_1}.",
            bodyTokens = {
                {
                    applyMode = "stat_amount",
                    baseField = "baseAmount",
                    effectIndex = 1,
                    key = "AURA_STAT_1",
                    tokenType = "aura_amount",
                },
            },
            stackingText = "Applies {AURA_APPLIED_STACKS_1} stack. Stacks up to {AURA_MAX_STACKS_1} times.",
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

#### Seal Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "b0211ab3",
    entry = {
        description = "",
        duration = 3,
        effects = {  },
        events = {
            {
                chance = 100,
                combatEventId = "on_auto_attack_hit",
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 28.1667,
                        damageSchoolRefs = {
                            "f82db71a:wwctys5s",
                        },
                        statScaling = {
                            {
                                coefficient = 0.4225,
                                statRef = "f82db71a:7t7xgzcx",
                            },
                        },
                        type = "damage",
                    },
                },
                triggerTarget = "event_other",
            },
            {
                chance = 100,
                combatEventId = "on_auto_attack_hit",
                effects = {
                    {
                        auraRef = "b0211ab3:twrdpry1",
                        basePower = 0,
                        duration = 3,
                        stacks = 1,
                        type = "apply_aura",
                    },
                },
                triggerTarget = "aura_caster",
            },
        },
        icon = "interface/icons/ability_priest_soulwarding.blp",
        id = "tsealwrd",
        maxStacks = 1,
        name = "Seal of Warding",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "When the affected unit hits with a basic attack, the target takes {AURA_EVENT_DAMAGE_1} Holy damage and the caster gains 1 stack of Warding for 3 turns.",
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
            stackingText = "",
            stackingTokens = {  },
            version = 1,
        },
    },
}
```

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "b0211ab3",
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
                    auraRef = "b0211ab3:tsealwrd",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "tsealap1",
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
        conditions = {
            {
                invert = false,
                showOnTooltip = true,
                slotKey = "mainhand",
                tooltipTextOverride = "Requires main hand",
                type = "item_equipped",
                weaponTypeRefs = {  },
            },
        },
        cooldown = 1,
        cooldownGroup = "seal",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_priest_soulwarding.blp",
        id = "tsealwsp",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Seal of Warding",
        range = 0,
        resourceCosts = {
            {
                amount = 15,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:c3gaf7dd",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Templar",
        tags = {
            "seal",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "b0211ab3:tsealwrd",
                    datasetId = "b0211ab3",
                    descriptionText = "When the affected unit hits with a basic attack, the target takes {AURA_EVENT_DAMAGE_1} Holy damage and the caster gains 1 stack of Warding for 3 turns.",
                    duration = 3,
                    icon = "interface/icons/ability_priest_soulwarding.blp",
                    nameText = "Seal of Warding",
                    powerLevel = 0,
                    spellDatasetId = "b0211ab3",
                    stacks = 1,
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
            mainText = "Apply Seal of Warding to yourself for 3 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Judgement of Warding

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "b0211ab3",
    entry = {
        description = "",
        duration = 2,
        effects = {
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
        icon = "interface/icons/spell_holy_righteousfury.blp",
        id = "tjudgwrd",
        maxStacks = 1,
        name = "Judgement of Warding",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Reduces Spell Hit Chance by {AURA_STAT_1}.",
            bodyTokens = {
                {
                    applyMode = "stat_amount",
                    baseField = "baseAmount",
                    effectIndex = 1,
                    key = "AURA_STAT_1",
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

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "b0211ab3",
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
                    baseDamage = 110.5,
                    damageSchoolRefs = {
                        "f82db71a:wwctys5s",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.5525,
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
                key = "tjuddmg1",
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
                    auraRef = "b0211ab3:tsealwrd",
                    stacks = 1,
                    targetEvents = {  },
                    type = "remove_aura",
                },
                key = "tjudrem1",
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
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "b0211ab3:tjudgwrd",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = {
                        "on_spell_taken",
                    },
                    type = "apply_aura",
                },
                key = "tjudaur1",
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
        conditions = {
            {
                auraRef = "b0211ab3:tsealwrd",
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Requires Seal of Warding",
                type = "aura_requirement",
                unit = "caster",
            },
        },
        cooldown = 3,
        cooldownGroup = "judgement",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_holy_righteousfury.blp",
        id = "tjudgwsp",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Judgement of Warding",
        range = 0,
        resourceCosts = {
            {
                amount = 30,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:c3gaf7dd",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Templar",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "b0211ab3:tjudgwrd",
                    datasetId = "b0211ab3",
                    descriptionText = "Reduces Spell Hit Chance by {AURA_STAT_1}.",
                    duration = 2,
                    icon = "interface/icons/spell_holy_righteousfury.blp",
                    nameText = "Judgement of Warding",
                    powerLevel = 0,
                    spellDatasetId = "b0211ab3",
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
                    },
                },
            },
            mainText = "Deal {DAMAGE_1} Holy damage to an enemy and apply Judgement of Warding for 2 turns.",
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

### Ardent Defender

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "b0211ab3",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                baseAmount = 25,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:tcn0s8kx",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/spell_holy_divineprotection.blp",
        id = "tarddef1",
        maxStacks = 1,
        name = "Ardent Defender",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Parry Chance by {AURA_STAT_1}.",
            bodyTokens = {
                {
                    applyMode = "stat_amount",
                    baseField = "baseAmount",
                    effectIndex = 1,
                    key = "AURA_STAT_1",
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

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "b0211ab3",
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
                    duration = 1,
                    targetEvents = {  },
                    type = "taunt",
                },
                key = "tardtaun",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 3,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "enemy",
                    type = "multi",
                },
            },
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "b0211ab3:tarddef1",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "tardaur1",
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
        cooldown = 3,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_holy_divineprotection.blp",
        id = "tarddfsp",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Ardent Defender",
        range = 0,
        resourceCosts = {
            {
                amount = 30,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:c3gaf7dd",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Templar",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "b0211ab3:tarddef1",
                    datasetId = "b0211ab3",
                    descriptionText = "Increases Parry Chance by {AURA_STAT_1}.",
                    duration = 1,
                    icon = "interface/icons/spell_holy_divineprotection.blp",
                    nameText = "Ardent Defender",
                    powerLevel = 0,
                    spellDatasetId = "b0211ab3",
                    stacks = 1,
                    targetContext = {
                        object = "you",
                        possessive = "your",
                        reflexive = "yourself",
                        subject = "you",
                    },
                    tokens = {
                        {
                            applyMode = "stat_amount",
                            baseField = "baseAmount",
                            effectIndex = 1,
                            key = "AURA_STAT_1",
                            tokenType = "aura_amount",
                        },
                    },
                },
            },
            mainText = "Taunt up to 3 enemies for 1 turn and apply Ardent Defender to yourself for 1 turn.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Light and Steel

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "b0211ab3",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                baseAmount = 25,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:tcn0s8kx",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/ability_parry.blp",
        id = "tlgtstl1",
        maxStacks = 1,
        name = "Light and Steel",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Parry Chance by {AURA_STAT_1}.",
            bodyTokens = {
                {
                    applyMode = "stat_amount",
                    baseField = "baseAmount",
                    effectIndex = 1,
                    key = "AURA_STAT_1",
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

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "b0211ab3",
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
                    auraRef = "b0211ab3:tlgtstl1",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "tlgtsta1",
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
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_parry.blp",
        id = "tlgtstsp",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Light and Steel",
        range = 0,
        resourceCosts = {
            {
                amount = 30,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:c3gaf7dd",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Templar",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "b0211ab3:tlgtstl1",
                    datasetId = "b0211ab3",
                    descriptionText = "Increases Parry Chance by {AURA_STAT_1}.",
                    duration = 2,
                    icon = "interface/icons/ability_parry.blp",
                    nameText = "Light and Steel",
                    powerLevel = 0,
                    spellDatasetId = "b0211ab3",
                    stacks = 1,
                    targetContext = {
                        object = "you",
                        possessive = "your",
                        reflexive = "yourself",
                        subject = "you",
                    },
                    tokens = {
                        {
                            applyMode = "stat_amount",
                            baseField = "baseAmount",
                            effectIndex = 1,
                            key = "AURA_STAT_1",
                            tokenType = "aura_amount",
                        },
                    },
                },
            },
            mainText = "Apply Light and Steel to yourself for 2 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
