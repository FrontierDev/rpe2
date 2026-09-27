# Warlock Spell Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for the Warlock class dataset `e8f3b2c6`.

## Authoring notes

- The current packaged Warlock dataset exists but has no spells or auras yet.
- These entries follow the current RPE2 spell-authoring specification and current shipped spell schemas.
- All spell and aura `description` fields are intentionally empty and `tooltipTemplate = true`; the runtime description generators should derive descriptions from the actual components and aura effects rather than relying on hand-authored descriptions.
- **Shadow Bolt** uses the standard 1-turn single-target Main Action DPS budget: **135 + 1.40 Spell Power** Shadow damage, costing **6.8% base Mana**.
- **Immolate** is a pure 5-turn active DoT using the current pure-active-DoT reference budget: **20.8 + 0.42 Spell Power per turn**. Its requested 1-turn cast remains on Main Action; the DoT uses the standard periodic **6.3% base Mana** cost convention.
- **Searing Pain** uses the standard instant single-target damage budget, but `threatCoefficient = 2` so the generated tooltip identifies it as high threat.
- **Rain of Fire** copies Volley's current up-to-5 same-raid-marker targeting shape, converted to a 1-turn Fire spell. The per-target budget is **60.75 + 0.63 Spell Power**, costing **12.3% base Mana**.
- **Hellfire** is an instant 4-target Fire spell using the 4-target direct budget: **50 + 0.50 Spell Power per target**. The task did not specify the Health cost; this code uses **15% base Health**, matching the only explicit Warlock Health-cost benchmark in this task (Life Tap).
- **Soul Fire** copies the current Pyroblast direct component and Mana cost exactly—**258.188 + 2.6776 Spell Power**, **31.8% base Mana**—but does not apply Pyroblast's DoT.
- **Corruption** uses the current pure active 5-turn Shadow DoT reference: **20.8 + 0.42 Spell Power per turn**, instant Bonus Action, **6.3% base Mana**.
- **Life Tap** costs **15% base Health** and restores **15% base Mana** as requested. The current instantaneous spell `resource` effect normalizer does **not** retain `statScaling`, so Spirit scaling cannot be represented faithfully in an import code today. No ignored/fake scaling field is authored.
- **Curse of Agony** is a 3-turn pure active DoT. Its flat periodic budget is **28.1667 per turn**; its Spell Power scaling uses the same **2.10 lifetime coefficient** as the current pure active Shadow Word: Pain reference, distributed over three turns as **0.70 Spell Power per turn**.
- **Curse of Weakness** had no duration or Spell Power coefficient specified. This code uses a **5-turn duration** and scales the base **-10% Melee Attack Power** effect by **-0.01 per Spell Power** (one additional percentage point of reduction per 100 Spell Power). It costs **5% base Mana** as short single-target utility.
- **Fear** copies current Paladin **Repentance**: 1-turn cast, 2-turn break-on-damage incapacitate, 6-turn cooldown, Main Action, **5% base Mana**.
- **Drain Soul** uses the current execute analogue from Shadow Word: Death, but with the requested **30% target-health gate** and 1-turn cast: **225 + 2.25 Spell Power** Shadow damage, **12.3% base Mana**.
- **Drain Life** independently budgets its damage and self-heal as secondary outputs: **114.75 + 1.19 Spell Power** Shadow damage and **61.625 + 0.34 Spell Power** self-healing. The calculated 1-turn hybrid cost is **3.4% base Mana**.
- **Drain Mana** has no current same-mechanic Warlock analogue and the transfer magnitude was not specified. This code uses **15% base Mana drained** and **15% base Mana restored**, reusing Life Tap's explicit 15% resource-conversion magnitude. It also deals the secondary-output Shadow damage budget (**114.75 + 1.19 Spell Power**) and costs **6.8% base Mana**, matching the standard 1-turn nuke cost rather than treating Mana generation as free.

# Destruction

## Shadow Bolt

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "e8f3b2c6",
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
                        "f82db71a:1ggt4t3v",
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
                key = "wlsbdmg1",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 1,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "enemy",
                    type = "single",
                },
            }
        },
        conditions = {
            
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_shadow_shadowbolt.blp",
        id = "wlsbolt1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Shadow Bolt",
        range = 0,
        resourceCosts = {
            {
                amount = 6.8,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            }
        },
        seedNPCSpell = false,
        spellbookCategory = "Destruction",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Immolate

### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "e8f3b2c6",
    entry = {
        description = "",
        duration = 5,
        effects = {
            {
                amountMode = "flat",
                baseDamage = 20.8,
                damageSchoolRefs = {
                    "f82db71a:esjguw6d",
                },
                statScaling = {
                    {
                        coefficient = 0.42,
                        statRef = "f82db71a:7t7xgzcx",
                    },
                },
                type = "damage",
            }
        },
        events = {  },
        icon = "interface/icons/spell_fire_immolation.blp",
        id = "wlimmoa1",
        maxStacks = 1,
        name = "Immolate",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
    },
}
```

### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "e8f3b2c6",
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
                    auraRef = "e8f3b2c6:wlimmoa1",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "wlimaur1",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 1,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "enemy",
                    type = "single",
                },
            }
        },
        conditions = {
            
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_fire_immolation.blp",
        id = "wlimmol1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Immolate",
        range = 0,
        resourceCosts = {
            {
                amount = 6.3,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            }
        },
        seedNPCSpell = false,
        spellbookCategory = "Destruction",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Searing Pain

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "e8f3b2c6",
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
                    baseDamage = 100,
                    damageSchoolRefs = {
                        "f82db71a:esjguw6d",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 1,
                            statRef = "f82db71a:7t7xgzcx",
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
                key = "wlspdmg1",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 1,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "enemy",
                    type = "single",
                },
            }
        },
        conditions = {
            
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_fire_soulburn.blp",
        id = "wlsearp1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Searing Pain",
        range = 0,
        resourceCosts = {
            {
                amount = 5,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            }
        },
        seedNPCSpell = false,
        spellbookCategory = "Destruction",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Rain of Fire

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "e8f3b2c6",
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
                    baseDamage = 60.75,
                    damageSchoolRefs = {
                        "f82db71a:esjguw6d",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.63,
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
                key = "wlrfdmg1",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 5,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "enemy",
                    type = "raid_marker",
                },
            }
        },
        conditions = {
            
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_shadow_rainoffire.blp",
        id = "wlrainf1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Rain of Fire",
        range = 0,
        resourceCosts = {
            {
                amount = 12.3,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            }
        },
        seedNPCSpell = false,
        spellbookCategory = "Destruction",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Hellfire

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "e8f3b2c6",
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
                    baseDamage = 50,
                    damageSchoolRefs = {
                        "f82db71a:esjguw6d",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.5,
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
                key = "wlhfdmg1",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 4,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "enemy",
                    type = "multi",
                },
            }
        },
        conditions = {
            
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_fire_incinerate.blp",
        id = "wlhellf1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Hellfire",
        range = 0,
        resourceCosts = {
            {
                amount = 15,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:q2ktkztt",
            }
        },
        seedNPCSpell = false,
        spellbookCategory = "Destruction",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Soul Fire

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "e8f3b2c6",
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
                    baseDamage = 258.188,
                    damageSchoolRefs = {
                        "f82db71a:esjguw6d",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 2.6776,
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
                key = "wlsfdmg1",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 1,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "enemy",
                    type = "single",
                },
            }
        },
        conditions = {
            
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_fire_fireball02.blp",
        id = "wlsoulf1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Soul Fire",
        range = 0,
        resourceCosts = {
            {
                amount = 31.8,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            }
        },
        seedNPCSpell = false,
        spellbookCategory = "Destruction",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

# Affliction

## Corruption

### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "e8f3b2c6",
    entry = {
        description = "",
        duration = 5,
        effects = {
            {
                amountMode = "flat",
                baseDamage = 20.8,
                damageSchoolRefs = {
                    "f82db71a:1ggt4t3v",
                },
                statScaling = {
                    {
                        coefficient = 0.42,
                        statRef = "f82db71a:7t7xgzcx",
                    },
                },
                type = "damage",
            }
        },
        events = {  },
        icon = "interface/icons/spell_shadow_abominationexplosion.blp",
        id = "wlcora01",
        maxStacks = 1,
        name = "Corruption",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
    },
}
```

### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "e8f3b2c6",
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
                    auraRef = "e8f3b2c6:wlcora01",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "wlcora1",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 1,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "enemy",
                    type = "single",
                },
            }
        },
        conditions = {
            
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_shadow_abominationexplosion.blp",
        id = "wlcorru1",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Corruption",
        range = 0,
        resourceCosts = {
            {
                amount = 6.3,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            }
        },
        seedNPCSpell = false,
        spellbookCategory = "Affliction",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Life Tap

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "e8f3b2c6",
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
                    amount = 15,
                    amountMode = "base_percent",
                    resourceRef = "f82db71a:4c8mfm99",
                    targetEvents = {  },
                    type = "resource",
                },
                key = "wltmana1",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 0,
                    minTargets = 0,
                    requiresTarget = false,
                    targetDisposition = "ally",
                    type = "caster",
                },
            }
        },
        conditions = {
            
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_shadow_burningspirit.blp",
        id = "wllifet1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Life Tap",
        range = 0,
        resourceCosts = {
            {
                amount = 15,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:q2ktkztt",
            }
        },
        seedNPCSpell = false,
        spellbookCategory = "Affliction",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Curse of Agony

### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "e8f3b2c6",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                amountMode = "flat",
                baseDamage = 28.1667,
                damageSchoolRefs = {
                    "f82db71a:1ggt4t3v",
                },
                statScaling = {
                    {
                        coefficient = 0.7,
                        statRef = "f82db71a:7t7xgzcx",
                    },
                },
                type = "damage",
            }
        },
        events = {  },
        icon = "interface/icons/spell_shadow_curseofsargeras.blp",
        id = "wlcaga01",
        maxStacks = 1,
        name = "Curse of Agony",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
    },
}
```

### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "e8f3b2c6",
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
                    auraRef = "e8f3b2c6:wlcaga01",
                    basePower = 0,
                    duration = 3,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "wlcaga1",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 1,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "enemy",
                    type = "single",
                },
            }
        },
        conditions = {
            
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_shadow_curseofsargeras.blp",
        id = "wlcago01",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Curse of Agony",
        range = 0,
        resourceCosts = {
            {
                amount = 6.3,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            }
        },
        seedNPCSpell = false,
        spellbookCategory = "Affliction",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Curse of Weakness

### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "e8f3b2c6",
    entry = {
        description = "",
        duration = 5,
        effects = {
            {
                baseAmount = -10,
                operation = "percent",
                statRef = "f82db71a:u7b49vs9",
                statScaling = {
                    {
                        coefficient = -0.01,
                        statRef = "f82db71a:7t7xgzcx",
                    },
                },
                type = "stat",
            }
        },
        events = {  },
        icon = "interface/icons/spell_shadow_curseofmannoroth.blp",
        id = "wlcweaka",
        maxStacks = 1,
        name = "Curse of Weakness",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
    },
}
```

### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "e8f3b2c6",
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
                    auraRef = "e8f3b2c6:wlcweaka",
                    basePower = 0,
                    duration = 5,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "wlcwka1",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 1,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "enemy",
                    type = "single",
                },
            }
        },
        conditions = {
            
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_shadow_curseofmannoroth.blp",
        id = "wlcweak1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Curse of Weakness",
        range = 0,
        resourceCosts = {
            {
                amount = 5,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            }
        },
        seedNPCSpell = false,
        spellbookCategory = "Affliction",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Fear

### Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "e8f3b2c6",
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
            }
        },
        events = {  },
        icon = "interface/icons/spell_shadow_possession.blp",
        id = "wlfeara1",
        maxStacks = 1,
        name = "Fear",
        stackBehavior = "refresh_duration",
        tags = {  },
        tooltipTemplate = true,
    },
}
```

### Spell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "e8f3b2c6",
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
                    auraRef = "e8f3b2c6:wlfeara1",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = {  },
                    type = "apply_aura",
                },
                key = "wlfearc1",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 1,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "enemy",
                    type = "single",
                },
            }
        },
        conditions = {
            
        },
        cooldown = 6,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_shadow_possession.blp",
        id = "wlfear01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Fear",
        range = 0,
        resourceCosts = {
            {
                amount = 5,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            }
        },
        seedNPCSpell = false,
        spellbookCategory = "Affliction",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Drain Soul

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "e8f3b2c6",
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
                            coefficient = 2.25,
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
                key = "wldsdam1",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 1,
                    minTargets = 1,
                    requiresTarget = true,
                    targetDisposition = "enemy",
                    type = "single",
                },
            }
        },
        conditions = {
            {
                invert = false,
                maximumValue = 30,
                showOnTooltip = true,
                tooltipTextOverride = "",
                type = "target_health_percent",
            }
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_shadow_haunting.blp",
        id = "wldrsol1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Drain Soul",
        range = 0,
        resourceCosts = {
            {
                amount = 12.3,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            }
        },
        seedNPCSpell = false,
        spellbookCategory = "Affliction",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Drain Life

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "e8f3b2c6",
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
                    baseDamage = 114.75,
                    damageSchoolRefs = {
                        "f82db71a:1ggt4t3v",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 1.19,
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
                key = "wldldmg1",
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
                    amountMode = "flat",
                    applyAura = false,
                    auraStacks = 1,
                    baseHealing = 61.625,
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.34,
                            statRef = "f82db71a:7t7xgzcx",
                        },
                    },
                    targetEvents = {
                        "on_heal_taken",
                        "on_critical_heal_taken",
                    },
                    type = "heal",
                    usesProjectile = false,
                },
                key = "wldlheal",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 0,
                    minTargets = 0,
                    requiresTarget = false,
                    targetDisposition = "ally",
                    type = "caster",
                },
            }
        },
        conditions = {
            
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_shadow_lifedrain02_purple.blp",
        id = "wldrlif1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Drain Life",
        range = 0,
        resourceCosts = {
            {
                amount = 3.4,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            }
        },
        seedNPCSpell = false,
        spellbookCategory = "Affliction",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Drain Mana

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "e8f3b2c6",
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
                    baseDamage = 114.75,
                    damageSchoolRefs = {
                        "f82db71a:1ggt4t3v",
                    },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 1.19,
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
                key = "wldmdmg1",
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
                    amount = -15,
                    amountMode = "base_percent",
                    resourceRef = "f82db71a:4c8mfm99",
                    targetEvents = {  },
                    type = "resource",
                },
                key = "wldmloss",
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
                    amountMode = "base_percent",
                    resourceRef = "f82db71a:4c8mfm99",
                    targetEvents = {  },
                    type = "resource",
                },
                key = "wldmgain",
                target = {
                    allowDeadTargets = false,
                    disableSelfCast = false,
                    maxTargets = 0,
                    minTargets = 0,
                    requiresTarget = false,
                    targetDisposition = "ally",
                    type = "caster",
                },
            }
        },
        conditions = {
            
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_shadow_siphonmana.blp",
        id = "wldrman1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Drain Mana",
        range = 0,
        resourceCosts = {
            {
                amount = 6.8,
                amountMode = "base_percent",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:4c8mfm99",
            }
        },
        seedNPCSpell = false,
        spellbookCategory = "Affliction",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
