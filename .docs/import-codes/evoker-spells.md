# Evoker Spell Import Codes

Standalone `RPE_DATASET_ENTRY_V1` import codes for the synthetic Classic-style Evoker dataset (`evokdata`).

The sheet preserves the recognizable **Devastation**, **Preservation**, and **Augmentation** identities while following the current RPE spell-authoring rules rather than copying retail coefficients.

## Authoring rules applied

- Evoker uses Core **Mana** (`f82db71a:4c8mfm99`) and Core **Essence** (`f82db71a:essence1`). No Evoker-specific Essence resource is created.
- Essence spenders use a fixed **3 Essence** cost: **Disintegrate**, **Pyre**, **Emerald Blossom**, and **Eruption**.
- **Empower** is not reproduced as a variable-rank subsystem. Fire Breath, Eternity Surge, Dream Breath, Spiritbloom, and Upheaval use fixed RPE cast/target profiles.
- **Living Flame** is split into separate damage and healing entries because the current spell schema cannot switch effect type according to ally/enemy target disposition.
- Spellfrost is represented as **Frost + Arcane**. Volcanic is represented as **Fire + Nature**.
- Main Action = channel 1; Bonus Action = channel 2; Buff Action = channel 3; Free Action = channel 4; Reaction = channel 5.
- Direct output follows `.docs/RPE2_Spell_Authoring_Specification.md`.
- Periodic healing uses current HoT analogues. Dream Breath's HoT is 85% of Wild Growth's current per-turn profile because Dream Breath also has an independently useful direct heal.
- Fire Breath's DoT is deliberately modest because the parent spell also has direct five-target damage.
- **Quell** uses the native RPE interrupt effect rather than a fake silence aura.
- **Cauterizing Flame** uses `remove_aura_by_tag` for `bleed`, `poison`, `curse`, and `disease`. Its conditional heal-on-success is omitted because the current effect model cannot make the heal contingent on actually removing an aura.
- Movement-defining spells such as Deep Breath, Rescue, Hover, Verdant Embrace's movement component, and Dream Flight are omitted.
- Spell-storage/replay and historical-damage mechanics such as Echo, Stasis, Rewind, Temporal Anomaly, Time Skip, and Breath of Eons are omitted rather than approximated.
- All icons use the Evoker spell/talent icon identities rather than generic placeholders.

# Supporting Auras

## Fire Breath — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "evokdata",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                amountMode = "flat",
                baseDamage = 8.619,
                damageSchoolRefs = { "f82db71a:esjguw6d" },
                statScaling = {
                    {
                        coefficient = 0.1,
                        statRef = "f82db71a:7t7xgzcx",
                    },
                },
                type = "damage",
            },
        },
        events = {

        },
        icon = "interface/icons/ability_evoker_firebreath.blp",
        id = "evfrbra1",
        maxStacks = 1,
        name = "Fire Breath",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
    },
}
```
## Obsidian Scales — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "evokdata",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                baseAmount = 35,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:pu05li08",
                statScaling = { },
                type = "stat",
            },
            {
                baseAmount = 20,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:zs1nbz13",
                statScaling = { },
                type = "stat",
            },
        },
        events = {

        },
        icon = "interface/icons/ability_evoker_obsidianscales.blp",
        id = "evobsca1",
        maxStacks = 1,
        name = "Obsidian Scales",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
    },
}
```
## Shattering Star — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "evokdata",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                baseAmount = -10,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:pu05li08",
                statScaling = { },
                type = "stat",
            },
        },
        events = {

        },
        icon = "interface/icons/ability_evoker_chargedblast.blp",
        id = "evshsta1",
        maxStacks = 1,
        name = "Shattering Star",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
    },
}
```
## Dragonrage — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "evokdata",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                baseAmount = 15,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:gj9wxb0x",
                statScaling = { },
                type = "stat",
            },
            {
                baseAmount = 10,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:69hfqhne",
                statScaling = { },
                type = "stat",
            },
        },
        events = {

        },
        icon = "interface/icons/ability_evoker_dragonrage2.blp",
        id = "evdrgra1",
        maxStacks = 1,
        name = "Dragonrage",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
    },
}
```
## Reversion — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "evokdata",
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
        events = {

        },
        icon = "interface/icons/ability_evoker_reversion.blp",
        id = "evrevera",
        maxStacks = 1,
        name = "Reversion",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
    },
}
```
## Dream Breath — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "evokdata",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                amountMode = "flat",
                baseHealing = 10.77375,
                statScaling = {
                    {
                        coefficient = 0.1939275,
                        statRef = "f82db71a:hj6d4kvy",
                    },
                },
                type = "heal",
            },
        },
        events = {

        },
        icon = "interface/icons/ability_evoker_dreambreath.blp",
        id = "evdrbea1",
        maxStacks = 1,
        name = "Dream Breath",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
    },
}
```
## Emerald Communion — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "evokdata",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                amountMode = "max_percent",
                baseHealing = 20,
                statScaling = { },
                type = "heal",
            },
        },
        events = { },
        icon = "interface/icons/ability_evoker_green_01.blp",
        id = "evemcoa1",
        maxStacks = 1,
        name = "Emerald Communion",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
    },
}
```

## Zephyr — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "evokdata",
    entry = {
        description = "",
        duration = 1,
        effects = {
            {
                baseAmount = 20,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:pu05li08",
                statScaling = { },
                type = "stat",
            },
        },
        events = {

        },
        icon = "interface/icons/ability_evoker_zephyr.blp",
        id = "evzepha1",
        maxStacks = 1,
        name = "Zephyr",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
    },
}
```
## Ebon Might — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "evokdata",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                baseAmount = 10,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:gj9wxb0x",
                statScaling = { },
                type = "stat",
            },
        },
        events = {

        },
        icon = "interface/icons/spell_sarkareth.blp",
        id = "evebona1",
        maxStacks = 1,
        name = "Ebon Might",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
    },
}
```
## Prescience — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "evokdata",
    entry = {
        description = "",
        duration = 2,
        effects = {
            {
                baseAmount = 5,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:jslmczbi",
                statScaling = { },
                type = "stat",
            },
            {
                baseAmount = 5,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:fercjhm5",
                statScaling = { },
                type = "stat",
            },
            {
                baseAmount = 5,
                operation = "flat",
                scaleWithRank = false,
                statRef = "f82db71a:69hfqhne",
                statScaling = { },
                type = "stat",
            },
        },
        events = {

        },
        icon = "interface/icons/ability_evoker_prescience.blp",
        id = "evpresa1",
        maxStacks = 1,
        name = "Prescience",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
    },
}
```
## Blistering Scales — Aura

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "auras",
    datasetId = "evokdata",
    entry = {
        description = "",
        duration = 3,
        effects = {
            {
                baseAmount = 30,
                operation = "percent",
                scaleWithRank = false,
                statRef = "f82db71a:v42albuv",
                statScaling = { },
                type = "stat",
            },
        },
        events = {
            {
                combatEventId = "on_melee_taken",
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 23.9417,
                        damageSchoolRefs = { "f82db71a:esjguw6d", "f82db71a:qtr10qyj" },
                        scaleWithRank = true,
                        statScaling = {
                            {
                                coefficient = 0.71825,
                                statRef = "f82db71a:7t7xgzcx",
                            },
                        },
                        type = "damage",
                    },
                },
                triggerTarget = "event_source",
            },
        },
        icon = "interface/icons/ability_evoker_blisteringscales.blp",
        id = "evblsca1",
        maxStacks = 1,
        name = "Blistering Scales",
        stackBehavior = "refresh_duration",
        tags = { },
        tooltipTemplate = true,
    },
}
```

# General

## Living Flame — Damage

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                damageSchoolRefs = { "f82db71a:esjguw6d" },
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
                        key = "evlfdm01",
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
        conditions = { },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_livingflame.blp",
        id = "evlfdmg1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Living Flame (Damage)",
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
        spellbookCategory = "General",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Cast for 1 turn to deal {DAMAGE_1} Fire damage to an enemy.",
            tokens = {
                {
                    applyMode = "damage_range",
                    componentIndex = 1,
                    key = "DAMAGE_1",
                    tokenType = "spell_damage_range",
                }
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Living Flame — Heal

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                threatCoefficient = 0.5,
                                type = "heal",
                                usesProjectile = false,
                            },
                        key = "evlfhe01",
                        target = {
                                allowDeadTargets = false,
                                disableSelfCast = false,
                                maxTargets = 1,
                                minTargets = 1,
                                requiresTarget = true,
                                targetDisposition = "ally",
                                type = "single",
                            },
                    }
        },
        conditions = { },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_livingflame.blp",
        id = "evlfhea1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Living Flame (Heal)",
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
        spellbookCategory = "General",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Cast for 1 turn to heal an ally for {HEAL_1} health.",
            tokens = {
                {
                    applyMode = "heal_range",
                    componentIndex = 1,
                    key = "HEAL_1",
                    tokenType = "spell_heal_range",
                }
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Azure Strike

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                baseDamage = 75,
                                damageSchoolRefs = { "f82db71a:hx7pnwv4", "f82db71a:dtxhglqg" },
                                damageType = "spell",
                                hitType = "ability",
                                projectilePath = "",
                                projectileSpeed = 0,
                                statScaling = {
                                    {
                                        coefficient = 0.75,
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
                        key = "evazdm01",
                        target = {
                                allowDeadTargets = false,
                                disableSelfCast = false,
                                maxTargets = 2,
                                minTargets = 1,
                                requiresTarget = true,
                                targetDisposition = "enemy",
                                type = "multi",
                            },
                    }
        },
        conditions = { },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_azurestrike.blp",
        id = "evazstr1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Azure Strike",
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
        spellbookCategory = "General",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Deal {DAMAGE_1} Spellfrost damage to up to 2 enemies.",
            tokens = {
                {
                    applyMode = "damage_range",
                    componentIndex = 1,
                    key = "DAMAGE_1",
                    tokenType = "spell_damage_range",
                }
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Fire Breath

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                baseDamage = 67.12875,
                                damageSchoolRefs = { "f82db71a:esjguw6d" },
                                damageType = "spell",
                                hitType = "ability",
                                projectilePath = "",
                                projectileSpeed = 0,
                                statScaling = {
                                    {
                                        coefficient = 0.69615,
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
                        key = "evfbdm01",
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
                                auraRef = "evokdata:evfrbra1",
                                basePower = 0,
                                duration = 3,
                                stacks = 1,
                                targetEvents = { },
                                type = "apply_aura",
                            },
                        key = "evfbau01",
                        target = {
                                allowDeadTargets = false,
                                disableSelfCast = false,
                                maxTargets = 5,
                                minTargets = 1,
                                requiresTarget = true,
                                targetDisposition = "enemy",
                                type = "multi",
                            },
                    }
        },
        conditions = { },
        cooldown = 3,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_firebreath.blp",
        id = "evfireb1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Fire Breath",
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
        spellbookCategory = "General",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Cast for 1 turn to deal {DAMAGE_1} Fire damage to up to 5 enemies and apply Fire Breath for 3 turns.",
            tokens = {
                {
                    applyMode = "damage_range",
                    componentIndex = 1,
                    key = "DAMAGE_1",
                    tokenType = "spell_damage_range",
                }
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Obsidian Scales

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                auraRef = "evokdata:evobsca1",
                                basePower = 0,
                                duration = 1,
                                stacks = 1,
                                targetEvents = { },
                                type = "apply_aura",
                            },
                        key = "evobsau1",
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
        conditions = { },
        cooldown = 5,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_obsidianscales.blp",
        id = "evobssp1",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Obsidian Scales",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "General",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Apply Obsidian Scales to yourself for 1 turn, increasing Damage Reduction by 35 and Magic Resistance by 20.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Quell

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                        key = "evquint1",
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
        conditions = { },
        cooldown = 4,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_quell.blp",
        id = "evquell1",
        cooldownChannel = 5,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Quell",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "General",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Interrupt an enemy's current spell cast.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Cauterizing Flame

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                tags = { "bleed", "poison", "curse", "disease" },
                                targetEvents = { },
                                type = "remove_aura_by_tag",
                            },
                        key = "evcaurm1",
                        target = {
                                allowDeadTargets = false,
                                disableSelfCast = false,
                                maxTargets = 1,
                                minTargets = 1,
                                requiresTarget = true,
                                targetDisposition = "ally",
                                type = "single",
                            },
                    }
        },
        conditions = { },
        cooldown = 5,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_fontofmagic_red.blp",
        id = "evcautf1",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Cauterizing Flame",
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
        spellbookCategory = "General",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Remove all Bleed, Poison, Curse, and Disease auras from an ally.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

# Devastation

## Disintegrate

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                baseDamage = 303.75,
                                damageSchoolRefs = { "f82db71a:hx7pnwv4", "f82db71a:dtxhglqg" },
                                damageType = "spell",
                                hitType = "ability",
                                projectilePath = "",
                                projectileSpeed = 0,
                                statScaling = {
                                    {
                                        coefficient = 3.15,
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
                        key = "evdidm01",
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
        conditions = { },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_disintegrate.blp",
        id = "evdisin1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Disintegrate",
        range = 0,
        resourceCosts = {
            {
                amount = 3,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:essence1",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Devastation",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Spend 3 Essence and channel for 1 turn to deal {DAMAGE_1} Spellfrost damage to an enemy.",
            tokens = {
                {
                    applyMode = "damage_range",
                    componentIndex = 1,
                    key = "DAMAGE_1",
                    tokenType = "spell_damage_range",
                }
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Pyre

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                baseDamage = 101.25,
                                damageSchoolRefs = { "f82db71a:esjguw6d" },
                                damageType = "spell",
                                hitType = "ability",
                                projectilePath = "",
                                projectileSpeed = 0,
                                statScaling = {
                                    {
                                        coefficient = 1.0125,
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
                        key = "evpydm01",
                        target = {
                                allowDeadTargets = false,
                                disableSelfCast = false,
                                maxTargets = 5,
                                minTargets = 1,
                                requiresTarget = true,
                                targetDisposition = "enemy",
                                type = "multi",
                            },
                    }
        },
        conditions = { },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_pyre.blp",
        id = "evpyre01",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Pyre",
        range = 0,
        resourceCosts = {
            {
                amount = 3,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:essence1",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Devastation",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Spend 3 Essence to deal {DAMAGE_1} Fire damage to up to 5 enemies.",
            tokens = {
                {
                    applyMode = "damage_range",
                    componentIndex = 1,
                    key = "DAMAGE_1",
                    tokenType = "spell_damage_range",
                }
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Eternity Surge

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                baseDamage = 105.3,
                                damageSchoolRefs = { "f82db71a:hx7pnwv4", "f82db71a:dtxhglqg" },
                                damageType = "spell",
                                hitType = "ability",
                                projectilePath = "",
                                projectileSpeed = 0,
                                statScaling = {
                                    {
                                        coefficient = 1.092,
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
                        key = "evetdm01",
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
        conditions = { },
        cooldown = 3,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_eternitysurge.blp",
        id = "evetsurg",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Eternity Surge",
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
        spellbookCategory = "Devastation",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Cast for 1 turn to deal {DAMAGE_1} Spellfrost damage to up to 3 enemies.",
            tokens = {
                {
                    applyMode = "damage_range",
                    componentIndex = 1,
                    key = "DAMAGE_1",
                    tokenType = "spell_damage_range",
                }
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Shattering Star

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                baseDamage = 71.825,
                                damageSchoolRefs = { "f82db71a:hx7pnwv4", "f82db71a:dtxhglqg" },
                                damageType = "spell",
                                hitType = "ability",
                                projectilePath = "",
                                projectileSpeed = 0,
                                statScaling = {
                                    {
                                        coefficient = 0.71825,
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
                        key = "evssdm01",
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
                                auraRef = "evokdata:evshsta1",
                                basePower = 0,
                                duration = 2,
                                stacks = 1,
                                targetEvents = { },
                                type = "apply_aura",
                            },
                        key = "evssau01",
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
        conditions = { },
        cooldown = 3,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_chargedblast.blp",
        id = "evshstr1",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Shattering Star",
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
        spellbookCategory = "Devastation",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Deal {DAMAGE_1} Spellfrost damage to an enemy and apply Shattering Star for 2 turns, reducing its Damage Reduction by 10.",
            tokens = {
                {
                    applyMode = "damage_range",
                    componentIndex = 1,
                    key = "DAMAGE_1",
                    tokenType = "spell_damage_range",
                }
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Dragonrage

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                auraRef = "evokdata:evdrgra1",
                                basePower = 0,
                                duration = 2,
                                stacks = 1,
                                targetEvents = { },
                                type = "apply_aura",
                            },
                        key = "evdrau01",
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
        conditions = { },
        cooldown = 10,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_dragonrage2.blp",
        id = "evdragr1",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Dragonrage",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Devastation",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Apply Dragonrage to yourself for 2 turns, increasing Damage Done by 15 and Spell Crit. Chance by 10.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

# Preservation

## Reversion

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                auraRef = "evokdata:evrevera",
                                basePower = 0,
                                duration = 5,
                                stacks = 1,
                                targetEvents = { },
                                type = "apply_aura",
                            },
                        key = "evrvau01",
                        target = {
                                allowDeadTargets = false,
                                disableSelfCast = false,
                                maxTargets = 1,
                                minTargets = 1,
                                requiresTarget = true,
                                targetDisposition = "ally",
                                type = "single",
                            },
                    }
        },
        conditions = { },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_reversion.blp",
        id = "evrever1",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Reversion",
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
        spellbookCategory = "Preservation",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Apply Reversion to an ally for 5 turns, healing each turn.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Emerald Blossom

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                baseHealing = 101.25,
                                projectilePath = "",
                                projectileSpeed = 0,
                                statScaling = {
                                    {
                                        coefficient = 0.6075,
                                        statRef = "f82db71a:hj6d4kvy",
                                    },
                                },
                                targetEvents = {
                                    "on_heal_taken",
                                    "on_critical_heal_taken",
                                },
                                threatCoefficient = 0.5,
                                type = "heal",
                                usesProjectile = false,
                            },
                        key = "evebhl01",
                        target = {
                                allowDeadTargets = false,
                                disableSelfCast = false,
                                maxTargets = 5,
                                minTargets = 1,
                                requiresTarget = true,
                                targetDisposition = "ally",
                                type = "multi",
                            },
                    }
        },
        conditions = { },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_emeraldblossom.blp",
        id = "evemblos",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Emerald Blossom",
        range = 0,
        resourceCosts = {
            {
                amount = 3,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:essence1",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Preservation",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Spend 3 Essence to heal up to 5 allies for {HEAL_1} health.",
            tokens = {
                {
                    applyMode = "heal_range",
                    componentIndex = 1,
                    key = "HEAL_1",
                    tokenType = "spell_heal_range",
                }
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Dream Breath

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                baseHealing = 72.10125,
                                projectilePath = "",
                                projectileSpeed = 0,
                                statScaling = {
                                    {
                                        coefficient = 0.3978,
                                        statRef = "f82db71a:hj6d4kvy",
                                    },
                                },
                                targetEvents = {
                                    "on_heal_taken",
                                    "on_critical_heal_taken",
                                },
                                threatCoefficient = 0.5,
                                type = "heal",
                                usesProjectile = false,
                            },
                        key = "evdbhl01",
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
            {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                                auraRef = "evokdata:evdrbea1",
                                basePower = 0,
                                duration = 3,
                                stacks = 1,
                                targetEvents = { },
                                type = "apply_aura",
                            },
                        key = "evdbau01",
                        target = {
                                allowDeadTargets = false,
                                disableSelfCast = false,
                                maxTargets = 5,
                                minTargets = 1,
                                requiresTarget = true,
                                targetDisposition = "ally",
                                type = "multi",
                            },
                    }
        },
        conditions = { },
        cooldown = 3,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_dreambreath.blp",
        id = "evdreamb",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Dream Breath",
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
        spellbookCategory = "Preservation",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Cast for 1 turn to heal up to 5 allies for {HEAL_1} health and apply Dream Breath for 3 turns.",
            tokens = {
                {
                    applyMode = "heal_range",
                    componentIndex = 1,
                    key = "HEAL_1",
                    tokenType = "spell_heal_range",
                }
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Spiritbloom

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                baseHealing = 94.6125,
                                projectilePath = "",
                                projectileSpeed = 0,
                                statScaling = {
                                    {
                                        coefficient = 0.522,
                                        statRef = "f82db71a:hj6d4kvy",
                                    },
                                },
                                targetEvents = {
                                    "on_heal_taken",
                                    "on_critical_heal_taken",
                                },
                                threatCoefficient = 0.5,
                                type = "heal",
                                usesProjectile = false,
                            },
                        key = "evsphl01",
                        target = {
                                allowDeadTargets = false,
                                disableSelfCast = false,
                                maxTargets = 5,
                                minTargets = 1,
                                requiresTarget = true,
                                targetDisposition = "ally",
                                type = "multi",
                            },
                    }
        },
        conditions = { },
        cooldown = 4,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_spiritbloom.blp",
        id = "evspirit",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Spiritbloom",
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
        spellbookCategory = "Preservation",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Cast for 1 turn to heal up to 5 allies for {HEAL_1} health.",
            tokens = {
                {
                    applyMode = "heal_range",
                    componentIndex = 1,
                    key = "HEAL_1",
                    tokenType = "spell_heal_range",
                }
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Zephyr

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                auraRef = "evokdata:evzepha1",
                                basePower = 0,
                                duration = 1,
                                stacks = 1,
                                targetEvents = { },
                                type = "apply_aura",
                            },
                        key = "evzeau01",
                        target = {
                                allowDeadTargets = false,
                                disableSelfCast = false,
                                maxTargets = 0,
                                minTargets = 0,
                                requiresTarget = false,
                                targetDisposition = "ally",
                                type = "all_allies",
                            },
                    }
        },
        conditions = { },
        cooldown = 5,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_zephyr.blp",
        id = "evzephyr",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Zephyr",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Preservation",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Apply Zephyr to all allies for 1 turn, increasing Damage Reduction by 20.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Emerald Communion

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                    auraRef = "evokdata:evemcoa1",
                    basePower = 0,
                    duration = 2,
                    stacks = 1,
                    targetEvents = { },
                    type = "apply_aura",
                },
                key = "evecau01",
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
        icon = "interface/icons/ability_evoker_green_01.blp",
        id = "evemcomm",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Emerald Communion",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Preservation",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Apply Emerald Communion to yourself for 2 turns, restoring 20% of maximum health each turn.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

# Augmentation

## Eruption

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                damageSchoolRefs = { "f82db71a:esjguw6d", "f82db71a:qtr10qyj" },
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
                        key = "everdm01",
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
        conditions = { },
        cooldown = 0,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_eruption.blp",
        id = "everupt1",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Eruption",
        range = 0,
        resourceCosts = {
            {
                amount = 3,
                amountMode = "flat",
                castPhase = "on_cast_end",
                refundOnInterrupt = 0,
                resourceRef = "f82db71a:essence1",
            },
        },
        seedNPCSpell = false,
        spellbookCategory = "Augmentation",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Spend 3 Essence to deal {DAMAGE_1} Volcanic damage to an enemy.",
            tokens = {
                {
                    applyMode = "damage_range",
                    componentIndex = 1,
                    key = "DAMAGE_1",
                    tokenType = "spell_damage_range",
                }
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Ebon Might

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                auraRef = "evokdata:evebona1",
                                basePower = 0,
                                duration = 2,
                                stacks = 1,
                                targetEvents = { },
                                type = "apply_aura",
                            },
                        key = "evemau01",
                        target = {
                                allowDeadTargets = false,
                                disableSelfCast = false,
                                maxTargets = 0,
                                minTargets = 0,
                                requiresTarget = false,
                                targetDisposition = "ally",
                                type = "all_allies",
                            },
                    }
        },
        conditions = { },
        cooldown = 5,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/spell_sarkareth.blp",
        id = "evebonmt",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Ebon Might",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Augmentation",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Apply Ebon Might to all allies for 2 turns, increasing Damage Done by 10.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Prescience

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                auraRef = "evokdata:evpresa1",
                                basePower = 0,
                                duration = 2,
                                stacks = 1,
                                targetEvents = { },
                                type = "apply_aura",
                            },
                        key = "evprau01",
                        target = {
                                allowDeadTargets = false,
                                disableSelfCast = false,
                                maxTargets = 1,
                                minTargets = 1,
                                requiresTarget = true,
                                targetDisposition = "ally",
                                type = "single",
                            },
                    }
        },
        conditions = { },
        cooldown = 2,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_prescience.blp",
        id = "evpresci",
        cooldownChannel = 2,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = false,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Prescience",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Augmentation",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Apply Prescience to an ally for 2 turns, increasing Melee, Ranged, and Spell Crit. Chance by 5.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Blistering Scales

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                auraRef = "evokdata:evblsca1",
                                basePower = 0,
                                duration = 3,
                                stacks = 1,
                                targetEvents = { },
                                type = "apply_aura",
                            },
                        key = "evbsau01",
                        target = {
                                allowDeadTargets = false,
                                disableSelfCast = false,
                                maxTargets = 1,
                                minTargets = 1,
                                requiresTarget = true,
                                targetDisposition = "ally",
                                type = "single",
                            },
                    }
        },
        conditions = { },
        cooldown = 3,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_blisteringscales.blp",
        id = "evblscal",
        cooldownChannel = 3,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Blistering Scales",
        range = 0,
        resourceCosts = { },
        seedNPCSpell = false,
        spellbookCategory = "Augmentation",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Apply Blistering Scales to an ally for 3 turns, increasing Armor by 30%. Melee attacks against the ally deal Volcanic damage back to the attacker.",
            tokens = { },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```
## Upheaval

```text
RPE_DATASET_ENTRY_V1
{
    format = "rpe-dataset-entry",
    version = 1,
    collectionKey = "spells",
    datasetId = "evokdata",
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
                                baseDamage = 78.975,
                                damageSchoolRefs = { "f82db71a:esjguw6d", "f82db71a:qtr10qyj" },
                                damageType = "spell",
                                hitType = "ability",
                                projectilePath = "",
                                projectileSpeed = 0,
                                statScaling = {
                                    {
                                        coefficient = 0.819,
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
                        key = "evupdm01",
                        target = {
                                allowDeadTargets = false,
                                disableSelfCast = false,
                                maxTargets = 5,
                                minTargets = 1,
                                requiresTarget = true,
                                targetDisposition = "enemy",
                                type = "multi",
                            },
                    }
        },
        conditions = { },
        cooldown = 3,
        cooldownGroup = "",
        cooldownScalesWithHaste = false,
        description = "",
        icon = "interface/icons/ability_evoker_upheaval.blp",
        id = "evupheav",
        cooldownChannel = 1,
        learnMode = "always_learned",
        learnLevel = 1,
        usesRanks = true,
        rankInterval = 8,
        mountedCombatOnly = false,
        name = "Upheaval",
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
        spellbookCategory = "Augmentation",
        tags = { },
        tooltipTemplate = true,
        tooltipTemplateData = {
            auraSections = { },
            mainText = "Cast for 1 turn to deal {DAMAGE_1} Volcanic damage to up to 5 enemies.",
            tokens = {
                {
                    applyMode = "damage_range",
                    componentIndex = 1,
                    key = "DAMAGE_1",
                    tokenType = "spell_damage_range",
                }
            },
            version = 1,
        },
        totalTicks = 0,
        useCooldownCharges = false,
    },
}
```

# Explicitly omitted

The following recognizable Evoker abilities are not included because their defining mechanic is not represented faithfully enough by the current RPE spell model:

- **Deep Breath**, **Hover**, **Rescue**, **Dream Flight**, and the movement component of **Verdant Embrace** — movement/pathing is the defining mechanic.
- **Echo** and **Stasis** — require storing/replaying arbitrary healing spells.
- **Rewind** — requires restoring historical health loss.
- **Temporal Anomaly** — moving area/projectile support behavior is not faithfully represented.
- **Time Skip** — generic cooldown acceleration is not represented as a spell effect.
- **Breath of Eons** — combines movement with recording allied damage and releasing delayed damage.
