# Death Knight Spell Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for the Death Knight dataset (`dknight1`).

Import required **Aura** entries before spells that reference them.

## Authoring rules applied

- Presences are **traits**, not spells.
- Pet/guardian-dependent abilities are omitted: Dancing Rune Weapon, Raise Dead, Death Pact, Ghoul Frenzy, Summon Gargoyle, Raise Ally, and Army of the Dead.
- No resource-system or cooldown-system changes are required.
- Rune-type simulation uses existing cooldown groups: `dk_blood`, `dk_frost`, and `dk_unholy`.
- A 1-Rune spell uses a 1-turn cooldown; a 2-Rune spell uses a 2-turn cooldown; Death and Decay uses a 3-turn cooldown. Runic Power-only spells have no DK rune group.
- Death Strike is Blood-only, Obliterate Frost-only, and Death and Decay Unholy-only for cooldown-group purposes.
- WotLK Rune/Runic Power costs are retained where represented, with RPE tuning overrides documented in the entries. Obliterate generates 20 Runic Power and Death and Decay generates 30.
- Blood uses the Tank role output profile; Frost and Unholy use DPS. DK magical attacks scale from Melee Attack Power.
- Descriptions are left empty so the runtime description builder derives them from components/effects.
- Disease-count scaling is not fabricated. Death Strike and Rune Tap use RPE direct-healing budgets that scale from Melee Attack Power rather than Healing Power.
- Frost Fever's attack-speed reduction is deferred because Core has no suitable attack-speed stat.
- Anti-Magic Shell is represented as +100 Magic Resistance for 1 turn; harmful-magic immunity and proportional Runic Power gain are not separately modelled.
- Anti-Magic Zone is represented as a one-turn all-allies +75 Magic Resistance effect; the stationary shared absorb pool is not currently representable.
- Bone Shield begins with 10 stacks and loses one stack on each damaging melee/ranged/spell event; its sub-turn internal cooldown is not represented.

## Deferred non-pet spells

- **Pestilence** — requires copying/spreading existing diseases.
- **Deathchill** — requires a next-qualifying-attack guaranteed-critical mechanic.
- **Lichborne** — requires fear/charm/sleep immunity and undead-state interactions.
- **Corpse Explosion** — requires corpse-centred AoE targeting.

# Blood

## Mark of Blood — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dknight1",
    entry = {
        description = "",
        duration = 3,
        effects = { },
        events = {
            {
                chance = 100,
                combatEventId = "on_melee_hit",
                triggerTarget = "event_other",
                effects = {
                    {
                        amountMode = "max_percent",
                        baseHealing = 4,
                        scaleWithRank = false,
                        statScaling = { },
                        type = "heal",
                    },
                },
            },
            {
                chance = 100,
                combatEventId = "on_melee_hit",
                triggerTarget = "aura_target",
                effects = {
                    {
                        auraRef = "dknight1:dkmob001",
                        stacks = 1,
                        type = "remove_aura",
                    },
                },
            },
            {
                chance = 100,
                combatEventId = "on_ranged_hit",
                triggerTarget = "event_other",
                effects = {
                    {
                        amountMode = "max_percent",
                        baseHealing = 4,
                        scaleWithRank = false,
                        statScaling = { },
                        type = "heal",
                    },
                },
            },
            {
                chance = 100,
                combatEventId = "on_ranged_hit",
                triggerTarget = "aura_target",
                effects = {
                    {
                        auraRef = "dknight1:dkmob001",
                        stacks = 1,
                        type = "remove_aura",
                    },
                },
            },
            {
                chance = 100,
                combatEventId = "on_spell_hit",
                triggerTarget = "event_other",
                effects = {
                    {
                        amountMode = "max_percent",
                        baseHealing = 4,
                        scaleWithRank = false,
                        statScaling = { },
                        type = "heal",
                    },
                },
            },
            {
                chance = 100,
                combatEventId = "on_spell_hit",
                triggerTarget = "aura_target",
                effects = {
                    {
                        auraRef = "dknight1:dkmob001",
                        stacks = 1,
                        type = "remove_aura",
                    },
                },
            },
        },
        icon = "interface/icons/ability_hunter_rapidkilling.blp",
        id = "dkmob001",
        maxStacks = 20,
        name = "Mark of Blood",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Vampiric Blood — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dknight1",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                baseAmount = 15,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:ygjno50i",
                statScaling = { },
                type = "stat",
            },
            {
                baseAmount = 35,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:ok80ohz3",
                statScaling = { },
                type = "stat",
            },
        },
        events = { },
        icon = "interface/icons/spell_shadow_lifedrain.blp",
        id = "dkvba001",
        maxStacks = 1,
        name = "Vampiric Blood",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Hysteria — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dknight1",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                baseAmount = 20,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:u7b49vs9",
                statScaling = { },
                type = "stat",
            },
            {
                amount = -10,
                amountMode = "max_percent",
                resourceRef = "f82db71a:q2ktkztt",
                scaleWithRank = false,
                type = "resource",
            },
        },
        events = { },
        icon = "interface/icons/spell_shadow_unholyfrenzy.blp",
        id = "dkhya001",
        maxStacks = 1,
        name = "Hysteria",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Blood Strike

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    baseDamage = 53.55,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.2499,
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
                    weaponDamageCoefficient = 0.714,
                    weaponDamageMode = "main_hand",
                },
                key = "dkbsdm01",
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
                    resourceRef = "f82db71a:jolh6o6e",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dkbsrp01",
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
        cooldownGroup = "dk_blood",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_deathknight_deathstrike.blp",
        id = "dkbs0001",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Blood Strike",
        range = 0,
        resourceCosts = {
            {
                amount = 1,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:runes001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Blood",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Blood Boil

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    baseDamage = 32.13,
                    damageSchoolRefs = {
                        "f82db71a:1ggt4t3v",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.112455,
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
                key = "dkbbdm01",
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
                    amount = 10,
                    amountMode = "flat",
                    resourceRef = "f82db71a:jolh6o6e",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dkbbrp01",
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
        cooldownGroup = "dk_blood",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_deathknight_bloodboil.blp",
        id = "dkbb0001",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Blood Boil",
        range = 0,
        resourceCosts = {
            {
                amount = 1,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:runes001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Blood",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Blood Tap

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    amount = 1,
                    amountMode = "flat",
                    resourceRef = "f82db71a:runes001",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dkbtrn01",
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
                    amount = 10,
                    amountMode = "flat",
                    resourceRef = "f82db71a:jolh6o6e",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dkbtrp01",
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
        icon = "interface/icons/spell_deathknight_bloodtap.blp",
        id = "dkbt0001",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Blood Tap",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Blood",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Death Strike

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    baseDamage = 58.65,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.2737,
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
                    weaponDamageCoefficient = 0.782,
                    weaponDamageMode = "main_hand",
                },
                key = "dkdsdm01",
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
                key = "dkdshl01",
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
                    amount = 15,
                    amountMode = "flat",
                    resourceRef = "f82db71a:jolh6o6e",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dkdsrp01",
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
        cooldown = 2,
        cooldownGroup = "dk_blood",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_deathknight_butcher2.blp",
        id = "dkds0001",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Death Strike",
        range = 0,
        resourceCosts = {
            {
                amount = 2,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:runes001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Blood",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Rune Strike

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    alwaysHits = true,
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
                    threatCoefficient = 2.5,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0.8,
                    weaponDamageMode = "main_hand",
                },
                key = "dkrsdm01",
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
            {
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Requires a successful melee defence this turn",
                type = "caster_defended_melee_this_turn",
            },
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_deathknight_darkconviction.blp",
        id = "dkrs0001",
        cooldownChannel = 5,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Rune Strike",
        range = 0,
        resourceCosts = {
            {
                amount = 20,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:jolh6o6e",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Blood",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Dark Command

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                key = "dkcmdt01",
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
        conditions = { },
        cooldown = 3,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_shamanrage.blp",
        id = "dkcmd001",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Dark Command",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Blood",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Rune Tap

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    baseHealing = 57.75,
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.3465,
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
                key = "dkrthl01",
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
        cooldownGroup = "dk_blood",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_deathknight_runetap.blp",
        id = "dkrt0001",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Rune Tap",
        range = 0,
        resourceCosts = {
            {
                amount = 1,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:runes001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Blood",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Mark of Blood

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    auraRef = "dknight1:dkmob001",
                    basePower = 0,
                    duration = 3,
                    stacks = 20,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dkmbau01",
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
        cooldownGroup = "dk_blood",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_hunter_rapidkilling.blp",
        id = "dkmb0001",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Mark of Blood",
        range = 0,
        resourceCosts = {
            {
                amount = 1,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:runes001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Blood",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Vampiric Blood

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    auraRef = "dknight1:dkvba001",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dkvbau01",
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
        icon = "interface/icons/spell_shadow_lifedrain.blp",
        id = "dkvb0001",
        cooldownChannel = 5,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Vampiric Blood",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Blood",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Heart Strike

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    baseDamage = 40.1625,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.187425,
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
                    weaponDamageCoefficient = 0.5355,
                    weaponDamageMode = "main_hand",
                },
                key = "dkhsdm01",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 2,
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
                    amount = 10,
                    amountMode = "flat",
                    resourceRef = "f82db71a:jolh6o6e",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dkhsrp01",
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
        cooldownGroup = "dk_blood",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/inv_weapon_shortblade_40.blp",
        id = "dkhs0001",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Heart Strike",
        range = 0,
        resourceCosts = {
            {
                amount = 1,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:runes001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Blood",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Hysteria

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    auraRef = "dknight1:dkhya001",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dkhyau01",
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
        icon = "interface/icons/spell_shadow_unholyfrenzy.blp",
        id = "dkhy0001",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Hysteria",
        range = 30,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Blood",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

# Frost

## Frost Fever — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dknight1",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                amountMode = "flat",
                baseDamage = 18,
                damageSchoolRefs = {
                    "f82db71a:hx7pnwv4",
                },
                scaleWithRank = true,
                statScaling = {
                    {
                        coefficient = 0.12,
                        statRef = "f82db71a:u7b49vs9",
                    },
                },
                type = "damage",
            },
        },
        events = { },
        icon = "interface/icons/spell_deathknight_frostfever.blp",
        id = "dkff0001",
        maxStacks = 1,
        name = "Frost Fever",
        stackBehavior = "refresh_duration",
        tags = {
            "disease",
            "dk_frost_fever",
        },
        tooltipTemplate = false,
    },
}
```

## Chains of Ice — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dknight1",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                cancelOnDamage = false,
                forceAutoHitAgainstTarget = false,
                preventCasting = false,
                type = "control",
                movementRangeOverride = 0,
            },
        },
        events = { },
        icon = "interface/icons/spell_frost_chainsofice.blp",
        id = "dkcia001",
        maxStacks = 1,
        name = "Chains of Ice",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Horn of Winter — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dknight1",
    entry = {
        description = "",
        duration = 10,
        effects = {
            {
                baseAmount = 6,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:zfqm8dxp",
                statScaling = { },
                type = "stat",
            },
            {
                baseAmount = 6,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:xqz0daz2",
                statScaling = { },
                type = "stat",
            },
        },
        events = { },
        icon = "interface/icons/inv_misc_horn_02.blp",
        id = "dkhwa001",
        maxStacks = 1,
        name = "Horn of Winter",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Icebound Fortitude — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dknight1",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                baseAmount = 30,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:pu05li08",
                statScaling = { },
                type = "stat",
            },
        },
        events = { },
        icon = "interface/icons/spell_deathknight_iceboundfortitude.blp",
        id = "dkifta01",
        maxStacks = 1,
        name = "Icebound Fortitude",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Remorseless Winter — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dknight1",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                cancelOnDamage = true,
                forceAutoHitAgainstTarget = false,
                preventCasting = true,
                type = "control",
                movementRangeOverride = 0,
            },
        },
        events = { },
        icon = "interface/icons/ability_deathknight_remorselesswinters2.blp",
        id = "dkhca001",
        maxStacks = 1,
        name = "Remorseless Winter",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Unbreakable Armor — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dknight1",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                baseAmount = 25,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:v42albuv",
                statScaling = { },
                type = "stat",
            },
            {
                baseAmount = 20,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:zfqm8dxp",
                statScaling = { },
                type = "stat",
            },
        },
        events = { },
        icon = "interface/icons/spell_frost_frostarmor02.blp",
        id = "dkuaa001",
        maxStacks = 1,
        name = "Unbreakable Armor",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Icy Touch

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    baseDamage = 89.25,
                    damageSchoolRefs = {
                        "f82db71a:hx7pnwv4",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.312375,
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
                key = "dkitdm01",
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
                    auraRef = "dknight1:dkff0001",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dkitau01",
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
                    resourceRef = "f82db71a:jolh6o6e",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dkitrp01",
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
        cooldownGroup = "dk_frost",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_deathknight_icetouch.blp",
        id = "dkit0001",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Icy Touch",
        range = 20,
        resourceCosts = {
            {
                amount = 1,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:runes001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Frost",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Chains of Ice

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    auraRef = "dknight1:dkcia001",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dkciau01",
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
                    auraRef = "dknight1:dkff0001",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dkciff01",
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
                    resourceRef = "f82db71a:jolh6o6e",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dkcirp01",
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
        cooldownGroup = "dk_frost",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_frost_chainsofice.blp",
        id = "dkci0001",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Chains of Ice",
        range = 20,
        resourceCosts = {
            {
                amount = 1,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:runes001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Frost",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Horn of Winter

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    auraRef = "dknight1:dkhwa001",
                    basePower = 0,
                    duration = 10,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dkhwau01",
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
                    amount = 10,
                    amountMode = "flat",
                    resourceRef = "f82db71a:jolh6o6e",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dkhwrp01",
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
        icon = "interface/icons/inv_misc_horn_02.blp",
        id = "dkhw0001",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Horn of Winter",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Frost",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Obliterate

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    baseDamage = 73.3125,
                    damageSchoolRefs = {
                        "f82db71a:hx7pnwv4",
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.342125,
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
                    weaponDamageCoefficient = 0.9775,
                    weaponDamageMode = "main_hand",
                },
                key = "dkobdm01",
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
                    amount = 20,
                    amountMode = "flat",
                    resourceRef = "f82db71a:jolh6o6e",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dkobrp01",
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
        cooldown = 2,
        cooldownGroup = "dk_frost",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_deathknight_classicon.blp",
        id = "dkob0001",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Obliterate",
        range = 0,
        resourceCosts = {
            {
                amount = 2,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:runes001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Frost",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Frost Strike

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                        "f82db71a:hx7pnwv4",
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
                key = "dkfsdm01",
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
        icon = "interface/icons/spell_deathknight_empowerruneblade2.blp",
        id = "dkfs0001",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Frost Strike",
        range = 0,
        resourceCosts = {
            {
                amount = 40,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:jolh6o6e",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Frost",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Howling Blast

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    baseDamage = 48.875,
                    damageSchoolRefs = {
                        "f82db71a:hx7pnwv4",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.1710625,
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
                key = "dkhbdm01",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 4,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "enemy",
                    type = "raid_marker",
                },
            },
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    amount = 15,
                    amountMode = "flat",
                    resourceRef = "f82db71a:jolh6o6e",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dkhbrp01",
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
        cooldownGroup = "dk_frost",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_frost_arcticwinds.blp",
        id = "dkhb0001",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Howling Blast",
        range = 20,
        resourceCosts = {
            {
                amount = 2,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:runes001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Frost",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Mind Freeze

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                key = "dkmfin01",
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
        icon = "interface/icons/spell_deathknight_mindfreeze.blp",
        id = "dkmf0001",
        cooldownChannel = 5,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Mind Freeze",
        range = 20,
        resourceCosts = {
            {
                amount = 10,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:jolh6o6e",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Frost",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Icebound Fortitude

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    auraRef = "dknight1:dkifta01",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dkifau01",
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
        icon = "interface/icons/spell_deathknight_iceboundfortitude.blp",
        id = "dkif0001",
        cooldownChannel = 5,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Icebound Fortitude",
        range = 0,
        resourceCosts = {
            {
                amount = 10,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:jolh6o6e",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Frost",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Remorseless Winter

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    auraRef = "dknight1:dkhca001",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dkhcau01",
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
                    auraRef = "dknight1:dkff0001",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dkhcff01",
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
        icon = "interface/icons/ability_deathknight_remorselesswinters2.blp",
        id = "dkhc0001",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Remorseless Winter",
        range = 0,
        resourceCosts = {
            {
                amount = 40,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:jolh6o6e",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Frost",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Unbreakable Armor

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    auraRef = "dknight1:dkuaa001",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dkuaau01",
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
                    amount = 10,
                    amountMode = "flat",
                    resourceRef = "f82db71a:jolh6o6e",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dkuarp01",
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
        cooldownGroup = "dk_frost",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_frost_frostarmor02.blp",
        id = "dkua0001",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Unbreakable Armor",
        range = 0,
        resourceCosts = {
            {
                amount = 1,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:runes001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Frost",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Empower Rune Weapon

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    amount = 6,
                    amountMode = "flat",
                    resourceRef = "f82db71a:runes001",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dkerwr01",
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
                    amount = 25,
                    amountMode = "flat",
                    resourceRef = "f82db71a:jolh6o6e",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dkerwp01",
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
        icon = "interface/icons/inv_sword_62.blp",
        id = "dkerw001",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Empower Rune Weapon",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Frost",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

# Unholy

## Blood Plague — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dknight1",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                amountMode = "flat",
                baseDamage = 18,
                damageSchoolRefs = {
                    "f82db71a:1ggt4t3v",
                },
                scaleWithRank = true,
                statScaling = {
                    {
                        coefficient = 0.12,
                        statRef = "f82db71a:u7b49vs9",
                    },
                },
                type = "damage",
            },
        },
        events = { },
        icon = "interface/icons/spell_shadow_bloodboil.blp",
        id = "dkbp0001",
        maxStacks = 1,
        name = "Blood Plague",
        stackBehavior = "refresh_duration",
        tags = {
            "disease",
            "dk_blood_plague",
        },
        tooltipTemplate = false,
    },
}
```

## Death and Decay — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dknight1",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                amountMode = "flat",
                baseDamage = 10.77375,
                damageSchoolRefs = {
                    "f82db71a:1ggt4t3v",
                },
                scaleWithRank = true,
                statScaling = {
                    {
                        coefficient = 0.1,
                        statRef = "f82db71a:u7b49vs9",
                    },
                },
                type = "damage",
                threatCoefficient = 2,
            },
        },
        events = { },
        icon = "interface/icons/spell_shadow_deathanddecay.blp",
        id = "dkdnda01",
        maxStacks = 1,
        name = "Death and Decay",
        stackBehavior = "refresh_duration",
        tags = {
            "dk_death_and_decay",
        },
        tooltipTemplate = false,
    },
}
```

## Death Grip

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                key = "dkdgta01",
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
        icon = "interface/icons/spell_deathknight_strangulate.blp",
        id = "dkdg0001",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Death Grip",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Unholy",
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

## Strangulate — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dknight1",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                cancelOnDamage = false,
                forceAutoHitAgainstTarget = false,
                preventCasting = true,
                type = "control",
            },
        },
        events = { },
        icon = "interface/icons/spell_shadow_soulleech_3.blp",
        id = "dkstra01",
        maxStacks = 1,
        name = "Strangulate",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Anti-Magic Shell — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dknight1",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                baseAmount = 100,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:zs1nbz13",
                statScaling = { },
                type = "stat",
            },
        },
        events = { },
        icon = "interface/icons/spell_shadow_antimagicshell.blp",
        id = "dkamsa01",
        maxStacks = 1,
        name = "Anti-Magic Shell",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Bone Shield — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dknight1",
    entry = {
        description = "",
        duration = 5,
        effects = {
            {
                baseAmount = 20,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:pu05li08",
                statScaling = { },
                type = "stat",
            },
            {
                baseAmount = 2,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:gj9wxb0x",
                statScaling = { },
                type = "stat",
            },
        },
        events = {
            {
                chance = 100,
                combatEventId = "on_melee_taken",
                triggerTarget = "aura_target",
                effects = {
                    {
                        auraRef = "dknight1:dkbsha01",
                        stacks = 1,
                        type = "remove_aura",
                    },
                },
            },
            {
                chance = 100,
                combatEventId = "on_ranged_taken",
                triggerTarget = "aura_target",
                effects = {
                    {
                        auraRef = "dknight1:dkbsha01",
                        stacks = 1,
                        type = "remove_aura",
                    },
                },
            },
            {
                chance = 100,
                combatEventId = "on_spell_taken",
                triggerTarget = "aura_target",
                effects = {
                    {
                        auraRef = "dknight1:dkbsha01",
                        stacks = 1,
                        type = "remove_aura",
                    },
                },
            },
        },
        icon = "interface/icons/ability_deathknight_boneshield.blp",
        id = "dkbsha01",
        maxStacks = 10,
        name = "Bone Shield",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Anti-Magic Zone — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "dknight1",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                baseAmount = 75,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:zs1nbz13",
                statScaling = { },
                type = "stat",
            },
        },
        events = { },
        icon = "interface/icons/spell_deathknight_antimagiczone.blp",
        id = "dkamza01",
        maxStacks = 1,
        name = "Anti-Magic Zone",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = false,
    },
}
```

## Plague Strike

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    baseDamage = 66.9375,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.312375,
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
                    weaponDamageCoefficient = 0.8925,
                    weaponDamageMode = "main_hand",
                },
                key = "dkpsdm01",
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
                    auraRef = "dknight1:dkbp0001",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dkpsau01",
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
                    resourceRef = "f82db71a:jolh6o6e",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dkpsrp01",
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
        cooldownGroup = "dk_unholy",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_deathknight_empowerruneblade.blp",
        id = "dkps0001",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Plague Strike",
        range = 0,
        resourceCosts = {
            {
                amount = 1,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:runes001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Unholy",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Death Coil

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    baseDamage = 225,
                    damageSchoolRefs = {
                        "f82db71a:1ggt4t3v",
                    },
                    damageType = "spell",
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
                        "on_spell_taken",
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0,
                    weaponDamageMode = "none",
                },
                key = "dkcodm01",
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
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_shadow_deathcoil.blp",
        id = "dkcoil01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Death Coil",
        range = 30,
        resourceCosts = {
            {
                amount = 40,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:jolh6o6e",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Unholy",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Death and Decay

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    auraRef = "dknight1:dkdnda01",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dkdndau1",
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
                    amount = 30,
                    amountMode = "flat",
                    resourceRef = "f82db71a:jolh6o6e",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dkdndrp1",
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
        cooldownGroup = "dk_unholy",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_shadow_deathanddecay.blp",
        id = "dkdnd001",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Death and Decay",
        range = 30,
        resourceCosts = {
            {
                amount = 3,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:runes001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Unholy",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Strangulate

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    auraRef = "dknight1:dkstra01",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dkstrau1",
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
        cooldownGroup = "dk_unholy",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_shadow_soulleech_3.blp",
        id = "dkstr001",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Strangulate",
        range = 30,
        resourceCosts = {
            {
                amount = 1,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:runes001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Unholy",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Anti-Magic Shell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    auraRef = "dknight1:dkamsa01",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dkamsau1",
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
        icon = "interface/icons/spell_shadow_antimagicshell.blp",
        id = "dkams001",
        cooldownChannel = 5,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Anti-Magic Shell",
        range = 0,
        resourceCosts = {
            {
                amount = 20,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:jolh6o6e",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Unholy",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Scourge Strike

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    baseDamage = 73.3125,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                        "f82db71a:1ggt4t3v",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.342125,
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
                    weaponDamageCoefficient = 0.9775,
                    weaponDamageMode = "main_hand",
                },
                key = "dkssph01",
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
                    amount = 15,
                    amountMode = "flat",
                    resourceRef = "f82db71a:jolh6o6e",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dkssrp01",
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
        cooldown = 2,
        cooldownGroup = "dk_unholy",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_deathknight_scourgestrike.blp",
        id = "dkss0001",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Scourge Strike",
        range = 0,
        resourceCosts = {
            {
                amount = 2,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:runes001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Unholy",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Bone Shield

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    auraRef = "dknight1:dkbsha01",
                    basePower = 0,
                    duration = 5,
                    stacks = 10,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dkbsau01",
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
                    amount = 10,
                    amountMode = "flat",
                    resourceRef = "f82db71a:jolh6o6e",
                    scaleWithRank = false,
                    targetEvents = { },
                    type = "resource",
                },
                key = "dkbsrp01",
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
        cooldownGroup = "dk_unholy",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_deathknight_boneshield.blp",
        id = "dkbsld01",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Bone Shield",
        range = 0,
        resourceCosts = {
            {
                amount = 1,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:runes001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Unholy",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Anti-Magic Zone

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "dknight1",
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
                    auraRef = "dknight1:dkamza01",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "dkamzau1",
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
        cooldown = 1,
        cooldownGroup = "dk_unholy",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_deathknight_antimagiczone.blp",
        id = "dkamz001",
        cooldownChannel = 5,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Anti-Magic Zone",
        range = 0,
        resourceCosts = {
            {
                amount = 1,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:runes001",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Unholy",
        tags = { },
        tooltipTemplate = false,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

