# Hunter Spell Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for the Hunter class dataset (`a93f7c12`).

Import each listed **Aura** before its associated **Spell**. All entries use the current RPE2 `dev` spell/aura schema and cooldown channels.

## Authoring notes

- Hunter uses **Mana** (`f82db71a:4c8mfm99`). Every Hunter spell below therefore pays an appropriate **base Mana** cost using `amountMode = "base_percent"`.
- Main Action = cooldown channel 1; Bonus Action = channel 2; Buff Action = channel 3.
- Damage/weapon spell Mana costs use the current spell-authoring resource formula. Pure utility/control buffs use the closest current Mana-based analogue; short personal/target utility is generally 5% base Mana, while Trueshot Aura uses the 10% group-stat-buff convention.
- Mana costs used here:

| Spell | Base Mana |
|---|---:|
| Bestial Wrath | 10.0% |
| Kill Command | 5.0% |
| Intimidation | 5.0% |
| Aimed Shot | 6.8% |
| Trueshot Aura | 10.0% |
| Hunter's Mark | 5.0% |
| Serpent Sting | 6.3% |
| Arcane Shot | 5.0% |
| Rapid Fire | 5.0% |
| Bursting Shot | 5.0% |
| Kill Shot | 13.6% |
| Explosive Shot | 18.1% |
| Multi Shot | 18.1% |
| Volley | 12.3% |
| Survival of the Fittest | 5.0% |
| Hatchet Toss | 6.3% |
| Carve | 10.0% |
| Raptor Strike | 5.0% |
| Mongoose Bite | 13.6% |
| Freezing Trap | 5.0% |
- Hunter ranged attacks and damaging ranged auras scale from **Ranged Attack Power** (`f82db71a:v2rs9cpy`). Hunter melee attacks scale from **Melee Attack Power** (`f82db71a:u7b49vs9`).
- Fixed percentage buffs and control effects do not scale with spell rank. Damage-bearing spells/auras use ranks with the standard 8-level interval.
- **Hunter's Mark** had no exact current reactive-damage analogue specified. Its proc uses the current Molten Armor reactive-event budget (`28.1667 + 0.4225 × Ranged Attack Power`), changed to Physical damage and `on_ranged_taken`. Its duration is set to 5 turns to match its 5-turn cooldown.
- **Raptor Strike** did not specify an aura duration. Its stacking Melee Attack Power aura is set to 5 turns, refreshing duration on additional stacks, with a maximum of 3 stacks.
- **Mongoose Bite** uses the **Spender** damage budget from the spell-authoring specification but remains on Bonus Action (channel 2), as requested. It requires Raptor Strike but does not consume Raptor Strike stacks because consumption was not specified.
- The current `dev` Mage dataset contains no spell or aura named **Blizzard**. The current Aura damage schema also does not support periodic weapon-damage coefficients. **Volley** is therefore represented as the closest supported current equivalent: a 1-turn Main Action, up-to-5-target, same-raid-marker Physical ranged-weapon attack using the current multi-target weapon-damage budget. No unsupported periodic weapon-damage aura is invented.
- **Intimidation** copies the current Hammer of Justice control behavior, cooldown and action channel, with Hunter name/icon/aura.
- **Survival of the Fittest** copies Divine Protection: 30% Damage Reduction for 1 turn, 5-turn cooldown, Reaction channel.
- **Hatchet Toss** copies Heroic Throw's damage, thrown-weapon requirement and high-threat behavior; its Rage cost is replaced with 6.3% base Mana.
- **Carve** copies Cleave's two-target same-raid-marker melee attack; its Rage cost is replaced with 10% base Mana.
- **Rapid Fire** now lasts 2 turns and deals additional Physical damage on each `on_ranged_hit`, using the current Shadow Blades triggered-damage shape with Ranged Attack Power.
- **Bursting Shot** copies Blind's 1-turn break-on-damage control, 10-turn cooldown and Bonus Action channel.
- **Kill Shot** uses the current Shadow Word: Death execute condition (`target_health_percent <= 20`) and spender-sized direct damage, converted to Physical damage and Ranged Attack Power.
- **Freezing Trap** copies the current Repentance control behavior, cast time, cooldown and action channel, with Hunter name/icon/aura.

## Beastmaster

### Bestial Wrath

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "a93f7c12",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                baseAmount = 20,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:gj9wxb0x",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/ability_druid_ferociousbite.blp",
        id = "a8j9d1rx",
        maxStacks = 1,
        name = "Bestial Wrath",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Damage Done by 20%.",
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
    datasetId = "a93f7c12",
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
                    baseDamage = 157.25,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.550375,
                            statRef = "f82db71a:v2rs9cpy",
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
                key = "bstwdmg1",
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
                    auraRef = "a93f7c12:a8j9d1rx",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "bstwself",
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
                    auraRef = "a93f7c12:a8j9d1rx",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "bstwpet1",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 1,
                    minTargets = 1,
                    requiresTarget = false,
                    targetDisposition = "ally",
                    type = "pet",
                },
            },
        },
        conditions = {  },
        cooldown = 10,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_druid_ferociousbite.blp",
        id = "5uzx6ajs",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Bestial Wrath",
        range = 0,
        resourceCosts = {
            {
                amount = 10,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Beastmaster",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "a93f7c12:a8j9d1rx",
                    datasetId = "a93f7c12",
                    descriptionText = "Increases Damage Done by 20%.",
                    duration = 2,
                    icon = "interface/icons/ability_druid_ferociousbite.blp",
                    nameText = "Bestial Wrath",
                    powerLevel = 0,
                    spellDatasetId = "a93f7c12",
                    stacks = 1,
                    targetContext = {
                        object = "you",
                        possessive = "your",
                        reflexive = "yourself",
                        subject = "you",
                    },
                    tokens = {  },
                },
                {
                    auraRef = "a93f7c12:a8j9d1rx",
                    datasetId = "a93f7c12",
                    descriptionText = "Increases Damage Done by 20%.",
                    duration = 2,
                    icon = "interface/icons/ability_druid_ferociousbite.blp",
                    nameText = "Bestial Wrath",
                    powerLevel = 0,
                    spellDatasetId = "a93f7c12",
                    stacks = 1,
                    targetContext = {
                        object = "your pet",
                        possessive = "your pet's",
                        reflexive = "itself",
                        subject = "your pet",
                    },
                    tokens = {  },
                },
            },
            mainText = "Deal {DAMAGE_1} Physical damage to an enemy. Apply Bestial Wrath to yourself and your pet for 2 turns.",
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

### Kill Command

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "a93f7c12",
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
        icon = "interface/icons/ability_hunter_killcommand.blp",
        id = "28vw28pd",
        maxStacks = 1,
        name = "Kill Command",
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
    datasetId = "a93f7c12",
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
                    auraRef = "a93f7c12:28vw28pd",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "killpet1",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 1,
                    minTargets = 1,
                    requiresTarget = false,
                    targetDisposition = "ally",
                    type = "pet",
                },
            },
        },
        conditions = {  },
        cooldown = 5,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_hunter_killcommand.blp",
        id = "bgsnh6id",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Kill Command",
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
        spellbookCategory = "Beastmaster",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "a93f7c12:28vw28pd",
                    datasetId = "a93f7c12",
                    descriptionText = "Increases Melee Attack Power by 30%.",
                    duration = 1,
                    icon = "interface/icons/ability_hunter_killcommand.blp",
                    nameText = "Kill Command",
                    powerLevel = 0,
                    spellDatasetId = "a93f7c12",
                    stacks = 1,
                    targetContext = {
                        object = "your pet",
                        possessive = "your pet's",
                        reflexive = "itself",
                        subject = "your pet",
                    },
                    tokens = {  },
                },
            },
            mainText = "Apply Kill Command to your pet for 1 turn.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Intimidation

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "a93f7c12",
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
        icon = "interface/icons/ability_devour.blp",
        id = "qnrcfx4u",
        maxStacks = 1,
        name = "Intimidation",
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
    datasetId = "a93f7c12",
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
                    auraRef = "a93f7c12:qnrcfx4u",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "intimda1",
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
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_devour.blp",
        id = "9btwec6f",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Intimidation",
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
        spellbookCategory = "Beastmaster",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "a93f7c12:qnrcfx4u",
                    datasetId = "a93f7c12",
                    descriptionText = "Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                    duration = 1,
                    icon = "interface/icons/ability_devour.blp",
                    nameText = "Intimidation",
                    powerLevel = 0,
                    spellDatasetId = "a93f7c12",
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
            mainText = "Apply Intimidation to an enemy for 1 turn.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Marksmanship

### Aimed Shot

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "a93f7c12",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 1,
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
                    baseDamage = 106.3125,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "ranged",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.525,
                            statRef = "f82db71a:v2rs9cpy",
                        },
                    },
                    targetEvents = {
                        "on_ranged_taken",
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 1.05,
                    weaponDamageMode = "main_hand",
                },
                key = "aimeddmg",
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
                slotKey = "ranged",
                tooltipTextOverride = "Requires a bow, crossbow, or gun",
                type = "item_equipped",
                weaponTypeRefs = {
                    "f82db71a:l3ce0puc",
                    "f82db71a:j2gceby4",
                    "f82db71a:anoo8qfp",
                },
            },
        },
        cooldown = 1,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/inv_spear_07.blp",
        id = "nq9mgf7d",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Aimed Shot",
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
        spellbookCategory = "Marksmanship",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Deal {DAMAGE_1} Physical ranged weapon damage to an enemy.",
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

### Trueshot Aura

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "a93f7c12",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                baseAmount = 40,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:v2rs9cpy",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/ability_trueshot.blp",
        id = "eq3o6532",
        maxStacks = 1,
        name = "Trueshot Aura",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Ranged Attack Power by 40%.",
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
    datasetId = "a93f7c12",
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
                    auraRef = "a93f7c12:eq3o6532",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "trueshot",
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
        icon = "interface/icons/ability_trueshot.blp",
        id = "6saw5yg2",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Trueshot Aura",
        range = 0,
        resourceCosts = {
            {
                amount = 10,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Marksmanship",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "a93f7c12:eq3o6532",
                    datasetId = "a93f7c12",
                    descriptionText = "Increases Ranged Attack Power by 40%.",
                    duration = 1,
                    icon = "interface/icons/ability_trueshot.blp",
                    nameText = "Trueshot Aura",
                    powerLevel = 0,
                    spellDatasetId = "a93f7c12",
                    stacks = 1,
                    targetContext = {
                        object = "all allies",
                        possessive = "all allies'",
                        reflexive = "themselves",
                        subject = "all allies",
                    },
                    tokens = {  },
                },
            },
            mainText = "Apply Trueshot Aura to all allies for 1 turn.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Hunter's Mark

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "a93f7c12",
    entry = {
        description = "",
        duration = 5,
        effects = {  },
        events = {
            {
                chance = 100,
                combatEventId = "on_ranged_taken",
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 28.1667,
                        damageSchoolRefs = {
                            "f82db71a:v1azo4j6",
                        },
                        scaleWithRank = true,
                        statScaling = {
                            {
                                coefficient = 0.4225,
                                statRef = "f82db71a:v2rs9cpy",
                            },
                        },
                        type = "damage",
                    },
                },
                triggerTarget = "aura_target",
            },
        },
        icon = "interface/icons/ability_hunter_snipershot.blp",
        id = "12rc9k9z",
        maxStacks = 1,
        name = "Hunter's Mark",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "When the affected unit is hit by a ranged attack, deal {AURA_EVENT_DAMAGE_1} Physical damage to it.",
            bodyTokens = {
                {
                    applyMode = "damage_amount",
                    baseField = "baseDamage",
                    effectIndex = 1,
                    key = "AURA_EVENT_DAMAGE_1",
                    tokenType = "aura_amount",
                    eventIndex = 1,
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
    datasetId = "a93f7c12",
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
                    auraRef = "a93f7c12:12rc9k9z",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "markaply",
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
        cooldown = 5,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_hunter_snipershot.blp",
        id = "11yx5k2d",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Hunter's Mark",
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
        spellbookCategory = "Marksmanship",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "a93f7c12:12rc9k9z",
                    datasetId = "a93f7c12",
                    descriptionText = "When the affected unit is hit by a ranged attack, deal {AURA_EVENT_DAMAGE_1} Physical damage to it.",
                    duration = 5,
                    icon = "interface/icons/ability_hunter_snipershot.blp",
                    nameText = "Hunter's Mark",
                    powerLevel = 0,
                    spellDatasetId = "a93f7c12",
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
                            key = "AURA_EVENT_DAMAGE_1",
                            tokenType = "aura_amount",
                            eventIndex = 1,
                        },
                    },
                },
            },
            mainText = "Apply Hunter's Mark to an enemy for 5 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Serpent Sting

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "a93f7c12",
    entry = {
        description = "",
        duration = 5,
        effects = {
            {
                amountMode = "flat",
                baseDamage = 20.8,
                damageSchoolRefs = {
                    "f82db71a:qtr10qyj",
                },
                scaleWithRank = true,
                statScaling = {
                    {
                        coefficient = 0.364,
                        statRef = "f82db71a:v2rs9cpy",
                    },
                },
                type = "damage",
            },
        },
        events = {  },
        icon = "interface/icons/ability_hunter_quickshot.blp",
        id = "0h6rl370",
        maxStacks = 1,
        name = "Serpent Sting",
        stackBehavior = "refresh_duration",
        tags = {  },
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

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "a93f7c12",
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
                    auraRef = "a93f7c12:0h6rl370",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "serpapp1",
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
                slotKey = "ranged",
                tooltipTextOverride = "Requires a bow, crossbow, or gun",
                type = "item_equipped",
                weaponTypeRefs = {
                    "f82db71a:l3ce0puc",
                    "f82db71a:j2gceby4",
                    "f82db71a:anoo8qfp",
                },
            },
        },
        cooldown = 1,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_hunter_quickshot.blp",
        id = "yuprvh3j",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Serpent Sting",
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
        spellbookCategory = "Marksmanship",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "a93f7c12:0h6rl370",
                    datasetId = "a93f7c12",
                    descriptionText = "Deals {AURA_DAMAGE_1} Nature damage each turn.",
                    duration = 5,
                    icon = "interface/icons/ability_hunter_quickshot.blp",
                    nameText = "Serpent Sting",
                    powerLevel = 0,
                    spellDatasetId = "a93f7c12",
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
            mainText = "Apply Serpent Sting to an enemy for 5 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Arcane Shot

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "a93f7c12",
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
                    baseDamage = 105,
                    damageSchoolRefs = {
                        "f82db71a:dtxhglqg",
                    },
                    damageType = "ranged",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.3675,
                            statRef = "f82db71a:v2rs9cpy",
                        },
                    },
                    targetEvents = {
                        "on_ranged_taken",
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0,
                    weaponDamageMode = "none",
                },
                key = "arcsdmg1",
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
                slotKey = "ranged",
                tooltipTextOverride = "Requires a bow, crossbow, or gun",
                type = "item_equipped",
                weaponTypeRefs = {
                    "f82db71a:l3ce0puc",
                    "f82db71a:j2gceby4",
                    "f82db71a:anoo8qfp",
                },
            },
        },
        cooldown = 1,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_hunter_criticalshot.blp",
        id = "fk5fq1st",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Arcane Shot",
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
        spellbookCategory = "Marksmanship",
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

### Rapid Fire

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "a93f7c12",
    entry = {
        description = "",
        duration = 2,
        effects = {  },
        events = {
            {
                chance = 100,
                combatEventId = "on_ranged_hit",
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 28.1667,
                        damageSchoolRefs = {
                            "f82db71a:v1azo4j6",
                        },
                        scaleWithRank = true,
                        statScaling = {
                            {
                                coefficient = 0.29575,
                                statRef = "f82db71a:v2rs9cpy",
                            },
                        },
                        type = "damage",
                    },
                },
                triggerTarget = "event_other",
            },
        },
        icon = "interface/icons/ability_hunter_runningshot.blp",
        id = "6phb5os0",
        maxStacks = 1,
        name = "Rapid Fire",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "When the affected unit hits with a ranged attack, deal {AURA_EVENT_DAMAGE_1} Physical damage to the target.",
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
    datasetId = "a93f7c12",
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
                    auraRef = "a93f7c12:6phb5os0",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "rapidself",
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
        icon = "interface/icons/ability_hunter_runningshot.blp",
        id = "0ukabaim",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Rapid Fire",
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
        spellbookCategory = "Marksmanship",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "a93f7c12:6phb5os0",
                    datasetId = "a93f7c12",
                    descriptionText = "When you hit with a ranged attack, deal {AURA_EVENT_DAMAGE_1} Physical damage to the target.",
                    duration = 2,
                    icon = "interface/icons/ability_hunter_runningshot.blp",
                    nameText = "Rapid Fire",
                    powerLevel = 0,
                    spellDatasetId = "a93f7c12",
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
            mainText = "Apply Rapid Fire to yourself for 2 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Bursting Shot

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "a93f7c12",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                cancelOnDamage = true,
                forceAutoHitAgainstTarget = true,
                movementRangeOverride = 0,
                preventCasting = true,
                statScaling = {  },
                type = "control",
            },
        },
        events = {  },
        icon = "interface/icons/ability_hunter_burstingshot.blp",
        id = "burstau1",
        maxStacks = 1,
        name = "Bursting Shot",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Breaks when the affected unit takes damage. Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
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
    datasetId = "a93f7c12",
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
                    auraRef = "a93f7c12:burstau1",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "burstcmp",
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
        cooldown = 10,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_hunter_burstingshot.blp",
        id = "burst001",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Bursting Shot",
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
        spellbookCategory = "Marksmanship",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "a93f7c12:burstau1",
                    datasetId = "a93f7c12",
                    descriptionText = "Breaks when the affected unit takes damage. Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                    duration = 1,
                    icon = "interface/icons/ability_hunter_burstingshot.blp",
                    nameText = "Bursting Shot",
                    powerLevel = 0,
                    spellDatasetId = "a93f7c12",
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
            mainText = "Apply Bursting Shot to an enemy for 1 turn.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Kill Shot

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "a93f7c12",
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
                    baseDamage = 225,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "ranged",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 1.125,
                            statRef = "f82db71a:v2rs9cpy",
                        },
                    },
                    targetEvents = {
                        "on_ranged_taken",
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0,
                    weaponDamageMode = "none",
                },
                key = "killdmg1",
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
                slotKey = "ranged",
                tooltipTextOverride = "Requires a bow, crossbow, or gun",
                type = "item_equipped",
                weaponTypeRefs = {
                    "f82db71a:l3ce0puc",
                    "f82db71a:j2gceby4",
                    "f82db71a:anoo8qfp",
                },
            },
            {
                invert = false,
                maximumValue = 20,
                showOnTooltip = true,
                tooltipTextOverride = "",
                type = "target_health_percent",
            },
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_hunter_assassinate2.blp",
        id = "killshot1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Kill Shot",
        range = 0,
        resourceCosts = {
            {
                amount = 13.6,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Marksmanship",
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

### Explosive Shot

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "a93f7c12",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                amountMode = "flat",
                baseDamage = 19.06125,
                damageSchoolRefs = {
                    "f82db71a:esjguw6d",
                },
                scaleWithRank = true,
                statScaling = {
                    {
                        coefficient = 0.13342875,
                        statRef = "f82db71a:v2rs9cpy",
                    },
                },
                type = "damage",
            },
        },
        events = {  },
        icon = "interface/icons/ability_hunter_explosiveshot.blp",
        id = "gi2ibat0",
        maxStacks = 1,
        name = "Explosive Shot",
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
    datasetId = "a93f7c12",
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
                    applyAura = true,
                    auraStacks = 1,
                    baseDamage = 66.3,
                    damageSchoolRefs = {
                        "f82db71a:esjguw6d",
                    },
                    damageType = "ranged",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.23205,
                            statRef = "f82db71a:v2rs9cpy",
                        },
                    },
                    targetEvents = {
                        "on_ranged_taken",
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0,
                    weaponDamageMode = "none",
                    auraRef = "a93f7c12:gi2ibat0",
                },
                key = "expldmg1",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 3,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "enemy",
                    type = "raid_marker",
                },
            },
        },
        conditions = {
            {
                invert = false,
                showOnTooltip = true,
                slotKey = "ranged",
                tooltipTextOverride = "Requires a bow, crossbow, or gun",
                type = "item_equipped",
                weaponTypeRefs = {
                    "f82db71a:l3ce0puc",
                    "f82db71a:j2gceby4",
                    "f82db71a:anoo8qfp",
                },
            },
        },
        cooldown = 3,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_hunter_explosiveshot.blp",
        id = "guy0r1dk",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Explosive Shot",
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
        spellbookCategory = "Marksmanship",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "a93f7c12:gi2ibat0",
                    datasetId = "a93f7c12",
                    descriptionText = "Deals {AURA_DAMAGE_1} Fire damage each turn.",
                    duration = 2,
                    icon = "interface/icons/ability_hunter_explosiveshot.blp",
                    nameText = "Explosive Shot",
                    powerLevel = 0,
                    spellDatasetId = "a93f7c12",
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
            mainText = "Deal {DAMAGE_1} Fire damage to up to 3 enemies sharing the same raid marker and apply Explosive Shot for 2 turns.",
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

### Multi Shot

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "a93f7c12",
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
                    baseDamage = 39.375,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "ranged",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.18375,
                            statRef = "f82db71a:v2rs9cpy",
                        },
                    },
                    targetEvents = {
                        "on_ranged_taken",
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0.525,
                    weaponDamageMode = "main_hand",
                },
                key = "multdmg1",
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
        },
        conditions = {
            {
                invert = false,
                showOnTooltip = true,
                slotKey = "ranged",
                tooltipTextOverride = "Requires a bow, crossbow, or gun",
                type = "item_equipped",
                weaponTypeRefs = {
                    "f82db71a:l3ce0puc",
                    "f82db71a:j2gceby4",
                    "f82db71a:anoo8qfp",
                },
            },
        },
        cooldown = 1,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_upgrademoonglaive.blp",
        id = "moxm408o",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Multi Shot",
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
        spellbookCategory = "Marksmanship",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Deal {DAMAGE_1} Physical ranged weapon damage to up to 4 enemies sharing the same raid marker.",
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

### Volley

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "a93f7c12",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 1,
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
                    baseDamage = 45.5625,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "ranged",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.225,
                            statRef = "f82db71a:v2rs9cpy",
                        },
                    },
                    targetEvents = {
                        "on_ranged_taken",
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0.45,
                    weaponDamageMode = "main_hand",
                },
                key = "vollDmg1",
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
        conditions = {
            {
                invert = false,
                showOnTooltip = true,
                slotKey = "ranged",
                tooltipTextOverride = "Requires a bow, crossbow, or gun",
                type = "item_equipped",
                weaponTypeRefs = {
                    "f82db71a:l3ce0puc",
                    "f82db71a:j2gceby4",
                    "f82db71a:anoo8qfp",
                },
            },
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_hunter_rapidkilling.blp",
        id = "e1peuvog",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Volley",
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
        spellbookCategory = "Marksmanship",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Deal {DAMAGE_1} Physical ranged weapon damage to up to 5 enemies sharing the same raid marker.",
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

## Survival

### Survival of the Fittest

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "a93f7c12",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                baseAmount = 30,
                operation = "flat",
                statRef = "f82db71a:pu05li08",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/spell_nature_spiritarmor.blp",
        id = "svfitau1",
        maxStacks = 1,
        name = "Survival of the Fittest",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Damage Reduction by 30%.",
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
    datasetId = "a93f7c12",
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
                    auraRef = "a93f7c12:svfitau1",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "svfitcmp",
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
        icon = "interface/icons/spell_nature_spiritarmor.blp",
        id = "svfit001",
        cooldownChannel = 5,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Survival of the Fittest",
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
        spellbookCategory = "Survival",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "a93f7c12:svfitau1",
                    datasetId = "a93f7c12",
                    descriptionText = "Increases Damage Reduction by 30%.",
                    duration = 1,
                    icon = "interface/icons/spell_nature_spiritarmor.blp",
                    nameText = "Survival of the Fittest",
                    powerLevel = 0,
                    spellDatasetId = "a93f7c12",
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
            mainText = "Apply Survival of the Fittest to yourself for 1 turn.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Hatchet Toss

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "a93f7c12",
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
                    baseDamage = 39,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "ranged",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.182,
                            statRef = "f82db71a:v2rs9cpy",
                        },
                    },
                    targetEvents = {
                        "on_ranged_taken",
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 2,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0.52,
                    weaponDamageMode = "main_hand",
                },
                key = "hatdmg01",
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
                slotKey = "ranged",
                tooltipTextOverride = "Requires a thrown weapon",
                type = "item_equipped",
                weaponTypeRefs = {
                    "f82db71a:we5ul4ne",
                },
            },
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_hunter_hatchettoss.blp",
        id = "hattoss1",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Hatchet Toss",
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
        spellbookCategory = "Survival",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Deal {DAMAGE_1} Physical damage to an enemy. Generates a high amount of threat.",
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

### Carve

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "a93f7c12",
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
                key = "carvdmg1",
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
        conditions = {
            {
                invert = false,
                showOnTooltip = true,
                slotKey = "mainhand",
                tooltipTextOverride = "Requires Main Hand",
                type = "item_equipped",
                weaponTypeRefs = {  },
            },
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_hunter_carve.blp",
        id = "carve001",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Carve",
        range = 0,
        resourceCosts = {
            {
                amount = 10,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Survival",
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

### Raptor Strike

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "a93f7c12",
    entry = {
        description = "",
        duration = 5,
        effects = {
            {
                baseAmount = 10,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:u7b49vs9",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/ability_hunter_raptorstrike.blp",
        id = "my9w5n5o",
        maxStacks = 3,
        name = "Raptor Strike",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Melee Attack Power by 10% per stack.",
            bodyTokens = {  },
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

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "a93f7c12",
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
                key = "raptdmg1",
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
                    auraRef = "a93f7c12:my9w5n5o",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "raptself",
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
                weaponTypeRefs = {  },
            },
        },
        cooldown = 1,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_hunter_raptorstrike.blp",
        id = "5x0v3mnp",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Raptor Strike",
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
        spellbookCategory = "Survival",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "a93f7c12:my9w5n5o",
                    datasetId = "a93f7c12",
                    descriptionText = "Increases Melee Attack Power by 10% per stack.",
                    duration = 5,
                    icon = "interface/icons/ability_hunter_raptorstrike.blp",
                    nameText = "Raptor Strike",
                    powerLevel = 0,
                    spellDatasetId = "a93f7c12",
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
            mainText = "Deal {DAMAGE_1} Physical melee weapon damage to an enemy and apply Raptor Strike to yourself for 5 turns.",
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

### Mongoose Bite

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "a93f7c12",
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
                    baseDamage = 219.375,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 1.02375,
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
                    weaponDamageCoefficient = 2.925,
                    weaponDamageMode = "main_hand",
                },
                key = "mongdmg1",
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
                weaponTypeRefs = {  },
            },
            {
                auraRef = "a93f7c12:my9w5n5o",
                invert = false,
                showOnTooltip = true,
                tooltipTextOverride = "Requires Raptor Strike",
                type = "aura_requirement",
                unit = "caster",
            },
        },
        cooldown = 3,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_hunter_mongoosebite.blp",
        id = "8f8h0a7t",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Mongoose Bite",
        range = 0,
        resourceCosts = {
            {
                amount = 13.6,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Survival",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Deal {DAMAGE_1} Physical melee weapon damage to an enemy.",
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

### Freezing Trap

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "a93f7c12",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                cancelOnDamage = true,
                forceAutoHitAgainstTarget = true,
                movementRangeOverride = 0,
                preventCasting = true,
                statScaling = {  },
                type = "control",
            },
        },
        events = {  },
        icon = "interface/icons/spell_frost_chainsofice.blp",
        id = "xd7tybgp",
        maxStacks = 1,
        name = "Freezing Trap",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Breaks when the affected unit takes damage. Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
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
    datasetId = "a93f7c12",
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
                    auraRef = "a93f7c12:xd7tybgp",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "frztrap1",
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
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_frost_chainsofice.blp",
        id = "3ckv5ybu",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Freezing Trap",
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
        spellbookCategory = "Survival",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "a93f7c12:xd7tybgp",
                    datasetId = "a93f7c12",
                    descriptionText = "Breaks when the affected unit takes damage. Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                    duration = 2,
                    icon = "interface/icons/spell_frost_chainsofice.blp",
                    nameText = "Freezing Trap",
                    powerLevel = 0,
                    spellDatasetId = "a93f7c12",
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
            mainText = "Apply Freezing Trap to an enemy for 2 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

