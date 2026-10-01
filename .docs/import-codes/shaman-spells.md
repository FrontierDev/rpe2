# Shaman Spell Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for the Shaman class dataset (`c4a91e7d`).

Import each listed **Aura** before its associated **Spell**. All entries use the current RPE2 `dev` spell/aura schema and cooldown channels.

## Authoring notes

- Shaman uses **Mana** (`f82db71a:4c8mfm99`).
- Main Action = cooldown channel 1; Bonus Action = channel 2; Buff Action = channel 3; Free Action = channel 4; Reaction = channel 5.
- Totem cooldown groups are ordinary spell-data strings: `fire_totem`, `earth_totem`, `water_totem`, and `air_totem`. No additional schema or runtime implementation is implied.
- Direct damage/healing follows the current spell-authoring specification. Magical damage scales from **Spell Power**; healing scales from **Healing Power**.
- **Earth Shock** uses the current interrupt-group convention and a 5-turn cooldown, but applies only the existing `interrupt` effect. It does **not** apply a silence/control aura.
- **Flame Shock** uses a Bonus Action hybrid direct-damage + 5-turn DoT budget. **Lava Burst** requires Flame Shock on the target, uses a 3-turn cooldown, and uses a heavy 1-turn-cast damage budget.
- **Frost Shock** reduces both Melee Hit Chance and Ranged Hit Chance by 3% for 2 turns, as requested. This deliberately does not copy the current packaged Frostbolt aura's positive Ranged Hit entry.
- **Elemental Mastery** uses the current Combustion stat shape: +100 Spell Crit. Chance for 1 turn.
- Output-bearing **Free Action** totems have no generic calculator multiplier. Their values therefore use conservative current analogues rather than inventing a Free Action multiplier: Searing Totem uses an Ignite-sized 3-turn periodic hit; Magma Totem uses Consecration-sized per-target ticks; Fire Nova Totem uses a reduced 5-target direct-damage profile.
- **Stoneclaw Totem** taunts one enemy for 1 turn and gives the caster a 1-turn generic absorb shield using the current Spell-Power ward value, **104 + 0.52 × Spell Power**.
- Weapon imbues last 10 turns and cost 5% base Mana. Their triggered damage uses existing reactive-aura damage shapes rather than the ordinary DoT formula.
- **Lightning Shield** applies 3 stacks. Each melee hit taken deals Nature damage to the attacker and removes one stack.
- Group stat/resistance totems last 5 turns, matching their 5-turn spell cooldown. Strength/Agility/Armor/Spell Power buffs use +10%; resistance totems use +30 resistance, matching the current fixed Frost Resistance magnitude used by Ice Armor.
- **Healing Stream Totem** applies a 5-turn all-allies HoT. Its per-target tick uses the standard 5-target periodic-healing reduction from the current Renew archetype.
- The Mana Spring request says allies gain “Healing Stream”; this sheet treats that as a naming slip and applies a **Mana Spring** aura instead. It restores **2% Base Mana per turn for 5 turns** (10% total per ally).
- **Tranquil Air Totem** targets between 1 and 10 selected allies and applies -30% Threat Generated for 5 turns.

## Elemental

### Lightning Bolt

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "c4a91e7d",
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
                        "f82db71a:qtr10qyj",
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
                key = "shlbdmg1",
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
        icon = "interface/icons/spell_nature_lightning.blp",
        id = "shlbolt1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Lightning Bolt",
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
        spellbookCategory = "Elemental",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Deal {DAMAGE_1} Nature damage to an enemy.",
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

### Earth Shock

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "c4a91e7d",
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
                    baseDamage = 70.72,
                    damageSchoolRefs = {
                        "f82db71a:qtr10qyj",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.7334,
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
                key = "shedmg01",
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
                    targetEvents = {  },
                    type = "interrupt",
                },
                key = "sheint01",
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
        cooldownGroup = "interrupt",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_earthshock.blp",
        id = "sherthsk",
        cooldownChannel = 5,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Earth Shock",
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
        spellbookCategory = "Elemental",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Deal {DAMAGE_1} Nature damage to an enemy and interrupt its current spellcast.",
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

### Flame Shock

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
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
                scaleWithRank = true,
                statScaling = {
                    {
                        coefficient = 0.22,
                        statRef = "f82db71a:7t7xgzcx",
                    },
                },
                threatCoefficient = 1,
                type = "damage",
            },
        },
        events = {  },
        icon = "interface/icons/spell_fire_flameshock.blp",
        id = "shflshka",
        maxStacks = 1,
        name = "Flame Shock",
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
    datasetId = "c4a91e7d",
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
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0,
                    weaponDamageMode = "none",
                },
                key = "shfsdmg1",
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
                    auraRef = "c4a91e7d:shflshka",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shfsaura",
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
        icon = "interface/icons/spell_fire_flameshock.blp",
        id = "shflmshk",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Flame Shock",
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
        spellbookCategory = "Elemental",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shflshka",
                    datasetId = "c4a91e7d",
                    descriptionText = "Deals {AURA_DAMAGE_1} Fire damage each turn.",
                    duration = 5,
                    icon = "interface/icons/spell_fire_flameshock.blp",
                    nameText = "Flame Shock",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
            mainText = "Deal {DAMAGE_1} Fire damage to an enemy and apply Flame Shock for 5 turns.",
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

### Frost Shock

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                baseAmount = -3,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:wbj4zuf3",
                statScaling = {  },
                type = "stat",
            },
            {
                baseAmount = -3,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:dd88li4c",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/spell_frost_frostshock.blp",
        id = "shfrshka",
        maxStacks = 1,
        name = "Frost Shock",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Reduces Melee Hit Chance by 3%. Reduces Ranged Hit Chance by 3%.",
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
    datasetId = "c4a91e7d",
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
                    baseDamage = 55.25,
                    damageSchoolRefs = {
                        "f82db71a:hx7pnwv4",
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
                key = "shfrdmg1",
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
                    auraRef = "c4a91e7d:shfrshka",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shfraura",
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
        icon = "interface/icons/spell_frost_frostshock.blp",
        id = "shfrtshk",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Frost Shock",
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
        spellbookCategory = "Elemental",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shfrshka",
                    datasetId = "c4a91e7d",
                    descriptionText = "Reduces Melee Hit Chance by 3%. Reduces Ranged Hit Chance by 3%.",
                    duration = 2,
                    icon = "interface/icons/spell_frost_frostshock.blp",
                    nameText = "Frost Shock",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
            mainText = "Deal {DAMAGE_1} Frost damage to an enemy and apply Frost Shock for 2 turns.",
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

### Lava Burst

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "c4a91e7d",
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
                    baseDamage = 175.5,
                    damageSchoolRefs = {
                        "f82db71a:esjguw6d",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 1.82,
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
                key = "shlvdmg1",
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
                auraRef = "c4a91e7d:shflshka",
                invert = false,
                minimumValue = 1,
                showOnTooltip = true,
                tooltipTextOverride = "Requires Flame Shock on the target",
                type = "aura_requirement",
                unit = "target",
            },
        },
        cooldown = 3,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_shaman_lavaburst.blp",
        id = "shlavabr",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Lava Burst",
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
        spellbookCategory = "Elemental",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Deal {DAMAGE_1} Fire damage to an enemy affected by Flame Shock.",
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

### Elemental Mastery

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                baseAmount = 100,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:69hfqhne",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/spell_nature_wispheal.blp",
        id = "shelmsta",
        maxStacks = 1,
        name = "Elemental Mastery",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Spell Crit. Chance by 100%.",
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shelmsta",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shelmaur",
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
        icon = "interface/icons/spell_nature_wispheal.blp",
        id = "shelmast",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Elemental Mastery",
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
        spellbookCategory = "Elemental",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shelmsta",
                    datasetId = "c4a91e7d",
                    descriptionText = "Increases Spell Crit. Chance by 100%.",
                    duration = 1,
                    icon = "interface/icons/spell_nature_wispheal.blp",
                    nameText = "Elemental Mastery",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
            mainText = "Apply Elemental Mastery to yourself for 1 turn.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Searing Totem

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                amountMode = "flat",
                baseDamage = 28.1667,
                damageSchoolRefs = {
                    "f82db71a:esjguw6d",
                },
                scaleWithRank = true,
                statScaling = {
                    {
                        coefficient = 0.25,
                        statRef = "f82db71a:7t7xgzcx",
                    },
                },
                threatCoefficient = 1,
                type = "damage",
            },
        },
        events = {  },
        icon = "interface/icons/spell_fire_searingtotem.blp",
        id = "shsearta",
        maxStacks = 1,
        name = "Searing Totem",
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shsearta",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shseara1",
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
        cooldownGroup = "fire_totem",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_fire_searingtotem.blp",
        id = "shseartm",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Searing Totem",
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
        spellbookCategory = "Elemental",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shsearta",
                    datasetId = "c4a91e7d",
                    descriptionText = "Deals {AURA_DAMAGE_1} Fire damage each turn.",
                    duration = 3,
                    icon = "interface/icons/spell_fire_searingtotem.blp",
                    nameText = "Searing Totem",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
            mainText = "Apply Searing Totem to an enemy for 3 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Fire Nova Totem

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "c4a91e7d",
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
                    baseDamage = 33.8,
                    damageSchoolRefs = {
                        "f82db71a:esjguw6d",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.42,
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
                key = "shfndmg1",
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
        cooldown = 5,
        cooldownGroup = "fire_totem",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_fire_sealoffire.blp",
        id = "shfirnva",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Fire Nova Totem",
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
        spellbookCategory = "Elemental",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Deal {DAMAGE_1} Fire damage to up to 5 enemies.",
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

### Magma Totem

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                amountMode = "flat",
                baseDamage = 11.2667,
                damageSchoolRefs = {
                    "f82db71a:esjguw6d",
                },
                scaleWithRank = true,
                statScaling = {
                    {
                        coefficient = 0.14,
                        statRef = "f82db71a:7t7xgzcx",
                    },
                },
                threatCoefficient = 1,
                type = "damage",
            },
        },
        events = {  },
        icon = "interface/icons/spell_fire_selfdestruct.blp",
        id = "shmagmaa",
        maxStacks = 1,
        name = "Magma Totem",
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shmagmaa",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shmgaur1",
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
        conditions = {  },
        cooldown = 3,
        cooldownGroup = "fire_totem",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_fire_selfdestruct.blp",
        id = "shmagmat",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Magma Totem",
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
        spellbookCategory = "Elemental",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shmagmaa",
                    datasetId = "c4a91e7d",
                    descriptionText = "Deals {AURA_DAMAGE_1} Fire damage each turn.",
                    duration = 3,
                    icon = "interface/icons/spell_fire_selfdestruct.blp",
                    nameText = "Magma Totem",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
            mainText = "Apply Magma Totem to up to 4 enemies on the same raid marker for 3 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Chain Lightning

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "c4a91e7d",
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
                    baseDamage = 81,
                    damageSchoolRefs = {
                        "f82db71a:qtr10qyj",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.84,
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
                key = "shcldmg1",
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
        conditions = {  },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_chainlightning.blp",
        id = "shchnltn",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Chain Lightning",
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
        spellbookCategory = "Elemental",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Deal {DAMAGE_1} Nature damage to up to 3 enemies.",
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

### Earthbind Totem

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                cancelOnDamage = false,
                forceAutoHitAgainstTarget = false,
                movementRangeOverride = 0,
                preventCasting = false,
                type = "control",
            },
        },
        events = {  },
        icon = "interface/icons/spell_nature_strengthofearthtotem02.blp",
        id = "shearthba",
        maxStacks = 1,
        name = "Earthbind Totem",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Sets the affected unit's movement range to 0.",
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shearthba",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shebnd01",
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
        cooldown = 5,
        cooldownGroup = "earth_totem",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_strengthofearthtotem02.blp",
        id = "shearthbd",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Earthbind Totem",
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
        spellbookCategory = "Elemental",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shearthba",
                    datasetId = "c4a91e7d",
                    descriptionText = "Sets the affected unit's movement range to 0.",
                    duration = 1,
                    icon = "interface/icons/spell_nature_strengthofearthtotem02.blp",
                    nameText = "Earthbind Totem",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
                    stacks = 1,
                    targetContext = {
                        object = "the affected enemies",
                        possessive = "the affected enemies'",
                        reflexive = "themselves",
                        subject = "the affected enemies",
                    },
                    tokens = {  },
                },
            },
            mainText = "Apply Earthbind Totem to up to 5 enemies for 1 turn.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Stoneclaw Totem

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                amountMode = "flat",
                baseAbsorption = 104,
                damageSchoolRefs = {  },
                scaleWithRank = true,
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
        icon = "interface/icons/spell_nature_stoneclawtotem.blp",
        id = "shstclwa",
        maxStacks = 1,
        name = "Stoneclaw Totem",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Absorbs {AURA_ABSORB_1} damage.",
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

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "c4a91e7d",
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
                key = "shsctnt1",
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
                    auraRef = "c4a91e7d:shstclwa",
                    basePower = 0,
                    duration = 1,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shscabs1",
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
        cooldownGroup = "earth_totem",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_stoneclawtotem.blp",
        id = "shstclwt",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Stoneclaw Totem",
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
        spellbookCategory = "Elemental",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shstclwa",
                    datasetId = "c4a91e7d",
                    descriptionText = "Absorbs {AURA_ABSORB_1} damage.",
                    duration = 1,
                    icon = "interface/icons/spell_nature_stoneclawtotem.blp",
                    nameText = "Stoneclaw Totem",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
            mainText = "Taunt an enemy for 1 turn and apply Stoneclaw Totem to yourself for 1 turn.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Enhancement

### Rockbiter Weapon

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 10,
        effects = {
            {
                baseAmount = 80,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:j8n012e6",
                statScaling = {  },
                type = "stat",
            },
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
        icon = "interface/icons/spell_nature_rockbiter.blp",
        id = "shrockba",
        maxStacks = 1,
        name = "Rockbiter Weapon",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Threat Generated by 80%. Increases Melee Attack Power by 10%.",
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shrockba",
                    basePower = 0,
                    duration = 10,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shrbau01",
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
        icon = "interface/icons/spell_nature_rockbiter.blp",
        id = "shrockbt",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Rockbiter Weapon",
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
        spellbookCategory = "Enhancement",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shrockba",
                    datasetId = "c4a91e7d",
                    descriptionText = "Increases Threat Generated by 80%. Increases Melee Attack Power by 10%.",
                    duration = 10,
                    icon = "interface/icons/spell_nature_rockbiter.blp",
                    nameText = "Rockbiter Weapon",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
            mainText = "Apply Rockbiter Weapon to yourself for 10 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Stoneskin Totem

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 5,
        effects = {
            {
                baseAmount = 10,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:v42albuv",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/spell_nature_stoneskintotem.blp",
        id = "shstskna",
        maxStacks = 1,
        name = "Stoneskin Totem",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Armor by 10%.",
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shstskna",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shssk001",
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
        cooldown = 5,
        cooldownGroup = "earth_totem",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_stoneskintotem.blp",
        id = "shstsknt",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Stoneskin Totem",
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
        spellbookCategory = "Enhancement",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shstskna",
                    datasetId = "c4a91e7d",
                    descriptionText = "Increases Armor by 10%.",
                    duration = 5,
                    icon = "interface/icons/spell_nature_stoneskintotem.blp",
                    nameText = "Stoneskin Totem",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
            mainText = "Apply Stoneskin Totem to all allies for 5 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Lightning Shield

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 10,
        effects = {  },
        events = {
            {
                chance = 100,
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
                    {
                        auraRef = "c4a91e7d:shlshlda",
                        stacks = 1,
                        type = "remove_aura",
                    },
                },
                triggerTarget = "event_source",
            },
        },
        icon = "interface/icons/spell_nature_lightningshield.blp",
        id = "shlshlda",
        maxStacks = 3,
        name = "Lightning Shield",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "When the affected unit is hit by a melee attack, deal {AURA_EVENT_DAMAGE_1} Nature damage to the attacker and remove 1 stack.",
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
            stackingText = "Applies {AURA_APPLIED_STACKS_1} stacks. Stacks up to {AURA_MAX_STACKS_1} times.",
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shlshlda",
                    basePower = 0,
                    duration = 10,
                    stacks = 3,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shlsau01",
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
        cooldown = 1,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_lightningshield.blp",
        id = "shlshldt",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Lightning Shield",
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
        spellbookCategory = "Enhancement",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shlshlda",
                    datasetId = "c4a91e7d",
                    descriptionText = "When the affected unit is hit by a melee attack, deal {AURA_EVENT_DAMAGE_1} Nature damage to the attacker and remove 1 stack.",
                    duration = 10,
                    icon = "interface/icons/spell_nature_lightningshield.blp",
                    nameText = "Lightning Shield",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
                    stacks = 3,
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
                            key = "AURA_EVENT_DAMAGE_1",
                            tokenType = "aura_amount",
                            eventIndex = 1,
                        },
                    },
                },
            },
            mainText = "Apply 3 stacks of Lightning Shield to yourself for 10 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Flametongue Weapon

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 10,
        effects = {
            {
                baseAmount = 10,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:7t7xgzcx",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {
            {
                chance = 100,
                combatEventId = "on_melee_hit",
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 28.1667,
                        damageSchoolRefs = {
                            "f82db71a:esjguw6d",
                        },
                        scaleWithRank = true,
                        statScaling = {
                            {
                                coefficient = 0.25,
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
                        amountMode = "flat",
                        baseDamage = 28.1667,
                        damageSchoolRefs = {
                            "f82db71a:esjguw6d",
                        },
                        scaleWithRank = true,
                        statScaling = {
                            {
                                coefficient = 0.25,
                                statRef = "f82db71a:7t7xgzcx",
                            },
                        },
                        type = "damage",
                    },
                },
                triggerTarget = "event_other",
            },
        },
        icon = "interface/icons/spell_fire_flametounge.blp",
        id = "shftwaua",
        maxStacks = 1,
        name = "Flametongue Weapon",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Spell Power by 10%. When the affected unit hits with a melee attack, the target takes {AURA_EVENT_DAMAGE_1} Fire damage. When the affected unit hits with a basic attack, the target takes {AURA_EVENT_DAMAGE_2} Fire damage.",
            bodyTokens = {
                {
                    applyMode = "damage_amount",
                    baseField = "baseDamage",
                    effectIndex = 1,
                    key = "AURA_EVENT_DAMAGE_1",
                    tokenType = "aura_amount",
                    eventIndex = 1,
                },
                {
                    applyMode = "damage_amount",
                    baseField = "baseDamage",
                    effectIndex = 1,
                    key = "AURA_EVENT_DAMAGE_2",
                    tokenType = "aura_amount",
                    eventIndex = 2,
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shftwaua",
                    basePower = 0,
                    duration = 10,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shftwau1",
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
        icon = "interface/icons/spell_fire_flametounge.blp",
        id = "shflmtwg",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Flametongue Weapon",
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
        spellbookCategory = "Enhancement",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shftwaua",
                    datasetId = "c4a91e7d",
                    descriptionText = "Increases Spell Power by 10%. When the affected unit hits with a melee attack, the target takes {AURA_EVENT_DAMAGE_1} Fire damage. When the affected unit hits with a basic attack, the target takes {AURA_EVENT_DAMAGE_2} Fire damage.",
                    duration = 10,
                    icon = "interface/icons/spell_fire_flametounge.blp",
                    nameText = "Flametongue Weapon",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
                            key = "AURA_EVENT_DAMAGE_1",
                            tokenType = "aura_amount",
                            eventIndex = 1,
                        },
                        {
                            applyMode = "damage_amount",
                            baseField = "baseDamage",
                            effectIndex = 1,
                            key = "AURA_EVENT_DAMAGE_2",
                            tokenType = "aura_amount",
                            eventIndex = 2,
                        },
                    },
                },
            },
            mainText = "Apply Flametongue Weapon to yourself for 10 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Strength of Earth Totem

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 5,
        effects = {
            {
                baseAmount = 10,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:zfqm8dxp",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/spell_nature_earthbindtotem.blp",
        id = "shsoetha",
        maxStacks = 1,
        name = "Strength of Earth Totem",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Strength by 10%.",
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shsoetha",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shsoea01",
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
        cooldown = 5,
        cooldownGroup = "earth_totem",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_earthbindtotem.blp",
        id = "shsoetht",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Strength of Earth Totem",
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
        spellbookCategory = "Enhancement",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shsoetha",
                    datasetId = "c4a91e7d",
                    descriptionText = "Increases Strength by 10%.",
                    duration = 5,
                    icon = "interface/icons/spell_nature_earthbindtotem.blp",
                    nameText = "Strength of Earth Totem",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
            mainText = "Apply Strength of Earth Totem to all allies for 5 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Frostbrand Weapon

#### Root Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                cancelOnDamage = false,
                forceAutoHitAgainstTarget = false,
                movementRangeOverride = 0,
                preventCasting = false,
                type = "control",
            },
        },
        events = {  },
        icon = "interface/icons/spell_frost_frostbrand.blp",
        id = "shfbrnda",
        maxStacks = 1,
        name = "Frostbrand",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Sets the affected unit's movement range to 0.",
            bodyTokens = {  },
            stackingText = "",
            stackingTokens = {  },
            version = 1,
        },
    },
}
```

#### Weapon Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 10,
        effects = {  },
        events = {
            {
                chance = 100,
                combatEventId = "on_melee_hit",
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 28.1667,
                        damageSchoolRefs = {
                            "f82db71a:hx7pnwv4",
                        },
                        scaleWithRank = true,
                        statScaling = {
                            {
                                coefficient = 0.25,
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
                        amountMode = "flat",
                        baseDamage = 28.1667,
                        damageSchoolRefs = {
                            "f82db71a:hx7pnwv4",
                        },
                        scaleWithRank = true,
                        statScaling = {
                            {
                                coefficient = 0.25,
                                statRef = "f82db71a:7t7xgzcx",
                            },
                        },
                        type = "damage",
                    },
                },
                triggerTarget = "event_other",
            },
            {
                chance = 5,
                combatEventId = "on_melee_hit",
                effects = {
                    {
                        auraRef = "c4a91e7d:shfbrnda",
                        basePower = 0,
                        duration = 1,
                        stacks = 1,
                        type = "apply_aura",
                    },
                },
                triggerTarget = "event_other",
            },
            {
                chance = 5,
                combatEventId = "on_auto_attack_hit",
                effects = {
                    {
                        auraRef = "c4a91e7d:shfbrnda",
                        basePower = 0,
                        duration = 1,
                        stacks = 1,
                        type = "apply_aura",
                    },
                },
                triggerTarget = "event_other",
            },
        },
        icon = "interface/icons/spell_frost_frostbrand.blp",
        id = "shfbrnwa",
        maxStacks = 1,
        name = "Frostbrand Weapon",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "When the affected unit hits with a melee attack, the target takes {AURA_EVENT_DAMAGE_1} Frost damage. When the affected unit hits with a basic attack, the target takes {AURA_EVENT_DAMAGE_2} Frost damage. Melee and basic attack hits each have a 5% chance to apply Frostbrand for 1 turn.",
            bodyTokens = {
                {
                    applyMode = "damage_amount",
                    baseField = "baseDamage",
                    effectIndex = 1,
                    key = "AURA_EVENT_DAMAGE_1",
                    tokenType = "aura_amount",
                    eventIndex = 1,
                },
                {
                    applyMode = "damage_amount",
                    baseField = "baseDamage",
                    effectIndex = 1,
                    key = "AURA_EVENT_DAMAGE_2",
                    tokenType = "aura_amount",
                    eventIndex = 2,
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shfbrnwa",
                    basePower = 0,
                    duration = 10,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shfbwau1",
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
        icon = "interface/icons/spell_frost_frostbrand.blp",
        id = "shfbrnwt",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Frostbrand Weapon",
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
        spellbookCategory = "Enhancement",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shfbrnwa",
                    datasetId = "c4a91e7d",
                    descriptionText = "When the affected unit hits with a melee attack, the target takes {AURA_EVENT_DAMAGE_1} Frost damage. When the affected unit hits with a basic attack, the target takes {AURA_EVENT_DAMAGE_2} Frost damage. Melee and basic attack hits each have a 5% chance to apply Frostbrand for 1 turn.",
                    duration = 10,
                    icon = "interface/icons/spell_frost_frostbrand.blp",
                    nameText = "Frostbrand Weapon",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
                            key = "AURA_EVENT_DAMAGE_1",
                            tokenType = "aura_amount",
                            eventIndex = 1,
                        },
                        {
                            applyMode = "damage_amount",
                            baseField = "baseDamage",
                            effectIndex = 1,
                            key = "AURA_EVENT_DAMAGE_2",
                            tokenType = "aura_amount",
                            eventIndex = 2,
                        },
                    },
                },
            },
            mainText = "Apply Frostbrand Weapon to yourself for 10 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Frost Resistance Totem

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 5,
        effects = {
            {
                baseAmount = 30,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:jjn0my8k",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/spell_frostresistancetotem_01.blp",
        id = "shfrresa",
        maxStacks = 1,
        name = "Frost Resistance Totem",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Frost Resistance by 30.",
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shfrresa",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shfrresc",
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
        cooldown = 5,
        cooldownGroup = "fire_totem",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_frostresistancetotem_01.blp",
        id = "shfrrest",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Frost Resistance Totem",
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
        spellbookCategory = "Enhancement",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shfrresa",
                    datasetId = "c4a91e7d",
                    descriptionText = "Increases Frost Resistance by 30.",
                    duration = 5,
                    icon = "interface/icons/spell_frostresistancetotem_01.blp",
                    nameText = "Frost Resistance Totem",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
            mainText = "Apply Frost Resistance Totem to all allies for 5 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Fire Resistance Totem

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 5,
        effects = {
            {
                baseAmount = 30,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:0w7c7p09",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/spell_fireresistancetotem_01.blp",
        id = "shfiresa",
        maxStacks = 1,
        name = "Fire Resistance Totem",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Fire Resistance by 30.",
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shfiresa",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shfiresc",
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
        cooldown = 5,
        cooldownGroup = "water_totem",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_fireresistancetotem_01.blp",
        id = "shfirest",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Fire Resistance Totem",
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
        spellbookCategory = "Enhancement",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shfiresa",
                    datasetId = "c4a91e7d",
                    descriptionText = "Increases Fire Resistance by 30.",
                    duration = 5,
                    icon = "interface/icons/spell_fireresistancetotem_01.blp",
                    nameText = "Fire Resistance Totem",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
            mainText = "Apply Fire Resistance Totem to all allies for 5 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Nature Resistance Totem

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 5,
        effects = {
            {
                baseAmount = 30,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:pg0ytacb",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/spell_nature_natureresistancetotem.blp",
        id = "shnaresa",
        maxStacks = 1,
        name = "Nature Resistance Totem",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Nature Resistance by 30.",
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shnaresa",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shnaresc",
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
        cooldown = 5,
        cooldownGroup = "air_totem",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_natureresistancetotem.blp",
        id = "shnarest",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Nature Resistance Totem",
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
        spellbookCategory = "Enhancement",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shnaresa",
                    datasetId = "c4a91e7d",
                    descriptionText = "Increases Nature Resistance by 30.",
                    duration = 5,
                    icon = "interface/icons/spell_nature_natureresistancetotem.blp",
                    nameText = "Nature Resistance Totem",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
            mainText = "Apply Nature Resistance Totem to all allies for 5 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Windfury Weapon

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 10,
        effects = {  },
        events = {
            {
                chance = 5,
                combatEventId = "on_auto_attack_hit",
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
                                statRef = "f82db71a:u7b49vs9",
                            },
                        },
                        type = "damage",
                    },
                },
                triggerTarget = "event_other",
            },
        },
        icon = "interface/icons/spell_nature_cyclone.blp",
        id = "shwndfra",
        maxStacks = 1,
        name = "Windfury Weapon",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "When the affected unit hits with a basic attack, there is a 5% chance for the target to take {AURA_EVENT_DAMAGE_1} Physical damage.",
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shwndfra",
                    basePower = 0,
                    duration = 10,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shwfau01",
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
        icon = "interface/icons/spell_nature_cyclone.blp",
        id = "shwndfry",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Windfury Weapon",
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
        spellbookCategory = "Enhancement",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shwndfra",
                    datasetId = "c4a91e7d",
                    descriptionText = "When the affected unit hits with a basic attack, there is a 5% chance for the target to take {AURA_EVENT_DAMAGE_1} Physical damage.",
                    duration = 10,
                    icon = "interface/icons/spell_nature_cyclone.blp",
                    nameText = "Windfury Weapon",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
                            key = "AURA_EVENT_DAMAGE_1",
                            tokenType = "aura_amount",
                            eventIndex = 1,
                        },
                    },
                },
            },
            mainText = "Apply Windfury Weapon to yourself for 10 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Grace of Air Totem

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 5,
        effects = {
            {
                baseAmount = 10,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:xqz0daz2",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/spell_nature_invisibilitytotem.blp",
        id = "shgoaira",
        maxStacks = 1,
        name = "Grace of Air Totem",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Agility by 10%.",
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shgoaira",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shgoaa01",
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
        cooldown = 5,
        cooldownGroup = "air_totem",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_invisibilitytotem.blp",
        id = "shgoairt",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Grace of Air Totem",
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
        spellbookCategory = "Enhancement",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shgoaira",
                    datasetId = "c4a91e7d",
                    descriptionText = "Increases Agility by 10%.",
                    duration = 5,
                    icon = "interface/icons/spell_nature_invisibilitytotem.blp",
                    nameText = "Grace of Air Totem",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
            mainText = "Apply Grace of Air Totem to all allies for 5 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Flametongue Totem

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 5,
        effects = {
            {
                baseAmount = 10,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:7t7xgzcx",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/spell_nature_guardianward.blp",
        id = "shfttoma",
        maxStacks = 1,
        name = "Flametongue Totem",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Increases Spell Power by 10%.",
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shfttoma",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shftta01",
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
        cooldown = 5,
        cooldownGroup = "fire_totem",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_guardianward.blp",
        id = "shfttomt",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Flametongue Totem",
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
        spellbookCategory = "Enhancement",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shfttoma",
                    datasetId = "c4a91e7d",
                    descriptionText = "Increases Spell Power by 10%.",
                    duration = 5,
                    icon = "interface/icons/spell_nature_guardianward.blp",
                    nameText = "Flametongue Totem",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
            mainText = "Apply Flametongue Totem to all allies for 5 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Restoration

### Healing Wave

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "c4a91e7d",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 1,
        casterEvents = {
            "on_heal",
            "on_critical_heal",
        },
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
                    targetEvents = {
                        "on_heal_taken",
                        "on_critical_heal_taken",
                    },
                    type = "heal",
                    usesProjectile = false,
                    threatCoefficient = 0.5,
                },
                key = "shhwhl01",
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
        icon = "interface/icons/spell_nature_magicimmunity.blp",
        id = "shhealwv",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Healing Wave",
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

### Healing Stream Totem

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 5,
        effects = {
            {
                amountMode = "flat",
                baseHealing = 9.36,
                scaleWithRank = true,
                statScaling = {
                    {
                        coefficient = 0.2808,
                        statRef = "f82db71a:hj6d4kvy",
                    },
                },
                type = "heal",
            },
        },
        events = {  },
        icon = "interface/icons/spell_nature_healingway.blp",
        id = "shhstrma",
        maxStacks = 1,
        name = "Healing Stream",
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shhstrma",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                    threatCoefficient = 0.5,
                },
                key = "shhsta01",
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
        cooldown = 5,
        cooldownGroup = "water_totem",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_healingway.blp",
        id = "shhstrmt",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Healing Stream Totem",
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
        spellbookCategory = "Restoration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shhstrma",
                    datasetId = "c4a91e7d",
                    descriptionText = "Heals for {AURA_HEAL_1} health each turn.",
                    duration = 5,
                    icon = "interface/icons/spell_nature_healingway.blp",
                    nameText = "Healing Stream",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
            mainText = "Apply Healing Stream to all allies for 5 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Lesser Healing Wave

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "c4a91e7d",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = {
            "on_heal",
            "on_critical_heal",
        },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    amountMode = "flat",
                    applyAura = false,
                    auraStacks = 1,
                    baseHealing = 65,
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.39,
                            statRef = "f82db71a:hj6d4kvy",
                        },
                    },
                    targetEvents = {
                        "on_heal_taken",
                        "on_critical_heal_taken",
                    },
                    type = "heal",
                    usesProjectile = false,
                    threatCoefficient = 0.375,
                },
                key = "shlhwh01",
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
        icon = "interface/icons/spell_nature_healingwavegreater.blp",
        id = "shleshwv",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Lesser Healing Wave",
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

### Mana Spring Totem

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 5,
        effects = {
            {
                amount = 2,
                amountMode = "base_percent",
                resourceRef = "f82db71a:4c8mfm99",
                scaleWithRank = false,
                type = "resource",
            },
        },
        events = {  },
        icon = "interface/icons/spell_nature_manaregentotem.blp",
        id = "shmsprga",
        maxStacks = 1,
        name = "Mana Spring",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Restores 2% of Base Mana each turn.",
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shmsprga",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shmspa01",
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
        cooldown = 5,
        cooldownGroup = "water_totem",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_manaregentotem.blp",
        id = "shmsprgt",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Mana Spring Totem",
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
        spellbookCategory = "Restoration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shmsprga",
                    datasetId = "c4a91e7d",
                    descriptionText = "Restores 2% of Base Mana each turn.",
                    duration = 5,
                    icon = "interface/icons/spell_nature_manaregentotem.blp",
                    nameText = "Mana Spring",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
            mainText = "Apply Mana Spring to all allies for 5 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

### Chain Heal

#### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "c4a91e7d",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 1,
        casterEvents = {
            "on_heal",
            "on_critical_heal",
        },
        charges = 0,
        components = {
            {
                castPhase = "on_cast_end",
                castingGroup = "default",
                effect = {
                    amountMode = "flat",
                    applyAura = false,
                    auraStacks = 1,
                    baseHealing = 87,
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.48,
                            statRef = "f82db71a:hj6d4kvy",
                        },
                    },
                    targetEvents = {
                        "on_heal_taken",
                        "on_critical_heal_taken",
                    },
                    type = "heal",
                    usesProjectile = false,
                    threatCoefficient = 0.5,
                },
                key = "shchhl01",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 3,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "ally",
                    type = "multi",
                },
            },
        },
        conditions = {  },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_healingwavegreater.blp",
        id = "shchnhel",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Chain Heal",
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
            auraSections = {  },
            mainText = "Heal up to 3 allies for {HEAL_1} health.",
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

### Tranquil Air Totem

#### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "c4a91e7d",
    entry = {
        description = "",
        duration = 5,
        effects = {
            {
                baseAmount = -30,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:j8n012e6",
                statScaling = {  },
                type = "stat",
            },
        },
        events = {  },
        icon = "interface/icons/spell_nature_brilliance.blp",
        id = "shtrqara",
        maxStacks = 1,
        name = "Tranquil Air",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            bodyText = "Reduces Threat Generated by 30%.",
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
    datasetId = "c4a91e7d",
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
                    auraRef = "c4a91e7d:shtrqara",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "shtrqa01",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 10,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "ally",
                    type = "multi",
                },
            },
        },
        conditions = {  },
        cooldown = 5,
        cooldownGroup = "air_totem",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_nature_brilliance.blp",
        id = "shtrqart",
        cooldownChannel = 4,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Tranquil Air Totem",
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
        spellbookCategory = "Restoration",
        tags = {  },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {
                {
                    auraRef = "c4a91e7d:shtrqara",
                    datasetId = "c4a91e7d",
                    descriptionText = "Reduces Threat Generated by 30%.",
                    duration = 5,
                    icon = "interface/icons/spell_nature_brilliance.blp",
                    nameText = "Tranquil Air",
                    powerLevel = 0,
                    spellDatasetId = "c4a91e7d",
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
            mainText = "Apply Tranquil Air to up to 10 allies for 5 turns.",
            tokens = {  },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
