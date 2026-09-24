# Druid Spell Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for the Druid class dataset (`6e4d2a91`).

Import each listed **Aura** before its associated **Spell**. These entries use the current RPE2 spell/aura schema, cooldown channels, `raid_marker` targeter and tokenised tooltip system.

## Authoring notes

- Balance Druid uses **Mana** (`f82db71a:4c8mfm99`); the Feral abilities in this document use **Energy** (`f82db71a:c3gaf7dd`) where applicable.
- Main Action = cooldown channel 1; Bonus Action = channel 2; Buff Action = channel 3.
- Balance damage scales from **Spell Power** (`f82db71a:7t7xgzcx`).
- Damage schools used here are Nature (`f82db71a:qtr10qyj`), Arcane (`f82db71a:dtxhglqg`) and Fire (`f82db71a:esjguw6d`).
- **Wrath** intentionally copies the current Priest **Smite** low-threat budget: 70 base damage, 0.70 Spell Power, 0.50 threat coefficient and 5% base Mana, converted from Holy to Nature.
- **Starfire** is the standard one-turn, single-target Main Action DPS budget: 135 base damage + 1.40 Spell Power, 6.8% base Mana.
- **Starsurge** is the standard instant single-target Bonus Action DPS budget: 65 base damage + 0.65 Spell Power, 0.75 threat coefficient, 6.3% base Mana.
- **Moonfire** and **Sunfire** have two independently useful numerical outputs. Their direct component remains the secondary-output Bonus Action budget at 55.25 + 0.5525 Spell Power. Their 5-turn periodic component remains 17.68 base damage per turn, but its authored per-tick coefficient follows the corrected hybrid-DoT convention and current Fireball DoT reference: **0.22 Spell Power per turn** (1.10 Spell Power over five ticks). Each costs 6.3% base Mana.
- **Thorns** is reactive and therefore is not forced through the direct/periodic calculator. Its reactive damage copies the current **Molten Armor** event budget (28.1667 + 0.845 Spell Power), converted to Nature. The fixed +8% Threat Generated effect does not rank-scale; reactive damage does. Use `on_melee_taken`, `on_ranged_taken` and `on_spell_taken`. Do **not** also register `on_auto_attack_taken`: current combat-event filtering treats a melee auto attack as both `hitType = "auto"` and `attackType = "melee"`, so registering both would retaliate twice against the same melee auto attack.
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
                                                                                    coefficient = 0.22,
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
                                                                                    coefficient = 0.22,
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

## Feral

### Energy-cost notes

The Feral abilities below use the requested WoW Classic Energy costs rather than the RPE calculator's generated Energy costs. Their damage/effect budgets still follow the current RPE2 spell-authoring specification or the explicitly named current RPE analogue.

| Spell | Energy cost | RPE implementation basis |
|---|---:|---|
| Prowl | 0 | Copy Rogue Stealth; Classic Prowl has no Energy cost. |
| Pounce | 50 | Bonus Action stealth opener; 1-turn stun, direct Physical damage, 2 Combo Points. |
| Rake | 40 | Rend-like 5-turn bleed plus 1 Combo Point. |
| Shred | 60 | Copy current Rogue Backstab damage shape; 2 Combo Points. |
| Ferocious Bite | 35 | Copy current Rogue Eviscerate; consumes 5 Combo Points. |
| Claw | 45 | Copy current Rogue Sinister Strike; 1 Combo Point. |
| Rip | 30 | Copy current Rogue Rupture; consumes 5 Combo Points. |
| Tiger's Fury | 30 | Fixed +30% Melee Attack Power for 1 turn; Buff Action. |
| Ravage | 60 | Copy current Rogue Ambush; requires Prowl and generates 2 Combo Points. |
| Swipe | 50 | Copy current Warrior Cleave; Cat-form Energy cost uses the WoW Classic Season of Discovery Cat Swipe because original vanilla Cat Form had no Energy-based Swipe. |

Authoring details:

- Energy: `f82db71a:c3gaf7dd`; Combo Points: `f82db71a:1h7yfxff`; Melee Attack Power: `f82db71a:u7b49vs9`.
- Prowl copies the current Rogue Stealth runtime shape exactly: self-hide, Buff Action, 10-turn RPE cooldown, and no resource cost.
- Pounce uses the current hidden-caster condition used by Ambush. Its direct weapon-attack output uses the Bonus Action budget with the 0.85 secondary-effect modifier: 41.4375 flat + 0.1934 Melee Attack Power + 0.5525 main-hand weapon damage. The stun is 1 turn and the spell generates the requested 2 Combo Points.
- Rake has no separate upfront damage component: it applies a Rend-like 5-turn bleed and generates 1 Combo Point. The flat periodic base remains the 0.85 secondary-output version of Rend at 17.68 per turn. Under the corrected per-tick DoT convention, current Rend is 0.15 Melee Attack Power per turn; applying the same 0.85 secondary-output allowance gives Rake **0.1275 Melee Attack Power per turn** (0.6375 over five ticks).
- Shred, Ferocious Bite, Claw, Rip, Ravage and Swipe intentionally copy the current RPE analogue's numerical damage/effect shape. In particular, **Rip now follows the current Rupture periodic coefficient of 0.20 Melee Attack Power per turn**, not the superseded 0.364 value. Only the icon/name/category, explicit Druid mechanics, and requested Classic Energy costs are changed.
- Shred and Ravage generate 2 Combo Points in this RPE design. This is deliberate and follows the requested design/current RPE analogue rather than original Classic's combo-point award.
- Ferocious Bite and Rip follow the current RPE finisher convention and consume 5 Combo Points.
- Tiger's Fury is a fixed percentage buff and therefore does not scale with spell rank.

### Prowl

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
            canTargetHiddenUnits = false,
            castTime = 0,
            casterEvents = {  },
            charges = 0,
            components = {
                        {
                                        castPhase = "on_cast_end",
                                        castingGroup = "default",
                                        effect = {
                                                            targetEvents = {  },
                                                            type = "hide",
                                                        },
                                        key = "prowlhd1",
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
            cooldown = 10,
            cooldownGroup = "",
            cooldownScalesWithHaste = false,
            description = "",
            doesNotRevealCaster = true,
            icon = "interface/icons/ability_ambush.blp",
            id = "drprowl1",
            cooldownChannel = 3,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = false,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Prowl",
            range = 0,
            resourceCosts = {  },
            seedNPCSpell = false,
            spellbookCategory = "Feral",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {  },
                        mainText = "Hide yourself.",
                        tokens = {  },
                        version = 1,
                    },
            totalTicks = 0,
            useCooldownCharges = false,
        },
}
```

### Pounce

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
                                        forceAutoHitAgainstTarget = true,
                                        movementRangeOverride = 0,
                                        preventCasting = true,
                                        statScaling = {  },
                                        type = "control",
                                    },
                    },
            events = {  },
            icon = "interface/icons/ability_druid_supriseattack.blp",
            id = "drpncau1",
            maxStacks = 1,
            name = "Pounce",
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
            canTargetHiddenUnits = false,
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
                                                            auraStacks = 1,
                                                            baseDamage = 41.4375,
                                                            damageSchoolRefs = {
                                                                                    "f82db71a:v1azo4j6",
                                                                                },
                                                            damageType = "melee",
                                                            hitType = "ability",
                                                            projectilePath = "",
                                                            projectileSpeed = 0,
                                                            statScaling = {
                                                                                    {
                                                                                                                coefficient = 0.1934,
                                                                                                                statRef = "f82db71a:u7b49vs9",
                                                                                                            },
                                                                                },
                                                            targetEvents = {
                                                                                    "on_melee_taken",
                                                                                    "on_critical_hit_taken",
                                                                                },
                                                            threatCoefficient = 0.75,
                                                            type = "damage",
                                                            usesProjectile = false,
                                                            weaponDamageCoefficient = 0.5525,
                                                            weaponDamageMode = "main_hand",
                                                            auraRef = "6e4d2a91:drpncau1",
                                                        },
                                        key = "pouncedm",
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
                                                            amount = 2,
                                                            amountMode = "flat",
                                                            resourceRef = "f82db71a:1h7yfxff",
                                                            targetEvents = {  },
                                                            type = "resource",
                                                        },
                                        key = "pouncecp",
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
                                        tooltipTextOverride = "Requires Prowl",
                                        type = "hidden",
                                        unit = "caster",
                                    },
                    },
            cooldown = 0,
            cooldownGroup = "stun",
            cooldownScalesWithHaste = false,
            description = "",
            doesNotRevealCaster = false,
            icon = "interface/icons/ability_druid_supriseattack.blp",
            id = "drpounc1",
            cooldownChannel = 2,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = true,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Pounce",
            range = 0,
            resourceCosts = {
                        {
                                        amount = 50,
                                        amountMode = "flat",
                                        castPhase = "on_cast_end",
                                        refundOnInterrupt = 0,
                                        resourceRef = "f82db71a:c3gaf7dd",
                                    },
                    },
            seedNPCSpell = false,
            spellbookCategory = "Feral",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {
                                        {
                                                            auraRef = "6e4d2a91:drpncau1",
                                                            datasetId = "6e4d2a91",
                                                            descriptionText = "Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                                                            duration = 1,
                                                            icon = "interface/icons/ability_druid_supriseattack.blp",
                                                            nameText = "Pounce",
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
                        mainText = "Deal {DAMAGE_1} Physical damage to an enemy, stun it for 1 turn, and restore {RESOURCE_AMOUNT_1} to yourself.",
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
            useCooldownCharges = false,
        },
}
```

### Rake

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
                                                            "f82db71a:v1azo4j6",
                                                        },
                                        statScaling = {
                                                            {
                                                                                    coefficient = 0.1275,
                                                                                    statRef = "f82db71a:u7b49vs9",
                                                                                },
                                                        },
                                        type = "damage",
                                    },
                    },
            events = {  },
            icon = "interface/icons/ability_druid_disembowel.blp",
            id = "drrakea1",
            maxStacks = 1,
            name = "Rake",
            stackBehavior = "refresh_duration",
            tags = {  },
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
                        "on_melee_hit",
                        "on_critical_hit",
                    },
            charges = 0,
            components = {
                        {
                                        castPhase = "on_cast_end",
                                        castingGroup = "default",
                                        effect = {
                                                            auraRef = "6e4d2a91:drrakea1",
                                                            basePower = 0,
                                                            duration = 5,
                                                            stacks = 1,
                                                            targetEvents = {
                                                                                    "on_melee_taken",
                                                                                    "on_critical_hit_taken",
                                                                                },
                                                            type = "apply_aura",
                                                        },
                                        key = "rakeaur1",
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
                                                            resourceRef = "f82db71a:1h7yfxff",
                                                            targetEvents = {  },
                                                            type = "resource",
                                                        },
                                        key = "rakecp01",
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
            icon = "interface/icons/ability_druid_disembowel.blp",
            id = "drrake01",
            cooldownChannel = 2,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = true,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Rake",
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
            spellbookCategory = "Feral",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {
                                        {
                                                            auraRef = "6e4d2a91:drrakea1",
                                                            datasetId = "6e4d2a91",
                                                            descriptionText = "Deals {AURA_DAMAGE_1} Physical damage each turn.",
                                                            duration = 5,
                                                            icon = "interface/icons/ability_druid_disembowel.blp",
                                                            nameText = "Rake",
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
                        mainText = "Apply Rake to an enemy for 5 turns and restore {RESOURCE_AMOUNT_1} to yourself.",
                        tokens = {
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
            useCooldownCharges = false,
        },
}
```

### Shred

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
                                                            baseDamage = 63.75,
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
                                                            weaponDamageCoefficient = 0.85,
                                                            weaponDamageMode = "main_hand",
                                                        },
                                        key = "shreddm",
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
                                                            amount = 2,
                                                            amountMode = "flat",
                                                            resourceRef = "f82db71a:1h7yfxff",
                                                            targetEvents = {  },
                                                            type = "resource",
                                                        },
                                        key = "shredcp",
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
            icon = "interface/icons/spell_shadow_vampiricaura.blp",
            id = "drshred1",
            cooldownChannel = 1,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = true,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Shred",
            range = 0,
            resourceCosts = {
                        {
                                        amount = 60,
                                        amountMode = "flat",
                                        castPhase = "on_cast_end",
                                        refundOnInterrupt = 0,
                                        resourceRef = "f82db71a:c3gaf7dd",
                                    },
                    },
            seedNPCSpell = false,
            spellbookCategory = "Feral",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {  },
                        mainText = "Deal {DAMAGE_1} Physical damage to an enemy. Restore {RESOURCE_AMOUNT_1} to yourself.",
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
            useCooldownCharges = false,
        },
}
```

### Ferocious Bite

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
                                                            baseDamage = 225,
                                                            damageSchoolRefs = {
                                                                                    "f82db71a:v1azo4j6",
                                                                                },
                                                            damageType = "melee",
                                                            hitType = "ability",
                                                            projectilePath = "",
                                                            projectileSpeed = 0,
                                                            statScaling = {
                                                                                    {
                                                                                                                coefficient = 0.7875,
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
                                        key = "fbitedmg",
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
            icon = "interface/icons/ability_druid_ferociousbite.blp",
            id = "drfbite1",
            cooldownChannel = 2,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = true,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Ferocious Bite",
            range = 0,
            resourceCosts = {
                        {
                                        amount = 35,
                                        amountMode = "flat",
                                        castPhase = "on_cast_end",
                                        refundOnInterrupt = 0,
                                        resourceRef = "f82db71a:c3gaf7dd",
                                    },
                        {
                                        amount = 5,
                                        amountMode = "flat",
                                        castPhase = "on_cast_end",
                                        refundOnInterrupt = 0,
                                        resourceRef = "f82db71a:1h7yfxff",
                                    },
                    },
            seedNPCSpell = false,
            spellbookCategory = "Feral",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {  },
                        mainText = "Deal {DAMAGE_1} Physical damage to an enemy.",
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

### Claw

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
                                                            baseDamage = 63.75,
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
                                                            weaponDamageCoefficient = 0.85,
                                                            weaponDamageMode = "main_hand",
                                                        },
                                        key = "clawdm",
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
                                                            resourceRef = "f82db71a:1h7yfxff",
                                                            targetEvents = {  },
                                                            type = "resource",
                                                        },
                                        key = "clawcp",
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
            icon = "interface/icons/ability_druid_rake.blp",
            id = "drclaw01",
            cooldownChannel = 1,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = true,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Claw",
            range = 0,
            resourceCosts = {
                        {
                                        amount = 45,
                                        amountMode = "flat",
                                        castPhase = "on_cast_end",
                                        refundOnInterrupt = 0,
                                        resourceRef = "f82db71a:c3gaf7dd",
                                    },
                    },
            seedNPCSpell = false,
            spellbookCategory = "Feral",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {  },
                        mainText = "Deal {DAMAGE_1} Physical damage to an enemy. Restore {RESOURCE_AMOUNT_1} to yourself.",
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
            useCooldownCharges = false,
        },
}
```

### Rip

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
                                        baseDamage = 20.8,
                                        damageSchoolRefs = {
                                                            "f82db71a:v1azo4j6",
                                                        },
                                        statScaling = {
                                                            {
                                                                                    coefficient = 0.2,
                                                                                    statRef = "f82db71a:u7b49vs9",
                                                                                },
                                                        },
                                        type = "damage",
                                    },
                    },
            events = {  },
            icon = "interface/icons/ability_ghoulfrenzy.blp",
            id = "drripau1",
            maxStacks = 1,
            name = "Rip",
            stackBehavior = "refresh_duration",
            tags = {  },
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
                        "on_melee_hit",
                        "on_critical_hit",
                    },
            charges = 0,
            components = {
                        {
                                        castPhase = "on_cast_end",
                                        castingGroup = "default",
                                        effect = {
                                                            auraRef = "6e4d2a91:drripau1",
                                                            basePower = 0,
                                                            duration = 5,
                                                            stacks = 1,
                                                            targetEvents = {
                                                                                    "on_melee_taken",
                                                                                    "on_critical_hit_taken",
                                                                                },
                                                            type = "apply_aura",
                                                        },
                                        key = "ripaur01",
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
            id = "drrip001",
            cooldownChannel = 2,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = true,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Rip",
            range = 0,
            resourceCosts = {
                        {
                                        amount = 30,
                                        amountMode = "flat",
                                        castPhase = "on_cast_end",
                                        refundOnInterrupt = 0,
                                        resourceRef = "f82db71a:c3gaf7dd",
                                    },
                        {
                                        amount = 5,
                                        amountMode = "flat",
                                        castPhase = "on_cast_end",
                                        refundOnInterrupt = 0,
                                        resourceRef = "f82db71a:1h7yfxff",
                                    },
                    },
            seedNPCSpell = false,
            spellbookCategory = "Feral",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {
                                        {
                                                            auraRef = "6e4d2a91:drripau1",
                                                            datasetId = "6e4d2a91",
                                                            descriptionText = "Deals {AURA_DAMAGE_1} Physical damage each turn.",
                                                            duration = 5,
                                                            icon = "interface/icons/ability_ghoulfrenzy.blp",
                                                            nameText = "Rip",
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
                        mainText = "Apply Rip to an enemy for 5 turns.",
                        tokens = {  },
                        version = 1,
                    },
            totalTicks = 0,
            useCooldownCharges = false,
        },
}
```

### Tiger's Fury

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
                                        baseAmount = 30,
                                        operation = "percent",
                                        scaleWithRank = false,
                                        statRef = "f82db71a:u7b49vs9",
                                        statScaling = {  },
                                        type = "stat",
                                    },
                    },
            events = {  },
            icon = "interface/icons/ability_mount_jungletiger.blp",
            id = "drtgfra1",
            maxStacks = 1,
            name = "Tiger's Fury",
            stackBehavior = "refresh_duration",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        bodyText = "Increases Melee Attack Power by 30%.",
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
                                                            auraRef = "6e4d2a91:drtgfra1",
                                                            basePower = 0,
                                                            duration = 1,
                                                            stacks = 1,
                                                            targetEvents = {  },
                                                            type = "apply_aura",
                                                        },
                                        key = "tgrfapp1",
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
            doesNotRevealCaster = true,
            icon = "interface/icons/ability_mount_jungletiger.blp",
            id = "drtgfry1",
            cooldownChannel = 3,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = false,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Tiger's Fury",
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
            spellbookCategory = "Feral",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {
                                        {
                                                            auraRef = "6e4d2a91:drtgfra1",
                                                            datasetId = "6e4d2a91",
                                                            descriptionText = "Increases Melee Attack Power by 30%.",
                                                            duration = 1,
                                                            icon = "interface/icons/ability_mount_jungletiger.blp",
                                                            nameText = "Tiger's Fury",
                                                            powerLevel = 0,
                                                            spellDatasetId = "6e4d2a91",
                                                            stacks = 1,
                                                            targetContext = {
                                                                                    object = "you",
                                                                                    possessive = "your",
                                                                                    reflexive = "yourself",
                                                                                    subject = "you",
                                                                                },
                                                            tokens = {  },
                                                        },
                                    },
                        mainText = "Apply Tiger's Fury to yourself for 1 turn.",
                        tokens = {  },
                        version = 1,
                    },
            totalTicks = 0,
            useCooldownCharges = false,
        },
}
```

### Ravage

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
                                                            baseDamage = 143.438,
                                                            damageSchoolRefs = {
                                                                                    "f82db71a:v1azo4j6",
                                                                                },
                                                            damageType = "melee",
                                                            hitType = "ability",
                                                            projectilePath = "",
                                                            projectileSpeed = 0,
                                                            statScaling = {
                                                                                    {
                                                                                                                coefficient = 0.6694,
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
                                                            weaponDamageCoefficient = 1.9125,
                                                            weaponDamageMode = "main_hand",
                                                        },
                                        key = "ravagedm",
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
                                                            amount = 2,
                                                            amountMode = "flat",
                                                            resourceRef = "f82db71a:1h7yfxff",
                                                            targetEvents = {  },
                                                            type = "resource",
                                                        },
                                        key = "ravagecp",
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
                                        tooltipTextOverride = "Requires Prowl",
                                        type = "hidden",
                                        unit = "caster",
                                    },
                    },
            cooldown = 0,
            cooldownGroup = "",
            cooldownScalesWithHaste = false,
            description = "",
            icon = "interface/icons/ability_druid_ravage.blp",
            id = "drravge1",
            cooldownChannel = 1,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = true,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Ravage",
            range = 0,
            resourceCosts = {
                        {
                                        amount = 60,
                                        amountMode = "flat",
                                        castPhase = "on_cast_end",
                                        refundOnInterrupt = 0,
                                        resourceRef = "f82db71a:c3gaf7dd",
                                    },
                    },
            seedNPCSpell = false,
            spellbookCategory = "Feral",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {  },
                        mainText = "Deal {DAMAGE_1} Physical damage to an enemy. Restore {RESOURCE_AMOUNT_1} to yourself.",
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
            useCooldownCharges = false,
            canTargetHiddenUnits = false,
            doesNotRevealCaster = false,
        },
}
```

### Swipe

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
                                                            baseDamage = 75,
                                                            damageSchoolRefs = {
                                                                                    "f82db71a:v1azo4j6",
                                                                                },
                                                            damageType = "melee",
                                                            hitType = "ability",
                                                            projectilePath = "",
                                                            projectileSpeed = 0,
                                                            statScaling = {
                                                                                    {
                                                                                                                coefficient = 0.35,
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
                                                            weaponDamageCoefficient = 1,
                                                            weaponDamageMode = "main_hand",
                                                        },
                                        key = "swipedmg",
                                        target = {
                                                            allowDeadTargets = false,
                                                            disableSelfCast = false,
                                                            maxTargets = 2,
                                                            minTargets = 1,
                                                            requiresTarget = true,
                                                            targetDisposition = "enemy",
                                                            type = "raid_marker",
                                                        },
                                    },
                    },
            conditions = {  },
            cooldown = 0,
            cooldownGroup = "",
            cooldownScalesWithHaste = false,
            description = "",
            icon = "interface/icons/inv_misc_monsterclaw_03.blp",
            id = "drswipe1",
            cooldownChannel = 1,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = true,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Swipe",
            range = 0,
            resourceCosts = {
                        {
                                        amount = 50,
                                        amountMode = "flat",
                                        castPhase = "on_cast_end",
                                        refundOnInterrupt = 0,
                                        resourceRef = "f82db71a:c3gaf7dd",
                                    },
                    },
            seedNPCSpell = false,
            spellbookCategory = "Feral",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {  },
                        mainText = "Deal {DAMAGE_1} Physical damage to up to 2 enemies. Targets must share the same raid marker.",
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

## Feral — Bear Abilities

These abilities are authored as the Druid's Bear/tank toolkit but, by design, **do not require Bear Form**. They remain in the `Feral` spellbook category and use Rage where appropriate.

### Bear authoring notes

| Spell | Rage | RPE implementation |
|---|---:|---|
| Maul | 15 | Actual WoW Classic Rage cost. Tank-role Bonus Action weapon attack; moderate threat. |
| Swipe (Bear) | 20 | Actual WoW Classic Rage cost. Tank-role Main Action, up to 3 enemies on one raid marker; high threat. |
| Growl | 0 | Copy Warrior Taunt: 3-turn taunt, 3-turn cooldown. |
| Demoralizing Roar | 10 | Copy Demoralizing Shout: -10% Melee Attack Power to up to 5 enemies for 2 turns. |
| Enrage | 0 | Generates 20 Rage over 5 RPE turns (4/turn) while reducing Armor by 27%; 10-turn cooldown. |
| Bash | 10 | 1-turn stun/control, Bonus Action, 6-turn cooldown. Uses Hammer of Justice as the current same-mechanic cooldown analogue; 10 Rage is the explicit Classic ability cost. |
| Challenging Roar | 15 | Bespoke multi-target taunt: up to 5 same-marker enemies for 2 turns, 10-turn cooldown. The numerical calculator does not cover multi-target taunt; 15 Rage is the explicit Classic ability cost. |

Damage/scaling notes:

- **Maul** costs **15 Rage**, matching WoW Classic. Its RPE output remains **39 base + 0.182 Melee Attack Power + 0.52 main-hand weapon damage**, with **1.5 threat coefficient**. This is also the exact current output shape of Warrior **Heroic Strike**, which costs the same 15 Rage, so no further damage reduction is justified.
- **Swipe (Bear)** costs **20 Rage**, matching WoW Classic. It is not modeled as a weapon strike because Classic Swipe is a direct Physical area attack rather than an empowered weapon swing. Its RPE output remains **48 base + 0.168 Melee Attack Power per target** against up to 3 targets, with **2.0 threat coefficient**. This was rechecked against the current 20-Rage Warrior **Cleave** and 25-Rage **Whirlwind**: Bear Swipe already has substantially lower per-target output because it is a Tank-profile, 3-target, non-weapon attack, so the incorrect 54-Rage calculator result must not be used to justify further damage inflation or a higher cost.
- Fixed control, taunt, stat-debuff, and resource-generation effects do not rank-scale. Maul and Swipe use normal 8-level ranks.
- **Bash** is control-only and therefore outside the numerical calculator. Its 1-turn stun shape and **6-turn cooldown** use current **Hammer of Justice** as the same-mechanic analogue. Its **10 Rage** cost is retained as the explicit Classic ability cost rather than presented as calculator-derived.
- **Challenging Roar** is also outside the numerical calculator. RPE has no current multi-target taunt analogue, so this entry is explicitly bespoke: **up to 5 enemies sharing one raid marker, 2-turn taunt, 10-turn cooldown, 15 Rage**. These values are design parameters, not calculator outputs.
- **Frenzied Regeneration is intentionally not included as an import entry.** Classic-style healing based on Rage actually consumed is not representable safely by the current aura/resource runtime. It should be added only after the runtime can condition healing on the amount of Rage successfully consumed; no fallback approximation is authored here.

### Maul

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
                                                            baseDamage = 39,
                                                            damageSchoolRefs = {
                                                                                    "f82db71a:v1azo4j6",
                                                                                },
                                                            damageType = "melee",
                                                            hitType = "ability",
                                                            projectilePath = "",
                                                            projectileSpeed = 0,
                                                            statScaling = {
                                                                                    {
                                                                                                                coefficient = 0.182,
                                                                                                                statRef = "f82db71a:u7b49vs9",
                                                                                                            },
                                                                                },
                                                            targetEvents = {
                                                                                    "on_melee_taken",
                                                                                    "on_critical_hit_taken",
                                                                                },
                                                            threatCoefficient = 1.5,
                                                            type = "damage",
                                                            usesProjectile = false,
                                                            weaponDamageCoefficient = 0.52,
                                                            weaponDamageMode = "main_hand",
                                                        },
                                        key = "mauldmg1",
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
            icon = "interface/icons/ability_druid_maul.blp",
            id = "drmaul01",
            cooldownChannel = 2,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = true,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Maul",
            range = 0,
            resourceCosts = {
                        {
                                        amount = 15,
                                        amountMode = "flat",
                                        castPhase = "on_cast_end",
                                        refundOnInterrupt = 0,
                                        resourceRef = "f82db71a:e2tfklq7",
                                    },
                    },
            seedNPCSpell = false,
            spellbookCategory = "Feral",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {  },
                        mainText = "Deal {DAMAGE_1} Physical damage to an enemy. Generates a moderate amount of threat.",
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

### Swipe (Bear)

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
                                                            baseDamage = 48,
                                                            damageSchoolRefs = {
                                                                                    "f82db71a:v1azo4j6",
                                                                                },
                                                            damageType = "melee",
                                                            hitType = "ability",
                                                            projectilePath = "",
                                                            projectileSpeed = 0,
                                                            statScaling = {
                                                                                    {
                                                                                                                coefficient = 0.168,
                                                                                                                statRef = "f82db71a:u7b49vs9",
                                                                                                            },
                                                                                },
                                                            targetEvents = {
                                                                                    "on_melee_taken",
                                                                                    "on_critical_hit_taken",
                                                                                },
                                                            threatCoefficient = 2,
                                                            type = "damage",
                                                            usesProjectile = false,
                                                            weaponDamageCoefficient = 0,
                                                            weaponDamageMode = "none",
                                                        },
                                        key = "swpbdmg1",
                                        target = {
                                                            allowDeadTargets = false,
                                                            disableSelfCast = true,
                                                            maxTargets = 3,
                                                            minTargets = 1,
                                                            requiresTarget = true,
                                                            targetDisposition = "enemy",
                                                            type = "raid_marker",
                                                        },
                                    },
                    },
            conditions = {  },
            cooldown = 0,
            cooldownGroup = "",
            cooldownScalesWithHaste = false,
            description = "",
            icon = "interface/icons/inv_misc_monsterclaw_03.blp",
            id = "drswpbr1",
            cooldownChannel = 1,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = true,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Swipe (Bear)",
            range = 0,
            resourceCosts = {
                        {
                                        amount = 20,
                                        amountMode = "flat",
                                        castPhase = "on_cast_end",
                                        refundOnInterrupt = 0,
                                        resourceRef = "f82db71a:e2tfklq7",
                                    },
                    },
            seedNPCSpell = false,
            spellbookCategory = "Feral",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {  },
                        mainText = "Deal {DAMAGE_1} Physical damage to up to 3 enemies. Targets must share the same raid marker. Generates a high amount of threat.",
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

### Growl

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
                                                            duration = 3,
                                                            targetEvents = {  },
                                                            type = "taunt",
                                                        },
                                        key = "growltnt",
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
            icon = "interface/icons/ability_physical_taunt.blp",
            id = "drgrowl1",
            cooldownChannel = 2,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = false,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Growl",
            range = 0,
            resourceCosts = {  },
            seedNPCSpell = false,
            spellbookCategory = "Feral",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {  },
                        mainText = "Taunt an enemy for 3 turns.",
                        tokens = {  },
                        version = 1,
                    },
            totalTicks = 0,
            useCooldownCharges = false,
        },
}
```

### Demoralizing Roar

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
            duration = 2,
            effects = {
                        {
                                        baseAmount = -10,
                                        operation = "percent",
                                        scaleWithRank = false,
                                        statRef = "f82db71a:u7b49vs9",
                                        statScaling = {  },
                                        type = "stat",
                                    },
                    },
            events = {  },
            icon = "interface/icons/ability_druid_demoralizingroar.blp",
            id = "drdmrau1",
            maxStacks = 1,
            name = "Demoralizing Roar",
            stackBehavior = "refresh_duration",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        bodyText = "Reduces Melee Attack Power by 10%.",
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
                                                            auraRef = "6e4d2a91:drdmrau1",
                                                            basePower = 0,
                                                            duration = 2,
                                                            stacks = 1,
                                                            targetEvents = {  },
                                                            type = "apply_aura",
                                                        },
                                        key = "dmroapp1",
                                        target = {
                                                            allowDeadTargets = false,
                                                            disableSelfCast = true,
                                                            maxTargets = 5,
                                                            minTargets = 1,
                                                            requiresTarget = true,
                                                            targetDisposition = "enemy",
                                                            type = "multi",
                                                        },
                                    },
                    },
            conditions = {  },
            cooldown = 2,
            cooldownGroup = "",
            cooldownScalesWithHaste = false,
            description = "",
            icon = "interface/icons/ability_druid_demoralizingroar.blp",
            id = "drdmror1",
            cooldownChannel = 1,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = false,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Demoralizing Roar",
            range = 0,
            resourceCosts = {
                        {
                                        amount = 10,
                                        amountMode = "flat",
                                        castPhase = "on_cast_end",
                                        refundOnInterrupt = 0,
                                        resourceRef = "f82db71a:e2tfklq7",
                                    },
                    },
            seedNPCSpell = false,
            spellbookCategory = "Feral",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {
                                        {
                                                            auraRef = "6e4d2a91:drdmrau1",
                                                            datasetId = "6e4d2a91",
                                                            descriptionText = "Reduces Melee Attack Power by 10%.",
                                                            duration = 2,
                                                            icon = "interface/icons/ability_druid_demoralizingroar.blp",
                                                            nameText = "Demoralizing Roar",
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
                        mainText = "Apply Demoralizing Roar to up to 5 enemies for 2 turns.",
                        tokens = {  },
                        version = 1,
                    },
            totalTicks = 0,
            useCooldownCharges = false,
        },
}
```

### Enrage

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
                                        amount = 4,
                                        amountMode = "flat",
                                        resourceRef = "f82db71a:e2tfklq7",
                                        scaleWithRank = false,
                                        type = "resource",
                                    },
                        {
                                        baseAmount = -27,
                                        operation = "percent",
                                        scaleWithRank = false,
                                        statRef = "f82db71a:v42albuv",
                                        statScaling = {  },
                                        type = "stat",
                                    },
                    },
            events = {  },
            icon = "interface/icons/ability_druid_enrage.blp",
            id = "drenrau1",
            maxStacks = 1,
            name = "Enrage",
            stackBehavior = "refresh_duration",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        bodyText = "Restores {AURA_RESOURCE_GAIN_1} Rage each turn. Reduces Armor by 27%.",
                        bodyTokens = {
                                        {
                                                            applyMode = "resource_gain_amount",
                                                            effectIndex = 1,
                                                            key = "AURA_RESOURCE_GAIN_1",
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
                                                            auraRef = "6e4d2a91:drenrau1",
                                                            basePower = 0,
                                                            duration = 5,
                                                            stacks = 1,
                                                            targetEvents = {  },
                                                            type = "apply_aura",
                                                        },
                                        key = "enrgapp1",
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
            cooldown = 10,
            cooldownGroup = "",
            cooldownScalesWithHaste = false,
            description = "",
            doesNotRevealCaster = true,
            icon = "interface/icons/ability_druid_enrage.blp",
            id = "drenrag1",
            cooldownChannel = 3,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = false,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Enrage",
            range = 0,
            resourceCosts = {  },
            seedNPCSpell = false,
            spellbookCategory = "Feral",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {
                                        {
                                                            auraRef = "6e4d2a91:drenrau1",
                                                            datasetId = "6e4d2a91",
                                                            descriptionText = "Restores {AURA_RESOURCE_GAIN_1} Rage each turn. Reduces Armor by 27%.",
                                                            duration = 5,
                                                            icon = "interface/icons/ability_druid_enrage.blp",
                                                            nameText = "Enrage",
                                                            powerLevel = 0,
                                                            spellDatasetId = "6e4d2a91",
                                                            stacks = 1,
                                                            targetContext = {
                                                                                    object = "you",
                                                                                    possessive = "your",
                                                                                    reflexive = "yourself",
                                                                                    subject = "you",
                                                                                },
                                                            tokens = {
                                                                                    {
                                                                                                                applyMode = "resource_gain_amount",
                                                                                                                effectIndex = 1,
                                                                                                                key = "AURA_RESOURCE_GAIN_1",
                                                                                                                tokenType = "aura_amount",
                                                                                                            },
                                                                                },
                                                        },
                                    },
                        mainText = "Apply Enrage to yourself for 5 turns.",
                        tokens = {  },
                        version = 1,
                    },
            totalTicks = 0,
            useCooldownCharges = false,
        },
}
```

### Bash

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
                                        forceAutoHitAgainstTarget = true,
                                        movementRangeOverride = 0,
                                        preventCasting = true,
                                        statScaling = {  },
                                        type = "control",
                                    },
                    },
            events = {  },
            icon = "interface/icons/ability_druid_bash.blp",
            id = "drbashau",
            maxStacks = 1,
            name = "Bash",
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
                                                            auraRef = "6e4d2a91:drbashau",
                                                            basePower = 0,
                                                            duration = 1,
                                                            stacks = 1,
                                                            targetEvents = {  },
                                                            type = "apply_aura",
                                                        },
                                        key = "bashapp1",
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
            cooldown = 6,
            cooldownGroup = "stun",
            cooldownScalesWithHaste = false,
            description = "",
            icon = "interface/icons/ability_druid_bash.blp",
            id = "drbash01",
            cooldownChannel = 2,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = false,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Bash",
            range = 0,
            resourceCosts = {
                        {
                                        amount = 10,
                                        amountMode = "flat",
                                        castPhase = "on_cast_end",
                                        refundOnInterrupt = 0,
                                        resourceRef = "f82db71a:e2tfklq7",
                                    },
                    },
            seedNPCSpell = false,
            spellbookCategory = "Feral",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {
                                        {
                                                            auraRef = "6e4d2a91:drbashau",
                                                            datasetId = "6e4d2a91",
                                                            descriptionText = "Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                                                            duration = 1,
                                                            icon = "interface/icons/ability_druid_bash.blp",
                                                            nameText = "Bash",
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
                        mainText = "Apply Bash to an enemy for 1 turn.",
                        tokens = {  },
                        version = 1,
                    },
            totalTicks = 0,
            useCooldownCharges = false,
        },
}
```

### Challenging Roar

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
                                                            duration = 2,
                                                            targetEvents = {  },
                                                            type = "taunt",
                                                        },
                                        key = "chaltnt1",
                                        target = {
                                                            allowDeadTargets = false,
                                                            disableSelfCast = true,
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
            icon = "interface/icons/ability_druid_challangingroar.blp",
            id = "drchalr1",
            cooldownChannel = 1,
            learnMode = "always_learned",
            learnLevel = 1,
            usesRanks = false,
            rankInterval = 8,
            mountedCombatOnly = false,
            name = "Challenging Roar",
            range = 0,
            resourceCosts = {
                        {
                                        amount = 15,
                                        amountMode = "flat",
                                        castPhase = "on_cast_end",
                                        refundOnInterrupt = 0,
                                        resourceRef = "f82db71a:e2tfklq7",
                                    },
                    },
            seedNPCSpell = false,
            spellbookCategory = "Feral",
            tags = {  },
            tooltipTemplate = true,
            tooltipTemplateData = {
                        auraSections = {  },
                        mainText = "Taunt up to 5 enemies on the same raid marker for 2 turns.",
                        tokens = {  },
                        version = 1,
                    },
            totalTicks = 0,
            useCooldownCharges = false,
        },
}
```

## Restoration

Restoration entries use Healing Power (`f82db71a:hj6d4kvy`) and Mana (`f82db71a:4c8mfm99`).

Authoring decisions:

- **Healing Touch** is the standard one-turn, single-target Main Action healer budget, matching current Priest **Heal**: **145 base + 0.80 Healing Power**, costing **6.8% base Mana**.
- **Rejuvenation** directly follows the current **Renew** HoT convention: **20.8 base + 0.624 Healing Power per turn for 5 turns**, Bonus Action, **15% base Mana**.
- **Regrowth** is a one-turn Main Action hybrid direct heal + HoT. Both numerical components use the 0.85 secondary-output allowance: direct healing is **123.25 + 0.68 Healing Power**; the 5-turn HoT is **17.68 + 0.5304 Healing Power per turn**. It costs **6.8% base Mana**.
- **Wild Growth** is a 5-target, 3-turn HoT on Bonus Action with a 3-turn cooldown. The standard HoT budget gives **12.675 + 0.22815 Healing Power per target per turn**. Its maximum-target power ratio places it in the Expensive instant-healing tier, for **27.2% base Mana**.
- **Mark of the Wild** is a single-ally, 10-turn Buff Action utility aura. It grants **+10% Armor**, **+2 Magic Resistance**, and **+20 Nature Resistance**. The resistance values deliberately use current RPE stat scales: +2 Magic Resistance matches Mage Armor's established percentage-point convention, while +20 Nature Resistance reflects the high-rank Classic Mark resistance magnitude. It costs **5% base Mana** and does not use spell ranks.
- **Tranquility** uses current **Divine Hymn** as the closest all-allies major-healing analogue, but spreads exactly the same total authored healing over the requested 3-turn HoT: **40.2375 + 0.222 Healing Power per turn for 3 turns**. It is a 1-turn Main Action cast, has a **10-turn cooldown**, and costs **12.3% base Mana**.
- **Revive** uses the existing dead-target support rather than a new effect type: `allowDeadTargets = true` at spell/target level, `target_health_percent <= 0` to require a dead ally, and a normal heal effect. The heal executor already permits Health to rise from 0 for spells flagged this way, which returns the unit to the alive state.

### Healing Touch

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
        casterEvents = { "on_heal", "on_critical_heal" },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    amountMode = "flat",
                    applyAura = false,
                    auraStacks = 1,
                    baseHealing = 145,
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.8,
                            statRef = "f82db71a:hj6d4kvy",
                        },
                    },
                    targetEvents = { "on_heal_taken", "on_critical_heal_taken" },
                    type = "heal",
                    usesProjectile = false,
                },
                key = "dhtheal1",
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
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_healingtouch.blp",
        id = "drhealt1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Healing Touch",
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
        spellbookCategory = "Restoration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Heal an ally for {HEAL_1} health.",
            tokens = {
                {
                    applyMode = "heal_range",
                    componentIndex = 1,
                    key = "HEAL_1",
                    tokenType = "spell_heal_range",
                },
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Rejuvenation

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
                baseHealing = 20.8,
                statScaling = {
                    {
                        coefficient = 0.624,
                        statRef = "f82db71a:hj6d4kvy",
                    },
                },
                type = "heal",
            },
        },
        events = {  },
        icon = "interface/icons/spell_nature_rejuvenation.blp",
        id = "drrejuv1",
        maxStacks = 1,
        name = "Rejuvenation",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Heals for {AURA_HEAL_1} health each turn.",
            bodyTokens = {
                {
                    applyMode = "heal_amount",
                    baseField = "baseHealing",
                    effectIndex = 1,
                    key = "AURA_HEAL_1",
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
                    auraRef = "6e4d2a91:drrejuv1",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "drejuva1",
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
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_rejuvenation.blp",
        id = "drrejus1",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 4,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Rejuvenation",
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
        seedNPCSpell = false,
        spellbookCategory = "Restoration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "6e4d2a91:drrejuv1",
                    datasetId = "6e4d2a91",
                    descriptionText = "Heals for {AURA_HEAL_1} health each turn.",
                    duration = 5,
                    icon = "interface/icons/spell_nature_rejuvenation.blp",
                    nameText = "Rejuvenation",
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
                            applyMode = "heal_amount",
                            baseField = "baseHealing",
                            effectIndex = 1,
                            key = "AURA_HEAL_1",
                            tokenType = "aura_amount",
                        },
                    },
                },
            },
            mainText = "Apply Rejuvenation to an ally for 5 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Regrowth

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
                baseHealing = 17.68,
                statScaling = {
                    {
                        coefficient = 0.5304,
                        statRef = "f82db71a:hj6d4kvy",
                    },
                },
                type = "heal",
            },
        },
        events = {  },
        icon = "interface/icons/spell_nature_resistnature.blp",
        id = "drregra1",
        maxStacks = 1,
        name = "Regrowth",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Heals for {AURA_HEAL_1} health each turn.",
            bodyTokens = {
                {
                    applyMode = "heal_amount",
                    baseField = "baseHealing",
                    effectIndex = 1,
                    key = "AURA_HEAL_1",
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
        castTime = 1,
        casterEvents = { "on_heal", "on_critical_heal" },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    amountMode = "flat",
                    applyAura = false,
                    auraStacks = 1,
                    baseHealing = 123.25,
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.68,
                            statRef = "f82db71a:hj6d4kvy",
                        },
                    },
                    targetEvents = { "on_heal_taken", "on_critical_heal_taken" },
                    type = "heal",
                    usesProjectile = false,
                },
                key = "drreghl1",
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
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "6e4d2a91:drregra1",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "drregap1",
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
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_resistnature.blp",
        id = "drregro1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 12,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Regrowth",
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
        spellbookCategory = "Restoration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "6e4d2a91:drregra1",
                    datasetId = "6e4d2a91",
                    descriptionText = "Heals for {AURA_HEAL_1} health each turn.",
                    duration = 5,
                    icon = "interface/icons/spell_nature_resistnature.blp",
                    nameText = "Regrowth",
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
                            applyMode = "heal_amount",
                            baseField = "baseHealing",
                            effectIndex = 1,
                            key = "AURA_HEAL_1",
                            tokenType = "aura_amount",
                        },
                    },
                },
            },
            mainText = "Heal an ally for {HEAL_1} health and apply Regrowth for 5 turns.",
            tokens = {
                {
                    applyMode = "heal_range",
                    componentIndex = 1,
                    key = "HEAL_1",
                    tokenType = "spell_heal_range",
                },
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Wild Growth

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
        duration = 3,
        effects = {
            {
                amountMode = "flat",
                baseHealing = 12.675,
                statScaling = {
                    {
                        coefficient = 0.22815,
                        statRef = "f82db71a:hj6d4kvy",
                    },
                },
                type = "heal",
            },
        },
        events = {  },
        icon = "interface/icons/ability_druid_flourish.blp",
        id = "drwgrowa",
        maxStacks = 1,
        name = "Wild Growth",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Heals for {AURA_HEAL_1} health each turn.",
            bodyTokens = {
                {
                    applyMode = "heal_amount",
                    baseField = "baseHealing",
                    effectIndex = 1,
                    key = "AURA_HEAL_1",
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
                    auraRef = "6e4d2a91:drwgrowa",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "drwgrowc",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 5,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "ally",
                    type = "multi",
                },
            },
        },
        conditions = {  },
        cooldown = 3,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_druid_flourish.blp",
        id = "drwgrow1",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 40,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Wild Growth",
        range = 0,
        resourceCosts = {
            {
                amount = 27.2,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Restoration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "6e4d2a91:drwgrowa",
                    datasetId = "6e4d2a91",
                    descriptionText = "Heals for {AURA_HEAL_1} health each turn.",
                    duration = 3,
                    icon = "interface/icons/ability_druid_flourish.blp",
                    nameText = "Wild Growth",
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
                            applyMode = "heal_amount",
                            baseField = "baseHealing",
                            effectIndex = 1,
                            key = "AURA_HEAL_1",
                            tokenType = "aura_amount",
                        },
                    },
                },
            },
            mainText = "Apply Wild Growth to up to 5 allies for 3 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Mark of the Wild

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
                baseAmount = 10,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:v42albuv",
                statScaling = {  },
                type = "stat",
            },
            {
                baseAmount = 2,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:zs1nbz13",
                statScaling = {  },
                type = "stat",
            },
            {
                baseAmount = 20,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:pg0ytacb",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/spell_nature_regeneration.blp",
        id = "drmotwa1",
        maxStacks = 1,
        name = "Mark of the Wild",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Armor by {AURA_STAT_1}%, Magic Resistance by {AURA_STAT_2}% and Nature Resistance by {AURA_STAT_3}.",
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
                    auraRef = "6e4d2a91:drmotwa1",
                    basePower = 0,
                    duration = 10,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "drmotwap",
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
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_regeneration.blp",
        id = "drmotw01",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Mark of the Wild",
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
        spellbookCategory = "Restoration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "6e4d2a91:drmotwa1",
                    datasetId = "6e4d2a91",
                    descriptionText = "Increases Armor by {AURA_STAT_1}%, Magic Resistance by {AURA_STAT_2}% and Nature Resistance by {AURA_STAT_3}.",
                    duration = 10,
                    icon = "interface/icons/spell_nature_regeneration.blp",
                    nameText = "Mark of the Wild",
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
                },
            },
            mainText = "Apply Mark of the Wild to an ally for 10 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Revive

Revive can be represented with the existing spell system; no new resurrection primitive is required.

The existing `allowDeadTargets` spell/target flag permits selecting and healing a dead unit. The heal executor explicitly allows Health to rise from 0 when the spell has `allowDeadTargets = true`, and unit death is derived from Health being at or below zero. A `target_health_percent` condition with `maximumValue = 0` makes the spell dead-target-only rather than merely dead-target-capable.

RPE authoring:

- 1-turn Main Action;
- one allied target;
- dead targets allowed at spell and component-target level;
- requires target Health <= 0%;
- standard one-turn healer output: **145 base + 0.80 Healing Power**;
- **6.8% base Mana**;
- normal rank scaling;
- tokenized tooltip.

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "6e4d2a91",
    entry = {
        allowDeadTargets = true,
        canMoveWhileCasting = false,
        castTime = 1,
        casterEvents = { "on_heal", "on_critical_heal" },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    amountMode = "flat",
                    applyAura = false,
                    auraStacks = 1,
                    baseHealing = 145,
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.8,
                            statRef = "f82db71a:hj6d4kvy",
                        },
                    },
                    targetEvents = { "on_heal_taken", "on_critical_heal_taken" },
                    type = "heal",
                    usesProjectile = false,
                },
                key = "drrevivh",
                target = {
                    allowDeadTargets = true,
                    disableSelfCast = false,
                    maxTargets = 1,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "ally",
                    type = "single",
                },
            },
        },
        conditions = {
            {
                maximumValue = 0,
                minimumValue = nil,
                showOnTooltip = true,
                tooltipTextOverride = "Requires a dead ally",
                type = "target_health_percent",
            },
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_revive.blp",
        id = "drreviv1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 12,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Revive",
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
        spellbookCategory = "Restoration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Revive a dead ally with {HEAL_1} health.",
            tokens = {
                {
                    applyMode = "heal_range",
                    componentIndex = 1,
                    key = "HEAL_1",
                    tokenType = "spell_heal_range",
                },
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Tranquility

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
        duration = 3,
        effects = {
            {
                amountMode = "flat",
                baseHealing = 40.2375,
                statScaling = {
                    {
                        coefficient = 0.222,
                        statRef = "f82db71a:hj6d4kvy",
                    },
                },
                type = "heal",
            },
        },
        events = {  },
        icon = "interface/icons/spell_nature_tranquility.blp",
        id = "drtranqa",
        maxStacks = 1,
        name = "Tranquility",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Heals for {AURA_HEAL_1} health each turn.",
            bodyTokens = {
                {
                    applyMode = "heal_amount",
                    baseField = "baseHealing",
                    effectIndex = 1,
                    key = "AURA_HEAL_1",
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
        castTime = 1,
        casterEvents = {  },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "6e4d2a91:drtranqa",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "drtranqc",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 0,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "ally",
                    type = "all_allies",
                },
            },
        },
        conditions = {  },
        cooldown = 10,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_tranquility.blp",
        id = "drtranq1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 30,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Tranquility",
        range = 0,
        resourceCosts = {
            {
                amount = 12.3,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Restoration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "6e4d2a91:drtranqa",
                    datasetId = "6e4d2a91",
                    descriptionText = "Heals for {AURA_HEAL_1} health each turn.",
                    duration = 3,
                    icon = "interface/icons/spell_nature_tranquility.blp",
                    nameText = "Tranquility",
                    powerLevel = 0,
                    spellDatasetId = "6e4d2a91",
                    stacks = 1,
                    targetContext = {
                        object = "all allies",
                        possessive = "all allies'",
                        reflexive = "themselves",
                        subject = "all allies",
                    },
                    tokens = {
                        {
                            applyMode = "heal_amount",
                            baseField = "baseHealing",
                            effectIndex = 1,
                            key = "AURA_HEAL_1",
                            tokenType = "aura_amount",
                        },
                    },
                },
            },
            mainText = "Apply Tranquility to all allies for 3 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

