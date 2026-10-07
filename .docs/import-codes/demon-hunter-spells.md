# Demon Hunter Spell Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for the Demon Hunter dataset (`dhunter1`).

Havoc and Vengeance are based on their **Legion-era** spell kits. Vengeance deliberately uses the shared Core **Fury** resource instead of Legion's historical Pain resource. Devourer uses its current Void-themed resource loop where that loop can be represented faithfully in RPE.

Import the **Soul Fragments resource** and all required **Aura** entries before spells that reference them.

## Authoring rules applied

- Categories are **Havoc**, **Vengeance**, and **Devourer**. No spell name is duplicated across category boundaries.
- Fury uses Core ref `f82db71a:fury0001`.
- Soul Fragments are authored as a Demon Hunter special resource, `dhunter1:dhsoul01`, with a maximum of **5** and starting at zero.
- Demon Hunter magical attacks scale from **Melee Attack Power** rather than Spell Power so they remain compatible with the Rogue-derived Agility/melee class chassis.
- **Chaos** damage is represented as **Fire + Shadow**.
- **Cosmic** damage is represented as **Arcane + Shadow**.
- Main Action = channel 1; Bonus Action = channel 2; Buff Action = channel 3; Free Action = channel 4; Reaction = channel 5.
- Spender balance is independent of runtime channel. Fury spenders and Soul Fragment spenders use the Spender output profile where appropriate.
- Spell-level `casterEvents` publish what the caster actually did. Damage/heal component `targetEvents` publish what happened to each affected target.
- Utility/apply-aura spells do not publish fake hit/heal events.
- Havoc **Consume Magic** uses the Legion interrupt identity. The later purge spell of the same name is not added elsewhere.
- **Chaos Nova** and **Immolation Aura** use unrestricted `multi` targeting and do not require a shared raid marker.
- Movement-defining abilities such as Fel Rush, Vengeful Retreat, Infernal Strike, The Hunt and Voidblade are omitted.
- Ground-sigil abilities are omitted because delayed ground-area targeting is not represented faithfully.
- Havoc Metamorphosis is omitted because Legion's defining spell-replacement/leap behavior is not representable cleanly.
- Vengeance **Shear** deterministically generates 1 Soul Fragment as the RPE abstraction of Legion's chance to shatter a Lesser Soul Fragment.
- Vengeance **Soul Cleave** uses a fixed 30 Fury + 1 Soul Fragment cost, replacing Legion's variable Pain spend/nearby-fragment consumption with a supported deterministic spend.
- **Demon Spikes** uses Parry + Armor as the supported translation of Legion's Parry + physical-only mitigation.
- **Empower Wards** uses Magic Resistance as the supported translation of Legion's magic-only damage reduction.
- Devourer **Soul Immolation** is a three-turn resource/healing aura: 10 Fury, 1 Soul Fragment, and 8% Max Health per turn.
- Devourer **Void Metamorphosis** consumes 5 Soul Fragments, refills Fury, lasts 3 turns, increases Damage Done, and drains 20 Fury per turn.
- **Collapsing Star** requires Void Metamorphosis and consumes 3 Soul Fragments.
- Reap, Cull, Eradicate and other ground-fragment collection or temporary spell-replacement mechanics are omitted rather than approximated incorrectly.
- All direct numerical outputs follow the current RPE Spell Authoring Specification rather than retail/Legion raw damage coefficients.


# Resources

## Soul Fragments

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "resources",
    datasetId = "dhunter1",
    entry = {
        baseValue = 5,
        color = {
            a = 1,
            b = 0.85,
            g = 0.25,
            r = 0.55,
        },
        description = "A special Demon Hunter resource representing harvested soul fragments.",
        icon = "interface/icons/inv_12_dh_void_ability_soulfragments.blp",
        id = "dhsoul01",
        multiplier = 0,
        name = "Soul Fragments",
        regenMode = "manual",
        regenMultiplier = 0,
        regenPerSecond = 0,
        seedNPCResource = false,
        special = true,
        startsAtZero = true,
        tags = { },
        valueMode = "manual",
    },
}
```


# Havoc

## Blade Dance — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dhunter1",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                baseAmount = 100,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:o6113cir",
                statScaling = { },
                type = "stat",
            },
        },
        events = { },
        icon = "interface/icons/ability_demonhunter_bladedance.blp",
        id = "dhbddg01",
        maxStacks = 1,
        name = "Blade Dance",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Dodge Chance by 100%.",
            bodyTokens = { },
            stackingText = "",
            stackingTokens = { },
            version = 1,
        },
    },
}
```

## Chaos Nova — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dhunter1",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                cancelOnDamage = false,
                forceAutoHitAgainstTarget = true,
                movementRangeOverride = 0,
                preventCasting = true,
                statScaling = { },
                type = "control",
            },
        },
        events = { },
        icon = "interface/icons/spell_fire_felfirenova.blp",
        id = "dhnova01",
        maxStacks = 1,
        name = "Chaos Nova",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Stunned. Prevents casting, sets movement range to 0, and causes attacks against the affected unit to automatically hit.",
            bodyTokens = { },
            stackingText = "",
            stackingTokens = { },
            version = 1,
        },
    },
}
```

## Blur — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dhunter1",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                baseAmount = 50,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:o6113cir",
                statScaling = { },
                type = "stat",
            },
            {
                baseAmount = 35,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:pu05li08",
                statScaling = { },
                type = "stat",
            },
        },
        events = { },
        icon = "interface/icons/ability_demonhunter_blur.blp",
        id = "dhblur01",
        maxStacks = 1,
        name = "Blur",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Dodge Chance by 50 and Damage Reduction by 35.",
            bodyTokens = { },
            stackingText = "",
            stackingTokens = { },
            version = 1,
        },
    },
}
```

## Imprison — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dhunter1",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                cancelOnDamage = true,
                forceAutoHitAgainstTarget = true,
                movementRangeOverride = 0,
                preventCasting = true,
                statScaling = { },
                type = "control",
            },
        },
        events = { },
        icon = "interface/icons/ability_demonhunter_imprison.blp",
        id = "dhimpr01",
        maxStacks = 1,
        name = "Imprison",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Incapacitated. Breaks on damage, prevents casting, sets movement range to 0, and causes attacks against the affected unit to automatically hit.",
            bodyTokens = { },
            stackingText = "",
            stackingTokens = { },
            version = 1,
        },
    },
}
```


# Vengeance

## Immolation Aura — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dhunter1",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                amountMode = "flat",
                baseDamage = 8.619,
                damageSchoolRefs = {
                    "f82db71a:esjguw6d",
                },
                statScaling = {
                    {
                        coefficient = 0.06,
                        statRef = "f82db71a:u7b49vs9",
                    },
                },
                type = "damage",
            },
        },
        events = { },
        icon = "interface/icons/ability_demonhunter_immolation.blp",
        id = "dhimmo01",
        maxStacks = 1,
        name = "Immolation Aura",
        stackBehavior = "refresh_duration",
        tags = { },
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
            stackingTokens = { },
            version = 1,
        },
    },
}
```

## Demon Spikes — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dhunter1",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                baseAmount = 20,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:tcn0s8kx",
                statScaling = { },
                type = "stat",
            },
            {
                baseAmount = 50,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:v42albuv",
                statScaling = { },
                type = "stat",
            },
        },
        events = { },
        icon = "interface/icons/ability_demonhunter_demonspikes.blp",
        id = "dhspike1",
        maxStacks = 1,
        name = "Demon Spikes",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Parry Chance by 20 and Armor by 50%.",
            bodyTokens = { },
            stackingText = "",
            stackingTokens = { },
            version = 1,
        },
    },
}
```

## Empower Wards — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dhunter1",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                baseAmount = 30,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:zs1nbz13",
                statScaling = { },
                type = "stat",
            },
        },
        events = { },
        icon = "interface/icons/ability_demonhunter_empowerwards.blp",
        id = "dhward01",
        maxStacks = 1,
        name = "Empower Wards",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Magic Resistance by 30.",
            bodyTokens = { },
            stackingText = "",
            stackingTokens = { },
            version = 1,
        },
    },
}
```

## Metamorphosis — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dhunter1",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                baseAmount = 30,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:ygjno50i",
                statScaling = { },
                type = "stat",
            },
            {
                baseAmount = 100,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:v42albuv",
                statScaling = { },
                type = "stat",
            },
            {
                amount = 20,
                amountMode = "flat",
                resourceRef = "f82db71a:fury0001",
                scaleWithRank = false,
                type = "resource",
            },
        },
        events = { },
        icon = "interface/icons/ability_demonhunter_metamorphasistank.blp",
        id = "dhmetaau",
        maxStacks = 1,
        name = "Metamorphosis",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Stamina by 30% and Armor by 100%. Restores 20 Fury each turn.",
            bodyTokens = { },
            stackingText = "",
            stackingTokens = { },
            version = 1,
        },
    },
}
```


# Devourer

## Soul Immolation — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dhunter1",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                amount = 10,
                amountMode = "flat",
                resourceRef = "f82db71a:fury0001",
                scaleWithRank = false,
                type = "resource",
            },
            {
                amount = 1,
                amountMode = "flat",
                resourceRef = "dhunter1:dhsoul01",
                scaleWithRank = false,
                type = "resource",
            },
            {
                amountMode = "max_percent",
                baseHealing = 8,
                statScaling = { },
                type = "heal",
            },
        },
        events = { },
        icon = "interface/icons/inv_12_dh_void_ability_voidpurge.blp",
        id = "dhsimmo1",
        maxStacks = 1,
        name = "Soul Immolation",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Each turn restores 10 Fury, generates 1 Soul Fragment, and heals you for 8% of Max Health.",
            bodyTokens = { },
            stackingText = "",
            stackingTokens = { },
            version = 1,
        },
    },
}
```

## Void Metamorphosis — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dhunter1",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                baseAmount = 30,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:gj9wxb0x",
                statScaling = { },
                type = "stat",
            },
            {
                amount = -20,
                amountMode = "flat",
                resourceRef = "f82db71a:fury0001",
                scaleWithRank = false,
                type = "resource",
            },
        },
        events = { },
        icon = "interface/icons/inv_112_ability_demonhunter_metamorphasisvoid.blp",
        id = "dhvmeta1",
        maxStacks = 1,
        name = "Void Metamorphosis",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Damage Done by 30. Loses 20 Fury each turn.",
            bodyTokens = { },
            stackingText = "",
            stackingTokens = { },
            version = 1,
        },
    },
}
```


# Havoc

## Demon's Bite

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
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
                key = "dhdbdm01",
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
                    amount = 25,
                    amountMode = "flat",
                    resourceRef = "f82db71a:fury0001",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dhdbfy01",
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
                tooltipTextOverride = "Requires Main Hand",
                type = "item_equipped",
                weaponTypeRefs = { },
            },
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_demonhunter_demonsbite.blp",
        id = "dhdbite1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Demon's Bite",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Havoc",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Deal {DAMAGE_1} Physical damage to an enemy and restore {RESOURCE_AMOUNT_1} Fury.",
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

## Chaos Strike

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
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
                    baseDamage = 168.75,
                    damageSchoolRefs = {
                        "f82db71a:esjguw6d",
                        "f82db71a:1ggt4t3v",
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
                    weaponDamageCoefficient = 2.25,
                    weaponDamageMode = "both",
                },
                key = "dhcsdm01",
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
                invert = false,
                showOnTooltip = true,
                slotKey = "mainhand",
                tooltipTextOverride = "Requires Main Hand",
                type = "item_equipped",
                weaponTypeRefs = { },
            },
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_demonhunter_chaosstrike.blp",
        id = "dhcstrk1",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Chaos Strike",
        range = 0,
        resourceCosts = {
            {
                amount = 40,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:fury0001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Havoc",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Spend 40 Fury to deal {DAMAGE_1} Chaos damage to an enemy.",
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

## Blade Dance

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
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
                    baseDamage = 67.77421875,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.3162796875,
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
                    weaponDamageCoefficient = 0.90365625,
                    weaponDamageMode = "both",
                },
                key = "dhbddm01",
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
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "dhunter1:dhbddg01",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dhbdau01",
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
                tooltipTextOverride = "Requires Main Hand",
                type = "item_equipped",
                weaponTypeRefs = { },
            },
        },
        cooldown = 1,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_demonhunter_bladedance.blp",
        id = "dhbdanc1",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Blade Dance",
        range = 0,
        resourceCosts = {
            {
                amount = 35,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:fury0001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Havoc",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Spend 35 Fury to deal {DAMAGE_1} Physical damage to up to 5 enemies and increase your Dodge Chance by 100% for 1 turn.",
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

## Eye Beam

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
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
                    baseDamage = 218.7,
                    damageSchoolRefs = {
                        "f82db71a:esjguw6d",
                        "f82db71a:1ggt4t3v",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.81,
                            statRef = "f82db71a:u7b49vs9",
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
                key = "dheydm01",
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
        conditions = { },
        cooldown = 5,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_demonhunter_eyebeam.blp",
        id = "dheyebe1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Eye Beam",
        range = 0,
        resourceCosts = {
            {
                amount = 50,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:fury0001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Havoc",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Spend 50 Fury and channel for 1 turn to deal {DAMAGE_1} Chaos damage to up to 5 enemies.",
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

## Throw Glaive

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = {
            "on_ranged_hit",
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
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "ranged",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.21,
                            statRef = "f82db71a:u7b49vs9",
                        },
                    },
                    targetEvents = {
                        "on_ranged_taken",
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0.6,
                    weaponDamageMode = "main_hand",
                },
                key = "dhgldm01",
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
        },
        conditions = {
            {
                invert = false,
                showOnTooltip = true,
                slotKey = "mainhand",
                tooltipTextOverride = "Requires Main Hand",
                type = "item_equipped",
                weaponTypeRefs = { },
            },
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_demonhunter_throwglaive.blp",
        id = "dhglaiv1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Throw Glaive",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Havoc",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Deal {DAMAGE_1} Physical damage to up to 3 enemies.",
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

## Chaos Nova

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
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
                    baseDamage = 45.995625,
                    damageSchoolRefs = {
                        "f82db71a:esjguw6d",
                        "f82db71a:1ggt4t3v",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.1609846875,
                            statRef = "f82db71a:u7b49vs9",
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
                key = "dhcvdm01",
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
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "dhunter1:dhnova01",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dhcvau01",
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
        conditions = { },
        cooldown = 6,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_fire_felfirenova.blp",
        id = "dhcnova1",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Chaos Nova",
        range = 0,
        resourceCosts = {
            {
                amount = 30,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:fury0001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Havoc",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Spend 30 Fury to deal {DAMAGE_1} Chaos damage to up to 5 enemies and stun them for 1 turn.",
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

## Blur

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = { },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "dhunter1:dhblur01",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dhblau01",
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
        conditions = { },
        cooldown = 6,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_demonhunter_blur.blp",
        id = "dhblursp",
        cooldownChannel = 5,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Blur",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Havoc",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Increase your Dodge Chance by 50 and Damage Reduction by 35 for 2 turns.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Consume Magic

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = { },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    targetEvents = { },
                    type = "interrupt",
                },
                key = "dhcmint1",
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
        conditions = { },
        cooldown = 5,
        cooldownGroup = "interrupt",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_demonhunter_consumemagic.blp",
        id = "dhconmag",
        cooldownChannel = 5,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Consume Magic",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Havoc",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Interrupt an enemy's spellcasting.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Imprison

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = { },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "dhunter1:dhimpr01",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dhimau01",
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
        conditions = { },
        cooldown = 6,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_demonhunter_imprison.blp",
        id = "dhimprsp",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Imprison",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Havoc",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Incapacitate an enemy for 2 turns. Breaks when the target takes damage.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```


# Vengeance

## Shear

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
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
                    baseDamage = 51,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.238,
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
                    weaponDamageCoefficient = 0.68,
                    weaponDamageMode = "main_hand",
                },
                key = "dhshdm01",
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
                    amount = 10,
                    amountMode = "flat",
                    resourceRef = "f82db71a:fury0001",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dhshfy01",
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
                    amount = 1,
                    amountMode = "flat",
                    resourceRef = "dhunter1:dhsoul01",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dhshso01",
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
                tooltipTextOverride = "Requires Main Hand",
                type = "item_equipped",
                weaponTypeRefs = { },
            },
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_demonhunter_hatefulstrike.blp",
        id = "dhshear1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Shear",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Vengeance",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Deal {DAMAGE_1} Physical damage to an enemy, restore {RESOURCE_AMOUNT_1} Fury, and generate 1 Soul Fragment.",
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

## Soul Cleave

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = {
            "on_melee_hit",
            "on_critical_hit",
            "on_heal",
            "on_critical_heal",
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
                    baseDamage = 51.6375,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.240975,
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
                    weaponDamageCoefficient = 0.6885,
                    weaponDamageMode = "both",
                },
                key = "dhscdm01",
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
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    applyAura = false,
                    auraStacks = 1,
                    amountMode = "flat",
                    baseHealing = 105.1875,
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.36815625,
                            statRef = "f82db71a:u7b49vs9",
                        },
                    },
                    targetEvents = {
                        "on_heal_taken",
                        "on_critical_heal_taken",
                    },
                    type = "heal",
                    usesProjectile = false,
                },
                key = "dhschl01",
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
                tooltipTextOverride = "Requires Main Hand",
                type = "item_equipped",
                weaponTypeRefs = { },
            },
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_demonhunter_soulcleave.blp",
        id = "dhsclev1",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Soul Cleave",
        range = 0,
        resourceCosts = {
            {
                amount = 30,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:fury0001",
            },
            {
                amount = 1,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "dhunter1:dhsoul01",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Vengeance",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Spend 30 Fury and 1 Soul Fragment to deal {DAMAGE_1} Physical damage to up to 5 enemies and heal yourself for {HEAL_1}.",
            tokens = {
                {
                    applyMode = "damage_range",
                    componentIndex = 1,
                    key = "DAMAGE_1",
                    tokenType = "spell_damage_range",
                },
                {
                    applyMode = "heal_range",
                    componentIndex = 2,
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

## Immolation Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
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
                    baseDamage = 22.8735,
                    damageSchoolRefs = {
                        "f82db71a:esjguw6d",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.08005725,
                            statRef = "f82db71a:u7b49vs9",
                        },
                    },
                    targetEvents = {
                        "on_spell_taken",
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 1.5,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0,
                    weaponDamageMode = "none",
                },
                key = "dhimdm01",
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
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "dhunter1:dhimmo01",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dhimau01",
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
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    amount = 20,
                    amountMode = "flat",
                    resourceRef = "f82db71a:fury0001",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dhimfy01",
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
        conditions = { },
        cooldown = 2,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_demonhunter_immolation.blp",
        id = "dhimolsp",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Immolation Aura",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Vengeance",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Deal {DAMAGE_1} Fire damage to up to 5 enemies, burn them for 3 turns, and restore {RESOURCE_AMOUNT_1} Fury.",
            tokens = {
                {
                    applyMode = "damage_range",
                    componentIndex = 1,
                    key = "DAMAGE_1",
                    tokenType = "spell_damage_range",
                },
                {
                    applyMode = "resource_gain_amount",
                    componentIndex = 3,
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

## Demon Spikes

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = { },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "dhunter1:dhspike1",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dhdpau1",
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
        conditions = { },
        cooldown = 2,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_demonhunter_demonspikes.blp",
        id = "dhdspik1",
        cooldownChannel = 5,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Demon Spikes",
        range = 0,
        resourceCosts = {
            {
                amount = 20,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:fury0001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Vengeance",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Spend 20 Fury to increase your Parry Chance by 20 and Armor by 50% for 1 turn.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Empower Wards

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = { },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "dhunter1:dhward01",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dhewau01",
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
        conditions = { },
        cooldown = 2,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_demonhunter_empowerwards.blp",
        id = "dheward1",
        cooldownChannel = 5,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Empower Wards",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Vengeance",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Increase your Magic Resistance by 30 for 1 turn.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Fel Devastation

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 1,
        casterEvents = {
            "on_spell_hit",
            "on_critical_hit",
            "on_heal",
            "on_critical_heal",
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
                    baseDamage = 148.716,
                    damageSchoolRefs = {
                        "f82db71a:esjguw6d",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.5508,
                            statRef = "f82db71a:u7b49vs9",
                        },
                    },
                    targetEvents = {
                        "on_spell_taken",
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 2,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0,
                    weaponDamageMode = "none",
                },
                key = "dhfddm01",
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
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    applyAura = false,
                    auraStacks = 1,
                    amountMode = "flat",
                    baseHealing = 244.035,
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.8415,
                            statRef = "f82db71a:u7b49vs9",
                        },
                    },
                    targetEvents = {
                        "on_heal_taken",
                        "on_critical_heal_taken",
                    },
                    type = "heal",
                    usesProjectile = false,
                },
                key = "dhfdhl01",
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
        conditions = { },
        cooldown = 5,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_demonhunter_feldevastation.blp",
        id = "dhfdev01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Fel Devastation",
        range = 0,
        resourceCosts = {
            {
                amount = 30,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:fury0001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Vengeance",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Spend 30 Fury and channel for 1 turn to deal {DAMAGE_1} Fire damage to up to 5 enemies and heal yourself for {HEAL_1}.",
            tokens = {
                {
                    applyMode = "damage_range",
                    componentIndex = 1,
                    key = "DAMAGE_1",
                    tokenType = "spell_damage_range",
                },
                {
                    applyMode = "heal_range",
                    componentIndex = 2,
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

## Metamorphosis

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = { },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "dhunter1:dhmetaau",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dhmtau01",
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
        conditions = { },
        cooldown = 10,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_demonhunter_metamorphasistank.blp",
        id = "dhmetasp",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Metamorphosis",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Vengeance",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Transform for 2 turns, increasing Stamina by 30% and Armor by 100%, and restoring 20 Fury each turn.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Torment

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = { },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    duration = 3,
                    targetEvents = { },
                    type = "taunt",
                },
                key = "dhtnta01",
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
        conditions = { },
        cooldown = 3,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_demonhunter_torment.blp",
        id = "dhtormt1",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Torment",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Vengeance",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Taunt an enemy for 3 turns.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```


# Devourer

## Consume

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = true,
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
                    baseDamage = 114.75,
                    damageSchoolRefs = {
                        "f82db71a:dtxhglqg",
                        "f82db71a:1ggt4t3v",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.425,
                            statRef = "f82db71a:u7b49vs9",
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
                key = "dhcodm01",
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
                    amount = 25,
                    amountMode = "flat",
                    resourceRef = "f82db71a:fury0001",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dhcofy01",
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
                    amount = 1,
                    amountMode = "flat",
                    resourceRef = "dhunter1:dhsoul01",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dhcoso01",
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
        conditions = { },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/inv_12_dh_void_ability_consume.blp",
        id = "dhconsum",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Consume",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Devourer",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Cast while moving for 1 turn to deal {DAMAGE_1} Cosmic damage, restore {RESOURCE_AMOUNT_1} Fury, and generate 1 Soul Fragment.",
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

## Void Ray

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
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
                    baseDamage = 136.6875,
                    damageSchoolRefs = {
                        "f82db71a:dtxhglqg",
                        "f82db71a:1ggt4t3v",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.50625,
                            statRef = "f82db71a:u7b49vs9",
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
                key = "dhvrdm01",
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
        conditions = { },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/inv_12_dh_void_ability_voidray.blp",
        id = "dhvray01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Void Ray",
        range = 0,
        resourceCosts = {
            {
                amount = 100,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:fury0001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Devourer",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Spend 100 Fury and channel for 1 turn to deal {DAMAGE_1} Cosmic damage to up to 5 enemies.",
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

## Soul Immolation

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = { },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "dhunter1:dhsimmo1",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dhsiau01",
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
        conditions = { },
        cooldown = 5,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/inv_12_dh_void_ability_voidpurge.blp",
        id = "dhsimosp",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Soul Immolation",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Devourer",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "For 3 turns, restore 10 Fury, generate 1 Soul Fragment, and restore 8% of Max Health each turn.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Void Metamorphosis

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = { },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    amount = 100,
                    amountMode = "flat",
                    resourceRef = "f82db71a:fury0001",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dhvmfy01",
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
                    auraRef = "dhunter1:dhvmeta1",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dhvmau01",
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
        conditions = { },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/inv_112_ability_demonhunter_metamorphasisvoid.blp",
        id = "dhvmetsp",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Void Metamorphosis",
        range = 0,
        resourceCosts = {
            {
                amount = 5,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "dhunter1:dhsoul01",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Devourer",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Consume 5 Soul Fragments to refill your Fury and enter Void Metamorphosis for 3 turns. Damage Done is increased by 30 and you lose 20 Fury each turn.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Collapsing Star

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dhunter1",
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
                    baseDamage = 143.521875,
                    damageSchoolRefs = {
                        "f82db71a:dtxhglqg",
                        "f82db71a:1ggt4t3v",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.5315625,
                            statRef = "f82db71a:u7b49vs9",
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
                key = "dhcsdm02",
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
        conditions = {
            {
                auraRef = "dhunter1:dhvmeta1",
                invert = false,
                minimumValue = 1,
                showOnTooltip = true,
                tooltipTextOverride = "",
                type = "aura_requirement",
                unit = "caster",
            },
        },
        cooldown = 1,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/inv_12_dh_void_ability_collapsingstar.blp",
        id = "dhcstar1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Collapsing Star",
        range = 0,
        resourceCosts = {
            {
                amount = 3,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "dhunter1:dhsoul01",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Devourer",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "While in Void Metamorphosis, consume 3 Soul Fragments and cast for 1 turn to deal {DAMAGE_1} Cosmic damage to up to 5 enemies.",
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

