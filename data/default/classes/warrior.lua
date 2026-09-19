local _, Addon = ...

Addon.Data.DefaultDatasets:Register({
        version = 32,
    dataset = {
        achievements = {},
        auras = {
            {
                description = "",
                duration = 2,
                effects = {
                    {
                        baseAmount = -50,
                        operation = "flat",
                        statRef = "f82db71a:ok80ohz3",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/ability_warrior_savageblow.blp",
                id = "sb4b9ef3",
                maxStacks = 1,
                name = "Mortal Strike",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Reduces Healing Received by 50%.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 5,
                effects = {
                    {
                        baseAmount = -5,
                        operation = "percent",
                        statRef = "f82db71a:v42albuv",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/ability_warrior_sunder.blp",
                id = "3zcf855l",
                maxStacks = 5,
                name = "Sunder Armor",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Reduces Armor by 5%.",
                    bodyTokens = {},
                    stackingText = "Applies {AURA_APPLIED_STACKS_1} stacks. Stacks up to {AURA_MAX_STACKS_1} times.",
                    stackingTokens = {
                        {
                            applyMode = "applied_stacks",
                            key = "AURA_APPLIED_STACKS_1",
                            tokenType = "aura_stacks"
                        },
                        {
                            applyMode = "max_stacks",
                            key = "AURA_MAX_STACKS_1",
                            tokenType = "aura_stacks"
                        }
                    },
                    version = 1
                }
            },
            {
                description = "",
                duration = 5,
                effects = {
                    {
                        amount = 3,
                        amountMode = "flat",
                        resourceRef = "f82db71a:e2tfklq7",
                        type = "resource"
                    }
                },
                events = {},
                icon = "interface/icons/ability_racial_bloodrage.blp",
                id = "symxsuw8",
                maxStacks = 1,
                name = "Bloodrage",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Restores {AURA_RESOURCE_GAIN_1} each turn.",
                    bodyTokens = {
                        {
                            applyMode = "resource_gain_amount",
                            effectIndex = 1,
                            key = "AURA_RESOURCE_GAIN_1",
                            tokenType = "aura_amount"
                        }
                    },
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 2,
                effects = {
                    {
                        baseAmount = 10,
                        operation = "flat",
                        statRef = "f82db71a:gj9wxb0x",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_shadow_unholyfrenzy.blp",
                id = "12yk1r4y",
                maxStacks = 1,
                name = "Enrage",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Damage Done by 10%.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 1,
                effects = {
                    {
                        baseAmount = 100,
                        operation = "flat",
                        statRef = "f82db71a:jslmczbi",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/warrior_talent_icon_innerrage.blp",
                id = "iuedsekl",
                maxStacks = 1,
                name = "Inner Rage",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Melee Crit. Chance by 100%.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 5,
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 20.8,
                        damageSchoolRefs = {
                            "f82db71a:v1azo4j6"
                        },
                        statScaling = {
                            {
                                coefficient = 0.364,
                                statRef = "f82db71a:u7b49vs9"
                            }
                        },
                        type = "damage"
                    }
                },
                events = {},
                icon = "interface/icons/ability_gouge.blp",
                id = "jkptpqlh",
                maxStacks = 1,
                name = "Rend",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Deals {AURA_DAMAGE_1} Physical damage each turn.",
                    bodyTokens = {
                        {
                            applyMode = "damage_amount",
                            baseField = "baseDamage",
                            effectIndex = 1,
                            key = "AURA_DAMAGE_1",
                            tokenType = "aura_amount"
                        }
                    },
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 3,
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 28.1667,
                        damageSchoolRefs = {
                            "f82db71a:v1azo4j6"
                        },
                        statScaling = {
                            {
                                coefficient = 0.29575,
                                statRef = "f82db71a:u7b49vs9"
                            }
                        },
                        type = "damage"
                    }
                },
                events = {},
                icon = "interface/icons/ability_backstab.blp",
                id = "q2mqgpzk",
                maxStacks = 1,
                name = "Deep Wounds",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true
            },
            {
                description = "",
                duration = 1,
                effects = {
                    {
                        cancelOnDamage = false,
                        forceAutoHitAgainstTarget = true,
                        preventCasting = true,
                        type = "control"
                    }
                },
                events = {},
                icon = "interface/icons/inv_mace_62.blp",
                id = "axrgl3wk",
                maxStacks = 1,
                name = "Knockdown",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Prevents the affected unit from casting spells. Causes all attacks against the affected unit to automatically hit.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 1,
                effects = {
                    {
                        cancelOnDamage = true,
                        forceAutoHitAgainstTarget = false,
                        preventCasting = true,
                        type = "control"
                    }
                },
                events = {},
                icon = "interface/icons/ability_golemthunderclap.blp",
                id = "yqye09rp",
                maxStacks = 1,
                name = "Initimidating Shout",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Breaks when the affected unit takes damage. Prevents the affected unit from casting spells.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 1,
                effects = {
                    {
                        baseAmount = 75,
                        operation = "flat",
                        statRef = "f82db71a:p8syz5ba",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/ability_defend.blp",
                id = "o3byh3lk",
                maxStacks = 1,
                name = "Shield Block",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Block Chance by 75%.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 10,
                effects = {
                    {
                        baseAmount = 10,
                        operation = "percent",
                        statRef = "f82db71a:u7b49vs9",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/ability_warrior_battleshout.blp",
                id = "hfmmcsmr",
                maxStacks = 1,
                name = "Battle Shout",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Melee Attack Power by 10%.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 10,
                effects = {
                    {
                        baseAmount = 5,
                        operation = "percent",
                        statRef = "f82db71a:ygjno50i",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/ability_warrior_rallyingcry.blp",
                id = "v65x2cz3",
                maxStacks = 1,
                name = "Commanding Shout",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Stamina by 5%.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
            {
                description = "",
                duration = 2,
                effects = {
                    {
                        baseAmount = 40,
                        operation = "flat",
                        statRef = "f82db71a:pu05li08",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/ability_warrior_shieldwall.blp",
                id = "mjmnbas1",
                maxStacks = 1,
                name = "Shield Wall",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Damage Reduction by 40%.",
                    bodyTokens = {},
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            }
        },
        authorName = "Ortellus-ArgentDawn",
        classes = {
            {
                description = "For as long as war has raged, heroes from every race have aimed to master the art of battle. Warriors combine strength, leadership, and a vast knowledge of arms and armor to wreak havoc in glorious combat. Some protect from the front lines with shields, locking down enemies while allies support the warrior from behind with spell and bow. Others forgo the shield and unleash their rage at the closest threat with a variety of deadly weapons.",
                icon = "interface/icons/classicon_warrior.blp",
                id = "wvirv9um",
                name = "Warrior",
                armorWeights = {
                    "mail",
                    "plate",
                    "shield",
                },
                weaponTypeRefs = {
                    "f82db71a:z6nh3znw",
                    "f82db71a:i4pivdig",
                    "f82db71a:9ni3vfas",
                    "f82db71a:y0dnlo8g",
                    "f82db71a:25s5wyry",
                    "f82db71a:3y1v01e4",
                    "f82db71a:l3ce0puc",
                    "f82db71a:j2gceby4",
                    "f82db71a:anoo8qfp",
                    "f82db71a:gjz2331m",
                    "f82db71a:we5ul4ne",
                },
                resourceProgressions = {
                    {
                        initialValue = 20,
                        perLevelValue = 28.29,
                        resourceRef = "f82db71a:q2ktkztt"
                    }
                },
                skillBonuses = {},
                statProgressions = {
                    {
                        initialValue = 3,
                        perLevelValue = 1.64,
                        statRef = "f82db71a:zfqm8dxp"
                    },
                    {
                        initialValue = 2,
                        perLevelValue = 1.49,
                        statRef = "f82db71a:ygjno50i"
                    },
                    {
                        initialValue = 0,
                        perLevelValue = 1.02,
                        statRef = "f82db71a:xqz0daz2"
                    },
                    {
                        initialValue = 0,
                        perLevelValue = 0.17,
                        statRef = "f82db71a:75y3a8ib"
                    },
                    {
                        initialValue = 0,
                        perLevelValue = 0.42,
                        statRef = "f82db71a:kec9rhli"
                    }
                },
                passiveTraitRefs = {
                    "7bbb4cb9:gntslayr",
                    "7bbb4cb9:momntm10"
                },
                talentTraitRefs = {
                    "7bbb4cb9:duukevtq",
                    "7bbb4cb9:r73vv899",
                    "7bbb4cb9:0ncx0gfs",
                    "7bbb4cb9:a8x4ee34",
                    "7bbb4cb9:sxq460qa",
                    "7bbb4cb9:cruelty3",
                    "7bbb4cb9:antcwar1",
                    "7bbb4cb9:shldspc1",
                    "7bbb4cb9:0yud4l94"
                }
            }
        },
        currencies = {},
        damageSchools = {},
        datasetType = "class",
        dependencies = {
            "f82db71a"
        },
        description = "",
        groupName = "Core",
        guildSettings = {},
        id = "7bbb4cb9",
        interactions = {},
        itemSlots = {},
        items = {},
        loot = {},
        mounts = {},
        name = "Warrior",
        pets = {},
        races = {},
        recipes = {},
        resources = {},
        skills = {},
        spells = {
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {},
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
                            baseDamage = 78.75,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.3675,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1.05,
                            weaponDamageMode = "main_hand"
                        },
                        key = "ovrpowr1",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {
                    {
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Requires a failed attack this turn",
                        type = "caster_failed_attack_this_turn"
                    },
                    {
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires Main Hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 1,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "Instantly overpower an enemy after a failed attack, dealing Physical damage.",
                icon = "interface/icons/ability_meleedamage.blp",
                id = "ovrpowr1",
                cooldownChannel = 5,
                learnMode = "always_learned",
                learnLevel = 12,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Overpower",
                range = 0,
                resourceCosts = {
                    {
                        amount = 5,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Arms",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Physical damage to an enemy after failing an attack this turn.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_melee_hit",
                    "on_critical_hit"
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
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.182,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1.5,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0.52,
                            weaponDamageMode = "main_hand"
                        },
                        key = "9e1eae8d",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {
                    {
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires Main Hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_rogue_ambush.blp",
                id = "c1s93sif",
                cooldownChannel = 2,
                learnMode = "always_learned",
                learnLevel = 1,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Heroic Strike",
                range = 0,
                resourceCosts = {
                    {
                        amount = 15,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Arms",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Physical damage to an enemy. Generates a moderate amount of threat.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_melee_hit",
                    "on_critical_hit"
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
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.35,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "main_hand"
                        },
                        key = "9e1eae8d",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 2,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "raid_marker"
                        }
                    }
                },
                conditions = {
                    {
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires Main Hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_warrior_cleave.blp",
                id = "e0mooybr",
                cooldownChannel = 1,
                learnMode = "always_learned",
                learnLevel = 20,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Cleave",
                range = 0,
                resourceCosts = {
                    {
                        amount = 20,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Fury",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Physical damage to up to 1 enemy. Targets must share the same raid marker.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                _resourceCostsByPhase = {
                    on_cast_end = {
                        {
                            amount = 30,
                            amountMode = "flat",
                            castPhase = "on_cast_end",
                            refundOnInterrupt = 0,
                            resourceRef = "f82db71a:e2tfklq7"
                        }
                    },
                    on_cast_start = {}
                },
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_melee_hit",
                    "on_critical_hit"
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
                            auraRef = "7bbb4cb9:sb4b9ef3",
                            auraStacks = 1,
                            baseDamage = 92.438,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.4314,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1.2325,
                            weaponDamageMode = "main_hand"
                        },
                        key = "fac025f0",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {
                    {
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires Main Hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 4,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_warrior_savageblow.blp",
                id = "0jiq0uoc",
                cooldownChannel = 1,
                learnMode = "always_learned",
                learnLevel = 40,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Mortal Strike",
                range = 0,
                resourceCosts = {
                    {
                        amount = 30,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Arms",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "7bbb4cb9:sb4b9ef3",
                            datasetId = "7bbb4cb9",
                            descriptionText = "Reduces Healing Received by 50%.",
                            icon = "interface/icons/ability_warrior_savageblow.blp",
                            nameText = "Mortal Strike",
                            powerLevel = 0,
                            spellDatasetId = "7bbb4cb9",
                            stacks = 1,
                            targetContext = {
                                object = "the affected enemy",
                                possessive = "the affected enemy's",
                                reflexive = "itself",
                                subject = "the affected enemy"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Deal {DAMAGE_1} Physical damage to an enemy and apply Mortal Strike for 2 turns.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 1,
                casterEvents = {
                    "on_melee_hit",
                    "on_critical_hit"
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
                            auraRef = "7bbb4cb9:sb4b9ef3",
                            auraStacks = 1,
                            baseDamage = 106.313,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.525,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1.05,
                            weaponDamageMode = "main_hand"
                        },
                        key = "fac025f0",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {
                    {
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires Main Hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 1,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_warrior_decisivestrike.blp",
                id = "68qm26aq",
                cooldownChannel = 1,
                learnMode = "always_learned",
                learnLevel = 30,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Slam",
                range = 0,
                resourceCosts = {
                    {
                        amount = 20,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Arms",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Physical damage to an enemy.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_melee_hit",
                    "on_critical_hit"
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
                            auraRef = "7bbb4cb9:3zcf855l",
                            auraStacks = 1,
                            baseDamage = 46.41,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.1624,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1.5,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0,
                            weaponDamageMode = "none"
                        },
                        key = "fac025f0",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {
                    {
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires Main Hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 1,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_warrior_sunder.blp",
                id = "etsuhe6x",
                cooldownChannel = 1,
                learnMode = "always_learned",
                learnLevel = 10,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Sunder Armor",
                range = 0,
                resourceCosts = {
                    {
                        amount = 15,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Protection",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "7bbb4cb9:3zcf855l",
                            datasetId = "7bbb4cb9",
                            descriptionText = "Reduces Armor by 5%. Applies {AURA_APPLIED_STACKS_1} stacks. Stacks up to {AURA_MAX_STACKS_1} times.",
                            icon = "interface/icons/ability_warrior_sunder.blp",
                            nameText = "Sunder Armor",
                            powerLevel = 0,
                            spellDatasetId = "7bbb4cb9",
                            stacks = 1,
                            targetContext = {
                                object = "the affected enemy",
                                possessive = "the affected enemy's",
                                reflexive = "itself",
                                subject = "the affected enemy"
                            },
                            tokens = {
                                {
                                    applyMode = "applied_stacks",
                                    key = "AURA_APPLIED_STACKS_1",
                                    tokenType = "aura_stacks"
                                },
                                {
                                    applyMode = "max_stacks",
                                    key = "AURA_MAX_STACKS_1",
                                    tokenType = "aura_stacks"
                                }
                            }
                        }
                    },
                    mainText = "Deal {DAMAGE_1} Physical damage to an enemy and apply Sunder Armor for 5 turns. Generates a moderate amount of threat.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_melee_hit",
                    "on_critical_hit"
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
                            baseDamage = 104,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.364,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 2,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0,
                            weaponDamageMode = "none"
                        },
                        key = "9e1eae8d",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {
                    {
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "offhand",
                        tooltipTextOverride = "Requires Shield",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 3,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/inv_shield_05.blp",
                id = "kejakdxo",
                cooldownChannel = 1,
                learnMode = "always_learned",
                learnLevel = 40,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Shield Slam",
                range = 0,
                resourceCosts = {
                    {
                        amount = 30,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Protection",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Physical damage to an enemy. Generates a high amount of threat.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_melee_hit",
                    "on_critical_hit"
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
                            baseDamage = 70.72,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.2475,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1.5,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0,
                            weaponDamageMode = "none"
                        },
                        key = "9e1eae8d",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    },
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            targetEvents = {},
                            type = "interrupt"
                        },
                        key = "41b5ff18",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {
                    {
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "offhand",
                        tooltipTextOverride = "Requires Shield",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 5,
                cooldownGroup = "interrupt",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_warrior_shieldbash.blp",
                id = "ti2j4umn",
                cooldownChannel = 5,
                learnMode = "always_learned",
                learnLevel = 12,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Shield Bash",
                range = 0,
                resourceCosts = {
                    {
                        amount = 5,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Protection",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Physical damage to an enemy. Interrupt an enemy's spellcasting. Generates a moderate amount of threat.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            duration = 3,
                            targetEvents = {},
                            type = "taunt"
                        },
                        key = "tntcmp01",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 3,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_nature_reincarnation.blp",
                id = "tntwar01",
                cooldownChannel = 2,
                learnMode = "always_learned",
                learnLevel = 10,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Taunt",
                range = 0,
                resourceCosts = {
                },
                seedNPCSpell = false,
                spellbookCategory = "Protection",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Taunt an enemy for 3 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            amount = 10,
                            amountMode = "flat",
                            resourceRef = "f82db71a:e2tfklq7",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "d865ff88",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 0,
                            requiresTarget = false,
                            targetDisposition = "ally",
                            type = "caster"
                        }
                    },
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "7bbb4cb9:symxsuw8",
                            basePower = 0,
                            duration = 5,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "20e2e3b2",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 0,
                            requiresTarget = false,
                            targetDisposition = "ally",
                            type = "caster"
                        }
                    }
                },
                conditions = {},
                cooldown = 10,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_racial_bloodrage.blp",
                id = "yn5l4xkq",
                cooldownChannel = 3,
                learnMode = "always_learned",
                learnLevel = 10,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Bloodrage",
                range = 0,
                resourceCosts = {
                    {
                        amount = 10,
                        amountMode = "base_percent",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:q2ktkztt"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Fury",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "7bbb4cb9:symxsuw8",
                            datasetId = "7bbb4cb9",
                            descriptionText = "Restores {AURA_RESOURCE_GAIN_1} each turn.",
                            duration = 5,
                            icon = "interface/icons/ability_racial_bloodrage.blp",
                            nameText = "Bloodrage",
                            powerLevel = 0,
                            spellDatasetId = "7bbb4cb9",
                            stacks = 1,
                            targetContext = {
                                object = "you",
                                possessive = "your",
                                reflexive = "yourself",
                                subject = "you"
                            },
                            tokens = {
                                {
                                    applyMode = "resource_gain_amount",
                                    effectIndex = 1,
                                    key = "AURA_RESOURCE_GAIN_1",
                                    tokenType = "aura_amount"
                                }
                            }
                        }
                    },
                    mainText = "Restore {RESOURCE_AMOUNT_1} to yourself. Apply Bloodrage to yourself for 5 turns.",
                    tokens = {
                        {
                            applyMode = "resource_gain_amount",
                            componentIndex = 1,
                            key = "RESOURCE_AMOUNT_1",
                            tokenType = "spell_resource_amount"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "7bbb4cb9:iuedsekl",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "fec17620",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 0,
                            requiresTarget = false,
                            targetDisposition = "ally",
                            type = "caster"
                        }
                    }
                },
                conditions = {},
                cooldown = 10,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/warrior_talent_icon_innerrage.blp",
                id = "lzan8taw",
                cooldownChannel = 3,
                learnMode = "always_learned",
                learnLevel = 56,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Inner Rage",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = false,
                spellbookCategory = "Fury",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "7bbb4cb9:iuedsekl",
                            datasetId = "7bbb4cb9",
                            descriptionText = "Increases Melee Crit. Chance by 100%.",
                            duration = 1,
                            icon = "interface/icons/warrior_talent_icon_innerrage.blp",
                            nameText = "Inner Rage",
                            powerLevel = 0,
                            spellDatasetId = "7bbb4cb9",
                            stacks = 1,
                            targetContext = {
                                object = "you",
                                possessive = "your",
                                reflexive = "yourself",
                                subject = "you"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Apply Inner Rage to yourself for 1 turn.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "7bbb4cb9:jkptpqlh",
                            basePower = 0,
                            duration = 5,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "63ec989c",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {
                    {
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires Main Hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_gouge.blp",
                id = "xniv44uu",
                cooldownChannel = 2,
                learnMode = "always_learned",
                learnLevel = 4,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Rend",
                range = 0,
                resourceCosts = {
                    {
                        amount = 8,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Arms",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "7bbb4cb9:jkptpqlh",
                            datasetId = "7bbb4cb9",
                            descriptionText = "Deals {AURA_DAMAGE_1} Physical damage each turn.",
                            duration = 5,
                            icon = "interface/icons/ability_gouge.blp",
                            nameText = "Rend",
                            powerLevel = 0,
                            spellDatasetId = "7bbb4cb9",
                            stacks = 1,
                            targetContext = {
                                object = "the affected enemy",
                                possessive = "the affected enemy's",
                                reflexive = "itself",
                                subject = "the affected enemy"
                            },
                            tokens = {
                                {
                                    applyMode = "damage_amount",
                                    baseField = "baseDamage",
                                    effectIndex = 1,
                                    key = "AURA_DAMAGE_1",
                                    tokenType = "aura_amount"
                                }
                            }
                        }
                    },
                    mainText = "Apply Rend to an enemy for 5 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_melee_hit",
                    "on_critical_hit"
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
                            baseDamage = 54.375,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.2538,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0.725,
                            weaponDamageMode = "main_hand"
                        },
                        key = "7957e474",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 4,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "raid_marker"
                        }
                    }
                },
                conditions = {
                    {
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires Main Hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 4,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_whirlwind.blp",
                id = "k7ndyn09",
                cooldownChannel = 1,
                learnMode = "always_learned",
                learnLevel = 36,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Whirlwind",
                range = 0,
                resourceCosts = {
                    {
                        amount = 25,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Fury",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Physical damage to up to 4 enemies. Targets must share the same raid marker.",
                    mainText = "Deal {DAMAGE_1} Physical damage to up to 4 enemies. Targets must share the same raid marker.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 1,
                casterEvents = {
                    "on_melee_hit",
                    "on_critical_hit"
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
                            baseDamage = 93.656,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.4625,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0.925,
                            weaponDamageMode = "main_hand"
                        },
                        key = "7957e474",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 4,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "raid_marker"
                        }
                    }
                },
                conditions = {
                    {
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires Main Hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 10,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_warrior_bladestorm.blp",
                id = "bblnsvg2",
                cooldownChannel = 1,
                learnMode = "always_learned",
                learnLevel = 60,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Bladestorm",
                range = 0,
                resourceCosts = {
                    {
                        amount = 30,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Arms",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Physical damage to up to 4 enemies. Targets must share the same raid marker.",
                    mainText = "Deal {DAMAGE_1} Physical damage to up to 4 enemies. Targets must share the same raid marker.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "7bbb4cb9:axrgl3wk",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "3892b335",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 6,
                cooldownGroup = "stun",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/inv_mace_62.blp",
                id = "9870xnra",
                cooldownChannel = 2,
                learnMode = "always_learned",
                learnLevel = 20,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Knockdown",
                range = 0,
                resourceCosts = {
                    {
                        amount = 5,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Arms",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "7bbb4cb9:axrgl3wk",
                            datasetId = "7bbb4cb9",
                            descriptionText = "Prevents the affected unit from casting spells. Causes all attacks against the affected unit to automatically hit.",
                            duration = 1,
                            icon = "interface/icons/inv_mace_62.blp",
                            nameText = "Knockdown",
                            powerLevel = 0,
                            spellDatasetId = "7bbb4cb9",
                            stacks = 1,
                            targetContext = {
                                object = "the affected enemy",
                                possessive = "the affected enemy's",
                                reflexive = "itself",
                                subject = "the affected enemy"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Apply Knockdown to an enemy for 1 turn.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "7bbb4cb9:yqye09rp",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "3892b335",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 3,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "multi"
                        }
                    }
                },
                conditions = {},
                cooldown = 10,
                cooldownGroup = "fear",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_golemthunderclap.blp",
                id = "s4nfrf2l",
                cooldownChannel = 2,
                learnMode = "always_learned",
                learnLevel = 22,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Intimidating Shout",
                range = 0,
                resourceCosts = {
                    {
                        amount = 15,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Fury",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "7bbb4cb9:yqye09rp",
                            datasetId = "7bbb4cb9",
                            descriptionText = "Breaks when the affected unit takes damage. Prevents the affected unit from casting spells.",
                            duration = 1,
                            icon = "interface/icons/ability_golemthunderclap.blp",
                            nameText = "Initimidating Shout",
                            powerLevel = 0,
                            spellDatasetId = "7bbb4cb9",
                            stacks = 1,
                            targetContext = {
                                object = "the affected enemy",
                                possessive = "the affected enemy's",
                                reflexive = "itself",
                                subject = "the affected enemy"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Apply Initimidating Shout to up to 3 enemies for 1 turn.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {},
                charges = 2,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "7bbb4cb9:o3byh3lk",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "1ec30e64",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 0,
                            requiresTarget = false,
                            targetDisposition = "ally",
                            type = "caster"
                        }
                    }
                },
                conditions = {
                    {
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "offhand",
                        tooltipTextOverride = "Requires Shield",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 5,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_defend.blp",
                id = "g36ujwt9",
                cooldownChannel = 5,
                learnMode = "always_learned",
                learnLevel = 16,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Shield Block",
                range = 0,
                resourceCosts = {
                    {
                        amount = 5,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Protection",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "7bbb4cb9:o3byh3lk",
                            datasetId = "7bbb4cb9",
                            descriptionText = "Increases Block Chance by 75%.",
                            duration = 1,
                            icon = "interface/icons/ability_defend.blp",
                            nameText = "Shield Block",
                            powerLevel = 0,
                            spellDatasetId = "7bbb4cb9",
                            stacks = 1,
                            targetContext = {
                                object = "you",
                                possessive = "your",
                                reflexive = "yourself",
                                subject = "you"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Apply Shield Block to yourself for 1 turn.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = true
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_melee_hit",
                    "on_critical_hit"
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
                            baseDamage = 82.875,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.3868,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1.105,
                            weaponDamageMode = "main_hand"
                        },
                        key = "9e1eae8d",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "single"
                        }
                    },
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            amountMode = "flat",
                            applyAura = false,
                            auraStacks = 1,
                            baseHealing = 35.913,
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.1257,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_heal_taken",
                                "on_critical_heal_taken"
                            },
                            type = "heal",
                            usesProjectile = false
                        },
                        key = "321a18bf",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 0,
                            requiresTarget = false,
                            targetDisposition = "ally",
                            type = "caster"
                        }
                    }
                },
                conditions = {
                    {
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires Main Hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 3,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_nature_bloodlust.blp",
                id = "05yeh7qb",
                cooldownChannel = 1,
                learnMode = "always_learned",
                learnLevel = 40,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Bloodthirst",
                range = 0,
                resourceCosts = {
                    {
                        amount = 15,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Fury",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Physical damage to an enemy. Heal yourself for {HEAL_1} health.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        },
                        {
                            applyMode = "heal_range",
                            componentIndex = 2,
                            key = "HEAL_1",
                            tokenType = "spell_heal_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_melee_hit",
                    "on_critical_hit"
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
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.182,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1.5,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0.52,
                            weaponDamageMode = "main_hand"
                        },
                        key = "9e1eae8d",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "last_melee_attacker"
                        }
                    }
                },
                conditions = {
                    {
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "mainhand",
                        tooltipTextOverride = "Requires Main Hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_warrior_revenge.blp",
                id = "mn1ltzeo",
                cooldownChannel = 2,
                learnMode = "always_learned",
                learnLevel = 14,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Revenge",
                range = 0,
                resourceCosts = {
                    {
                        amount = 5,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Protection",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Physical damage to the last enemy to attack you with a melee attack. Generates a moderate amount of threat.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        }
                    },
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "7bbb4cb9:hfmmcsmr",
                            basePower = 0,
                            duration = 10,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "cd64fcf4",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "all_allies"
                        }
                    }
                },
                conditions = {},
                cooldown = 1,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_warrior_battleshout.blp",
                id = "9gh28pe5",
                cooldownChannel = 3,
                learnMode = "always_learned",
                learnLevel = 1,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Battle Shout",
                range = 0,
                resourceCosts = {
                    {
                        amount = 10,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Fury",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "7bbb4cb9:hfmmcsmr",
                            datasetId = "7bbb4cb9",
                            descriptionText = "Increases Melee Attack Power by 10%.",
                            duration = 10,
                            icon = "interface/icons/ability_warrior_battleshout.blp",
                            nameText = "Battle Shout",
                            powerLevel = 0,
                            spellDatasetId = "7bbb4cb9",
                            stacks = 1,
                            targetContext = {
                                object = "all allies",
                                possessive = "all allies'",
                                reflexive = "themselves",
                                subject = "all allies"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Apply Battle Shout to all allies for 10 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "7bbb4cb9:v65x2cz3",
                            basePower = 0,
                            duration = 10,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "cd64fcf4",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "all_allies"
                        }
                    }
                },
                conditions = {},
                cooldown = 1,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_warrior_rallyingcry.blp",
                id = "c6j8zcqx",
                cooldownChannel = 3,
                learnMode = "always_learned",
                learnLevel = 54,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Commanding Shout",
                range = 0,
                resourceCosts = {
                    {
                        amount = 10,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Arms",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "7bbb4cb9:v65x2cz3",
                            datasetId = "7bbb4cb9",
                            descriptionText = "Increases Stamina by 5%.",
                            duration = 10,
                            icon = "interface/icons/ability_warrior_rallyingcry.blp",
                            nameText = "Commanding Shout",
                            powerLevel = 0,
                            spellDatasetId = "7bbb4cb9",
                            stacks = 1,
                            targetContext = {
                                object = "all allies",
                                possessive = "all allies'",
                                reflexive = "themselves",
                                subject = "all allies"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Apply Commanding Shout to all allies for 10 turns.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            auraRef = "7bbb4cb9:mjmnbas1",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "c7610585",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 0,
                            minTargets = 0,
                            requiresTarget = false,
                            targetDisposition = "ally",
                            type = "caster"
                        }
                    }
                },
                conditions = {
                    {
                        invert = false,
                        showOnTooltip = true,
                        slotKey = "offhand",
                        tooltipTextOverride = "Requires Shield",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 10,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_warrior_shieldwall.blp",
                id = "tkb4huco",
                cooldownChannel = 5,
                learnMode = "always_learned",
                learnLevel = 28,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Shield Wall",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = false,
                spellbookCategory = "Protection",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "7bbb4cb9:mjmnbas1",
                            datasetId = "7bbb4cb9",
                            descriptionText = "Increases Damage Reduction by 40%.",
                            duration = 1,
                            icon = "interface/icons/ability_warrior_shieldwall.blp",
                            nameText = "Shield Wall",
                            powerLevel = 0,
                            spellDatasetId = "7bbb4cb9",
                            stacks = 1,
                            targetContext = {
                                object = "you",
                                possessive = "your",
                                reflexive = "yourself",
                                subject = "you"
                            },
                            tokens = {}
                        }
                    },
                    mainText = "Apply Shield Wall to yourself for 1 turn.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            targetEvents = {},
                            type = "revert"
                        },
                        key = "85653990",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = true,
                            maxTargets = 1,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "ally",
                            type = "single"
                        }
                    }
                },
                conditions = {},
                cooldown = 6,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_warrior_victoryrush.blp",
                id = "0ttffa47",
                cooldownChannel = 5,
                learnMode = "always_learned",
                learnLevel = 56,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Intervene",
                range = 0,
                resourceCosts = {
                    {
                        amount = 5,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:e2tfklq7"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Protection",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Reverse the effects of the last reversible spell received by an ally this turn.",
                    tokens = {},
                    version = 1
                },
                totalTicks = 0,
                useCooldownCharges = false
            }
        },
        stats = {},
        traits = {
            {
                automaticAuras = {},
                category = "Arms",
                conditions = {},
                description = "Increases your damage against Giants by 5%.",
                events = {},
                icon = "interface/icons/ability_warrior_savageblow.blp",
                id = "gntslayr",
                isEnvironmental = false,
                name = "Giantslayer",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:x1lxi8cf",
                        value = 5
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Protection",
                conditions = {
                    {
                        invert = true,
                        showOnTooltip = true,
                        tooltipTextOverride = "Does not have Battle Stance",
                        traitRef = "7bbb4cb9:r73vv899",
                        type = "trait_requirement",
                        unit = "caster"
                    },
                    {
                        invert = true,
                        showOnTooltip = true,
                        tooltipTextOverride = "Does not have Berserker Stance",
                        traitRef = "7bbb4cb9:0ncx0gfs",
                        type = "trait_requirement",
                        unit = "caster"
                    }
                },
                description = "",
                events = {
                    {
                        combatEventId = "on_auto_attack_taken",
                        effects = {
                            {
                                amount = 2,
                                amountMode = "flat",
                                resourceRef = "f82db71a:e2tfklq7",
                                type = "resource"
                            }
                        },
                        triggerTarget = "aura_caster"
                    }
                },
                icon = "interface/icons/ability_warrior_defensivestance.blp",
                id = "duukevtq",
                isEnvironmental = false,
                name = "Defensive Stance",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:j8n012e6",
                        value = 80
                    },
                    {
                        statRef = "f82db71a:pu05li08",
                        value = 10
                    },
                    {
                        statRef = "f82db71a:gj9wxb0x",
                        value = -10
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Fury",
                conditions = {},
                description = "",
                events = {
                    {
                        combatEventId = "on_critical_hit",
                        effects = {
                            {
                                auraRef = "7bbb4cb9:12yk1r4y",
                                basePower = 0,
                                duration = 2,
                                stacks = 1,
                                type = "apply_aura"
                            }
                        },
                        triggerTarget = "aura_caster"
                    }
                },
                icon = "interface/icons/spell_shadow_unholyfrenzy.blp",
                id = "a8x4ee34",
                isEnvironmental = false,
                name = "Enrage",
                skillBonuses = {},
                statBonuses = {},
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "",
                conditions = {
                    {
                        invert = true,
                        showOnTooltip = true,
                        tooltipTextOverride = "Does not have Defensive Stance",
                        traitRef = "7bbb4cb9:duukevtq",
                        type = "trait_requirement",
                        unit = "caster"
                    },
                    {
                        invert = true,
                        showOnTooltip = true,
                        tooltipTextOverride = "Does not have Berserker Stance",
                        traitRef = "7bbb4cb9:0ncx0gfs",
                        type = "trait_requirement",
                        unit = "caster"
                    }
                },
                description = "",
                events = {
                    {
                        combatEventId = "on_auto_attack_hit",
                        effects = {
                            {
                                amount = 2,
                                amountMode = "flat",
                                resourceRef = "f82db71a:e2tfklq7",
                                type = "resource"
                            }
                        },
                        triggerTarget = "aura_caster"
                    },
                    {
                        combatEventId = "on_critical_hit",
                        effects = {
                            {
                                amount = 3,
                                amountMode = "flat",
                                resourceRef = "f82db71a:e2tfklq7",
                                type = "resource"
                            }
                        },
                        triggerTarget = "aura_caster"
                    }
                },
                icon = "interface/icons/ability_warrior_offensivestance.blp",
                id = "r73vv899",
                isEnvironmental = false,
                name = "Battle Stance",
                skillBonuses = {},
                statBonuses = {},
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Fury",
                conditions = {
                    {
                        invert = true,
                        showOnTooltip = true,
                        tooltipTextOverride = "Does not have Battle Stance",
                        traitRef = "7bbb4cb9:r73vv899",
                        type = "trait_requirement",
                        unit = "caster"
                    },
                    {
                        invert = true,
                        showOnTooltip = true,
                        tooltipTextOverride = "Does not have Defensive Stance",
                        traitRef = "7bbb4cb9:duukevtq",
                        type = "trait_requirement",
                        unit = "caster"
                    }
                },
                description = "",
                events = {
                    {
                        combatEventId = "on_critical_hit",
                        effects = {
                            {
                                amount = 8,
                                amountMode = "flat",
                                resourceRef = "f82db71a:e2tfklq7",
                                type = "resource"
                            }
                        },
                        triggerTarget = "aura_caster"
                    }
                },
                icon = "interface/icons/ability_racial_avatar.blp",
                id = "0ncx0gfs",
                isEnvironmental = false,
                name = "Berserker Stance",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:jslmczbi",
                        value = 3
                    },
                    {
                        statRef = "f82db71a:pu05li08",
                        value = -10
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Arms",
                conditions = {},
                description = "",
                events = {
                    {
                        chance = 100,
                        combatEventId = "on_critical_hit",
                        effects = {
                            {
                                auraRef = "7bbb4cb9:q2mqgpzk",
                                basePower = 0,
                                duration = 3,
                                stacks = 1,
                                type = "apply_aura"
                            }
                        },
                        triggerTarget = "event_other"
                    }
                },
                icon = "interface/icons/ability_backstab.blp",
                id = "0yud4l94",
                isEnvironmental = false,
                name = "Deep Wounds",
                skillBonuses = {},
                statBonuses = {},
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Protection",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_holy_devotion.blp",
                id = "sxq460qa",
                isEnvironmental = false,
                name = "Toughness",
                skillBonuses = {},
                statBonuses = {
                    {
                        operation = "percent",
                        statRef = "f82db71a:v42albuv",
                        value = 10
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Fury",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/ability_rogue_eviscerate.blp",
                id = "cruelty3",
                isEnvironmental = false,
                name = "Cruelty",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:jslmczbi",
                        value = 3
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Protection",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_nature_mirrorimage.blp",
                id = "antcwar1",
                isEnvironmental = false,
                name = "Anticipation",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:0wyp78x9",
                        value = 10
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Protection",
                conditions = {
                    {
                        invert = false,
                        requiresShield = true,
                        showOnTooltip = true,
                        slotKey = "offhand",
                        tooltipTextOverride = "Requires a shield equipped in the off-hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                description = "",
                events = {},
                icon = "interface/icons/inv_shield_06.blp",
                id = "shldspc1",
                isEnvironmental = false,
                name = "Shield Specialisation",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:p8syz5ba",
                        value = 5
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "",
                conditions = {},
                description = "",
                events = {
                    {
                        combatEventId = "on_auto_attack_hit",
                        effects = {
                            {
                                amount = 10,
                                amountMode = "flat",
                                resourceRef = "f82db71a:e2tfklq7",
                                type = "resource"
                            }
                        },
                        triggerTarget = "aura_caster"
                    }
                },
                icon = "interface/icons/ability_warrior_innerrage.blp",
                id = "momntm10",
                isEnvironmental = false,
                name = "Momentum",
                skillBonuses = {},
                statBonuses = {},
                unlockLevel = 1
            }
        },
        units = {},
        weaponTypes = {}
    },
})
