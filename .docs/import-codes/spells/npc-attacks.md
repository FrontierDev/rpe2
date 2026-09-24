# NPC Basic Attack Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for Core NPC basic attacks.

These attacks deliberately **do not use weapon damage or require equipment**. Their damage is determined entirely by the NPC's authored offensive stats:

| Attack | Scaling | Damage type |
|---|---:|---|
| NPC Melee Attack | 0.5 × Melee Attack Power | Melee / Physical |
| NPC Ranged Attack | 0.5 × Ranged Attack Power | Ranged / Physical |
| NPC Wand Attack | 1.0 × Spell Power | Spell / Physical |
| NPC Throw | 0.5 × Ranged Attack Power | Ranged / Physical |

All four remain basic auto attacks on Free Action (cooldown channel 4), use no ranks, have no resource cost, and are unavailable to player spell learning. They are seeded for NPC authoring.

## NPC Melee Attack

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "f82db71a",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = {
            "on_auto_attack_hit",
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
                    baseDamage = 0,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "melee",
                    hitType = "auto",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.5,
                            statRef = "f82db71a:u7b49vs9",
                        },
                    },
                    targetEvents = {
                        "on_auto_attack_taken",
                    },
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0,
                    weaponDamageMode = "none",
                },
                key = "npcmel01",
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
        icon = "interface/icons/petbattle_attack.blp",
        id = "npcmel01",
        cooldownChannel = 4,
        learnMode = "unavailable",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "NPC Melee Attack",
        range = 0,
        resourceCosts = {  },
        seedNPCSpell = true,
        spellbookCategory = "",
        tags = {
            "npc",
            "basic_attack",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Basic NPC melee attack. Deal {DAMAGE_1} Physical damage to an enemy.",
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

## NPC Ranged Attack

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "f82db71a",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = {
            "on_auto_attack_hit",
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
                    baseDamage = 0,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "ranged",
                    hitType = "auto",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.5,
                            statRef = "f82db71a:v2rs9cpy",
                        },
                    },
                    targetEvents = {
                        "on_auto_attack_taken",
                    },
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0,
                    weaponDamageMode = "none",
                },
                key = "npcrng01",
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
        icon = "interface/icons/ability_marksmanship.blp",
        id = "npcrng01",
        cooldownChannel = 4,
        learnMode = "unavailable",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "NPC Ranged Attack",
        range = 0,
        resourceCosts = {  },
        seedNPCSpell = true,
        spellbookCategory = "",
        tags = {
            "npc",
            "basic_attack",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Basic NPC ranged attack. Deal {DAMAGE_1} Physical damage to an enemy.",
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

## NPC Wand Attack

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "f82db71a",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = {
            "on_auto_attack_hit",
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
                    baseDamage = 0,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "spell",
                    hitType = "auto",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 1.0,
                            statRef = "f82db71a:7t7xgzcx",
                        },
                    },
                    targetEvents = {
                        "on_auto_attack_taken",
                    },
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0,
                    weaponDamageMode = "none",
                },
                key = "npcwnd01",
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
        icon = "interface/icons/ability_shootwand.blp",
        id = "npcwnd01",
        cooldownChannel = 4,
        learnMode = "unavailable",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "NPC Wand Attack",
        range = 0,
        resourceCosts = {  },
        seedNPCSpell = true,
        spellbookCategory = "",
        tags = {
            "npc",
            "basic_attack",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Basic NPC spell attack. Deal {DAMAGE_1} Physical damage to an enemy.",
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

## NPC Throw

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "f82db71a",
    entry = {
        allowDeadTargets = false,
        canMoveWhileCasting = false,
        castTime = 0,
        casterEvents = {
            "on_auto_attack_hit",
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
                    baseDamage = 0,
                    damageSchoolRefs = {
                        "f82db71a:v1azo4j6",
                    },
                    damageType = "ranged",
                    hitType = "auto",
                    projectilePath = "",
                    projectileSpeed = 0,
                    statScaling = {
                        {
                            coefficient = 0.5,
                            statRef = "f82db71a:v2rs9cpy",
                        },
                    },
                    targetEvents = {
                        "on_auto_attack_taken",
                    },
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 0,
                    weaponDamageMode = "none",
                },
                key = "npcthr01",
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
        icon = "interface/icons/inv_throwingknife_02.blp",
        id = "npcthr01",
        cooldownChannel = 4,
        learnMode = "unavailable",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "NPC Throw",
        range = 0,
        resourceCosts = {  },
        seedNPCSpell = true,
        spellbookCategory = "",
        tags = {
            "npc",
            "basic_attack",
        },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = {  },
            mainText = "Basic NPC thrown attack. Deal {DAMAGE_1} Physical damage to an enemy.",
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
