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

- **Curse of Tongues** is authored as an instant Main Action, 1-turn silence, costing **5% base Mana**. Silence uses the existing control effect with `preventCasting = true` and does not add movement control or auto-hit behavior.
- **Curse of Elements** lasts 5 turns and reduces the percentage-point **Magic Resistance** stat by **5 + 0.01 × Spell Power**. This means its magnitude increases by 20% of the base reduction per 100 Spell Power.
- **Curse of Shadows** had no duration specified, so it uses the same **5-turn curse duration**. It reduces both Arcane and Shadow Resistance by **25 + 0.05 × Spell Power**, preserving the same 20%-of-base-per-100-SP scaling convention as Curse of Elements.
- **Death Coil** is a Bonus Action that applies the existing Warlock Fear aura for **1 turn** and heals the caster for **27.625 + 0.16575 × Spell Power**. Its heal uses the current DPS secondary-healing budget and costs **15% base Mana**.
- **Howl of Terror** copies current Warrior **Intimidating Shout** mechanically: instant Bonus Action, up to 3 targets, 1-turn break-on-damage casting prevention, 10-turn cooldown and `fear` cooldown group. Rage is replaced with the current multi-target-control Mana analogue: **18.1% base Mana**.
- **Demon Skin** is a 10-turn Buff Action self-buff granting **+100% Armor** and **+20% Healing Received**, costing **5% base Mana**.
- **Banish** uses the current `target_creature_type` condition with `elemental`, `demon`, and `aberration`. It is a 1-turn Main Action cast applying a 3-turn break-on-damage incapacitate and costs **5% base Mana**.
- **Shadow Ward** copies Mage **Fire Ward** exactly except for damage school and icon: **104 + 0.52 Spell Power** Shadow-only absorption for 2 turns, Buff Action, 5-turn cooldown, **15% base Mana**.
- **Detect Invisibility cannot currently be represented as a functional standalone spell import.** The hidden-status extension supports direct spell `hide`, but direct spell normalization has no `remove_hidden` effect. `remove_hidden` is currently preserved only for Aura event effects. A standalone import code would silently normalize incorrectly, so no fake code is included below.

- **Chaos Bolt** is a 1-turn Main Action with a **5-turn cooldown**. The current direct-damage formula gives **216 + 2.24 Spell Power**. It uses an empty `damageSchoolRefs` list, which RPE2 presents as **True** damage and therefore applies no damage-school mitigation. Its power ratio is Expensive, giving a **12.3% base Mana** cost.

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

## Chaos Bolt

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
        canTargetHiddenUnits = false,
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
                    baseDamage = 216,
                    damageSchoolRefs = {  },
                    damageType = "spell",
                    hitType = "ability",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 2.24,
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
                key = "wlchblt1",
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
        doesNotRevealCaster = false,
        icon = "interface/icons/ability_warlock_chaosbolt.blp",
        id = "wlchaos1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Chaos Bolt",
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


## Curse of Tongues

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
        duration = 1,
        effects = {
            {
                            cancelOnDamage = false,
                            forceAutoHitAgainstTarget = false,
                            preventCasting = true,
                            statScaling = {  },
                            type = "control",
                        }
        },
        events = {  },
        icon = "interface/icons/spell_shadow_curseoftounges.blp",
        id = "wlctnga1",
        maxStacks = 1,
        name = "Curse of Tongues",
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
        canTargetHiddenUnits = false,
        castTime = 0,
        casterEvents = {  },
        charges = 0,
        components = {
            {
                            castPhase = "on_cast_end",
                            castingGroup = "default",
                            effect = {
                                auraRef = "e8f3b2c6:wlctnga1",
                                basePower = 0,
                                duration = 1,
                                stacks = 1,
                                targetEvents = {  },
                                type = "apply_aura",
                            },
                            key = "wlctngc1",
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
        doesNotRevealCaster = false,
        icon = "interface/icons/spell_shadow_curseoftounges.blp",
        id = "wlctngs1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Curse of Tongues",
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
        spellbookCategory = "Affliction",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Curse of Elements

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
                            baseAmount = -5,
                            operation = "flat",
                            scaleWithRank = false,
                            statRef = "f82db71a:zs1nbz13",
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
        icon = "interface/icons/spell_shadow_chilltouch.blp",
        id = "wlcelea1",
        maxStacks = 1,
        name = "Curse of Elements",
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
        canTargetHiddenUnits = false,
        castTime = 0,
        casterEvents = {  },
        charges = 0,
        components = {
            {
                            castPhase = "on_cast_end",
                            castingGroup = "default",
                            effect = {
                                auraRef = "e8f3b2c6:wlcelea1",
                                basePower = 0,
                                duration = 5,
                                stacks = 1,
                                targetEvents = {  },
                                type = "apply_aura",
                            },
                            key = "wlcelec1",
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
        doesNotRevealCaster = false,
        icon = "interface/icons/spell_shadow_chilltouch.blp",
        id = "wlceles1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Curse of Elements",
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
        spellbookCategory = "Affliction",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Curse of Shadows

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
                            baseAmount = -25,
                            operation = "flat",
                            scaleWithRank = false,
                            statRef = "f82db71a:954yunb9",
                            statScaling = {
                                {
                                    coefficient = -0.05,
                                    statRef = "f82db71a:7t7xgzcx",
                                },
                            },
                            type = "stat",
                        },
            {
                            baseAmount = -25,
                            operation = "flat",
                            scaleWithRank = false,
                            statRef = "f82db71a:itpo751d",
                            statScaling = {
                                {
                                    coefficient = -0.05,
                                    statRef = "f82db71a:7t7xgzcx",
                                },
                            },
                            type = "stat",
                        }
        },
        events = {  },
        icon = "interface/icons/spell_shadow_curseofachimonde.blp",
        id = "wlcshada",
        maxStacks = 1,
        name = "Curse of Shadows",
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
        canTargetHiddenUnits = false,
        castTime = 0,
        casterEvents = {  },
        charges = 0,
        components = {
            {
                            castPhase = "on_cast_end",
                            castingGroup = "default",
                            effect = {
                                auraRef = "e8f3b2c6:wlcshada",
                                basePower = 0,
                                duration = 5,
                                stacks = 1,
                                targetEvents = {  },
                                type = "apply_aura",
                            },
                            key = "wlcshac1",
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
        doesNotRevealCaster = false,
        icon = "interface/icons/spell_shadow_curseofachimonde.blp",
        id = "wlcshads",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Curse of Shadows",
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
        spellbookCategory = "Affliction",
        tags = {  },
        tooltipTemplate = true,
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
    datasetId = "e8f3b2c6",
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
                                auraRef = "e8f3b2c6:wlfeara1",
                                basePower = 0,
                                duration = 1,
                                stacks = 1,
                                targetEvents = {  },
                                type = "apply_aura",
                            },
                            key = "wldcaur1",
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
                                baseHealing = 27.625,
                                projectilePath = "",
                                projectileSpeed = 0,
                                statScaling = {
                                    {
                                        coefficient = 0.16575,
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
                            key = "wldcheal",
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
        doesNotRevealCaster = false,
        icon = "interface/icons/spell_shadow_deathcoil.blp",
        id = "wldcoil1",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Death Coil",
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
        spellbookCategory = "Affliction",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Howl of Terror

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
        duration = 1,
        effects = {
            {
                            cancelOnDamage = true,
                            forceAutoHitAgainstTarget = false,
                            preventCasting = true,
                            statScaling = {  },
                            type = "control",
                        }
        },
        events = {  },
        icon = "interface/icons/spell_shadow_deathscream.blp",
        id = "wlhowlta",
        maxStacks = 1,
        name = "Howl of Terror",
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
        canTargetHiddenUnits = false,
        castTime = 0,
        casterEvents = {  },
        charges = 0,
        components = {
            {
                            castPhase = "on_cast_end",
                            castingGroup = "default",
                            effect = {
                                auraRef = "e8f3b2c6:wlhowlta",
                                basePower = 0,
                                duration = 1,
                                stacks = 1,
                                targetEvents = {  },
                                type = "apply_aura",
                            },
                            key = "wlhowltc",
                            target = {
                                allowDeadTargets = false,
                                disableSelfCast = false,
                                maxTargets = 3,
                                minTargets = 1,
                                requiresTarget = true,
                                targetDisposition = "enemy",
                                type = "multi",
                            },
                        }
        },
        conditions = {

        },
        cooldown = 10,
        cooldownGroup = "fear",
        cooldownScalesWithHaste = false,
        description = "",
        doesNotRevealCaster = false,
        icon = "interface/icons/spell_shadow_deathscream.blp",
        id = "wlhowlts",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Howl of Terror",
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
        spellbookCategory = "Affliction",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

# Demonology

## Demon Skin

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
        duration = 10,
        effects = {
            {
                            baseAmount = 100,
                            operation = "percent",
                            scaleWithRank = false,
                            statRef = "f82db71a:v42albuv",
                            statScaling = {  },
                            type = "stat",
                        },
            {
                            baseAmount = 20,
                            operation = "flat",
                            scaleWithRank = false,
                            statRef = "f82db71a:ok80ohz3",
                            statScaling = {  },
                            type = "stat",
                        }
        },
        events = {  },
        icon = "interface/icons/spell_shadow_ragingscream.blp",
        id = "wldskina",
        maxStacks = 1,
        name = "Demon Skin",
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
        canTargetHiddenUnits = false,
        castTime = 0,
        casterEvents = {  },
        charges = 0,
        components = {
            {
                            castPhase = "on_cast_end",
                            castingGroup = "default",
                            effect = {
                                auraRef = "e8f3b2c6:wldskina",
                                basePower = 0,
                                duration = 10,
                                stacks = 1,
                                targetEvents = {  },
                                type = "apply_aura",
                            },
                            key = "wldskinc",
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
        doesNotRevealCaster = false,
        icon = "interface/icons/spell_shadow_ragingscream.blp",
        id = "wldskins",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Demon Skin",
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
        spellbookCategory = "Demonology",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Banish

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
                            cancelOnDamage = true,
                            forceAutoHitAgainstTarget = true,
                            movementRangeOverride = 0,
                            preventCasting = true,
                            statScaling = {  },
                            type = "control",
                        }
        },
        events = {  },
        icon = "interface/icons/spell_shadow_cripple.blp",
        id = "wlbanisa",
        maxStacks = 1,
        name = "Banish",
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
        canTargetHiddenUnits = false,
        castTime = 1,
        casterEvents = {  },
        charges = 0,
        components = {
            {
                            castPhase = "on_cast_end",
                            castingGroup = "default",
                            effect = {
                                auraRef = "e8f3b2c6:wlbanisa",
                                basePower = 0,
                                duration = 3,
                                stacks = 1,
                                targetEvents = {  },
                                type = "apply_aura",
                            },
                            key = "wlbanisc",
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
                            creatureTypes = {
                                "elemental",
                                "demon",
                                "aberration",
                            },
                            invert = false,
                            showOnTooltip = true,
                            tooltipTextOverride = "",
                            type = "target_creature_type",
                        }
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        doesNotRevealCaster = false,
        icon = "interface/icons/spell_shadow_cripple.blp",
        id = "wlbaniss",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Banish",
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
        spellbookCategory = "Demonology",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Shadow Ward

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
                            amountMode = "flat",
                            baseAbsorption = 104,
                            damageSchoolRefs = {
                                "f82db71a:1ggt4t3v",
                            },
                            statScaling = {
                                {
                                    coefficient = 0.52,
                                    statRef = "f82db71a:7t7xgzcx",
                                },
                            },
                            type = "absorb",
                        }
        },
        events = {  },
        icon = "interface/icons/spell_shadow_antishadow.blp",
        id = "wlshwada",
        maxStacks = 1,
        name = "Shadow Ward",
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
        canTargetHiddenUnits = false,
        castTime = 0,
        casterEvents = {  },
        charges = 0,
        components = {
            {
                            castPhase = "on_cast_end",
                            castingGroup = "default",
                            effect = {
                                auraRef = "e8f3b2c6:wlshwada",
                                basePower = 0,
                                duration = 2,
                                stacks = 1,
                                targetEvents = {  },
                                type = "apply_aura",
                            },
                            key = "wlshwadc",
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
        cooldown = 5,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        doesNotRevealCaster = false,
        icon = "interface/icons/spell_shadow_antishadow.blp",
        id = "wlshwads",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Shadow Ward",
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
        spellbookCategory = "Demonology",
        tags = {  },
        tooltipTemplate = true,
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

## Detect Invisibility

A correct standalone import code cannot be authored against the current spell schema.

The runtime has a `remove_hidden` implementation in `client/spellcasting/effects/RemoveHidden.lua`, but it is registered as an Aura event effect. The hidden-status schema extension preserves direct spell `hide` effects, but does not preserve a direct spell `remove_hidden` component through `Spell:Merge` / spell-effect normalization. Until direct `remove_hidden` is added to the spell effect schema/normalization path, an import entry for this spell would not reliably unhide its target.

Intended behavior once that support exists:

- instant cast;
- one target;
- may target hidden units;
- applies `remove_hidden` directly to the selected target;
- no rank scaling.
