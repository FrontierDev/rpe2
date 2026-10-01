# Monk Spell Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for the Monk dataset (`monkdata`), based as closely as practical on the launch-era Mists of Pandaria Monk while remaining within currently supported RPE mechanics.

Import required **Aura** entries before spells that reference them.

## Authoring rules applied

- Brewmaster uses the **Tank** role profile; Windwalker uses **DPS**; Mistweaver uses **Healer**.
- Brewmaster and Windwalker spend **Energy** (`f82db71a:c3gaf7dd`) and generate/spend **Chi** (`f82db71a:p8kik0ep`).
- Mistweaver spends **Mana** (`f82db71a:4c8mfm99`) and also generates/spends Chi.
- The Core Chi resource already has a 4-Chi maximum and starts at zero, matching early Mists of Pandaria.
- Authentic Energy and Chi costs are retained rather than derived from the Mana calculator.
- Early-MoP Mana costs are used where patch history exposes them. In particular, Mistweaver Jab uses 4% base Mana (before the later 8% increase); Surging Mist uses 8% base Mana; Life Cocoon 4.5%; Revival 7%; Renewing Mist 4.5%.
- RPE damage/healing values are calculated from the current Spell Authoring Specification. Historical Blizzard damage numbers are not imported.
- RPE cooldowns are turn-based adaptations: short 8–15 second cooldowns generally use 1–2 turns; ~25–30 seconds uses 2–3; ~1 minute uses 5; major 2–3 minute cooldowns use 10.
- Channels are converted into supported one-turn casts and/or periodic auras. They are not authored as fake instant spells with full channel output.
- Launch-era mechanics that depend on positional checks, ground objects, statues, movement/teleports, Stagger, damage redirection, caster-specific target vulnerability, or "next specific spell" state are deliberately omitted.
- Spinning Crane Kick does **not** generate Chi because the historical Chi generation required hitting at least 3 targets and RPE cannot currently condition resource generation on the number actually hit.
- Brewmaster Tiger Palm is authored with no Chi cost, following Brewmaster Training. Its Power Guard interaction is omitted.
- Brewmaster Blackout Kick applies the supported portion of Shuffle: +20 Parry Chance for 1 turn. Stagger is omitted.
- Keg Smash uses the launch-era three-target limit, applies Dizzying Haze, and generates 2 Chi. Weakened Blows is omitted because RPE has no Physical-only damage-done modifier.
- Breath of Fire omits its conditional Dizzying-Haze DoT because RPE cannot condition one component on each target's aura state.
- Guard uses Melee Attack Power scaling and +30 Healing Received as the closest supported translation of its original self-healing bonus.
- Rising Sun Kick applies -50 Healing Received. Its caster-specific +20% damage vulnerability is omitted.
- Fists of Fury is a one-turn cast hitting up to 5 enemies and applying a 1-turn stun.
- Soothing Mist is represented as a one-turn cast that applies a two-turn HoT. Its chance-per-tick Chi generation is omitted.
- Enveloping Mist is a 3-Chi, one-turn-cast HoT. Its Soothing-Mist-specific healing bonus is omitted.
- Renewing Mist is a single-target HoT that generates 1 Chi. Automatic jumping is omitted.
- Life Cocoon uses an absorb plus +50 Healing Received; the original bonus only to periodic healing cannot be expressed separately.
- Revival heals all allies and removes all auras tagged `magic`, `poison`, or `disease`.
- Detox removes `poison` and `disease` tagged auras.
- Stance of the Sturdy Ox, Stance of the Fierce Tiger, and Stance of the Wise Serpent belong in the Monk **trait** import sheet, not here.

# Brewmaster

## Shuffle — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "monkdata",
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
        },
        events = { },
        icon = "interface/icons/ability_monk_shuffle.blp",
        id = "mnshuf01",
        maxStacks = 1,
        name = "Shuffle",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Dizzying Haze — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "monkdata",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                baseAmount = -50,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:s1mt6jh9",
                statScaling = { },
                type = "stat",
            },
        },
        events = { },
        icon = "interface/icons/ability_monk_drunkenhaze.blp",
        id = "mnhaze01",
        maxStacks = 1,
        name = "Dizzying Haze",
        stackBehavior = "refresh_duration",
        tags = {
            "monk_dizzying_haze",
        },
        tooltipTemplate = false,
    },
}
```

## Guard — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "monkdata",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                amountMode = "flat",
                baseAbsorption = 248.625,
                damageSchoolRefs = { },
                scaleWithRank = true,
                statScaling = {
                    {
                        coefficient = 0.8701875,
                        statRef = "f82db71a:u7b49vs9",
                    },
                },
                type = "absorb",
            },
            {
                baseAmount = 30,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:ok80ohz3",
                statScaling = { },
                type = "stat",
            },
        },
        events = { },
        icon = "interface/icons/ability_monk_guard.blp",
        id = "mnguard1",
        maxStacks = 1,
        name = "Guard",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Fortifying Brew — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "monkdata",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                baseAmount = 20,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:ygjno50i",
                statScaling = { },
                type = "stat",
            },
            {
                baseAmount = 20,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:pu05li08",
                statScaling = { },
                type = "stat",
            },
        },
        events = { },
        icon = "interface/icons/ability_monk_fortifyingale_new.blp",
        id = "mnfort01",
        maxStacks = 1,
        name = "Fortifying Brew",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Paralysis — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "monkdata",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                cancelOnDamage = true,
                forceAutoHitAgainstTarget = true,
                movementRangeOverride = 0,
                preventCasting = true,
                type = "control",
            },
        },
        events = { },
        icon = "interface/icons/ability_monk_paralysis.blp",
        id = "mnpara01",
        maxStacks = 1,
        name = "Paralysis",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Jab

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                key = "mnbjbdm",
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
                    resourceRef = "f82db71a:p8kik0ep",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "mnbjbch",
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
        icon = "interface/icons/ability_monk_jab.blp",
        id = "mnbjab01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Jab",
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
        spellbookCategory = "Brewmaster",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Expel Harm

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    applyAura = false,
                    auraStacks = 1,
                    amountMode = "flat",
                    baseHealing = 53.7625,
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.322575,
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
                key = "mnbexphl",
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
                    alwaysHits = false,
                    amountMode = "flat",
                    applyAura = false,
                    auraStacks = 1,
                    baseDamage = 26.88125,
                    damageSchoolRefs = {
                        "f82db71a:qtr10qyj",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.1612875,
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
                key = "mnbexpdm",
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
                    resourceRef = "f82db71a:p8kik0ep",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "mnbexpch",
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
        icon = "interface/icons/ability_monk_expelharm.blp",
        id = "mnbexp01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Expel Harm",
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
        spellbookCategory = "Brewmaster",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Tiger Palm

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    baseDamage = 60,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.28,
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
                    weaponDamageCoefficient = 0.8,
                    weaponDamageMode = "main_hand",
                },
                key = "mnbtpdm1",
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
        icon = "interface/icons/ability_monk_tigerpalm.blp",
        id = "mnbtp001",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Tiger Palm",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Brewmaster",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Blackout Kick

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    baseDamage = 114.75,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.5355,
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
                    weaponDamageCoefficient = 1.53,
                    weaponDamageMode = "main_hand",
                },
                key = "mnbbokdm",
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
                    auraRef = "monkdata:mnshuf01",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "mnbbokau",
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
        icon = "interface/icons/ability_monk_roundhousekick.blp",
        id = "mnbbok01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Blackout Kick",
        range = 0,
        resourceCosts = {
            {
                amount = 2,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:p8kik0ep",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Brewmaster",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Keg Smash

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    baseDamage = 32.13,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.14994,
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
                    weaponDamageCoefficient = 0.4284,
                    weaponDamageMode = "main_hand",
                },
                key = "mnbkegdm",
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
                    auraRef = "monkdata:mnhaze01",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "mnbkegau",
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
                    amount = 2,
                    amountMode = "flat",
                    resourceRef = "f82db71a:p8kik0ep",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "mnbkegch",
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
        icon = "interface/icons/ability_monk_kegsmash.blp",
        id = "mnbkeg01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Keg Smash",
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
        spellbookCategory = "Brewmaster",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Dizzying Haze

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    auraRef = "monkdata:mnhaze01",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "mnbhazau",
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
        icon = "interface/icons/ability_monk_drunkenhaze.blp",
        id = "mnbhaz01",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Dizzying Haze",
        range = 30,
        resourceCosts = {
            {
                amount = 20,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:c3gaf7dd",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Brewmaster",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Breath of Fire

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    baseDamage = 93.15,
                    damageSchoolRefs = {
                        "f82db71a:esjguw6d",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.326025,
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
                key = "mnbbofdm",
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
        cooldown = 2,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_monk_breathoffire.blp",
        id = "mnbbof01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Breath of Fire",
        range = 0,
        resourceCosts = {
            {
                amount = 2,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:p8kik0ep",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Brewmaster",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Guard

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    auraRef = "monkdata:mnguard1",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "mnbgrdau",
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
        cooldown = 3,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_monk_guard.blp",
        id = "mnbgrd01",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Guard",
        range = 0,
        resourceCosts = {
            {
                amount = 2,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:p8kik0ep",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Brewmaster",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Fortifying Brew

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    auraRef = "monkdata:mnfort01",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "mnbforau",
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
        icon = "interface/icons/ability_monk_fortifyingale_new.blp",
        id = "mnbfor01",
        cooldownChannel = 5,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Fortifying Brew",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Brewmaster",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Provoke

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    duration = 1,
                    targetEvents = {
                        "on_taunted",
                    },
                    type = "taunt",
                },
                key = "mnbprvtk",
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
        cooldown = 1,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_monk_provoke.blp",
        id = "mnbprv01",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Provoke",
        range = 30,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Brewmaster",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Spinning Crane Kick

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 1,
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
                    baseDamage = 36.45,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.18,
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
                    weaponDamageCoefficient = 0.36,
                    weaponDamageMode = "main_hand",
                },
                key = "mnbsckdm",
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
        icon = "interface/icons/ability_monk_cranekick_new.blp",
        id = "mnbsck01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Spinning Crane Kick",
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
        spellbookCategory = "Brewmaster",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Paralysis

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    auraRef = "monkdata:mnpara01",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "mnbparau",
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
        cooldown = 2,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_monk_paralysis.blp",
        id = "mnbpar01",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Paralysis",
        range = 20,
        resourceCosts = {
            {
                amount = 20,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:c3gaf7dd",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Brewmaster",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Spear Hand Strike

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                key = "mnbsphin",
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
        cooldown = 2,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_monk_spearhand.blp",
        id = "mnbsph01",
        cooldownChannel = 5,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Spear Hand Strike",
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
        spellbookCategory = "Brewmaster",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Detox

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    maxAuras = nil,
                    tags = {
                        "poison",
                    },
                    targetEvents = { },
                    type = "remove_aura_by_tag",
                },
                key = "mnbdetpo",
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
                    maxAuras = nil,
                    tags = {
                        "disease",
                    },
                    targetEvents = { },
                    type = "remove_aura_by_tag",
                },
                key = "mnbdetdi",
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
        conditions = { },
        cooldown = 1,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_monk_detox.blp",
        id = "mnbdet01",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Detox",
        range = 30,
        resourceCosts = {
            {
                amount = 20,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:c3gaf7dd",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Brewmaster",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

# Windwalker

## Mortal Wounds — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "monkdata",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                baseAmount = -50,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:ok80ohz3",
                statScaling = { },
                type = "stat",
            },
        },
        events = { },
        icon = "interface/icons/ability_monk_risingsunkick.blp",
        id = "mnmorta1",
        maxStacks = 1,
        name = "Mortal Wounds",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Fists of Fury — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "monkdata",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                cancelOnDamage = false,
                forceAutoHitAgainstTarget = true,
                movementRangeOverride = 0,
                preventCasting = true,
                type = "control",
            },
        },
        events = { },
        icon = "interface/icons/monk_ability_fistoffury.blp",
        id = "mnfofst1",
        maxStacks = 1,
        name = "Fists of Fury",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Energizing Brew — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "monkdata",
    entry = {
        description = "",
        duration = 6,
        effects = {
            {
                amount = 10,
                amountMode = "flat",
                resourceRef = "f82db71a:c3gaf7dd",
                scaleWithRank = false,
                type = "resource",
            },
        },
        events = { },
        icon = "interface/icons/ability_monk_chibrew.blp",
        id = "mnenerg1",
        maxStacks = 1,
        name = "Energizing Brew",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Jab

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                key = "mnwjbdm1",
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
                    resourceRef = "f82db71a:p8kik0ep",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "mnwjbchi",
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
        icon = "interface/icons/ability_monk_jab.blp",
        id = "mnwjab01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Jab",
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
        spellbookCategory = "Windwalker",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Expel Harm

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    applyAura = false,
                    auraStacks = 1,
                    amountMode = "flat",
                    baseHealing = 48.875,
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.29325,
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
                key = "mnwexphl",
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
                    alwaysHits = false,
                    amountMode = "flat",
                    applyAura = false,
                    auraStacks = 1,
                    baseDamage = 24.4375,
                    damageSchoolRefs = {
                        "f82db71a:qtr10qyj",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.146625,
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
                key = "mnwexpdm",
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
                    resourceRef = "f82db71a:p8kik0ep",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "mnwexpch",
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
        icon = "interface/icons/ability_monk_expelharm.blp",
        id = "mnwexp01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Expel Harm",
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
        spellbookCategory = "Windwalker",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Tiger Palm

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    weaponDamageCoefficient = 2.25,
                    weaponDamageMode = "main_hand",
                },
                key = "mnwtpdm1",
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
        icon = "interface/icons/ability_monk_tigerpalm.blp",
        id = "mnwtp001",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Tiger Palm",
        range = 0,
        resourceCosts = {
            {
                amount = 1,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:p8kik0ep",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Windwalker",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Blackout Kick

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    weaponDamageCoefficient = 2.25,
                    weaponDamageMode = "main_hand",
                },
                key = "mnwbokdm",
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
        icon = "interface/icons/ability_monk_roundhousekick.blp",
        id = "mnwbok01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Blackout Kick",
        range = 0,
        resourceCosts = {
            {
                amount = 2,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:p8kik0ep",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Windwalker",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Rising Sun Kick

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    baseDamage = 150.609375,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.70284375,
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
                    weaponDamageCoefficient = 2.008125,
                    weaponDamageMode = "main_hand",
                },
                key = "mnwrskdm",
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
                    auraRef = "monkdata:mnmorta1",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "mnwrskau",
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
        cooldown = 1,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_monk_risingsunkick.blp",
        id = "mnwrsk01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Rising Sun Kick",
        range = 0,
        resourceCosts = {
            {
                amount = 2,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:p8kik0ep",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Windwalker",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Fists of Fury

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 1,
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
                    baseDamage = 113.27976562,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.55940625,
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
                    weaponDamageCoefficient = 1.1188125,
                    weaponDamageMode = "main_hand",
                },
                key = "mnwfofdm",
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
                    auraRef = "monkdata:mnfofst1",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "mnwfofau",
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
                invert = false,
                showOnTooltip = true,
                slotKey = "mainhand",
                tooltipTextOverride = "Requires Main Hand",
                type = "item_equipped",
                weaponTypeRefs = { },
            },
        },
        cooldown = 3,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/monk_ability_fistoffury.blp",
        id = "mnwfof01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Fists of Fury",
        range = 0,
        resourceCosts = {
            {
                amount = 3,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:p8kik0ep",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Windwalker",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Spinning Crane Kick

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 1,
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
                    baseDamage = 45.5625,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.225,
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
                    weaponDamageCoefficient = 0.45,
                    weaponDamageMode = "main_hand",
                },
                key = "mnwsckdm",
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
        icon = "interface/icons/ability_monk_cranekick_new.blp",
        id = "mnwsck01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Spinning Crane Kick",
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
        spellbookCategory = "Windwalker",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Energizing Brew

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    auraRef = "monkdata:mnenerg1",
                    basePower = 0,
                    duration = 6,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "mnwengau",
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
        icon = "interface/icons/ability_monk_chibrew.blp",
        id = "mnweng01",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Energizing Brew",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Windwalker",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Paralysis

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    auraRef = "monkdata:mnpara01",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "mnwparau",
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
        cooldown = 2,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_monk_paralysis.blp",
        id = "mnwpar01",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Paralysis",
        range = 20,
        resourceCosts = {
            {
                amount = 20,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:c3gaf7dd",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Windwalker",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Spear Hand Strike

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                key = "mnwsphin",
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
        cooldown = 2,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_monk_spearhand.blp",
        id = "mnwsph01",
        cooldownChannel = 5,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Spear Hand Strike",
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
        spellbookCategory = "Windwalker",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Detox

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    maxAuras = nil,
                    tags = {
                        "poison",
                    },
                    targetEvents = { },
                    type = "remove_aura_by_tag",
                },
                key = "mnwdetpo",
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
                    maxAuras = nil,
                    tags = {
                        "disease",
                    },
                    targetEvents = { },
                    type = "remove_aura_by_tag",
                },
                key = "mnwdetdi",
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
        conditions = { },
        cooldown = 1,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_monk_detox.blp",
        id = "mnwdet01",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Detox",
        range = 30,
        resourceCosts = {
            {
                amount = 20,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:c3gaf7dd",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Windwalker",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

# Mistweaver

## Soothing Mist — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "monkdata",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                amountMode = "flat",
                baseHealing = 57.5,
                scaleWithRank = true,
                statScaling = {
                    {
                        coefficient = 0.6,
                        statRef = "f82db71a:hj6d4kvy",
                    },
                },
                type = "heal",
            },
        },
        events = { },
        icon = "interface/icons/ability_monk_soothingmists.blp",
        id = "mnsooth1",
        maxStacks = 1,
        name = "Soothing Mist",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Enveloping Mist — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "monkdata",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                amountMode = "flat",
                baseHealing = 108.75,
                scaleWithRank = true,
                statScaling = {
                    {
                        coefficient = 0.6,
                        statRef = "f82db71a:hj6d4kvy",
                    },
                },
                type = "heal",
            },
        },
        events = { },
        icon = "interface/icons/spell_monk_envelopingmist.blp",
        id = "mnenvel1",
        maxStacks = 1,
        name = "Enveloping Mist",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Renewing Mist — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "monkdata",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                amountMode = "flat",
                baseHealing = 23.9417,
                scaleWithRank = true,
                statScaling = {
                    {
                        coefficient = 0.5304,
                        statRef = "f82db71a:hj6d4kvy",
                    },
                },
                type = "heal",
            },
        },
        events = { },
        icon = "interface/icons/ability_monk_renewingmists.blp",
        id = "mnrenew1",
        maxStacks = 1,
        name = "Renewing Mist",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Life Cocoon — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "monkdata",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                amountMode = "flat",
                baseAbsorption = 102.2125,
                damageSchoolRefs = { },
                scaleWithRank = true,
                statScaling = {
                    {
                        coefficient = 0.613275,
                        statRef = "f82db71a:hj6d4kvy",
                    },
                },
                type = "absorb",
            },
            {
                baseAmount = 50,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:ok80ohz3",
                statScaling = { },
                type = "stat",
            },
        },
        events = { },
        icon = "interface/icons/ability_monk_chicocoon.blp",
        id = "mncocoo1",
        maxStacks = 1,
        name = "Life Cocoon",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Jab

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    baseDamage = 44.625,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.20825,
                            statRef = "f82db71a:u7b49vs9",
                        },
                    },
                    targetEvents = {
                        "on_melee_taken",
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 0.5,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0.595,
                    weaponDamageMode = "main_hand",
                },
                key = "mnmjbdm1",
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
                    resourceRef = "f82db71a:p8kik0ep",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "mnmjbchi",
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
        icon = "interface/icons/ability_monk_jab.blp",
        id = "mnmjab01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Jab",
        range = 0,
        resourceCosts = {
            {
                amount = 4,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Mistweaver",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Expel Harm

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    applyAura = false,
                    auraStacks = 1,
                    amountMode = "flat",
                    baseHealing = 97.75,
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.5865,
                            statRef = "f82db71a:hj6d4kvy",
                        },
                    },
                    targetEvents = {
                        "on_heal_taken",
                        "on_critical_heal_taken",
                    },
                    type = "heal",
                    usesProjectile = false,
                },
                key = "mnmexphl",
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
                    alwaysHits = false,
                    amountMode = "flat",
                    applyAura = false,
                    auraStacks = 1,
                    baseDamage = 48.875,
                    damageSchoolRefs = {
                        "f82db71a:qtr10qyj",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.29325,
                            statRef = "f82db71a:hj6d4kvy",
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
                key = "mnmexpdm",
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
                    resourceRef = "f82db71a:p8kik0ep",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "mnmexpch",
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
        icon = "interface/icons/ability_monk_expelharm.blp",
        id = "mnmexp01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Expel Harm",
        range = 0,
        resourceCosts = {
            {
                amount = 2.5,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Mistweaver",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Soothing Mist

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 1,
        casterEvents = { },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "monkdata:mnsooth1",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "mnmsooau",
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
        conditions = { },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_monk_soothingmists.blp",
        id = "mnmsoo01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Soothing Mist",
        range = 30,
        resourceCosts = {
            {
                amount = 9,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Mistweaver",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Surging Mist

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 1,
        casterEvents = { },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    applyAura = false,
                    auraStacks = 1,
                    amountMode = "flat",
                    baseHealing = 123.25,
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.68,
                            statRef = "f82db71a:hj6d4kvy",
                        },
                    },
                    targetEvents = {
                        "on_heal_taken",
                        "on_critical_heal_taken",
                    },
                    type = "heal",
                    usesProjectile = false,
                },
                key = "mnmsurhl",
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
                    amount = 1,
                    amountMode = "flat",
                    resourceRef = "f82db71a:p8kik0ep",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "mnmsurch",
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
        icon = "interface/icons/ability_monk_surgingmist.blp",
        id = "mnmsur01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Surging Mist",
        range = 30,
        resourceCosts = {
            {
                amount = 8,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Mistweaver",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Enveloping Mist

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 1,
        casterEvents = { },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    auraRef = "monkdata:mnenvel1",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "mnmenvau",
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
        conditions = { },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_monk_envelopingmist.blp",
        id = "mnmenv01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Enveloping Mist",
        range = 30,
        resourceCosts = {
            {
                amount = 3,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:p8kik0ep",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Mistweaver",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Renewing Mist

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    auraRef = "monkdata:mnrenew1",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "mnmrenau",
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
                    amount = 1,
                    amountMode = "flat",
                    resourceRef = "f82db71a:p8kik0ep",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "mnmrench",
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
        cooldown = 1,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_monk_renewingmists.blp",
        id = "mnmren01",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Renewing Mist",
        range = 30,
        resourceCosts = {
            {
                amount = 4.5,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Mistweaver",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Life Cocoon

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    auraRef = "monkdata:mncocoo1",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "mnmcocau",
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
        conditions = { },
        cooldown = 10,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_monk_chicocoon.blp",
        id = "mnmcoc01",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Life Cocoon",
        range = 30,
        resourceCosts = {
            {
                amount = 4.5,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Mistweaver",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Revival

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    applyAura = false,
                    auraStacks = 1,
                    amountMode = "flat",
                    baseHealing = 70.7625,
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.424575,
                            statRef = "f82db71a:hj6d4kvy",
                        },
                    },
                    targetEvents = {
                        "on_heal_taken",
                        "on_critical_heal_taken",
                    },
                    type = "heal",
                    usesProjectile = false,
                },
                key = "mnmrevhl",
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
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    maxAuras = nil,
                    tags = {
                        "magic",
                    },
                    targetEvents = { },
                    type = "remove_aura_by_tag",
                },
                key = "mnmrevmg",
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
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    maxAuras = nil,
                    tags = {
                        "poison",
                    },
                    targetEvents = { },
                    type = "remove_aura_by_tag",
                },
                key = "mnmrevpo",
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
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    maxAuras = nil,
                    tags = {
                        "disease",
                    },
                    targetEvents = { },
                    type = "remove_aura_by_tag",
                },
                key = "mnmrevdi",
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
        conditions = { },
        cooldown = 10,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_monk_revival.blp",
        id = "mnmrev01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Revival",
        range = 0,
        resourceCosts = {
            {
                amount = 7,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Mistweaver",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Spinning Crane Kick

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 1,
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
                    baseDamage = 27.1096875,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.133875,
                            statRef = "f82db71a:u7b49vs9",
                        },
                    },
                    targetEvents = {
                        "on_melee_taken",
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 0.5,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0.26775,
                    weaponDamageMode = "main_hand",
                },
                key = "mnmsckdm",
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
                    baseHealing = 55.4625,
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.306,
                            statRef = "f82db71a:hj6d4kvy",
                        },
                    },
                    targetEvents = {
                        "on_heal_taken",
                        "on_critical_heal_taken",
                    },
                    type = "heal",
                    usesProjectile = false,
                },
                key = "mnmsckhl",
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
        icon = "interface/icons/ability_monk_cranekick_new.blp",
        id = "mnmsck01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Spinning Crane Kick",
        range = 0,
        resourceCosts = {
            {
                amount = 7.15,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Mistweaver",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Paralysis

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    auraRef = "monkdata:mnpara01",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "mnmparau",
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
        cooldown = 2,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_monk_paralysis.blp",
        id = "mnmpar01",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Paralysis",
        range = 20,
        resourceCosts = {
            {
                amount = 3,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Mistweaver",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Detox

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "monkdata",
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
                    maxAuras = nil,
                    tags = {
                        "poison",
                    },
                    targetEvents = { },
                    type = "remove_aura_by_tag",
                },
                key = "mnmdetpo",
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
                    maxAuras = nil,
                    tags = {
                        "disease",
                    },
                    targetEvents = { },
                    type = "remove_aura_by_tag",
                },
                key = "mnmdetdi",
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
        conditions = { },
        cooldown = 1,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_monk_detox.blp",
        id = "mnmdet01",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Detox",
        range = 30,
        resourceCosts = {
            {
                amount = 2.6,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Mistweaver",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

