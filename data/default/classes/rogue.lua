local _, Addon = ...

Addon.Data.DefaultDatasets:Register({
    version = 32,
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
                        baseDamage = 20.8,
                        damageSchoolRefs = {
                            "f82db71a:v1azo4j6"
                        },
                        statScaling = {
                            {
                                coefficient = 0.2,
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
                        baseDamage = 31.7688,
                        damageSchoolRefs = {
                            "f82db71a:v1azo4j6"
                        },
                        statScaling = {
                            {
                                coefficient = 0.2224,
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
            },
            {
                description = "",
                duration = 5,
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 4.16,
                        damageSchoolRefs = {
                            "f82db71a:qtr10qyj"
                        },
                        statScaling = {
                            {
                                coefficient = 0.03,
                                statRef = "f82db71a:u7b49vs9"
                            }
                        },
                        type = "damage"
                    }
                },
                events = {},
                icon = "interface/icons/ability_rogue_dualweild.blp",
                id = "dlypsn01",
                maxStacks = 5,
                name = "Deadly Poison",
                stackBehavior = "refresh_duration",
                tags = {
                    "poison"
                },
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Deals {AURA_DAMAGE_1} Nature damage each turn.",
                    bodyTokens = {
                        {
                            applyMode = "damage_amount",
                            baseField = "baseDamage",
                            effectIndex = 1,
                            key = "AURA_DAMAGE_1",
                            tokenType = "aura_amount"
                        }
                    },
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
                duration = 3,
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
                icon = "interface/icons/ability_sap.blp",
                id = "sapaura1",
                maxStacks = 1,
                name = "Sap",
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
                        cancelOnDamage = true,
                        forceAutoHitAgainstTarget = true,
                        movementRangeOverride = 0,
                        preventCasting = true,
                        statScaling = {},
                        type = "control"
                    }
                },
                events = {},
                icon = "interface/icons/spell_shadow_mindsteal.blp",
                id = "blndaura1",
                maxStacks = 1,
                name = "Blind",
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
                duration = 2,
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
                icon = "interface/icons/ability_cheapshot.blp",
                id = "chpshtau",
                maxStacks = 1,
                name = "Cheap Shot",
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
                duration = 3,
                effects = {
                    {
                        baseAmount = 6,
                        operation = "flat",
                        statRef = "f82db71a:pu05li08",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {
                    {
                        chance = 100,
                        combatEventId = "on_auto_attack_taken",
                        effects = {
                            {
                                auraRef = "23d5dce2:cmbtrdau",
                                stacks = 1,
                                type = "remove_aura"
                            }
                        },
                        triggerTarget = "aura_target"
                    }
                },
                icon = "interface/icons/ability_rogue_combatreadiness.blp",
                id = "cmbtrdau",
                maxStacks = 5,
                name = "Combat Readiness",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Damage Reduction by 6%. When the affected unit is victim of a basic attack, remove 1 stack.",
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
                duration = 2,
                effects = {
                    {
                        baseAmount = 5,
                        operation = "flat",
                        statRef = "f82db71a:wbj4zuf3",
                        statScaling = {},
                        type = "stat"
                    }
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
                                    "f82db71a:1ggt4t3v"
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
                        triggerTarget = "event_other"
                    },
                    {
                        chance = 100,
                        combatEventId = "on_auto_attack_hit",
                        effects = {
                            {
                                amountMode = "flat",
                                baseDamage = 28.1667,
                                damageSchoolRefs = {
                                    "f82db71a:1ggt4t3v"
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
                        triggerTarget = "event_other"
                    }
                },
                icon = "interface/icons/inv_knife_1h_grimbatolraid_d_03.blp",
                id = "shdblada",
                maxStacks = 1,
                name = "Shadow Blades",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Melee Hit Chance by 5%. When the affected unit hits with a melee attack, the target takes {AURA_EVENT_DAMAGE_1} Shadow damage. When the affected unit hits with a basic attack, the target takes {AURA_EVENT_DAMAGE_2} Shadow damage.",
                    bodyTokens = {
                        {
                            applyMode = "damage_amount",
                            baseField = "baseDamage",
                            effectIndex = 1,
                            eventIndex = 1,
                            key = "AURA_EVENT_DAMAGE_1",
                            tokenType = "aura_amount"
                        },
                        {
                            applyMode = "damage_amount",
                            baseField = "baseDamage",
                            effectIndex = 1,
                            eventIndex = 2,
                            key = "AURA_EVENT_DAMAGE_2",
                            tokenType = "aura_amount"
                        }
                    },
                    stackingText = "",
                    stackingTokens = {},
                    version = 1
                }
            },
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
                    "23d5dce2:dlypsntr",
                    "23d5dce2:malice05",
                    "23d5dce2:sealfate",
                    "23d5dce2:lghtref5",
                    "23d5dce2:deflect5",
                    "23d5dce2:weapexp6",
                    "23d5dce2:unfair01",
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
        items = {
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 2,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_cloth_07.blp",
                id = "rg2tchst",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_rogue_tank",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodfang Chestguard",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {
                    {
                        color = "blue",
                    },
                    {
                        color = "blue",
                    },
                    {
                        color = "yellow",
                    },
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 225,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 17,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 32,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 2,
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 11,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto",
                },
                yellowSockets = 1,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_08.blp",
                id = "rg2tfoot",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_rogue_tank",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodfang Footpads",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 154,
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 27,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 11,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_21.blp",
                id = "rg2thand",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_rogue_tank",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodfang Handguards",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 140,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 20,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 23,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 10,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 1,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_41.blp",
                id = "rg2tcowl",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_rogue_tank",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 1,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodfang Cowl",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {
                    {
                        color = "meta",
                    },
                    {
                        color = "blue",
                    },
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 183,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 25,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 35,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 13,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 1,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_06.blp",
                id = "rg2tlegs",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_rogue_tank",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodfang Legguards",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {
                    {
                        color = "blue",
                    },
                    {
                        color = "yellow",
                    },
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 197,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 23,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 34,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 14,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq",
                },
                yellowSockets = 1,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_23.blp",
                id = "rg2tshld",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_rogue_tank",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodfang Shoulderpads",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 169,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 28,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 11,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 1,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_belt_23.blp",
                id = "rg2twast",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_rogue_tank",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodfang Waistguard",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {
                    {
                        color = "blue",
                    },
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 126,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 18,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 26,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 7,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_bracer_02.blp",
                id = "rg2twris",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_rogue_tank",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodfang Wristguards",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 98,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 11,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 21,
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 7,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_cloth_07.blp",
                id = "rg2dchst",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_rogue_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodfang Chestpiece",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 2,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {
                    {
                        color = "red",
                    },
                    {
                        color = "red",
                    },
                    {
                        color = "yellow",
                    },
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 225,
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 12,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 26,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 17,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 2,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto",
                },
                yellowSockets = 1,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_08.blp",
                id = "rg2dboot",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_rogue_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodfang Boots",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 154,
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 25,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 17,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_21.blp",
                id = "rg2dglov",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_rogue_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodfang Gloves",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 140,
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 16,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 20,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_41.blp",
                id = "rg2dhood",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_rogue_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 1,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodfang Hood",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 1,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {
                    {
                        color = "meta",
                    },
                    {
                        color = "red",
                    },
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 183,
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 16,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 34,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 2,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_06.blp",
                id = "rg2dpant",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_rogue_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodfang Pants",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 1,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {
                    {
                        color = "red",
                    },
                    {
                        color = "yellow",
                    },
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 197,
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 11,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 34,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 17,
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq",
                },
                yellowSockets = 1,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_23.blp",
                id = "rg2dspau",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_rogue_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodfang Spaulders",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 169,
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 25,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 15,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_belt_23.blp",
                id = "rg2dbelt",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_rogue_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodfang Belt",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {
                    {
                        color = "yellow",
                    },
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 126,
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 15,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 20,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4",
                },
                yellowSockets = 1,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_bracer_02.blp",
                id = "rg2dbrac",
                isTwoHanded = false,
                itemLevel = 75,
                itemSetKey = "t2_rogue_dps",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodfang Bracers",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 98,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 24,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10,
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_leather_07.blp",
                id = "r05dtuni",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_rogue_darkmantle",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkmantle Tunic",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 185,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 31,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 15,
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 2,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_08.blp",
                id = "r05dfoot",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_rogue_darkmantle",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkmantle Footpads",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 127,
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 7,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 24,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_24.blp",
                id = "r05dgrip",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_rogue_darkmantle",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkmantle Grips",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 108,
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 22,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 9,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_41.blp",
                id = "r05dcap",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_rogue_darkmantle",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkmantle Cap",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 150,
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 16,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 29,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 15,
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_02.blp",
                id = "r05dpant",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_rogue_darkmantle",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkmantle Pants",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 160,
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 25,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_07.blp",
                id = "r05dspau",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_rogue_darkmantle",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkmantle Spaulders",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 136,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 22,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 5,
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_belt_03.blp",
                id = "r05dbelt",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_rogue_darkmantle",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkmantle Belt",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 102,
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 19,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_bracer_07.blp",
                id = "r05dbrac",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_rogue_darkmantle",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkmantle Bracers",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 79,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 8,
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_leather_07.blp",
                id = "r05tarmo",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_rogue_darkmantle",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkmantle Armor",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 185,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 19,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 31,
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 8,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_08.blp",
                id = "r05ttrea",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_rogue_darkmantle",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkmantle Treads",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 127,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 15,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 22,
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 5,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_24.blp",
                id = "r05thand",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_rogue_darkmantle",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkmantle Handguards",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 108,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 22,
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 4,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_41.blp",
                id = "r05tface",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_rogue_darkmantle",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkmantle Faceguard",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 150,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 18,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 32,
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1,
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 5,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_02.blp",
                id = "r05tlegs",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_rogue_darkmantle",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkmantle Legguards",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 160,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 13,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 30,
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_07.blp",
                id = "r05tpaul",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_rogue_darkmantle",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkmantle Pauldrons",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 136,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 11,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 21,
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 5,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_belt_03.blp",
                id = "r05twais",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_rogue_darkmantle",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkmantle Waistguard",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 102,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 14,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 20,
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 3,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4",
                },
                yellowSockets = 0,
            },
            {
                allowWowConversion = false,
                armorWeight = "leather",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 60,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level",
                    },
                    {
                        classRefs = {
                            "23d5dce2:ta9uh9xw",
                        },
                        invert = false,
                        showOnTooltip = true,
                        tooltipTextOverride = "Classes: Rogue",
                        type = "class",
                    },
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_bracer_07.blp",
                id = "r05twris",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "t05_rogue_darkmantle",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1,
                },
                maxModificationCounts = {
                    mod = 1,
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkmantle Wristguards",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {  },
                socketTypes = {  },
                sockets = {  },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 79,
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 9,
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 16,
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 3,
                    },
                },
                tags = {  },
                targetArmorWeight = "none",
                targetSlotRefs = {  },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix",
                },
                yellowSockets = 0,
            }
        },
        loot = {
            {
                conditions = {},
                description = "Equal-weight Tier 0.5 DPS Rogue set-piece table.",
                drawCount = 1,
                entries = {
                    { id = "r05dtuni", maxQuantity = 1, minQuantity = 1, ref = "23d5dce2:r05dtuni", type = "item", weight = 1 },
                    { id = "r05dfoot", maxQuantity = 1, minQuantity = 1, ref = "23d5dce2:r05dfoot", type = "item", weight = 1 },
                    { id = "r05dgrip", maxQuantity = 1, minQuantity = 1, ref = "23d5dce2:r05dgrip", type = "item", weight = 1 },
                    { id = "r05dcap", maxQuantity = 1, minQuantity = 1, ref = "23d5dce2:r05dcap", type = "item", weight = 1 },
                    { id = "r05dpant", maxQuantity = 1, minQuantity = 1, ref = "23d5dce2:r05dpant", type = "item", weight = 1 },
                    { id = "r05dspau", maxQuantity = 1, minQuantity = 1, ref = "23d5dce2:r05dspau", type = "item", weight = 1 },
                    { id = "r05dbelt", maxQuantity = 1, minQuantity = 1, ref = "23d5dce2:r05dbelt", type = "item", weight = 1 },
                    { id = "r05dbrac", maxQuantity = 1, minQuantity = 1, ref = "23d5dce2:r05dbrac", type = "item", weight = 1 },
                },
                icon = "interface/icons/inv_helmet_41.blp",
                id = "rg05dps1",
                items = {},
                name = "Darkmantle Armor - DPS",
                tags = {},
            },
            {
                conditions = {},
                description = "Equal-weight Tier 0.5 Tank Rogue set-piece table.",
                drawCount = 1,
                entries = {
                    { id = "r05tarmo", maxQuantity = 1, minQuantity = 1, ref = "23d5dce2:r05tarmo", type = "item", weight = 1 },
                    { id = "r05ttrea", maxQuantity = 1, minQuantity = 1, ref = "23d5dce2:r05ttrea", type = "item", weight = 1 },
                    { id = "r05thand", maxQuantity = 1, minQuantity = 1, ref = "23d5dce2:r05thand", type = "item", weight = 1 },
                    { id = "r05tface", maxQuantity = 1, minQuantity = 1, ref = "23d5dce2:r05tface", type = "item", weight = 1 },
                    { id = "r05tlegs", maxQuantity = 1, minQuantity = 1, ref = "23d5dce2:r05tlegs", type = "item", weight = 1 },
                    { id = "r05tpaul", maxQuantity = 1, minQuantity = 1, ref = "23d5dce2:r05tpaul", type = "item", weight = 1 },
                    { id = "r05twais", maxQuantity = 1, minQuantity = 1, ref = "23d5dce2:r05twais", type = "item", weight = 1 },
                    { id = "r05twris", maxQuantity = 1, minQuantity = 1, ref = "23d5dce2:r05twris", type = "item", weight = 1 },
                },
                icon = "interface/icons/inv_helmet_41.blp",
                id = "rg05tank",
                items = {},
                name = "Darkmantle Armor - Tank",
                tags = {},
            },
        },
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
                                    coefficient = 0.2975,
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
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_shadow_ritualofsacrifice.blp",
                id = "g9o4t7uj",
                cooldownChannel = 1,
                learnMode = "always_learned",
                learnLevel = 1,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Sinister Strike",
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
                            baseDamage = 143.438,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.6694,
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
                            weaponDamageCoefficient = 1.9125,
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
                learnLevel = 18,
                usesRanks = true,
                rankInterval = 8,
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
                learnLevel = 1,
                usesRanks = false,
                rankInterval = 8,
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
                                    coefficient = 0.2975,
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
                learnLevel = 4,
                usesRanks = true,
                rankInterval = 8,
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
                            baseDamage = 225,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.7875,
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
                learnLevel = 1,
                usesRanks = true,
                rankInterval = 8,
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
                                    coefficient = 0.2975,
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
                learnLevel = 50,
                usesRanks = true,
                rankInterval = 8,
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
                learnLevel = 8,
                usesRanks = false,
                rankInterval = 8,
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
                learnLevel = 40,
                usesRanks = false,
                rankInterval = 8,
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
                learnLevel = 10,
                usesRanks = false,
                rankInterval = 8,
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
                            baseDamage = 73.312,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.3421,
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
                            weaponDamageCoefficient = 0.9775,
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
                learnLevel = 20,
                usesRanks = true,
                rankInterval = 8,
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
                            baseDamage = 66.938,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.3124,
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
                            weaponDamageCoefficient = 0.8925,
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
                learnLevel = 30,
                usesRanks = true,
                rankInterval = 8,
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
                learnLevel = 20,
                usesRanks = true,
                rankInterval = 8,
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
                learnLevel = 14,
                usesRanks = true,
                rankInterval = 8,
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
                learnLevel = 12,
                usesRanks = false,
                rankInterval = 8,
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
                learnLevel = 6,
                usesRanks = false,
                rankInterval = 8,
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
                learnLevel = 30,
                usesRanks = false,
                rankInterval = 8,
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
                learnLevel = 30,
                usesRanks = false,
                rankInterval = 8,
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
                            auraRef = "23d5dce2:sapaura1",
                            basePower = 0,
                            duration = 3,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "sapcmp01",
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
                        tooltipTextOverride = "Requires Stealth",
                        type = "hidden",
                        unit = "caster"
                    }
                },
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_sap.blp",
                id = "sapspell",
                cooldownChannel = 1,
                learnMode = "always_learned",
                learnLevel = 1,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Sap",
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
                spellbookCategory = "Subtlety",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "23d5dce2:sapaura1",
                            datasetId = "23d5dce2",
                            descriptionText = "Breaks when the affected unit takes damage. Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                            duration = 3,
                            icon = "interface/icons/ability_sap.blp",
                            nameText = "Sap",
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
                    mainText = "Apply Sap to an enemy for 3 turns.",
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
                            auraRef = "23d5dce2:blndaura1",
                            basePower = 0,
                            duration = 1,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "blindcmp",
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
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_shadow_mindsteal.blp",
                id = "blind001",
                cooldownChannel = 2,
                learnMode = "always_learned",
                learnLevel = 1,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Blind",
                range = 0,
                resourceCosts = {
                    {
                        amount = 10,
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
                            auraRef = "23d5dce2:blndaura1",
                            datasetId = "23d5dce2",
                            descriptionText = "Breaks when the affected unit takes damage. Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                            duration = 1,
                            icon = "interface/icons/spell_shadow_mindsteal.blp",
                            nameText = "Blind",
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
                    mainText = "Apply Blind to an enemy for 1 turn.",
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
                            auraRef = "23d5dce2:chpshtau",
                            basePower = 0,
                            duration = 2,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "cheapcmp",
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
                        key = "cheapcp2",
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
                cooldown = 1,
                cooldownGroup = "stun",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_cheapshot.blp",
                id = "chpsht01",
                cooldownChannel = 2,
                learnMode = "always_learned",
                learnLevel = 1,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Cheap Shot",
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
                spellbookCategory = "Subtlety",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "23d5dce2:chpshtau",
                            datasetId = "23d5dce2",
                            descriptionText = "Prevents the affected unit from casting spells. Sets the affected unit's movement range to 0. Causes all attacks against the affected unit to automatically hit.",
                            duration = 2,
                            icon = "interface/icons/ability_cheapshot.blp",
                            nameText = "Cheap Shot",
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
                    mainText = "Apply Cheap Shot to an enemy for 2 turns. Restore {RESOURCE_AMOUNT_1} to yourself.",
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
                            amount = 2,
                            amountMode = "flat",
                            resourceRef = "f82db71a:1h7yfxff",
                            targetEvents = {},
                            type = "resource"
                        },
                        key = "premedcp",
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
                        tooltipTextOverride = "Requires Stealth",
                        type = "hidden",
                        unit = "caster"
                    }
                },
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                doesNotRevealCaster = true,
                icon = "interface/icons/spell_shadow_possession.blp",
                id = "premed01",
                cooldownChannel = 3,
                learnMode = "always_learned",
                learnLevel = 1,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Premeditation",
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
                spellbookCategory = "Subtlety",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Restore {RESOURCE_AMOUNT_1} to yourself.",
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
                casterEvents = {
                    "on_ranged_hit",
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
                            baseDamage = 28.6875,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "ranged",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.133875,
                                    statRef = "f82db71a:v2rs9cpy"
                                }
                            },
                            targetEvents = {
                                "on_ranged_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 0.3825,
                            weaponDamageMode = "main_hand"
                        },
                        key = "fankndmg",
                        target = {
                            allowDeadTargets = false,
                            disableSelfCast = false,
                            maxTargets = 5,
                            minTargets = 1,
                            requiresTarget = true,
                            targetDisposition = "enemy",
                            type = "multi"
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
                        key = "fankncp1",
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
                        slotKey = "ranged",
                        tooltipTextOverride = "Requires Ranged Weapon",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_rogue_fanofknives.blp",
                id = "fankniv1",
                cooldownChannel = 1,
                learnMode = "always_learned",
                learnLevel = 1,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Fan of Knives",
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
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Physical damage to up to 5 enemies. Restore {RESOURCE_AMOUNT_1} to yourself.",
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
                            auraRef = "23d5dce2:cmbtrdau",
                            basePower = 0,
                            duration = 3,
                            stacks = 5,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "cmbtrcmp",
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
                icon = "interface/icons/ability_rogue_combatreadiness.blp",
                id = "cmbtrd01",
                cooldownChannel = 3,
                learnMode = "always_learned",
                learnLevel = 1,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Combat Readiness",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = false,
                spellbookCategory = "Combat",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "23d5dce2:cmbtrdau",
                            datasetId = "23d5dce2",
                            descriptionText = "Increases Damage Reduction by 6%. When the affected unit is victim of a basic attack, remove 1 stack. Applies {AURA_APPLIED_STACKS_1} stacks. Stacks up to {AURA_MAX_STACKS_1} times.",
                            duration = 3,
                            icon = "interface/icons/ability_rogue_combatreadiness.blp",
                            nameText = "Combat Readiness",
                            powerLevel = 0,
                            spellDatasetId = "23d5dce2",
                            stacks = 5,
                            targetContext = {
                                object = "you",
                                possessive = "your",
                                reflexive = "yourself",
                                subject = "you"
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
                    mainText = "Apply Combat Readiness to yourself with 5 stacks for 3 turns.",
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
                            baseDamage = 236.25,
                            damageSchoolRefs = {
                                "f82db71a:qtr10qyj"
                            },
                            damageType = "melee",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.826875,
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
                        key = "envndmg1",
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
                    },
                    {
                        auraRef = "23d5dce2:dlypsn01",
                        invert = false,
                        minimumValue = 5,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "aura_requirement",
                        unit = "target"
                    }
                },
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_rogue_disembowel.blp",
                id = "envenom1",
                cooldownChannel = 2,
                learnMode = "always_learned",
                learnLevel = 1,
                usesRanks = true,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Envenom",
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
                    auraSections = {},
                    mainText = "Deal {DAMAGE_1} Nature damage to an enemy.",
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
                            auraRef = "23d5dce2:shdblada",
                            basePower = 0,
                            duration = 2,
                            stacks = 1,
                            targetEvents = {},
                            type = "apply_aura"
                        },
                        key = "shdblcmp",
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
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/inv_knife_1h_grimbatolraid_d_03.blp",
                id = "shdblad1",
                cooldownChannel = 3,
                learnMode = "always_learned",
                learnLevel = 1,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Shadow Blades",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = false,
                spellbookCategory = "Assassination",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {
                        {
                            auraRef = "23d5dce2:shdblada",
                            datasetId = "23d5dce2",
                            descriptionText = "Increases Melee Hit Chance by 5%. When the affected unit hits with a melee attack, the target takes {AURA_EVENT_DAMAGE_1} Shadow damage. When the affected unit hits with a basic attack, the target takes {AURA_EVENT_DAMAGE_2} Shadow damage.",
                            duration = 2,
                            icon = "interface/icons/ability_rogue_shadowblades.blp",
                            nameText = "Shadow Blades",
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
                                    applyMode = "damage_amount",
                                    baseField = "baseDamage",
                                    effectIndex = 1,
                                    eventIndex = 1,
                                    key = "AURA_EVENT_DAMAGE_1",
                                    tokenType = "aura_amount"
                                },
                                {
                                    applyMode = "damage_amount",
                                    baseField = "baseDamage",
                                    effectIndex = 1,
                                    eventIndex = 2,
                                    key = "AURA_EVENT_DAMAGE_2",
                                    tokenType = "aura_amount"
                                }
                            }
                        }
                    },
                    mainText = "Apply Shadow Blades to yourself for 2 turns.",
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
                            duration = 3,
                            targetEvents = {},
                            type = "taunt"
                        },
                        key = "teasecmp",
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
                icon = "interface/icons/achievement_halloween_smiley_01.blp",
                id = "tease001",
                cooldownChannel = 2,
                learnMode = "always_learned",
                learnLevel = 1,
                usesRanks = false,
                rankInterval = 8,
                mountedCombatOnly = false,
                name = "Tease",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = false,
                spellbookCategory = "Combat",
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
        },
        stats = {},
        traits = {
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
                                auraRef = "23d5dce2:dlypsn01",
                                basePower = 0,
                                duration = 5,
                                stacks = 1,
                                type = "apply_aura"
                            }
                        },
                        triggerTarget = "event_other"
                    }
                },
                icon = "interface/icons/ability_rogue_dualweild.blp",
                id = "dlypsntr",
                isEnvironmental = false,
                mutuallyExclusiveTraitRefs = {
                    "23d5dce2:z9yfqvhy"
                },
                name = "Deadly Poison",
                skillBonuses = {},
                statBonuses = {},
                unlockLevel = 1
            },
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
                mutuallyExclusiveTraitRefs = {
                    "23d5dce2:dlypsntr"
                },
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
                category = "Combat",
                conditions = {},
                description = "",
                events = {
                    {
                        chance = 100,
                        combatEventId = "on_defence",
                        defenceStatRef = "f82db71a:o6113cir",
                        effects = {
                            {
                                amountMode = "flat",
                                baseDamage = 96,
                                damageSchoolRefs = {
                                    "f82db71a:v1azo4j6"
                                },
                                statScaling = {
                                    {
                                        coefficient = 0.14,
                                        statRef = "f82db71a:u7b49vs9"
                                    }
                                },
                                type = "damage"
                            }
                        },
                        triggerTarget = "event_source"
                    }
                },
                icon = "interface/icons/ability_rogue_unfairadvantage.blp",
                id = "unfair01",
                isEnvironmental = false,
                name = "Unfair Advantage",
                skillBonuses = {},
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
                    },
                    {
                        skillRef = "f82db71a:gwgzj5kg",
                        value = 5
                    },
                    {
                        skillRef = "f82db71a:8188fykv",
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
