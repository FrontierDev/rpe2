# Druid Spell Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for the Druid class dataset (`6e4d2a91`).

Import each listed **Aura** before its associated **Spell**. These entries use the current RPE2 spell/aura schema, cooldown channels, `raid_marker` targeter and tokenised tooltip system.

## Authoring notes

- Druid uses **Mana** (`f82db71a:4c8mfm99`).
- Main Action = cooldown channel 1; Bonus Action = channel 2; Buff Action = channel 3.
- Balance damage scales from **Spell Power** (`f82db71a:7t7xgzcx`).
- Damage schools used here are Nature (`f82db71a:qtr10qyj`), Arcane (`f82db71a:dtxhglqg`) and Fire (`f82db71a:esjguw6d`).
- **Wrath** intentionally copies the current Priest **Smite** low-threat budget: 70 base damage, 0.70 Spell Power, 0.50 threat coefficient and 5% base Mana, converted from Holy to Nature.
- **Starfire** is the standard one-turn, single-target Main Action DPS budget: 135 base damage + 1.40 Spell Power, 6.8% base Mana.
- **Starsurge** is the standard instant single-target Bonus Action DPS budget: 65 base damage + 0.65 Spell Power, 0.75 threat coefficient, 6.3% base Mana.
- **Moonfire** and **Sunfire** have two independently useful numerical outputs, so both direct and periodic components use the 0.85 secondary-effect modifier. Direct damage is 55.25 + 0.5525 Spell Power; the 5-turn DoT is 17.68 + 0.884 Spell Power per turn. Each costs 6.3% base Mana.
- **Thorns** is reactive and therefore is not forced through the direct/periodic calculator. Its reactive damage copies the current **Molten Armor** event budget (28.1667 + 0.845 Spell Power), converted to Nature. The fixed +8% Threat Generated effect does not rank-scale; reactive damage does. It responds to auto attacks, melee abilities, ranged abilities and spell attacks so the authored wording "attackers" is implemented literally.
- **Thorns** uses the current 5% base-Mana utility/reactive-buff convention, lasts 10 turns, uses Buff Action and has the requested 1-turn personal cooldown.
- **Entangling Roots** copies the current Polymorph/Freezing-Trap control shape but does **not** prevent spellcasting: it breaks on damage, sets movement range to 0 and causes attacks against the target to automatically hit. It costs 5% base Mana.
- **Solar Beam** uses the implemented `raid_marker` targeter with `maxTargets = 5`. Control-only mechanics are outside the numerical output calculator; its 18.1% base-Mana cost follows the current multi-target control analogue (Psychic Scream), while keeping the requested Bonus Action channel, 1-turn duration and 10-turn cooldown.
- Damage-bearing spells and damaging auras use the standard 8-level rank interval. Pure control effects do not use ranks.

## Balance

### Wrath

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "6e4d2a91",
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
                                                            baseDamage = 70,
                                                            damageSchoolRefs = {
                                                                                    "f82db71a:qtr10qyj",
                                                                                },
                                                            damageType = "spell",
                                                            hitType = "ability",
                                                            projectilePath = "",
                                                            projectileSpeed = 0,
                                                            statScaling = {
                                                                                    {
                                                                                                                coefficient = 0.7,
                                                                                                                statRef = "f82db71a:7t7xgzcx",
                                                                                                            },
                                                                                },
                                                            targetEvents = {
                                                                                    "on_spell_taken",
                                                                                    "on_critical_hit_taken",
                                                                                },
                                                            threatCoefficient = 0.5,
                                                            type = "damage",
                                                            usesProjectile = false,
                                                            weaponDamageCoefficient = 0,
                                                            weaponDamageMode = "none",
                                                        },
                                        key = "wrthdmg1",
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
            icon = "interface/icons/spell_nature_abolishmagic.blp",
            id = "drwrth01",
            cooldownChannel = 1,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = true,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Wrath",
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
            seedNPCSpell = false,
            spellbookCategory = "Balance",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {  },
                        mainText = "Deal {DAMAGE_1} Nature damage to an enemy. Generates a low amount of threat.",
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

### Starfire

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "6e4d2a91",
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
                                                                                    "f82db71a:dtxhglqg",
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
                                        key = "stfrdmg1",
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
            icon = "interface/icons/spell_arcane_starfire.blp",
            id = "drstarf1",
            cooldownChannel = 1,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = true,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Starfire",
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
            seedNPCSpell = false,
            spellbookCategory = "Balance",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {  },
                        mainText = "Deal {DAMAGE_1} Arcane damage to an enemy.",
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

### Starsurge

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "6e4d2a91",
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
                                                            baseDamage = 65,
                                                            damageSchoolRefs = {
                                                                                    "f82db71a:dtxhglqg",
                                                                                },
                                                            damageType = "spell",
                                                            hitType = "ability",
                                                            projectilePath = "",
                                                            projectileSpeed = 0,
                                                            statScaling = {
                                                                                    {
                                                                                                                coefficient = 0.65,
                                                                                                                statRef = "f82db71a:7t7xgzcx",
                                                                                                            },
                                                                                },
                                                            targetEvents = {
                                                                                    "on_spell_taken",
                                                                                    "on_critical_hit_taken",
                                                                                },
                                                            threatCoefficient = 0.75,
                                                            type = "damage",
                                                            usesProjectile = false,
                                                            weaponDamageCoefficient = 0,
                                                            weaponDamageMode = "none",
                                                        },
                                        key = "stsrdmg1",
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
            icon = "interface/icons/spell_arcane_arcane03.blp",
            id = "drstars1",
            cooldownChannel = 2,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = true,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Starsurge",
            range = 0,
            resourceCosts = {
                        {
                                        amount = 6.3,
                                        amountMode = "base_percent",
                                        castPhase = "on_cast_end",
                                        refundOnInterrupt = 0,
                                        resourceRef = "f82db71a:4c8mfm99",
                                    },
                    },
            seedNPCSpell = false,
            spellbookCategory = "Balance",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {  },
                        mainText = "Deal {DAMAGE_1} Arcane damage to an enemy.",
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

### Moonfire

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "6e4d2a91",
    entry = {
            description = "",
            duration = 5,
            effects = {
                        {
                                        amountMode = "flat",
                                        baseDamage = 17.68,
                                        damageSchoolRefs = {
                                                            "f82db71a:dtxhglqg",
                                                        },
                                        statScaling = {
                                                            {
                                                                                    coefficient = 0.884,
                                                                                    statRef = "f82db71a:7t7xgzcx",
                                                                                },
                                                        },
                                        type = "damage",
                                    },
                    },
            events = {  },
            icon = "interface/icons/spell_nature_starfall.blp",
            id = "drmnaur1",
            maxStacks = 1,
            name = "Moonfire",
            stackBehavior = "refresh_duration",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        bodyText = "Deals {AURA_DAMAGE_1} Arcane damage each turn.",
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

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "6e4d2a91",
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
                                                            applyAura = true,
                                                            auraRef = "6e4d2a91:drmnaur1",
                                                            auraStacks = 1,
                                                            baseDamage = 55.25,
                                                            damageSchoolRefs = {
                                                                                    "f82db71a:dtxhglqg",
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
                                                            threatCoefficient = 0.75,
                                                            type = "damage",
                                                            usesProjectile = false,
                                                            weaponDamageCoefficient = 0,
                                                            weaponDamageMode = "none",
                                                        },
                                        key = "mnfrdmg1",
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
            icon = "interface/icons/spell_nature_starfall.blp",
            id = "drmnfr01",
            cooldownChannel = 2,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = true,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Moonfire",
            range = 0,
            resourceCosts = {
                        {
                                        amount = 6.3,
                                        amountMode = "base_percent",
                                        castPhase = "on_cast_end",
                                        refundOnInterrupt = 0,
                                        resourceRef = "f82db71a:4c8mfm99",
                                    },
                    },
            seedNPCSpell = false,
            spellbookCategory = "Balance",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {
                                        {
                                                            auraRef = "6e4d2a91:drmnaur1",
                                                            datasetId = "6e4d2a91",
                                                            descriptionText = "Deals {AURA_DAMAGE_1} Arcane damage each turn.",
                                                            duration = 5,
                                                            icon = "interface/icons/spell_nature_starfall.blp",
                                                            nameText = "Moonfire",
                                                            powerLevel = 0,
                                                            spellDatasetId = "6e4d2a91",
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
                        mainText = "Deal {DAMAGE_1} Arcane damage to an enemy and apply Moonfire for 5 turns.",
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

### Sunfire

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "6e4d2a91",
    entry = {
            description = "",
            duration = 5,
            effects = {
                        {
                                        amountMode = "flat",
                                        baseDamage = 17.68,
                                        damageSchoolRefs = {
                                                            "f82db71a:esjguw6d",
                                                        },
                                        statScaling = {
                                                            {
                                                                                    coefficient = 0.884,
                                                                                    statRef = "f82db71a:7t7xgzcx",
                                                                                },
                                                        },
                                        type = "damage",
                                    },
                    },
            events = {  },
            icon = "interface/icons/ability_mage_firestarter.blp",
            id = "drsnaur1",
            maxStacks = 1,
            name = "Sunfire",
            stackBehavior = "refresh_duration",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        bodyText = "Deals {AURA_DAMAGE_1} Fire damage each turn.",
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

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "6e4d2a91",
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
                                                            applyAura = true,
                                                            auraRef = "6e4d2a91:drsnaur1",
                                                            auraStacks = 1,
                                                            baseDamage = 55.25,
                                                            damageSchoolRefs = {
                                                                                    "f82db71a:esjguw6d",
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
                                                            threatCoefficient = 0.75,
                                                            type = "damage",
                                                            usesProjectile = false,
                                                            weaponDamageCoefficient = 0,
                                                            weaponDamageMode = "none",
                                                        },
                                        key = "snfrdmg1",
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
            icon = "interface/icons/ability_mage_firestarter.blp",
            id = "drsnfr01",
            cooldownChannel = 2,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = true,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Sunfire",
            range = 0,
            resourceCosts = {
                        {
                                        amount = 6.3,
                                        amountMode = "base_percent",
                                        castPhase = "on_cast_end",
                                        refundOnInterrupt = 0,
                                        resourceRef = "f82db71a:4c8mfm99",
                                    },
                    },
            seedNPCSpell = false,
            spellbookCategory = "Balance",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {
                                        {
                                                            auraRef = "6e4d2a91:drsnaur1",
                                                            datasetId = "6e4d2a91",
                                                            descriptionText = "Deals {AURA_DAMAGE_1} Fire damage each turn.",
                                                            duration = 5,
                                                            icon = "interface/icons/ability_mage_firestarter.blp",
                                                            nameText = "Sunfire",
                                                            powerLevel = 0,
                                                            spellDatasetId = "6e4d2a91",
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
                        mainText = "Deal {DAMAGE_1} Fire damage to an enemy and apply Sunfire for 5 turns.",
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

### Thorns

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "6e4d2a91",
    entry = {
            description = "",
            duration = 10,
            effects = {
                        {
                                        baseAmount = 8,
                                        operation = "flat",
                                        scaleWithRank = false,
                                        statRef = "f82db71a:j8n012e6",
                                        statScaling = {  },
                                        type = "stat",
                                    },
                    },
            events = {
                        {
                                        combatEventId = "on_auto_attack_taken",
                                        effects = {
                                                            {
                                                                                    amountMode = "flat",
                                                                                    baseDamage = 28.1667,
                                                                                    damageSchoolRefs = {
                                                                                                                "f82db71a:qtr10qyj",
                                                                                                            },
                                                                                    scaleWithRank = true,
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
                                        combatEventId = "on_melee_taken",
                                        effects = {
                                                            {
                                                                                    amountMode = "flat",
                                                                                    baseDamage = 28.1667,
                                                                                    damageSchoolRefs = {
                                                                                                                "f82db71a:qtr10qyj",
                                                                                                            },
                                                                                    scaleWithRank = true,
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
                                        combatEventId = "on_ranged_taken",
                                        effects = {
                                                            {
                                                                                    amountMode = "flat",
                                                                                    baseDamage = 28.1667,
                                                                                    damageSchoolRefs = {
                                                                                                                "f82db71a:qtr10qyj",
                                                                                                            },
                                                                                    scaleWithRank = true,
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
                                        combatEventId = "on_spell_taken",
                                        effects = {
                                                            {
                                                                                    amountMode = "flat",
                                                                                    baseDamage = 28.1667,
                                                                                    damageSchoolRefs = {
                                                                                                                "f82db71a:qtr10qyj",
                                                                                                            },
                                                                                    scaleWithRank = true,
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
                    },
            icon = "interface/icons/spell_nature_thorns.blp",
            id = "drthaur1",
            maxStacks = 1,
            name = "Thorns",
            stackBehavior = "refresh_duration",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        bodyText = "Increases Threat Generated by 8%. When the affected unit is attacked, deal {AURA_EVENT_DAMAGE_1} Nature damage to the attacker.",
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
    datasetId = "6e4d2a91",
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
                                                            auraRef = "6e4d2a91:drthaur1",
                                                            basePower = 0,
                                                            duration = 10,
                                                            stacks = 1,
                                                            targetEvents = {  },
                                                            type = "apply_aura",
                                                        },
                                        key = "thrnapp1",
                                        target = {
                                                            allowDeadTargets = false,
                                                            disableSelfCast = false,
                                                            maxTargets = 1,
                                                            minTargets = 1,
                                                            requiresTarget = true,
                                                            targetDisposition = "ally",
                                                            type = "single",
                                                        },
                                    },
                    },
            conditions = {  },
            cooldown = 1,
            cooldownGroup = "",
            cooldownScalesWithHaste = false,
            description = "",
            icon = "interface/icons/spell_nature_thorns.blp",
            id = "drthrn01",
            cooldownChannel = 3,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = true,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Thorns",
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
            seedNPCSpell = false,
            spellbookCategory = "Balance",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {
                                        {
                                                            auraRef = "6e4d2a91:drthaur1",
                                                            datasetId = "6e4d2a91",
                                                            descriptionText = "Increases Threat Generated by 8%. When the affected unit is attacked, deal {AURA_EVENT_DAMAGE_1} Nature damage to the attacker.",
                                                            duration = 10,
                                                            icon = "interface/icons/spell_nature_thorns.blp",
                                                            nameText = "Thorns",
                                                            powerLevel = 0,
                                                            spellDatasetId = "6e4d2a91",
                                                            stacks = 1,
                                                            targetContext = {
                                                                                    object = "the affected ally",
                                                                                    possessive = "the affected ally's",
                                                                                    reflexive = "itself",
                                                                                    subject = "the affected ally",
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
                        mainText = "Apply Thorns to an ally for 10 turns.",
                        tokens = {  },
                        version = 1,
                    },
            totalTicks = 0,
            useCooldownCharges = false,
        },
}
```

### Entangling Roots

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "6e4d2a91",
    entry = {
            description = "",
            duration = 1,
            effects = {
                        {
                                        cancelOnDamage = true,
                                        forceAutoHitAgainstTarget = true,
                                        movementRangeOverride = 0,
                                        preventCasting = false,
                                        statScaling = {  },
                                        type = "control",
                                    },
                    },
            events = {  },
            icon = "interface/icons/spell_nature_stranglevines.blp",
            id = "dreroot1",
            maxStacks = 1,
            name = "Entangling Roots",
            stackBehavior = "refresh_duration",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        bodyText = "Breaks when the affected unit takes damage. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                        bodyTokens = {  },
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
    datasetId = "6e4d2a91",
    entry = {
            allowDeadTargets = false,
            canMoveWhileCasting = false,
            castTime = 1,
            casterEvents = {  },
            charges = 0,
            components = {
                        {
                                        castPhase = "on_cast_end",
                                        castingGroup = "default",
                                        effect = {
                                                            auraRef = "6e4d2a91:dreroot1",
                                                            basePower = 0,
                                                            duration = 1,
                                                            stacks = 1,
                                                            targetEvents = {  },
                                                            type = "apply_aura",
                                                        },
                                        key = "rootapp1",
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
            cooldown = 3,
            cooldownGroup = "",
            cooldownScalesWithHaste = false,
            description = "",
            icon = "interface/icons/spell_nature_stranglevines.blp",
            id = "drroot01",
            cooldownChannel = 1,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = false,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Entangling Roots",
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
            seedNPCSpell = false,
            spellbookCategory = "Balance",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {
                                        {
                                                            auraRef = "6e4d2a91:dreroot1",
                                                            datasetId = "6e4d2a91",
                                                            descriptionText = "Breaks when the affected unit takes damage. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                                                            duration = 1,
                                                            icon = "interface/icons/spell_nature_stranglevines.blp",
                                                            nameText = "Entangling Roots",
                                                            powerLevel = 0,
                                                            spellDatasetId = "6e4d2a91",
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
                        mainText = "Apply Entangling Roots to an enemy for 1 turn.",
                        tokens = {  },
                        version = 1,
                    },
            totalTicks = 0,
            useCooldownCharges = false,
        },
}
```

### Solar Beam

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "6e4d2a91",
    entry = {
            description = "",
            duration = 1,
            effects = {
                        {
                                        cancelOnDamage = false,
                                        forceAutoHitAgainstTarget = false,
                                        preventCasting = true,
                                        statScaling = {  },
                                        type = "control",
                                    },
                    },
            events = {  },
            icon = "interface/icons/ability_vehicle_sonicshockwave.blp",
            id = "drsolaru",
            maxStacks = 1,
            name = "Solar Beam",
            stackBehavior = "refresh_duration",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        bodyText = "Prevents the affected unit from casting spells.",
                        bodyTokens = {  },
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
    datasetId = "6e4d2a91",
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
                                                            auraRef = "6e4d2a91:drsolaru",
                                                            basePower = 0,
                                                            duration = 1,
                                                            stacks = 1,
                                                            targetEvents = {  },
                                                            type = "apply_aura",
                                                        },
                                        key = "solrapp1",
                                        target = {
                                                            allowDeadTargets = false,
                                                            disableSelfCast = false,
                                                            maxTargets = 5,
                                                            minTargets = 1,
                                                            requiresTarget = true,
                                                            targetDisposition = "enemy",
                                                            type = "raid_marker",
                                                        },
                                    },
                    },
            conditions = {  },
            cooldown = 10,
            cooldownGroup = "",
            cooldownScalesWithHaste = false,
            description = "",
            icon = "interface/icons/ability_vehicle_sonicshockwave.blp",
            id = "drsolar1",
            cooldownChannel = 2,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = false,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Solar Beam",
            range = 0,
            resourceCosts = {
                        {
                                        amount = 18.1,
                                        amountMode = "base_percent",
                                        castPhase = "on_cast_end",
                                        refundOnInterrupt = 0,
                                        resourceRef = "f82db71a:4c8mfm99",
                                    },
                    },
            seedNPCSpell = false,
            spellbookCategory = "Balance",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {
                                        {
                                                            auraRef = "6e4d2a91:drsolaru",
                                                            datasetId = "6e4d2a91",
                                                            descriptionText = "Prevents the affected unit from casting spells.",
                                                            duration = 1,
                                                            icon = "interface/icons/ability_vehicle_sonicshockwave.blp",
                                                            nameText = "Solar Beam",
                                                            powerLevel = 0,
                                                            spellDatasetId = "6e4d2a91",
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
                        mainText = "Apply Solar Beam to up to 5 enemies on the same raid marker for 1 turn.",
                        tokens = {  },
                        version = 1,
                    },
            totalTicks = 0,
            useCooldownCharges = false,
        },
}
```

