local _, Addon = ...

Addon.Data.DefaultDatasets:Register({
    version = 17,
    dataset = {
        achievements = {},
        auras = {
            {
                description = "",
                duration = 3,
                effects = {
                    {
                        baseAmount = 25,
                        operation = "flat",
                        statRef = "f82db71a:jslmczbi",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/ability_rogue_slicedice.blp",
                id = "iectp9f1",
                maxStacks = 1,
                name = "Slice and Dice",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Melee Crit. Chance by 25%.",
                    bodyTokens = {},
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
                        amount = 20,
                        amountMode = "flat",
                        resourceRef = "f82db71a:c3gaf7dd",
                        statScaling = {},
                        type = "resource"
                    }
                },
                events = {},
                icon = "interface/icons/spell_shadow_shadowworddominate.blp",
                id = "8o3v4oj0",
                maxStacks = 1,
                name = "Adrenaline Rush",
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
                duration = 1,
                effects = {
                    {
                        baseAmount = 75,
                        operation = "flat",
                        statRef = "f82db71a:o6113cir",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_shadow_shadowward.blp",
                id = "rdh6r6o2",
                maxStacks = 1,
                name = "Evasion",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Dodge Chance by 75%.",
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
                        baseAmount = 15,
                        operation = "flat",
                        statRef = "f82db71a:o6113cir",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_shadow_curse.blp",
                id = "duvzheeq",
                maxStacks = 1,
                name = "Ghostly Strike",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Dodge Chance by 15%.",
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
                        baseAmount = -2,
                        operation = "flat",
                        statRef = "f82db71a:pu05li08",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/spell_shadow_lifedrain.blp",
                id = "8phuvfx1",
                maxStacks = 5,
                name = "Hemorrhage",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Reduces Damage Reduction by 2%.",
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
                        amountMode = "flat",
                        baseDamage = 38.25,
                        damageSchoolRefs = {
                            "f82db71a:v1azo4j6"
                        },
                        statScaling = {
                            {
                                coefficient = 0.669,
                                statRef = "f82db71a:u7b49vs9"
                            }
                        },
                        type = "damage"
                    }
                },
                events = {},
                icon = "interface/icons/ability_rogue_rupture.blp",
                id = "631lrfbc",
                maxStacks = 1,
                name = "Rupture",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = false
            },
            {
                description = "",
                duration = 2,
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 57.5,
                        damageSchoolRefs = {
                            "f82db71a:v1azo4j6"
                        },
                        statScaling = {
                            {
                                coefficient = 0.403,
                                statRef = "f82db71a:u7b49vs9"
                            }
                        },
                        type = "damage"
                    }
                },
                events = {},
                icon = "interface/icons/ability_rogue_garrote.blp",
                id = "72luk1ge",
                maxStacks = 1,
                name = "Garrote",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = false
            },
            {
                description = "",
                duration = 1,
                effects = {
                    {
                        cancelOnDamage = true,
                        forceAutoHitAgainstTarget = true,
                        movementRangeOverride = 0,
                        preventCasting = true,
                        statScaling = {},
                        type = "control"
                    }
                },
                events = {},
                icon = "interface/icons/ability_gouge.blp",
                id = "j39oh8sx",
                maxStacks = 1,
                name = "Gouge",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Breaks when the affected unit takes damage. Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
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
                        cancelOnDamage = false,
                        forceAutoHitAgainstTarget = true,
                        movementRangeOverride = 0,
                        preventCasting = true,
                        statScaling = {},
                        type = "control"
                    }
                },
                events = {},
                icon = "interface/icons/ability_rogue_kidneyshot.blp",
                id = "3da83m39",
                maxStacks = 1,
                name = "Kidney Shot",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
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
                icon = "interface/icons/spell_ice_lament.blp",
                id = "o6g2sn1c",
                maxStacks = 1,
                name = "Cold Blood",
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
                duration = 2,
                effects = {
                    {
                        baseAmount = -20,
                        operation = "flat",
                        statRef = "f82db71a:ok80ohz3",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/inv_misc_herb_16.blp",
                id = "hjsfi9pe",
                maxStacks = 1,
                name = "Wound Poison",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = false
            }
        },
        authorName = "Ortellus-ArgentDawn",
        classes = {
            {
                description = "For Rogues, the only code is the contract, and their honor is purchased in gold. Free from the constraints of a conscience, these mercenaries rely on brutal and efficient tactics. Lethal assassins and masters of stealth, they will approach their marks from behind, piercing a vital organ and vanishing into the shadows before the victim hits the ground.",
                icon = "interface/icons/classicon_rogue.blp",
                id = "ta9uh9xw",
                name = "Rogue",
                armorWeights = {
                    "leather",
                },
                weaponTypeRefs = {
                    "f82db71a:z6nh3znw",
                    "f82db71a:i4pivdig",
                    "f82db71a:9ni3vfas",
                    "f82db71a:y0dnlo8g",
                    "f82db71a:l3ce0puc",
                    "f82db71a:j2gceby4",
                    "f82db71a:anoo8qfp",
                    "f82db71a:gjz2331m",
                    "f82db71a:we5ul4ne",
                },
                resourceProgressions = {
                    {
                        initialValue = 25,
                        perLevelValue = 25.39,
                        resourceRef = "f82db71a:q2ktkztt"
                    }
                },
                skillBonuses = {},
                statProgressions = {
                    {
                        initialValue = 1,
                        perLevelValue = 1,
                        statRef = "f82db71a:zfqm8dxp"
                    },
                    {
                        initialValue = 3,
                        perLevelValue = 1.81,
                        statRef = "f82db71a:xqz0daz2"
                    },
                    {
                        initialValue = 1,
                        perLevelValue = 0.92,
                        statRef = "f82db71a:ygjno50i"
                    },
                    {
                        initialValue = 0,
                        perLevelValue = 0.25,
                        statRef = "f82db71a:75y3a8ib"
                    },
                    {
                        initialValue = 0,
                        perLevelValue = 0.51,
                        statRef = "f82db71a:kec9rhli"
                    }
                },
                passiveTraitRefs = {
                    "23d5dce2:murderxx"
                },
                talentTraitRefs = {
                    "23d5dce2:z9yfqvhy",
                    "23d5dce2:58pob6kr",
                    "23d5dce2:malice05",
                    "23d5dce2:sealfate",
                    "23d5dce2:lghtref5",
                    "23d5dce2:deflect5",
                    "23d5dce2:weapexp6",
                    "23d5dce2:mstdecpt",
                    "23d5dce2:deadly10",
                    "23d5dce2:hghtsens"
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
        id = "23d5dce2",
        interactions = {},
        itemSlots = {},
        items = {},
        loot = {},
        mounts = {},
        name = "Rogue",
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
                        key = "0ce4d5de",
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
                            amount = 1,
                            amountMode = "flat",
                            resourceRef = "f82db71a:1h7yfxff",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "6900cd49",
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
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_shadow_ritualofsacrifice.blp",
                id = "g9o4t7uj",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Sinister Strike",
                range = 0,
                resourceCosts = {
                    {
                        amount = 30,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:c3gaf7dd"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Combat",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Physical damage to an enemy. Restore {RESOURCE_AMOUNT_1} to yourself.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        },
                        {
                            applyMode = "resource_gain_amount",
                            componentIndex = 2,
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
                canTargetHiddenUnits = false,
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
                            baseDamage = 265.359,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 1.238,
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
                            weaponDamageCoefficient = 3.538,
                            weaponDamageMode = "main_hand"
                        },
                        key = "0ce4d5de",
                        target = {
                            allowDeadTargets = false,
                            allowHiddenTargets = false,
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
                            amount = 2,
                            amountMode = "flat",
                            resourceRef = "f82db71a:1h7yfxff",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "6900cd49",
                        target = {
                            allowDeadTargets = false,
                            allowHiddenTargets = false,
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
                        tooltipTextOverride = "Requires Dagger in Main Hand",
                        type = "weapon_type",
                        weaponTypeRefs = {
                            "f82db71a:y0dnlo8g"
                        }
                    },
                    {
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Require Stealth",
                        type = "hidden",
                        unit = "caster"
                    }
                },
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                doesNotRevealCaster = false,
                icon = "interface/icons/ability_rogue_ambush.blp",
                id = "pfskjkhi",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Ambush",
                range = 0,
                resourceCosts = {
                    {
                        amount = 60,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:c3gaf7dd"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Subtlety",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Physical damage to an enemy. Restore {RESOURCE_AMOUNT_1} to yourself.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        },
                        {
                            applyMode = "resource_gain_amount",
                            componentIndex = 2,
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
                canTargetHiddenUnits = false,
                castTime = 0,
                casterEvents = {},
                charges = 0,
                components = {
                    {
                        castPhase = "on_cast_end",
                        castingGroup = "default",
                        effect = {
                            targetEvents = {},
                            type = "hide"
                        },
                        key = "stealthhide",
                        target = {
                            allowDeadTargets = false,
                            allowHiddenTargets = false,
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
                doesNotRevealCaster = true,
                icon = "interface/icons/ability_stealth.blp",
                id = "stealth01",
                cooldownChannel = 3,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Stealth",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = false,
                spellbookCategory = "Subtlety",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Hide yourself.",
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
                            baseDamage = 86.25,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.403,
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
                            weaponDamageCoefficient = 1.15,
                            weaponDamageMode = "main_hand"
                        },
                        key = "0ce4d5de",
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
                            amount = 2,
                            amountMode = "flat",
                            resourceRef = "f82db71a:1h7yfxff",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "6900cd49",
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
                        tooltipTextOverride = "Requires Dagger in Main Hand",
                        type = "weapon_type",
                        weaponTypeRefs = {
                            "f82db71a:y0dnlo8g"
                        }
                    }
                },
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_backstab.blp",
                id = "3yvu5lwf",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Backstab",
                range = 0,
                resourceCosts = {
                    {
                        amount = 50,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:c3gaf7dd"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Assassination",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Physical damage to an enemy. Restore {RESOURCE_AMOUNT_1} to yourself.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        },
                        {
                            applyMode = "resource_gain_amount",
                            componentIndex = 2,
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
                            baseDamage = 360,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 1.26,
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
                            weaponDamageCoefficient = 0,
                            weaponDamageMode = "none"
                        },
                        key = "0ce4d5de",
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
                icon = "interface/icons/ability_rogue_eviscerate.blp",
                id = "am7ew5wl",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Eviscerate",
                range = 0,
                resourceCosts = {
                    {
                        amount = 15,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:c3gaf7dd"
                    },
                    {
                        amount = 5,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:1h7yfxff"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Combat",
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
                            applyAura = false,
                            auraStacks = 1,
                            baseDamage = 86.25,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.403,
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
                            weaponDamageCoefficient = 1.15,
                            weaponDamageMode = "both"
                        },
                        key = "0ce4d5de",
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
                            amount = 2,
                            amountMode = "flat",
                            resourceRef = "f82db71a:1h7yfxff",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "6900cd49",
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
                        tooltipTextOverride = "Requires Dagger in Main Hand",
                        type = "weapon_type",
                        weaponTypeRefs = {
                            "f82db71a:y0dnlo8g"
                        }
                    }
                },
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_rogue_shadowstrikes.blp",
                id = "7scy4qhi",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Mutilate",
                range = 0,
                resourceCosts = {
                    {
                        amount = 50,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:c3gaf7dd"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Assassination",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Physical damage to an enemy. Restore {RESOURCE_AMOUNT_1} to yourself.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        },
                        {
                            applyMode = "resource_gain_amount",
                            componentIndex = 2,
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
                            auraRef = "23d5dce2:rdh6r6o2",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "6b517a36",
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
                icon = "interface/icons/spell_shadow_shadowward.blp",
                id = "kbifnqpj",
                cooldownChannel = 5,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Evasion",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = false,
                spellbookCategory = "Subtlety",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "23d5dce2:rdh6r6o2",
                            datasetId = "23d5dce2",
                            descriptionText = "Increases Dodge Chance by 75%.",
                            duration = 1,
                            icon = "interface/icons/spell_shadow_shadowward.blp",
                            nameText = "Evasion",
                            powerLevel = 0,
                            spellDatasetId = "23d5dce2",
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
                    mainText = "Apply Evasion to yourself for 1 turn.",
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
                            auraRef = "23d5dce2:8o3v4oj0",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "6b517a36",
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
                icon = "interface/icons/spell_shadow_shadowworddominate.blp",
                id = "wf9orqz9",
                cooldownChannel = 3,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Adrenaline Rush",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = false,
                spellbookCategory = "Combat",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "23d5dce2:8o3v4oj0",
                            datasetId = "23d5dce2",
                            descriptionText = "Restores {AURA_RESOURCE_GAIN_1} each turn.",
                            duration = 1,
                            icon = "interface/icons/spell_shadow_shadowworddominate.blp",
                            nameText = "Adrenaline Rush",
                            powerLevel = 0,
                            spellDatasetId = "23d5dce2",
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
                    mainText = "Apply Adrenaline Rush to yourself for 1 turn.",
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
                            auraRef = "23d5dce2:iectp9f1",
                            basePower = 0,
                            duration = 3,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "0ce4d5de",
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
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_rogue_slicedice.blp",
                id = "gp51edzy",
                cooldownChannel = 3,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Slice and Dice",
                range = 0,
                resourceCosts = {
                    {
                        amount = 15,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:c3gaf7dd"
                    },
                    {
                        amount = 5,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:1h7yfxff"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Assassination",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "23d5dce2:iectp9f1",
                            datasetId = "23d5dce2",
                            descriptionText = "Increases Melee Crit. Chance by 25%.",
                            duration = 3,
                            icon = "interface/icons/ability_rogue_slicedice.blp",
                            nameText = "Slice and Dice",
                            powerLevel = 0,
                            spellDatasetId = "23d5dce2",
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
                    mainText = "Apply Slice and Dice to yourself for 3 turns.",
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
                            baseDamage = 73.313,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.342,
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
                            weaponDamageCoefficient = 0.978,
                            weaponDamageMode = "main_hand"
                        },
                        key = "0ce4d5de",
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
                            amount = 1,
                            amountMode = "flat",
                            resourceRef = "f82db71a:1h7yfxff",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "6900cd49",
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
                            auraRef = "23d5dce2:duvzheeq",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "6559e76b",
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
                cooldown = 2,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_shadow_curse.blp",
                id = "i2uuda23",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Ghostly Strike",
                range = 0,
                resourceCosts = {
                    {
                        amount = 30,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:c3gaf7dd"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Subtlety",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "23d5dce2:duvzheeq",
                            datasetId = "23d5dce2",
                            descriptionText = "Increases Dodge Chance by 15%.",
                            duration = 1,
                            icon = "interface/icons/spell_shadow_curse.blp",
                            nameText = "Ghostly Strike",
                            powerLevel = 0,
                            spellDatasetId = "23d5dce2",
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
                    mainText = "Deal {DAMAGE_1} Physical damage to an enemy. Restore {RESOURCE_AMOUNT_1} to yourself. Apply Ghostly Strike to yourself for 1 turn.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        },
                        {
                            applyMode = "resource_gain_amount",
                            componentIndex = 2,
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
                            auraRef = "23d5dce2:8phuvfx1",
                            auraStacks = 1,
                            baseDamage = 63.75,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.298,
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
                            weaponDamageCoefficient = 0.85,
                            weaponDamageMode = "main_hand"
                        },
                        key = "0ce4d5de",
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
                            amount = 1,
                            amountMode = "flat",
                            resourceRef = "f82db71a:1h7yfxff",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "6900cd49",
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
                cooldown = 1,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_shadow_lifedrain.blp",
                id = "7x7itakn",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Hemmorhage",
                range = 0,
                resourceCosts = {
                    {
                        amount = 30,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:c3gaf7dd"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Subtlety",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "23d5dce2:8phuvfx1",
                            datasetId = "23d5dce2",
                            descriptionText = "Reduces Damage Reduction by 2%. Applies {AURA_APPLIED_STACKS_1} stacks. Stacks up to {AURA_MAX_STACKS_1} times.",
                            icon = "interface/icons/spell_shadow_lifedrain.blp",
                            nameText = "Hemorrhage",
                            powerLevel = 0,
                            spellDatasetId = "23d5dce2",
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
                    mainText = "Deal {DAMAGE_1} Physical damage to an enemy and apply Hemorrhage for 5 turns. Restore {RESOURCE_AMOUNT_1} to yourself.",
                    tokens = {
                        {
                            applyMode = "damage_range",
                            componentIndex = 1,
                            key = "DAMAGE_1",
                            tokenType = "spell_damage_range"
                        },
                        {
                            applyMode = "resource_gain_amount",
                            componentIndex = 2,
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
                            auraRef = "23d5dce2:631lrfbc",
                            basePower = 0,
                            duration = 5,
                            stacks = 1,
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            type = "apply_aura"
                        },
                        key = "0ce4d5de",
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
                icon = "interface/icons/ability_rogue_rupture.blp",
                id = "ugc0mlrz",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Rupture",
                range = 0,
                resourceCosts = {
                    {
                        amount = 15,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:c3gaf7dd"
                    },
                    {
                        amount = 5,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:1h7yfxff"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Assassination",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "23d5dce2:631lrfbc",
                            datasetId = "23d5dce2",
                            descriptionText = "Deals {AURA_DAMAGE_1} Physical damage each turn.",
                            duration = 5,
                            icon = "interface/icons/ability_rogue_rupture.blp",
                            nameText = "Rupture",
                            powerLevel = 0,
                            spellDatasetId = "23d5dce2",
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
                    mainText = "Apply Rupture to an enemy for 5 turns.",
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
                            auraRef = "23d5dce2:72luk1ge",
                            basePower = 0,
                            duration = 2,
                            stacks = 1,
                            targetEvents = {
                                "on_melee_taken",
                                "on_critical_hit_taken"
                            },
                            type = "apply_aura"
                        },
                        key = "0ce4d5de",
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
                            amount = 2,
                            amountMode = "flat",
                            resourceRef = "f82db71a:1h7yfxff",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "563c30bc",
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
                    },
                    {
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Require Stealth",
                        type = "hidden",
                        unit = "caster"
                    }
                },
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_rogue_garrote.blp",
                id = "v0mihgpd",
                cooldownChannel = 1,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Garrote",
                range = 0,
                resourceCosts = {
                    {
                        amount = 50,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:c3gaf7dd"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Assassination",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "23d5dce2:72luk1ge",
                            datasetId = "23d5dce2",
                            descriptionText = "Deals {AURA_DAMAGE_1} Physical damage each turn.",
                            duration = 2,
                            icon = "interface/icons/ability_rogue_garrote.blp",
                            nameText = "Garrote",
                            powerLevel = 0,
                            spellDatasetId = "23d5dce2",
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
                    mainText = "Apply Garrote to an enemy for 2 turns. Restore {RESOURCE_AMOUNT_1} to yourself.",
                    tokens = {
                        {
                            applyMode = "resource_gain_amount",
                            componentIndex = 2,
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
                            targetEvents = {},
                            type = "interrupt"
                        },
                        key = "b88a1052",
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
                cooldown = 10,
                cooldownGroup = "interrupt",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_kick.blp",
                id = "300h0gls",
                cooldownChannel = 5,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Kick",
                range = 0,
                resourceCosts = {
                    {
                        amount = 5,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:c3gaf7dd"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Combat",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Interrupt an enemy's spellcasting.",
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
                            auraRef = "23d5dce2:j39oh8sx",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "b88a1052",
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
                            amount = 1,
                            amountMode = "flat",
                            resourceRef = "f82db71a:1h7yfxff",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "bddd0d31",
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
                cooldown = 5,
                cooldownGroup = "incapacitate",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_gouge.blp",
                id = "i8x4n8kh",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Gouge",
                range = 0,
                resourceCosts = {
                    {
                        amount = 40,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:c3gaf7dd"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Combat",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "23d5dce2:j39oh8sx",
                            datasetId = "23d5dce2",
                            descriptionText = "Breaks when the affected unit takes damage. Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                            duration = 1,
                            icon = "interface/icons/ability_gouge.blp",
                            nameText = "Gouge",
                            powerLevel = 0,
                            spellDatasetId = "23d5dce2",
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
                    mainText = "Apply Gouge to an enemy for 1 turn. Restore {RESOURCE_AMOUNT_1} to yourself.",
                    tokens = {
                        {
                            applyMode = "resource_gain_amount",
                            componentIndex = 2,
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
                            auraRef = "23d5dce2:3da83m39",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "b88a1052",
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
                cooldown = 1,
                cooldownGroup = "stun",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_rogue_kidneyshot.blp",
                id = "yql2eonk",
                cooldownChannel = 2,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Kidney Shot",
                range = 0,
                resourceCosts = {
                    {
                        amount = 15,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:c3gaf7dd"
                    },
                    {
                        amount = 5,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:1h7yfxff"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "Assassination",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "23d5dce2:3da83m39",
                            datasetId = "23d5dce2",
                            descriptionText = "Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                            duration = 1,
                            icon = "interface/icons/ability_rogue_kidneyshot.blp",
                            nameText = "Kidney Shot",
                            powerLevel = 0,
                            spellDatasetId = "23d5dce2",
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
                    mainText = "Apply Kidney Shot to an enemy for 1 turn.",
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
                            auraRef = "23d5dce2:o6g2sn1c",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "5be298f5",
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
                icon = "interface/icons/spell_ice_lament.blp",
                id = "t7gns8bg",
                cooldownChannel = 3,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Cold Blood",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = false,
                spellbookCategory = "Assassination",
                tags = {},
                tooltipTemplate = false,
                totalTicks = 0,
                useCooldownCharges = false
            }
        },
        stats = {},
        traits = {
            {
                automaticAuras = {},
                category = "",
                conditions = {},
                description = "Increases your damage against Humanoids by 5%.",
                events = {},
                icon = "interface/icons/ability_rogue_murderspree.blp",
                id = "murderxx",
                isEnvironmental = false,
                name = "Murder",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:bj6h5ikw",
                        value = 5
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "",
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
                description = "",
                events = {
                    {
                        chance = 100,
                        combatEventId = "on_auto_attack_hit",
                        effects = {
                            {
                                amountMode = "flat",
                                baseDamage = 55.25,
                                damageSchoolRefs = {
                                    "f82db71a:qtr10qyj"
                                },
                                statScaling = {
                                    {
                                        coefficient = 0.193,
                                        statRef = "f82db71a:u7b49vs9"
                                    }
                                },
                                type = "damage"
                            }
                        },
                        triggerTarget = "event_other"
                    }
                },
                icon = "interface/icons/ability_poisonarrow.blp",
                id = "z9yfqvhy",
                isEnvironmental = false,
                name = "Instant Poison",
                skillBonuses = {},
                statBonuses = {},
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "",
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
                description = "",
                events = {
                    {
                        chance = 100,
                        combatEventId = "on_auto_attack_hit",
                        effects = {
                            {
                                auraRef = "23d5dce2:hjsfi9pe",
                                basePower = 0,
                                duration = 2,
                                stacks = 1,
                                type = "apply_aura"
                            }
                        },
                        triggerTarget = "event_other"
                    }
                },
                icon = "interface/icons/inv_misc_herb_16.blp",
                id = "58pob6kr",
                isEnvironmental = false,
                name = "Wound Poison",
                skillBonuses = {},
                statBonuses = {},
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Assassination",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/ability_racial_bloodrage.blp",
                id = "malice05",
                isEnvironmental = false,
                name = "Malice",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:jslmczbi",
                        value = 5
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Assassination",
                conditions = {},
                description = "",
                events = {
                    {
                        chance = 100,
                        combatEventId = "on_critical_hit",
                        effects = {
                            {
                                amount = 1,
                                amountMode = "flat",
                                resourceRef = "f82db71a:1h7yfxff",
                                type = "resource"
                            }
                        },
                        triggerTarget = "aura_caster"
                    }
                },
                icon = "interface/icons/spell_shadow_chilltouch.blp",
                id = "sealfate",
                isEnvironmental = false,
                name = "Seal Fate",
                skillBonuses = {},
                statBonuses = {},
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Combat",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_nature_invisibilty.blp",
                id = "lghtref5",
                isEnvironmental = false,
                name = "Lightning Reflexes",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:o6113cir",
                        value = 5
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Combat",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/ability_parry.blp",
                id = "deflect5",
                isEnvironmental = false,
                name = "Deflection",
                skillBonuses = {},
                statBonuses = {
                    {
                        statRef = "f82db71a:tcn0s8kx",
                        value = 5
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Combat",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_holy_blessingofstrength.blp",
                id = "weapexp6",
                isEnvironmental = false,
                name = "Weapon Expertise",
                skillBonuses = {
                    {
                        skillRef = "f82db71a:3z6vlkhn",
                        value = 6
                    },
                    {
                        skillRef = "f82db71a:tbvqz1rq",
                        value = 6
                    },
                    {
                        skillRef = "f82db71a:t5wlibfx",
                        value = 6
                    }
                },
                statBonuses = {},
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Subtlety",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/spell_shadow_charm.blp",
                id = "mstdecpt",
                isEnvironmental = false,
                name = "Master of Deception",
                skillBonuses = {
                    {
                        skillRef = "f82db71a:muuwon1r",
                        value = 5
                    }
                },
                statBonuses = {},
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Subtlety",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/inv_weapon_crossbow_11.blp",
                id = "deadly10",
                isEnvironmental = false,
                name = "Deadliness",
                skillBonuses = {},
                statBonuses = {
                    {
                        operation = "percent",
                        statRef = "f82db71a:u7b49vs9",
                        value = 10
                    }
                },
                unlockLevel = 1
            },
            {
                automaticAuras = {},
                category = "Subtlety",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/ability_ambush.blp",
                id = "hghtsens",
                isEnvironmental = false,
                name = "Heightened Senses",
                skillBonuses = {
                    {
                        skillRef = "f82db71a:b0sh5zo7",
                        value = 5
                    }
                },
                statBonuses = {
                    {
                        statRef = "f82db71a:zs1nbz13",
                        value = 3
                    }
                },
                unlockLevel = 1
            }
        },
        units = {},
        weaponTypes = {}
    },
})
