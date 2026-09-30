# Rage Attack Import Code

Standalone `RPE_DATASET_ENTRY_V1` import code for the Core dataset (`f82db71a`).

`Rage Attack` is mechanically the same as `Main Hand Attack`, but also grants **15 Rage** to the caster when used. It is seeded for NPC authoring and unavailable to player spell learning.

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
                    auraRef = "f82db71a:r0r1vl0a",
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
                        "on_critical_hit_taken",
                    },
                    threatCoefficient = 1,
                    type = "damage",
                    usesProjectile = false,
                    weaponDamageCoefficient = 1,
                    weaponDamageMode = "main_hand",
                },
                key = "npcrage1",
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
                    resourceRef = "f82db71a:e2tfklq7",
                    targetEvents = {  },
                    type = "resource",
                },
                key = "npcrage2",
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
                tooltipTextOverride = "Requires main hand",
                type = "item_equipped",
                weaponTypeRefs = {  },
            },
        },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_warrior_charge.blp",
        id = "npcrage1",
        cooldownChannel = 4,
        learnMode = "unavailable",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Rage Attack",
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
            mainText = "Basic attack. Deal {DAMAGE_1} Physical damage to an enemy and generate 15 Rage.",
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
