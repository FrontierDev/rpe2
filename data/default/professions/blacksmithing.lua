local _, Addon = ...

Addon.Data.DefaultDatasets:Register({
    version = 5,
    dataset = {
        achievements = {},
        auras = {
            {
                description = "",
                duration = 3,
                effects = {
                    {
                        baseAmount = -100,
                        operation = "flat",
                        statRef = "f82db71a:v42albuv",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/inv_sword_40.blp",
                id = "jfg3jwrp",
                maxStacks = 1,
                name = "Phantom Blade",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Reduces Armor by {AURA_STAT_1}.",
                    bodyTokens = {
                        {
                            applyMode = "stat_amount",
                            baseField = "baseAmount",
                            effectIndex = 1,
                            key = "AURA_STAT_1",
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
                duration = 10,
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 20,
                        damageSchoolRefs = {
                            "f82db71a:qtr10qyj"
                        },
                        statScaling = {},
                        type = "damage"
                    }
                },
                events = {},
                icon = "interface/icons/inv_spear_07.blp",
                id = "3ku0dihj",
                maxStacks = 1,
                name = "Blight",
                stackBehavior = "refresh_duration",
                tags = {},
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
                icon = "interface/icons/inv_hammer_09.blp",
                id = "b302zkfw",
                maxStacks = 1,
                name = "Dark Iron Pulverizer",
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
                        baseAmount = -300,
                        operation = "flat",
                        statRef = "f82db71a:v42albuv",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/inv_weapon_halberd_02.blp",
                id = "q68ch5hf",
                maxStacks = 1,
                name = "Dark Iron Sunderer",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Reduces Armor by {AURA_STAT_1}.",
                    bodyTokens = {
                        {
                            applyMode = "stat_amount",
                            baseField = "baseAmount",
                            effectIndex = 1,
                            key = "AURA_STAT_1",
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
                duration = 10,
                effects = {
                    {
                        amountMode = "flat",
                        baseDamage = 24,
                        damageSchoolRefs = {
                            "f82db71a:esjguw6d"
                        },
                        statScaling = {},
                        type = "damage"
                    }
                },
                events = {},
                icon = "interface/icons/inv_sword_30.blp",
                id = "t7e5bu60",
                maxStacks = 1,
                name = "Blazing Rapier",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Deals {AURA_DAMAGE_1} Fire damage each turn.",
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
                        baseDamage = 64,
                        damageSchoolRefs = {
                            "f82db71a:esjguw6d"
                        },
                        statScaling = {},
                        type = "damage"
                    }
                },
                events = {},
                icon = "interface/icons/inv_hammer_06.blp",
                id = "qbdf82lc",
                maxStacks = 1,
                name = "Volcanic Hammer",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Deals {AURA_DAMAGE_1} Fire damage each turn.",
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
                duration = 5,
                effects = {
                    {
                        amountMode = "flat",
                        baseHealing = 90,
                        statScaling = {},
                        type = "heal"
                    },
                    {
                        baseAmount = 120,
                        operation = "flat",
                        statRef = "f82db71a:zfqm8dxp",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/inv_sword_39.blp",
                id = "vonnsice",
                maxStacks = 1,
                name = "Arcanite Champion",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Heals for {AURA_HEAL_1} health each turn. Increases Strength by {AURA_STAT_1}.",
                    bodyTokens = {
                        {
                            applyMode = "heal_amount",
                            baseField = "baseHealing",
                            effectIndex = 1,
                            key = "AURA_HEAL_1",
                            tokenType = "aura_amount"
                        },
                        {
                            applyMode = "stat_amount",
                            baseField = "baseAmount",
                            effectIndex = 2,
                            key = "AURA_STAT_1",
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
                        cancelOnDamage = false,
                        forceAutoHitAgainstTarget = true,
                        movementRangeOverride = 0,
                        preventCasting = true,
                        statScaling = {},
                        type = "control"
                    }
                },
                events = {},
                icon = "interface/icons/inv_hammer_09.blp",
                id = "w6r8sctw",
                maxStacks = 1,
                name = "Hammer of the Titans",
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
                duration = 5,
                effects = {
                    {
                        baseAmount = -200,
                        operation = "flat",
                        statRef = "f82db71a:v42albuv",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/inv_axe_12.blp",
                id = "52qk3wyd",
                maxStacks = 3,
                name = "Annihilator",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Reduces Armor by {AURA_STAT_1}.",
                    bodyTokens = {
                        {
                            applyMode = "stat_amount",
                            baseField = "baseAmount",
                            effectIndex = 1,
                            key = "AURA_STAT_1",
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
                duration = 5,
                effects = {
                    {
                        baseAmount = -3,
                        operation = "flat",
                        statRef = "f82db71a:wbj4zuf3",
                        statScaling = {
                            {
                                coefficient = 0.01,
                                statRef = "f82db71a:7t7xgzcx"
                            }
                        },
                        type = "stat"
                    },
                    {
                        baseAmount = 3,
                        operation = "flat",
                        statRef = "f82db71a:dd88li4c",
                        statScaling = {
                            {
                                coefficient = 0.01,
                                statRef = "f82db71a:7t7xgzcx"
                            }
                        },
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/inv_sword_11.blp",
                id = "ddtdgrqi",
                maxStacks = 1,
                name = "Frostguard",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Reduces Melee Hit Chance by 3%. Increases Ranged Hit Chance by 3%.",
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
                        baseAmount = -15,
                        operation = "flat",
                        statRef = "f82db71a:zs1nbz13",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/inv_axe_12.blp",
                id = "xsxl9wyg",
                maxStacks = 1,
                name = "Nightfall",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = false
            }
        },
        authorName = "Ortellus-ArgentDawn",
        classes = {},
        currencies = {},
        damageSchools = {},
        datasetType = "crafting",
        dependencies = {
            "f82db71a"
        },
        description = "",
        groupName = "Core",
        guildSettings = {},
        id = "61fdf3df",
        interactions = {},
        itemSlots = {},
        items = {
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 54,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_22.blp",
                id = "yuzinwkc",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "imperial_plate",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Imperial Plate Helm",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 456
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 18
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 17
                    }
                },
                tags = {
                    "bs55"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 47,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_02.blp",
                id = "9c20ak9e",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "imperial_plate",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Imperial Plate Shoulders",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 380
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 11
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 12
                    }
                },
                tags = {
                    "bs55"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 55,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_plate10.blp",
                id = "lsh6ku63",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "imperial_plate",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Imperial Plate Chest",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 1,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "red"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 570
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 17
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 18
                    }
                },
                tags = {
                    "bs55"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 56,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_04.blp",
                id = "lsxtg6mf",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "imperial_plate",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Imperial Plate Leggings",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 507
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 18
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 18
                    }
                },
                tags = {
                    "bs55"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 49,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_bracer_19.blp",
                id = "3gp91s7a",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "imperial_plate",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Imperial Plate Bracers",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 225
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 8
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 9
                    }
                },
                tags = {
                    "bs55"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 47,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_belt_01.blp",
                id = "7dstz3ty",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "imperial_plate",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Imperial Plate Belt",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 285
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 11
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 12
                    }
                },
                tags = {
                    "bs55"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 54,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_plate_01.blp",
                id = "n7fuc0ph",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "imperial_plate",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Imperial Plate Boots",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 386
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 13
                    }
                },
                tags = {
                    "bs55"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 52,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_27.blp",
                id = "7cqgfruc",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "imperial_plate",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Imperial Plate Gauntlets",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 342
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 13
                    }
                },
                tags = {
                    "bs55"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = true,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_ingot_07.blp",
                id = "5m4zt99z",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "material",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 200,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Thorium Bar",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {},
                wowConversionSkillRef = "f82db71a:6hydytdf",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = false,
                canStack = true,
                canTrade = false,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_hammer_20.blp",
                id = "518sbr8g",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "tool",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 99,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Blacksmithing Hammer",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {},
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 13,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_01.blp",
                id = "raj0rzpg",
                isTwoHanded = false,
                itemLevel = 18,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Rough Bronze Boots",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 106
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 3
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 18,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_bracer_05.blp",
                id = "y78y2o9u",
                isTwoHanded = false,
                itemLevel = 20,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Rough Bronze Bracers",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 225
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 4
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 18,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_chain_08.blp",
                id = "uo0hunwt",
                isTwoHanded = false,
                itemLevel = 23,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Rough Bronze Curiass",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 168
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 4
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 4
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 16,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_03.blp",
                id = "np2eb1gq",
                isTwoHanded = false,
                itemLevel = 21,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Rough Bronze Leggings",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 149
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 4
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 17,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_05.blp",
                id = "kg9aep85",
                isTwoHanded = false,
                itemLevel = 22,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Rough Bronze Shoulders",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 149
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 5
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 22,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_05.blp",
                id = "6xws2b6w",
                isTwoHanded = false,
                itemLevel = 20,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Silvered Bronze Gauntlets",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 118
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 4
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 4
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 3
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = true,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_ingot_bronze.blp",
                id = "xegz4i5q",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "material",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 200,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bronze Bar",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {},
                wowConversionSkillRef = "f82db71a:6hydytdf",
                yellowSockets = 0
            },
            {
                allowWowConversion = true,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_ingot_steel.blp",
                id = "ov027km6",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "material",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 200,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Steel Bar",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {},
                wowConversionSkillRef = "f82db71a:6hydytdf",
                yellowSockets = 0
            },
            {
                allowWowConversion = true,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_ingot_01.blp",
                id = "nvc1anz9",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "material",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 200,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Silver Bar",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {},
                wowConversionSkillRef = "f82db71a:6hydytdf",
                yellowSockets = 0
            },
            {
                allowWowConversion = true,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_ingot_03.blp",
                id = "hqook9xe",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "material",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 200,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Gold Bar",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {},
                wowConversionSkillRef = "f82db71a:6hydytdf",
                yellowSockets = 0
            },
            {
                allowWowConversion = true,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_ingot_06.blp",
                id = "225h536c",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "material",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 200,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Mithril Bar",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {},
                wowConversionSkillRef = "f82db71a:6hydytdf",
                yellowSockets = 0
            },
            {
                allowWowConversion = true,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_ingot_08.blp",
                id = "ufv4fdnf",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "material",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 200,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Truesilver Bar",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {},
                wowConversionSkillRef = "f82db71a:6hydytdf",
                yellowSockets = 0
            },
            {
                allowWowConversion = true,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_ingot_mithril.blp",
                id = "pb24e7k5",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "material",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 200,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Dark Iron Bar",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {},
                wowConversionSkillRef = "f82db71a:6hydytdf",
                yellowSockets = 0
            },
            {
                allowWowConversion = true,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_stonetablet_05.blp",
                id = "6hy57ood",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "material",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 200,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Arcanite Bar",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                wowConversionSkillRef = "f82db71a:6hydytdf",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 2,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_chain.blp",
                id = "id2tqbql",
                isTwoHanded = false,
                itemLevel = 7,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bronze Chain Vest",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 81
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 4,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_03.blp",
                id = "bg148qwn",
                isTwoHanded = false,
                itemLevel = 9,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bronze Chain Pants",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 83
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 4,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_01.blp",
                id = "9cfkn6qj",
                isTwoHanded = false,
                itemLevel = 9,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bronze Chain Boots",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 65
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 6,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_belt_02.blp",
                id = "fs47rswm",
                isTwoHanded = false,
                itemLevel = 11,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bronze Chain Belt",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 61
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 8,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_03.blp",
                id = "7f2ixi08",
                isTwoHanded = false,
                itemLevel = 9,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Runed Bronze Pants",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 113
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 2
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 2
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {},
                    icon = "",
                    name = "",
                    phase = "event_start",
                    skillBonuses = {},
                    statBonuses = {
                        {
                            operation = "flat",
                            statRef = "f82db71a:u7b49vs9",
                            value = 8
                        }
                    },
                    unlockLevel = 1
                },
                consumableType = "enhancement",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_stone_sharpeningstone_01.blp",
                id = "op5en83c",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "consumable",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 20,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Rough Sharpening Stone",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {},
                    icon = "",
                    name = "",
                    phase = "event_start",
                    skillBonuses = {},
                    statBonuses = {
                        {
                            operation = "flat",
                            statRef = "f82db71a:u7b49vs9",
                            value = 8
                        }
                    },
                    unlockLevel = 1
                },
                consumableType = "enhancement",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_stone_weightstone_01.blp",
                id = "iw2fp34l",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "consumable",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 20,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Rough Weightstone",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                yellowSockets = 0
            },
            {
                allowWowConversion = true,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_stone_06.blp",
                id = "c7urqe23",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "material",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 200,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Rough Stone",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                wowConversionSkillRef = "f82db71a:6hydytdf",
                yellowSockets = 0
            },
            {
                allowWowConversion = true,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_stone_09.blp",
                id = "qcah9yrg",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "material",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 200,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Coarse Stone",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                wowConversionSkillRef = "f82db71a:6hydytdf",
                yellowSockets = 0
            },
            {
                allowWowConversion = true,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_stone_12.blp",
                id = "u8qtuhfq",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "material",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 200,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Heavy Stone",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                wowConversionSkillRef = "f82db71a:6hydytdf",
                yellowSockets = 0
            },
            {
                allowWowConversion = true,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_stonetablet_01.blp",
                id = "a4kj24o4",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "material",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 200,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Dense Stone",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                wowConversionSkillRef = "f82db71a:6hydytdf",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 8,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_throwingaxe_02.blp",
                id = "8fp9w74u",
                isTwoHanded = true,
                itemLevel = 13,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 35,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 23,
                modificationKind = "generic",
                name = "Bronze Battle Axe",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 3
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:9ni3vfas",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 6,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_25.blp",
                id = "w2s2cutb",
                isTwoHanded = false,
                itemLevel = 11,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 20,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 10,
                modificationKind = "generic",
                name = "Light Bronze Longsword",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {},
                    icon = "",
                    name = "",
                    phase = "event_start",
                    skillBonuses = {},
                    statBonuses = {
                        {
                            operation = "flat",
                            statRef = "f82db71a:u7b49vs9",
                            value = 16
                        }
                    },
                    unlockLevel = 1
                },
                consumableType = "enhancement",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_stone_sharpeningstone_02.blp",
                id = "30qv0a2x",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "consumable",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 20,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Coarse Sharpening Stone",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {},
                    icon = "",
                    name = "",
                    phase = "event_start",
                    skillBonuses = {},
                    statBonuses = {
                        {
                            operation = "flat",
                            statRef = "f82db71a:u7b49vs9",
                            value = 16
                        }
                    },
                    unlockLevel = 1
                },
                consumableType = "enhancement",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_stone_weightstone_02.blp",
                id = "sbhu57ga",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "consumable",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 20,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Coarse Weightstone",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 10,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_04.blp",
                id = "ag5ampla",
                isTwoHanded = false,
                itemLevel = 15,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Gemmed Bronze Gauntlets",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 90
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 1
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 11,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_hammer_18.blp",
                id = "yh4qvi2o",
                isTwoHanded = true,
                itemLevel = 16,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 32,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 21,
                modificationKind = "generic",
                name = "Heavy Bronze Maul",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 2
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 2
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:i4pivdig",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 12,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_throwingaxe_01.blp",
                id = "lbpcwlrf",
                isTwoHanded = false,
                itemLevel = 17,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 28,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 15,
                modificationKind = "generic",
                name = "Thick War Axe",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 1
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:9ni3vfas",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 6,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
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
                id = "40tnm7x9",
                isTwoHanded = false,
                itemLevel = 18,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Runed Bronze Belt",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 86
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 2
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 1
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 14,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_bracer_03.blp",
                id = "9bq41la7",
                isTwoHanded = false,
                itemLevel = 19,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Runed Bronze Bracers",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 68
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 3
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 13,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_plate03.blp",
                id = "rv4hqt7k",
                isTwoHanded = false,
                itemLevel = 18,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Runed Bronze Breastplate",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 162
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 3
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 4
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 14,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_14.blp",
                id = "c3o79n21",
                isTwoHanded = true,
                itemLevel = 19,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 41,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 27,
                modificationKind = "generic",
                name = "Heavy Bronze Broadsword",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 6
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 15,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_spear_05.blp",
                id = "4smyd6ly",
                isTwoHanded = false,
                itemLevel = 20,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 24,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 16,
                modificationKind = "generic",
                name = "Thick Bronze Darts",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 2
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:q8ve6n6t"
                },
                weaponTypeRef = "f82db71a:we5ul4ne",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 15,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_plate05.blp",
                id = "gwq05kni",
                isTwoHanded = false,
                itemLevel = 20,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Ironforge Breastplate",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 198
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 4
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 4
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 15,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_weapon_shortblade_04.blp",
                id = "lgdn8ym2",
                isTwoHanded = false,
                itemLevel = 20,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 25,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 13,
                modificationKind = "generic",
                name = "Big Bronze Knife",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 3
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                weaponTypeRef = "f82db71a:y0dnlo8g",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 18,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_weapon_shortblade_04.blp",
                id = "d83dlv7u",
                isTwoHanded = false,
                itemLevel = 23,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 26,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 13,
                modificationKind = "generic",
                name = "Pearl-handled Dagger",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 2
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 2
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                weaponTypeRef = "f82db71a:y0dnlo8g",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 20,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
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
                id = "jg3tuoxe",
                isTwoHanded = false,
                itemLevel = 25,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Patterned Bronze Bracers",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 80
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 5
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {},
                    icon = "",
                    name = "",
                    phase = "event_start",
                    skillBonuses = {},
                    statBonuses = {
                        {
                            operation = "flat",
                            statRef = "f82db71a:u7b49vs9",
                            value = 32
                        }
                    },
                    unlockLevel = 1
                },
                consumableType = "enhancement",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_stone_sharpeningstone_03.blp",
                id = "zdoehl40",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "consumable",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 20,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Heavy Sharpening Stone",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {},
                    icon = "",
                    name = "",
                    phase = "event_start",
                    skillBonuses = {},
                    statBonuses = {
                        {
                            operation = "flat",
                            statRef = "f82db71a:u7b49vs9",
                            value = 32
                        }
                    },
                    unlockLevel = 1
                },
                consumableType = "enhancement",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_stone_weightstone_03.blp",
                id = "7ovx0a64",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "consumable",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 20,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Heavy Weightstone",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 20,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_05.blp",
                id = "3ekhevbe",
                isTwoHanded = false,
                itemLevel = 25,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Silvered Bronze Shoulders",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 137
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 3
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 3
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 3
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 20,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_weapon_shortblade_05.blp",
                id = "c4frv7vq",
                isTwoHanded = false,
                itemLevel = 25,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 30,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 16,
                modificationKind = "generic",
                name = "Deadly Bronze Poinard",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 4
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                weaponTypeRef = "f82db71a:y0dnlo8g",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 20,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_mace_08.blp",
                id = "p0wjao14",
                isTwoHanded = false,
                itemLevel = 25,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 47,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 25,
                modificationKind = "generic",
                name = "Heavy Bronze Mace",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 4
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                weaponTypeRef = "f82db71a:i4pivdig",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 21,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_chain_09.blp",
                id = "qcfxifb8",
                isTwoHanded = false,
                itemLevel = 26,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Silvered Bronze Breastplate",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 186
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 4
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 21,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_01.blp",
                id = "orqaw603",
                isTwoHanded = false,
                itemLevel = 26,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Silvered Bronze Boots",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 128
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 4
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 4
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 3
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 23,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_hammer_05.blp",
                id = "jmbdhlih",
                isTwoHanded = false,
                itemLevel = 28,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 34,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 18,
                modificationKind = "generic",
                name = "Iridescent Hammer",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 3
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 3
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                weaponTypeRef = "f82db71a:i4pivdig",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 24,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_plate15.blp",
                id = "vgyjt86n",
                isTwoHanded = false,
                itemLevel = 29,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Shining Silver Breastplate",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 214
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 14
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 24,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_01.blp",
                id = "cgh5tv7w",
                isTwoHanded = false,
                itemLevel = 29,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Green Steel Boots",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 134
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 7
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 3
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 25,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_hammer_05.blp",
                id = "si0uloh3",
                isTwoHanded = false,
                itemLevel = 30,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 57,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 30,
                modificationKind = "generic",
                name = "Mighty Steel Hammer",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 5
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:i4pivdig",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 100,
                            combatEventId = "on_melee_taken",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseDamage = 20,
                                    damageSchoolRefs = {
                                        "f82db71a:v1azo4j6"
                                    },
                                    statScaling = {},
                                    type = "damage"
                                }
                            },
                            triggerTarget = "event_other"
                        },
                        {
                            chance = 100,
                            combatEventId = "on_auto_attack_taken",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseDamage = 15,
                                    damageSchoolRefs = {
                                        "f82db71a:v1azo4j6"
                                    },
                                    statScaling = {},
                                    type = "damage"
                                }
                            },
                            triggerTarget = "event_other"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "mod",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_armorkit_01.blp",
                id = "drrm1215",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "modification",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Steel Shield Spike",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "shield",
                targetSlotRefs = {
                    "f82db71a:l1hvib8g"
                },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 25,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_05.blp",
                id = "y7ct6ztr",
                isTwoHanded = false,
                itemLevel = 30,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Green Steel Gauntlets",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 124
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 5
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 26,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_04.blp",
                id = "606sogr2",
                isTwoHanded = false,
                itemLevel = 31,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Silvered Bronze Leggings",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 176
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 7
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 6
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 26,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_05.blp",
                id = "zjpw1cnm",
                isTwoHanded = false,
                itemLevel = 31,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Green Steel Leggings",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 176
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 8
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 8
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 26,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_hammer_07.blp",
                id = "eiuaqmbm",
                isTwoHanded = true,
                itemLevel = 31,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 89,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 59,
                modificationKind = "generic",
                name = "Solid Iron Maul",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:i4pivdig",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 27,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_09.blp",
                id = "t2ytpwde",
                isTwoHanded = false,
                itemLevel = 32,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Green Steel Shoulders",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 153
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 7
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 4
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 27,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
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
                id = "t5hzhzlo",
                isTwoHanded = false,
                itemLevel = 32,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Barbaric Steel Shoulders",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 153
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 6
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 27,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_chain_15.blp",
                id = "cksgzwog",
                isTwoHanded = false,
                itemLevel = 32,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Barbaric Steel Chestplate",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 204
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 12
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 27,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_20.blp",
                id = "ny43jsvb",
                isTwoHanded = false,
                itemLevel = 32,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 39,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 21,
                modificationKind = "generic",
                name = "Hardened Steel Shortsword",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 5
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {},
                    icon = "",
                    name = "",
                    phase = "event_start",
                    skillBonuses = {},
                    statBonuses = {
                        {
                            operation = "flat",
                            statRef = "f82db71a:wbj4zuf3",
                            value = 1
                        }
                    },
                    unlockLevel = 1
                },
                consumableType = "enhancement",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_orb_01.blp",
                id = "c91tdk98",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "consumable",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 20,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Iron Counterweight",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 29,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_03.blp",
                id = "vqfe7ri4",
                isTwoHanded = false,
                itemLevel = 34,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Green Steel Helmet",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 171
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 11
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 29,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_04.blp",
                id = "sdczv31c",
                isTwoHanded = false,
                itemLevel = 34,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Golden Scale Leggings",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 184
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 11
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 29,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_hammer_04.blp",
                id = "8wv368lv",
                isTwoHanded = true,
                itemLevel = 31,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 76,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 50,
                modificationKind = "generic",
                name = "Golden Steel Destroyer",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 4
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 11
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:i4pivdig",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 30,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_25.blp",
                id = "0s4n0m2j",
                isTwoHanded = false,
                itemLevel = 35,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Barbaric Steel Helm",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 173
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 9
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 9
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 30,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_09.blp",
                id = "73nd7h4h",
                isTwoHanded = false,
                itemLevel = 35,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Golden Scale Shoulders",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 160
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 7
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 30,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_36.blp",
                id = "byxtguye",
                isTwoHanded = false,
                itemLevel = 35,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 62,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 33,
                modificationKind = "generic",
                name = "Jade Serpentblade",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 4
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 4
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 31,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_chain.blp",
                id = "xvi0gf16",
                isTwoHanded = false,
                itemLevel = 36,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Green Steel Hauberk",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 358
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 7
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 11
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 31,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_plate_01.blp",
                id = "5eujrwfi",
                isTwoHanded = false,
                itemLevel = 36,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Barbaric Steel Boots",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 149
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 7
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 7
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 31,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_weapon_shortblade_05.blp",
                id = "5bh3c0m6",
                isTwoHanded = false,
                itemLevel = 20,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 37,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 19,
                modificationKind = "generic",
                name = "Glinting Steel Dagger",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:u7b49vs9",
                        value = 12
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                weaponTypeRef = "f82db71a:y0dnlo8g",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 31,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_25.blp",
                id = "tyw2yswi",
                isTwoHanded = true,
                itemLevel = 36,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 83,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 55,
                modificationKind = "generic",
                name = "Moonsteel Broadsword",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 12
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 4
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 32,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_01.blp",
                id = "03moyy1v",
                isTwoHanded = false,
                itemLevel = 37,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Polished Steel Boots",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 151
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 11
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 32,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_31.blp",
                id = "o95sn68u",
                isTwoHanded = false,
                itemLevel = 37,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Barbaric Steel Gloves",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 137
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 11
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 32,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_throwingaxe_05.blp",
                id = "9u2dm9bm",
                isTwoHanded = true,
                itemLevel = 37,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 108,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 71,
                modificationKind = "generic",
                name = "Massive Steel Axe",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 11
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 7
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:9ni3vfas",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {},
                    icon = "",
                    name = "",
                    phase = "event_start",
                    skillBonuses = {},
                    statBonuses = {
                        {
                            operation = "flat",
                            statRef = "f82db71a:tcn0s8kx",
                            value = 2
                        }
                    },
                    unlockLevel = 1
                },
                consumableType = "enhancement",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/spell_frost_chainsofice.blp",
                id = "wpb8yq2y",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "consumable",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 20,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Steel Weapon Chain",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 33,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_36.blp",
                id = "xyqeiyd9",
                isTwoHanded = false,
                itemLevel = 38,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Golden Scale Coif",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 181
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 10
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 33,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 80,
                            combatEventId = "on_auto_attack_hit",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseDamage = 30,
                                    damageSchoolRefs = {
                                        "f82db71a:hx7pnwv4"
                                    },
                                    statScaling = {},
                                    type = "damage"
                                }
                            },
                            triggerTarget = "event_other"
                        },
                        {
                            chance = 40,
                            combatEventId = "on_melee_hit",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseDamage = 30,
                                    damageSchoolRefs = {
                                        "f82db71a:hx7pnwv4"
                                    },
                                    statScaling = {},
                                    type = "damage"
                                }
                            },
                            triggerTarget = "event_other"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_axe_06.blp",
                id = "ibzdwels",
                isTwoHanded = false,
                itemLevel = 38,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 56,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 30,
                modificationKind = "generic",
                name = "Edge of Winter",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 3
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:9ni3vfas",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 34,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_weapon_shortblade_05.blp",
                id = "n3r95yhf",
                isTwoHanded = false,
                itemLevel = 39,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 39,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 21,
                modificationKind = "generic",
                name = "Searing Golden Blade",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 10
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                weaponTypeRef = "f82db71a:y0dnlo8g",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 35,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_chain_06.blp",
                id = "eugizgo2",
                isTwoHanded = false,
                itemLevel = 40,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Golden Scale Curiass",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 231
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 14
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 6
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = true,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_stone_10.blp",
                id = "o1ogtdcq",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "material",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 200,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Solid Stone",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                wowConversionSkillRef = "f82db71a:6hydytdf",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {},
                    icon = "",
                    name = "",
                    phase = "event_start",
                    skillBonuses = {},
                    statBonuses = {
                        {
                            operation = "flat",
                            statRef = "f82db71a:u7b49vs9",
                            value = 48
                        }
                    },
                    unlockLevel = 1
                },
                consumableType = "enhancement",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_stone_sharpeningstone_04.blp",
                id = "chvq05c4",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "consumable",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 20,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Solid Sharpening Stone",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {},
                    icon = "",
                    name = "",
                    phase = "event_start",
                    skillBonuses = {},
                    statBonuses = {
                        {
                            operation = "flat",
                            statRef = "f82db71a:u7b49vs9",
                            value = 48
                        }
                    },
                    unlockLevel = 1
                },
                consumableType = "enhancement",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_stone_weightstone_04.blp",
                id = "bpzrl6bz",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "consumable",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 20,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Solid Weightstone",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 35,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_axe_05.blp",
                id = "o9lv0aod",
                isTwoHanded = false,
                itemLevel = 40,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 57,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 30,
                modificationKind = "generic",
                name = "Whirling Steel Axes",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 4
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 3
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:q8ve6n6t"
                },
                weaponTypeRef = "f82db71a:we5ul4ne",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 35,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_plate05.blp",
                id = "yc0b74rs",
                isTwoHanded = false,
                itemLevel = 40,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Steel Breastplate",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 381
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 35,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_01.blp",
                id = "wn3qs2dl",
                isTwoHanded = false,
                itemLevel = 40,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Golden Scale Boots",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 159
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 8
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 8
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 35,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_axe_17.blp",
                id = "njvkrtvf",
                isTwoHanded = true,
                itemLevel = 40,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 87,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 58,
                modificationKind = "generic",
                name = "Shadow Crescent Axe",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 11
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:9ni3vfas",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 35,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 100,
                            combatEventId = "on_auto_attack_hit",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseDamage = 45,
                                    damageSchoolRefs = {
                                        "f82db71a:hx7pnwv4"
                                    },
                                    statScaling = {},
                                    type = "damage"
                                }
                            },
                            triggerTarget = "event_other"
                        },
                        {
                            chance = 40,
                            combatEventId = "on_melee_hit",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseDamage = 45,
                                    damageSchoolRefs = {
                                        "f82db71a:hx7pnwv4"
                                    },
                                    statScaling = {},
                                    type = "damage"
                                }
                            },
                            triggerTarget = "event_other"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_05.blp",
                id = "j9vfvg5m",
                isTwoHanded = true,
                itemLevel = 40,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 118,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 78,
                modificationKind = "generic",
                name = "Frost Tiger Blade",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 40,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_22.blp",
                id = "41ra4g5n",
                isTwoHanded = false,
                itemLevel = 45,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Heavy Mithril Shoulder",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 225
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 40,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_27.blp",
                id = "4s7vch2u",
                isTwoHanded = false,
                itemLevel = 45,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Heavy Mithril Gauntlet",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 268
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 8
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 36,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_29.blp",
                id = "o1p0jx6u",
                isTwoHanded = false,
                itemLevel = 41,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Golden Scale Gauntlets",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 146
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 11
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 4
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 40,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_03.blp",
                id = "rr281vk6",
                isTwoHanded = false,
                itemLevel = 45,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Heavy Mithril Pants",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 417
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 11
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 37,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_03.blp",
                id = "u49zms89",
                isTwoHanded = false,
                itemLevel = 42,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Mithril Scale Pants",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 208
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 11
                    },
                    {
                        sourceStatRef = "f82db71a:o6113cir",
                        value = 1
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 37,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_axe_14.blp",
                id = "dnw6g52l",
                isTwoHanded = false,
                itemLevel = 42,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 85,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 45,
                modificationKind = "generic",
                name = "Heavy Mithril Axe",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 7
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:9ni3vfas",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 100,
                            combatEventId = "on_melee_taken",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseDamage = 40,
                                    damageSchoolRefs = {
                                        "f82db71a:v1azo4j6"
                                    },
                                    statScaling = {},
                                    type = "damage"
                                }
                            },
                            triggerTarget = "event_other"
                        },
                        {
                            chance = 100,
                            combatEventId = "on_auto_attack_taken",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseDamage = 35,
                                    damageSchoolRefs = {
                                        "f82db71a:v1azo4j6"
                                    },
                                    statScaling = {},
                                    type = "damage"
                                }
                            },
                            triggerTarget = "event_other"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "mod",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_armorkit_02.blp",
                id = "gp7ft2s1",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "modification",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Mithril Shield Spike",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "shield",
                targetSlotRefs = {
                    "f82db71a:l1hvib8g"
                },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 38,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
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
                id = "ken7rmiw",
                isTwoHanded = false,
                itemLevel = 43,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Mithril Scale Bracers",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 106
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 7
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 6
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 40,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_04.blp",
                id = "7ebhc61t",
                isTwoHanded = false,
                itemLevel = 45,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Ornate Mithril Pants",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 375
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 12
                    },
                    {
                        sourceStatRef = "f82db71a:o6113cir",
                        value = 1
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 40,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_31.blp",
                id = "0x0tsxhr",
                isTwoHanded = false,
                itemLevel = 45,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Ornate Mithril Gloves",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 268
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 39,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_axe_03.blp",
                id = "3pyjmrn1",
                isTwoHanded = false,
                itemLevel = 44,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 61,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 32,
                modificationKind = "generic",
                name = "Blue Glittering Axe",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 8
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                weaponTypeRef = "f82db71a:9ni3vfas",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 40,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_22.blp",
                id = "e6nypjtr",
                isTwoHanded = false,
                itemLevel = 45,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Ornate Mithril Shoulder",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 327
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:o6113cir",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 40,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_29.blp",
                id = "bygojy13",
                isTwoHanded = false,
                itemLevel = 45,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Truesilver Gauntlets",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 300
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 16
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 7
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 40,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_10.blp",
                id = "dfj2fhoq",
                isTwoHanded = false,
                itemLevel = 45,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 80,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 43,
                modificationKind = "generic",
                name = "Wicked Mithril Blade",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 4
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 37,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_03.blp",
                id = "i35x1al5",
                isTwoHanded = false,
                itemLevel = 42,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Orcish War Leggings",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 208
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 17
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 41,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_35.blp",
                id = "836rxkhj",
                isTwoHanded = false,
                itemLevel = 46,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Ornate Mithril Coif",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 206
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 13
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 41,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_plate10.blp",
                id = "vdtmfmn8",
                isTwoHanded = false,
                itemLevel = 46,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Heavy Mithril Breastplate",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 536
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 15
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 41,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_mace_15.blp",
                id = "wzdlo97u",
                isTwoHanded = false,
                itemLevel = 46,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 86,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 46,
                modificationKind = "generic",
                name = "Big Black Mace",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 8
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:i4pivdig",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 40,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/ability_rogue_sprint.blp",
                id = "jt7tm4z1",
                isTwoHanded = false,
                itemLevel = 45,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Mithril Spurs",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:s1mt6jh9",
                        value = 3
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:uw353kk1"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 42,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_12.blp",
                id = "m0w5ulmv",
                isTwoHanded = false,
                itemLevel = 47,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Mithril Scale Shoulders",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 194
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 10
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 42,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_plate_01.blp",
                id = "6qw94g2f",
                isTwoHanded = false,
                itemLevel = 47,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Heavy Mithril Boots",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 382
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 42,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 100,
                            combatEventId = "on_critical_hit",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseDamage = 100,
                                    damageSchoolRefs = {
                                        "f82db71a:v1azo4j6"
                                    },
                                    statScaling = {},
                                    type = "damage"
                                }
                            },
                            triggerTarget = "event_other"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_hammer_18.blp",
                id = "p2yq2n1d",
                isTwoHanded = false,
                itemLevel = 47,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 99,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 53,
                modificationKind = "generic",
                name = "The Shatterer",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:i4pivdig",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 43,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_plate10.blp",
                id = "xt3otnm9",
                isTwoHanded = false,
                itemLevel = 47,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Ornate Mithril Breastplate",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 463
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1
                    },
                    {
                        sourceStatRef = "f82db71a:o6113cir",
                        value = 1
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 43,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_30.blp",
                id = "w47ofap2",
                isTwoHanded = false,
                itemLevel = 48,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 63,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 34,
                modificationKind = "generic",
                name = "Dazzling Mithril Rapier",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 8
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 42,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_10.blp",
                id = "j7jkiwxm",
                isTwoHanded = false,
                itemLevel = 47,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Heavy Mithril Helm",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 469
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 15
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 44,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_10.blp",
                id = "yldu4bmt",
                isTwoHanded = false,
                itemLevel = 49,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Ornate Mithril Helm",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 383
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 44,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 9,
                            combatEventId = "on_melee_taken",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseHealing = 80,
                                    statScaling = {},
                                    type = "heal"
                                }
                            },
                            triggerTarget = "event_other"
                        },
                        {
                            chance = 3,
                            combatEventId = "on_auto_attack_taken",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseHealing = 80,
                                    statScaling = {},
                                    type = "heal"
                                }
                            },
                            triggerTarget = "event_other"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_plate04.blp",
                id = "yes6wowr",
                isTwoHanded = false,
                itemLevel = 49,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Truesilver Breastplate",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 519
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 44,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_01.blp",
                id = "qwbyig3d",
                isTwoHanded = false,
                itemLevel = 49,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Ornate Mithril Boots",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 324
                    },
                    {
                        sourceStatRef = "f82db71a:o6113cir",
                        value = 1
                    },
                    {
                        sourceStatRef = "f82db71a:s1mt6jh9",
                        value = 2
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 44,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_hammer_17.blp",
                id = "8j022vl5",
                isTwoHanded = false,
                itemLevel = 49,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 76,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 41,
                modificationKind = "generic",
                name = "Runed Mithril Hammer",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 7
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 4
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:i4pivdig",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 44,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 80,
                            combatEventId = "on_auto_attack_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:jfg3jwrp",
                                    basePower = 0,
                                    duration = 3,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_other"
                        },
                        {
                            chance = 40,
                            combatEventId = "on_melee_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:jfg3jwrp",
                                    basePower = 0,
                                    duration = 3,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_other"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_40.blp",
                id = "spclk4k7",
                isTwoHanded = false,
                itemLevel = 49,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 111,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 59,
                modificationKind = "generic",
                name = "Phantom Blade",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {},
                    icon = "",
                    name = "",
                    phase = "event_start",
                    skillBonuses = {},
                    statBonuses = {
                        {
                            operation = "flat",
                            statRef = "f82db71a:u7b49vs9",
                            value = 60
                        }
                    },
                    unlockLevel = 1
                },
                consumableType = "enhancement",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_stone_sharpeningstone_05.blp",
                id = "speqlqeq",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "consumable",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 20,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Dense Sharpening Stone",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {},
                    icon = "",
                    name = "",
                    phase = "event_start",
                    skillBonuses = {},
                    statBonuses = {
                        {
                            operation = "flat",
                            statRef = "f82db71a:u7b49vs9",
                            value = 60
                        }
                    },
                    unlockLevel = 1
                },
                consumableType = "enhancement",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_stone_weightstone_05.blp",
                id = "5qbru4im",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "consumable",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 20,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Dense Weightstone",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 45,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_plate08.blp",
                id = "ssgofy9r",
                isTwoHanded = false,
                itemLevel = 50,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Thorium Armor",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 480
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 8
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 8
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 8
                    },
                    {
                        sourceStatRef = "f82db71a:954yunb9",
                        value = 8
                    },
                    {
                        sourceStatRef = "f82db71a:itpo751d",
                        value = 8
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 45,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_belt_30.blp",
                id = "1emq5i46",
                isTwoHanded = false,
                itemLevel = 50,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Thorium Belt",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 270
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:954yunb9",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:itpo751d",
                        value = 6
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 44,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 80,
                            combatEventId = "on_auto_attack_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:3ku0dihj",
                                    basePower = 0,
                                    duration = 10,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_other"
                        },
                        {
                            chance = 40,
                            combatEventId = "on_melee_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:3ku0dihj",
                                    basePower = 0,
                                    duration = 10,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_other"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_spear_07.blp",
                id = "9gxl3cdw",
                isTwoHanded = true,
                itemLevel = 50,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 141,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 93,
                modificationKind = "generic",
                name = "Blight",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:25s5wyry",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 46,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_bracer_13.blp",
                id = "foxaurkf",
                isTwoHanded = false,
                itemLevel = 51,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Thorium Bracers",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 214
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:954yunb9",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:itpo751d",
                        value = 5
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 46,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_weapon_shortblade_14.blp",
                id = "2wc54pn0",
                isTwoHanded = false,
                itemLevel = 51,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 59,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 32,
                modificationKind = "generic",
                name = "Ebon Shiv",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 9
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                weaponTypeRef = "f82db71a:y0dnlo8g",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
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
                        minimumValue = 47,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_mail_10.blp",
                id = "hmddllyn",
                isTwoHanded = false,
                itemLevel = 52,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Windforged Leggings",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 272
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 14
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 7
                    },
                    {
                        sourceStatRef = "f82db71a:u7b49vs9",
                        value = 20
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 14
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
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
                        minimumValue = 47,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_plate_17.blp",
                id = "t1rzn5e5",
                isTwoHanded = false,
                itemLevel = 52,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Earthforged Leggings",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 479
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 16
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 24
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 10
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
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
                        minimumValue = 47,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_axe_67.blp",
                id = "w2o8k74r",
                isTwoHanded = false,
                itemLevel = 52,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 113,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 60,
                modificationKind = "generic",
                name = "Light Skyforged Axe",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 2
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:9ni3vfas",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
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
                        minimumValue = 47,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_draenei_02.blp",
                id = "kibg02xb",
                isTwoHanded = false,
                itemLevel = 52,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 108,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 58,
                modificationKind = "generic",
                name = "Light Earthforged Blade",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 13
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
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
                        minimumValue = 47,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_hammer_21.blp",
                id = "32v5izp8",
                isTwoHanded = false,
                itemLevel = 52,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 117,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 63,
                modificationKind = "generic",
                name = "Light Emberforged Hammer",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:u7b49vs9",
                        value = 26
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:i4pivdig",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 47,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 3,
                            combatEventId = "on_melee_hit",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseHealing = 125,
                                    statScaling = {},
                                    type = "heal"
                                }
                            },
                            triggerTarget = "event_source"
                        },
                        {
                            chance = 9,
                            combatEventId = "on_auto_attack_hit",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseHealing = 125,
                                    statScaling = {},
                                    type = "heal"
                                }
                            },
                            triggerTarget = "event_source"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_19.blp",
                id = "v2evl4fo",
                isTwoHanded = true,
                itemLevel = 52,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 162,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 108,
                modificationKind = "generic",
                name = "Truesilver Champion",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 47,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 3,
                            combatEventId = "on_auto_attack_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:b302zkfw",
                                    basePower = 0,
                                    duration = 1,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_other"
                        },
                        {
                            chance = 9,
                            combatEventId = "on_melee_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:b302zkfw",
                                    basePower = 0,
                                    duration = 1,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_other"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_hammer_09.blp",
                id = "m1z9ck13",
                isTwoHanded = true,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 211,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 140,
                modificationKind = "generic",
                name = "Dark Iron Pulverizer",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:i4pivdig",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 49,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_chain_12.blp",
                id = "2sleu35z",
                isTwoHanded = false,
                itemLevel = 54,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Wildthorn Mail",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 322
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 11
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 22
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 22
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 51,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_chain_16.blp",
                id = "5tgbmo9j",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Dark Iron Mail",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 433
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 13
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 12
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 100,
                            combatEventId = "on_melee_taken",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseDamage = 60,
                                    damageSchoolRefs = {
                                        "f82db71a:v1azo4j6"
                                    },
                                    statScaling = {},
                                    type = "damage"
                                }
                            },
                            triggerTarget = "event_other"
                        },
                        {
                            chance = 100,
                            combatEventId = "on_auto_attack_taken",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseDamage = 55,
                                    damageSchoolRefs = {
                                        "f82db71a:v1azo4j6"
                                    },
                                    statScaling = {},
                                    type = "damage"
                                }
                            },
                            triggerTarget = "event_other"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "mod",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_armorkit_20.blp",
                id = "o3h5ce22",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "modification",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Thorium Shield Spike",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "shield",
                targetSlotRefs = {
                    "f82db71a:l1hvib8g"
                },
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 52,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 3,
                            combatEventId = "on_auto_attack_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:q68ch5hf",
                                    basePower = 0,
                                    duration = 3,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_other"
                        },
                        {
                            chance = 9,
                            combatEventId = "on_melee_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:q68ch5hf",
                                    basePower = 0,
                                    duration = 3,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_other"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_weapon_halberd_03.blp",
                id = "txrat1ru",
                isTwoHanded = true,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 153,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 101,
                modificationKind = "generic",
                name = "Dark Iron Sunderer",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:9ni3vfas",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 50,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_axe_05.blp",
                id = "t1wjgvya",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 100,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 53,
                modificationKind = "generic",
                name = "Dawn's Edge",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                weaponTypeRef = "f82db71a:9ni3vfas",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
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
                        minimumValue = 50,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_axe_12.blp",
                id = "lkogtqzt",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 81,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 43,
                modificationKind = "generic",
                name = "Ornate Thorium Handaxe",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 10
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:9ni3vfas",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 51,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_23.blp",
                id = "45wqzn9f",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Thorium Helm",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 434
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:954yunb9",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:itpo751d",
                        value = 10
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 51,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_plate_08.blp",
                id = "sohazja8",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Thorium Boots",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 367
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 7
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 7
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 7
                    },
                    {
                        sourceStatRef = "f82db71a:954yunb9",
                        value = 7
                    },
                    {
                        sourceStatRef = "f82db71a:itpo751d",
                        value = 7
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 53,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_09.blp",
                id = "hixe6i7c",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Dark Iron Shoulders",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 513
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 10
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 51,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 9,
                            combatEventId = "on_auto_attack_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:t7e5bu60",
                                    basePower = 0,
                                    duration = 10,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_other"
                        },
                        {
                            chance = 3,
                            combatEventId = "on_melee_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:t7e5bu60",
                                    basePower = 0,
                                    duration = 10,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_other"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_30.blp",
                id = "xv52dwvs",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 82,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 44,
                modificationKind = "generic",
                name = "Blazing Rapier",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 51,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_weapon_halberd_11.blp",
                id = "3o0e7cdk",
                isTwoHanded = true,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 172,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 114,
                modificationKind = "generic",
                name = "Huge Thorium Battleaxe",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {
                    {
                        skillRef = "f82db71a:jeeso2wd",
                        value = 3
                    }
                },
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 2
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:9ni3vfas",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 51,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_hammer_05.blp",
                id = "i3fy0hpi",
                isTwoHanded = true,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 150,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 100,
                modificationKind = "generic",
                name = "Enchanted Battlehammer",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:tcn0s8kx",
                        value = 2
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 2
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:i4pivdig",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
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
                        minimumValue = 54,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_plate08.blp",
                id = "7tqwv2h0",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Dark Iron Plate",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 817
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 19
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 53,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_20.blp",
                id = "rf8zblfk",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Dawnbringer Shoulders",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 455
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 15
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 44
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 53,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_belt_16.blp",
                id = "l5lf2i61",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Heavy Timbermaw Belt",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 193
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 9
                    },
                    {
                        sourceStatRef = "f82db71a:u7b49vs9",
                        value = 42
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 53,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_belt_11.blp",
                id = "8pjjbq20",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Girdle of the Dawn",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 341
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 9
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 21
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 53,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 100,
                            combatEventId = "on_melee_hit",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseDamage = 40,
                                    damageSchoolRefs = {
                                        "f82db71a:esjguw6d"
                                    },
                                    statScaling = {},
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
                                    baseDamage = 40,
                                    damageSchoolRefs = {
                                        "f82db71a:esjguw6d"
                                    },
                                    statScaling = {},
                                    type = "damage"
                                }
                            },
                            triggerTarget = "event_other"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_03.blp",
                id = "44j20j6y",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Fiery Plate Gauntlets",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 379
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 10
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 53,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 9,
                            combatEventId = "on_auto_attack_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:qbdf82lc",
                                    basePower = 0,
                                    duration = 3,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_other"
                        },
                        {
                            chance = 3,
                            combatEventId = "on_melee_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:qbdf82lc",
                                    basePower = 0,
                                    duration = 3,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_other"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_hammer_06.blp",
                id = "6308fgwh",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 113,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 60,
                modificationKind = "generic",
                name = "Volcanic Hammer",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:i4pivdig",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
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
                        minimumValue = 53,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_07.blp",
                id = "q5u2p8yf",
                isTwoHanded = true,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 179,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 119,
                modificationKind = "generic",
                name = "Corruption",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {
                    {
                        skillRef = "f82db71a:jeeso2wd",
                        value = 3
                    }
                },
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 30
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 30
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = -40
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 54,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 100,
                            combatEventId = "on_melee_hit",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseDamage = 30,
                                    damageSchoolRefs = {
                                        "f82db71a:qtr10qyj"
                                    },
                                    statScaling = {},
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
                                    baseDamage = 30,
                                    damageSchoolRefs = {
                                        "f82db71a:qtr10qyj"
                                    },
                                    statScaling = {},
                                    type = "damage"
                                }
                            },
                            triggerTarget = "event_other"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_30.blp",
                id = "k4xav5wd",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Storm Gauntlets",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 218
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 7
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 16
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 16
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 54,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_belt_13.blp",
                id = "kb1ljv4c",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Fiery Chain Girdle",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 245
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 9
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 8
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 24
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 54,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
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
                id = "1e2dayyu",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Dark Iron Bracers",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 436
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 7
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 18
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
                canSell = true,
                canStack = true,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {},
                    icon = "",
                    name = "",
                    phase = "event_start",
                    skillBonuses = {},
                    statBonuses = {
                        {
                            operation = "flat",
                            statRef = "f82db71a:jslmczbi",
                            value = 2
                        }
                    },
                    unlockLevel = 1
                },
                consumableType = "enhancement",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_stone_02.blp",
                id = "wus2dp8n",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "consumable",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 20,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Elemental Sharpening Stone",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {},
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 55,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_04.blp",
                id = "wkm2lyl7",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Thorium Leggings",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 499
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:954yunb9",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:itpo751d",
                        value = 10
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 55,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_13.blp",
                id = "5rtbdx5b",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Whitesoul Helm",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 629
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 15
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 15
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 35
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 12
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 55,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_04.blp",
                id = "58g10o8n",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Dark Iron Leggings",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 863
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 14
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 30
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 55,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_04.blp",
                id = "3vcoyfp4",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Titanic Leggings",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 683
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 30
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 2
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 2
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 55,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_weapon_shortblade_26.blp",
                id = "aieu8td6",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 92,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 49,
                modificationKind = "generic",
                name = "Enchanted Thorium Blades",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:v2rs9cpy",
                        value = 10
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:q8ve6n6t"
                },
                weaponTypeRef = "f82db71a:we5ul4ne",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 56,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_36.blp",
                id = "qvczjily",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Lionheart Helm",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 645
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 18
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 2
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 2
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 57,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_30.blp",
                id = "xbn1r8tg",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Stronghold Gauntlets",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 504
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12
                    },
                    {
                        sourceStatRef = "f82db71a:tcn0s8kx",
                        value = 2
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 2
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 58,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_10.blp",
                id = "dju4r2mj",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkrune Helm",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 534
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12
                    },
                    {
                        sourceStatRef = "f82db71a:itpo751d",
                        value = 25
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 57,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_02.blp",
                id = "ldfq8j9c",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Enchanted Thorium Helm",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 526
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 25
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 12
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 13
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 57,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
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
                id = "objdbnrr",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Fiery Chain Shoulders",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 341
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 14
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 25
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 58,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_plate10.blp",
                id = "emqbmk5g",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Enchanted Thorium Breastplate",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 657
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 26
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 12
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 13
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 58,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_plate06.blp",
                id = "3k11jbcy",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkrune Breastplate",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 657
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 14
                    },
                    {
                        sourceStatRef = "f82db71a:itpo751d",
                        value = 25
                    },
                    {
                        sourceStatRef = "f82db71a:o6113cir",
                        value = 1
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 58,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_04.blp",
                id = "qu0vkjyp",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Enchanted Thorium Leggings",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 575
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 21
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 20
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 12
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 58,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_27.blp",
                id = "0ei4gv14",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darkrune Gauntlets",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 410
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 8
                    },
                    {
                        sourceStatRef = "f82db71a:itpo751d",
                        value = 20
                    },
                    {
                        sourceStatRef = "f82db71a:p8syz5ba",
                        value = 1
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 58,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_17.blp",
                id = "uzxq31hq",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 92,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 49,
                modificationKind = "generic",
                name = "Heartseeker",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 4
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                weaponTypeRef = "f82db71a:y0dnlo8g",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 58,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_axe_09.blp",
                id = "8qkr89o4",
                isTwoHanded = true,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 256,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 153,
                modificationKind = "generic",
                name = "Arcanite Reaper",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 13
                    },
                    {
                        sourceStatRef = "f82db71a:u7b49vs9",
                        value = 62
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:9ni3vfas",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 58,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 9,
                            combatEventId = "on_auto_attack_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:vonnsice",
                                    basePower = 0,
                                    duration = 5,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_source"
                        },
                        {
                            chance = 3,
                            combatEventId = "on_melee_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:vonnsice",
                                    basePower = 0,
                                    duration = 5,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_source"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_39.blp",
                id = "oiw5pyea",
                isTwoHanded = true,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 194,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 129,
                modificationKind = "generic",
                name = "Arcanite Champion",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 58,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 9,
                            combatEventId = "on_auto_attack_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:w6r8sctw",
                                    basePower = 0,
                                    duration = 5,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_source"
                        },
                        {
                            chance = 3,
                            combatEventId = "on_melee_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:w6r8sctw",
                                    basePower = 0,
                                    duration = 5,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_source"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_hammer_09.blp",
                id = "ubltkvfl",
                isTwoHanded = true,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 246,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 163,
                modificationKind = "generic",
                name = "Hammer of the Titans",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 15
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:i4pivdig",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 58,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 80,
                            combatEventId = "on_auto_attack_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:52qk3wyd",
                                    basePower = 0,
                                    duration = 5,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_source"
                        },
                        {
                            chance = 40,
                            combatEventId = "on_melee_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:52qk3wyd",
                                    basePower = 0,
                                    duration = 5,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_source"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_axe_12.blp",
                id = "sr0gfxld",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 92,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 49,
                modificationKind = "generic",
                name = "Annihilator",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:9ni3vfas",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 58,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_hammer_08.blp",
                id = "c2e0gqt2",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 161,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 86,
                modificationKind = "generic",
                name = "Persuader",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:i4pivdig",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 58,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 9,
                            combatEventId = "on_auto_attack_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:ddtdgrqi",
                                    basePower = 0,
                                    duration = 5,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_source"
                        },
                        {
                            chance = 3,
                            combatEventId = "on_melee_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:ddtdgrqi",
                                    basePower = 0,
                                    duration = 5,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_source"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_11.blp",
                id = "cn7ppx1l",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 124,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 66,
                modificationKind = "generic",
                name = "Frostguard",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 59,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_chain_10.blp",
                id = "dis60p68",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Heavy Timbermaw Boots",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 258
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 23
                    },
                    {
                        sourceStatRef = "f82db71a:u7b49vs9",
                        value = 20
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 59,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_29.blp",
                id = "2ck5q11k",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Gloves of the Dawn",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 417
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 23
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 59,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_51.blp",
                id = "sp17wnlk",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 100,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 49,
                modificationKind = "generic",
                name = "Sageblade",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 14
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:v2g0tw0o",
                        value = 1
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 20
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 20
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_15.blp",
                id = "v13n72tk",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodsoul Shoulders",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 286
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 24
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_shoulder_01.blp",
                id = "031xwjd6",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darksoul Shoulders",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 507
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 24
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:66i80qm1"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_chain_14.blp",
                id = "0kn4xk2l",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodsoul Breastplate",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 381
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 13
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 9
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 2
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_plate08.blp",
                id = "fkpc6s0o",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darksoul Breastplate",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 736
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 32
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_pants_plate_21.blp",
                id = "2pjh04pf",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Darksoul Leggings",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 722
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 22
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 2
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_31.blp",
                id = "ykq1a4jv",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bloodsoul Gauntlets",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 381
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 17
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 1
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_axe_12.blp",
                id = "ikj9jawz",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 134,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 71,
                modificationKind = "generic",
                name = "Dark Iron Destroyer",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 6
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:9ni3vfas",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_48.blp",
                id = "g3hsjfqw",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 134,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 71,
                modificationKind = "generic",
                name = "Dark Iron Reaver",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 6
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_helmet_22.blp",
                id = "24bjwmah",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Dark Iron Helm",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 845
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 20
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 35
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_spear_08.blp",
                id = "6rfc7i6h",
                isTwoHanded = true,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 158,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 105,
                modificationKind = "generic",
                name = "Blackfury",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 35
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 15
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 10
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:25s5wyry",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_plate07.blp",
                id = "ytlkngbc",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Ironvine Breastplate",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 726
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 15
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 30
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 10
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_belt_21.blp",
                id = "eib0cvip",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Ironvine Belt",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 726
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 12
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 15
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 5
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_boots_chain_08.blp",
                id = "dcl6258y",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Dark Iron Boots",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 741
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 16
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 28
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_22.blp",
                id = "lpdpfbda",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Dark Iron Gauntlets",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 741
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 12
                    },
                    {
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 28
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 15
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_29.blp",
                id = "yl92l79e",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Ironvine Gloves",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 454
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:pg0ytacb",
                        value = 20
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 5
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_39.blp",
                id = "a2pb1qhp",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 121,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 65,
                modificationKind = "generic",
                name = "Blackguard",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 9
                    },
                    {
                        sourceStatRef = "f82db71a:tcn0s8kx",
                        value = 2
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 3,
                            combatEventId = "on_melee_hit",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseDamage = 200,
                                    damageSchoolRefs = {
                                        "f82db71a:1ggt4t3v"
                                    },
                                    statScaling = {},
                                    type = "damage"
                                }
                            },
                            triggerTarget = "event_other"
                        },
                        {
                            chance = 9,
                            combatEventId = "on_auto_attack_hit",
                            effects = {
                                {
                                    amountMode = "flat",
                                    baseDamage = 200,
                                    damageSchoolRefs = {
                                        "f82db71a:1ggt4t3v"
                                    },
                                    statScaling = {},
                                    type = "damage"
                                }
                            },
                            triggerTarget = "event_other"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_hammer_19.blp",
                id = "3b5fjgnc",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 168,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 90,
                modificationKind = "generic",
                name = "Ebon Hand",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 9
                    },
                    {
                        sourceStatRef = "f82db71a:tcn0s8kx",
                        value = 2
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                weaponTypeRef = "f82db71a:i4pivdig",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "mail",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 0,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                equipmentTrait = {
                    automaticAuras = {},
                    category = "",
                    conditions = {},
                    description = "",
                    events = {
                        {
                            chance = 80,
                            combatEventId = "on_auto_attack_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:xsxl9wyg",
                                    basePower = 0,
                                    duration = 1,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_other"
                        },
                        {
                            chance = 40,
                            combatEventId = "on_auto_attack_hit",
                            effects = {
                                {
                                    auraRef = "61fdf3df:xsxl9wyg",
                                    basePower = 0,
                                    duration = 1,
                                    stacks = 1,
                                    type = "apply_aura"
                                }
                            },
                            triggerTarget = "event_other"
                        }
                    },
                    icon = "",
                    name = "",
                    skillBonuses = {},
                    statBonuses = {},
                    unlockLevel = 1
                },
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_axe_12.blp",
                id = "kfusej8c",
                isTwoHanded = true,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 282,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 187,
                modificationKind = "generic",
                name = "Nightfall",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:9ni3vfas",
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_chest_chain_11.blp",
                id = "r41xfk05",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Icebane Breastplate",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 1027
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 12
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 42
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 24
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 12
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
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
                id = "hjmxq16x",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Icebane Bracers",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 449
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 24
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 13
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 7
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "plate",
                bindingFlag = "bind_on_equip",
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
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_gauntlets_28.blp",
                id = "rwohpfqh",
                isTwoHanded = false,
                itemLevel = 60,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {
                    mod = 1
                },
                maxModificationCounts = {
                    mod = 1
                },
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Icebane Gauntlets",
                prismaticSockets = 0,
                quality = "epic",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 642
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 9
                    },
                    {
                        sourceStatRef = "f82db71a:jjn0my8k",
                        value = 32
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 18
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 8
                    }
                },
                tags = {
                    "bs20"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = true,
                canDisenchant = false,
                icon = "interface/icons/inv_ingot_02.blp",
                id = "nntycdj5",
                itemLevel = 10,
                itemType = "material",
                maxStackSize = 20,
                name = "Copper Bar",
                quality = "common"
            }
        },
        loot = {},
        mounts = {},
        name = "Blacksmithing",
        pets = {},
        races = {},
        recipes = {
            {
                category = "",
                description = "",
                id = "3ixh3i7m",
                inputs = {
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 18
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:mr1cbt76",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Imperial Plate Helm",
                output = {
                    itemRef = "61fdf3df:yuzinwkc",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 295,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 147575
            },
            {
                category = "",
                description = "",
                id = "gf8aqza5",
                inputs = {
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "538a54a0:4gnkyr9f",
                        kind = "rpe_item",
                        quantity = 6
                    }
                },
                learnMode = "trainer",
                name = "Imperial Plate Shoulders",
                output = {
                    itemRef = "61fdf3df:9c20ak9e",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 265,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 119855
            },
            {
                category = "",
                description = "",
                id = "9b50gvww",
                inputs = {
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "538a54a0:4gnkyr9f",
                        kind = "rpe_item",
                        quantity = 6
                    }
                },
                learnMode = "trainer",
                name = "Imperial Plate Belt",
                output = {
                    itemRef = "61fdf3df:7dstz3ty",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 265,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 119855
            },
            {
                category = "",
                description = "",
                id = "a7jm2be6",
                inputs = {
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Imperial Plate Chest",
                output = {
                    itemRef = "61fdf3df:lsh6ku63",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "yl36ztnu",
                inputs = {
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 24
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Imperial Plate Leggings",
                output = {
                    itemRef = "61fdf3df:lsxtg6mf",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "f3j1wcpz",
                inputs = {
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Imperial Plate Bracers",
                output = {
                    itemRef = "61fdf3df:3gp91s7a",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 270,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 124275
            },
            {
                category = "",
                description = "",
                id = "qeejcmhc",
                inputs = {
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 18
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Imperial Plate Boots",
                output = {
                    itemRef = "61fdf3df:n7fuc0ph",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 295,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 147575
            },
            {
                category = "",
                description = "",
                id = "dsfik6sd",
                inputs = {
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Imperial Plate Gauntlets",
                output = {
                    itemRef = "61fdf3df:7cqgfruc",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 280,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 133355
            },
            {
                category = "",
                description = "",
                id = "week9uzb",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Bronze Chain Vest",
                output = {
                    itemRef = "61fdf3df:id2tqbql",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 5,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 255
            },
            {
                category = "",
                description = "",
                id = "jtkwrmok",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Bronze Chain Pants",
                output = {
                    itemRef = "61fdf3df:bg148qwn",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 10,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 515
            },
            {
                category = "",
                description = "",
                id = "6dkn787w",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 8
                    }
                },
                learnMode = "trainer",
                name = "Bronze Chain Boots",
                output = {
                    itemRef = "61fdf3df:9cfkn6qj",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 20,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 1275
            },
            {
                category = "",
                description = "",
                id = "2p9zihbg",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 6
                    }
                },
                learnMode = "trainer",
                name = "Bronze Chain Belt",
                output = {
                    itemRef = "61fdf3df:fs47rswm",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 35,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 3015
            },
            {
                category = "",
                description = "",
                id = "03bp3y0n",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "7259f1d3:4ml43y0u",
                        kind = "rpe_item",
                        quantity = 3
                    }
                },
                learnMode = "trainer",
                name = "Runed Bronze Pants",
                output = {
                    itemRef = "61fdf3df:7f2ixi08",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 45,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 4575
            },
            {
                category = "",
                description = "",
                id = "4zw9e13y",
                inputs = {
                    {
                        itemRef = "61fdf3df:c7urqe23",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "always_learned",
                name = "Rough Sharpening Stone",
                output = {
                    itemRef = "61fdf3df:op5en83c",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 1,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 104
            },
            {
                category = "",
                description = "",
                id = "75ggoqs3",
                inputs = {
                    {
                        itemRef = "61fdf3df:c7urqe23",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "7259f1d3:agzskvec",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "always_learned",
                name = "Rough Weightstone",
                output = {
                    itemRef = "61fdf3df:iw2fp34l",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 1,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 104
            },
            {
                category = "",
                description = "",
                id = "eoif6as4",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "61fdf3df:c7urqe23",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:fcj318z0",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "538a54a0:sm9q37oi",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Bronze Battle Axe",
                output = {
                    itemRef = "61fdf3df:8fp9w74u",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 40,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 3755
            },
            {
                category = "",
                description = "",
                id = "v1vzzfsk",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "61fdf3df:c7urqe23",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:n2q67aox",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Heavy Bronze Longsword",
                output = {
                    itemRef = "61fdf3df:w2s2cutb",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 30,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 2355
            },
            {
                category = "",
                description = "",
                id = "e55vdo7y",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "4999dcec:fcj318z0",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:n2q67aox",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Gemmed Bronze Gauntlets",
                output = {
                    itemRef = "61fdf3df:ag5ampla",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 60,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 7515
            },
            {
                category = "",
                description = "",
                id = "4ybfj0ge",
                inputs = {
                    {
                        itemRef = "61fdf3df:qcah9yrg",
                        kind = "rpe_item",
                        quantity = 3
                    }
                },
                learnMode = "trainer",
                name = "Coarse Sharpening Stone",
                output = {
                    itemRef = "61fdf3df:30qv0a2x",
                    maxQuantity = 65,
                    minQuantity = 65
                },
                reagents = {},
                requiredSkillLevel = 50,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 5475
            },
            {
                category = "",
                description = "",
                id = "ppjfovm1",
                inputs = {
                    {
                        itemRef = "61fdf3df:qcah9yrg",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "7259f1d3:1wssn0qp",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Coarse Weightstone",
                output = {
                    itemRef = "61fdf3df:sbhu57ga",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 55,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 6455
            },
            {
                category = "",
                description = "",
                id = "lpg31rf1",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "538a54a0:sm9q37oi",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Heavy Bronze Maul",
                output = {
                    itemRef = "61fdf3df:yh4qvi2o",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 65,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 8655
            },
            {
                category = "",
                description = "",
                id = "ep3ohmcx",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "538a54a0:sm9q37oi",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:nvc1anz9",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:c7urqe23",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Thick War Axe",
                output = {
                    itemRef = "61fdf3df:lbpcwlrf",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 70,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 9875
            },
            {
                category = "",
                description = "",
                id = "5rjx4xig",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 10
                    }
                },
                learnMode = "trainer",
                name = "Runed Copper Belt",
                output = {
                    itemRef = "61fdf3df:40tnm7x9",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 75,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 11175
            },
            {
                category = "",
                description = "",
                id = "o3m1ppkn",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "4999dcec:l3c8nzh7",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:c7urqe23",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Runed Copper Breastplate",
                output = {
                    itemRef = "61fdf3df:rv4hqt7k",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 80,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 12555
            },
            {
                category = "",
                description = "",
                id = "o84xpwjs",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "61fdf3df:c7urqe23",
                        kind = "rpe_item",
                        quantity = 3
                    }
                },
                learnMode = "trainer",
                name = "Runed Copper Bracers",
                output = {
                    itemRef = "61fdf3df:9bq41la7",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 85,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 14015
            },
            {
                category = "",
                description = "",
                id = "lfk582ak",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:c7urqe23",
                        kind = "rpe_item",
                        quantity = 6
                    }
                },
                learnMode = "trainer",
                name = "Rough Bronze Boots",
                output = {
                    itemRef = "61fdf3df:raj0rzpg",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 90,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 15555
            },
            {
                category = "",
                description = "",
                id = "we6fdupf",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 14
                    },
                    {
                        itemRef = "538a54a0:84y6qzsn",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:n2q67aox",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Heavy Bronze Broadsword",
                output = {
                    itemRef = "61fdf3df:c3o79n21",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 95,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 17175
            },
            {
                category = "",
                description = "",
                id = "bzd28cg5",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "538a54a0:84y6qzsn",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:c7urqe23",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Thick Bronze Darts",
                output = {
                    itemRef = "61fdf3df:4smyd6ly",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 100,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 18875
            },
            {
                category = "",
                description = "",
                id = "57retyzd",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "4999dcec:n2q67aox",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:c7urqe23",
                        kind = "rpe_item",
                        quantity = 3
                    }
                },
                learnMode = "trainer",
                name = "Ironforge Breastplate",
                output = {
                    itemRef = "61fdf3df:gwq05kni",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 100,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 18875
            },
            {
                category = "",
                description = "",
                id = "02i1fcbe",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "4999dcec:n2q67aox",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:c7urqe23",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "538a54a0:84y6qzsn",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Big Bronze Knife",
                output = {
                    itemRef = "61fdf3df:lgdn8ym2",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 105,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 20655
            },
            {
                category = "",
                description = "",
                id = "o05v5jsx",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 6
                    }
                },
                learnMode = "trainer",
                name = "Rough Bronze Leggings",
                output = {
                    itemRef = "61fdf3df:np2eb1gq",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 105,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 20655
            },
            {
                category = "",
                description = "",
                id = "crjtukvb",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 8
                    }
                },
                learnMode = "trainer",
                name = "Rough Bronze Curiass",
                output = {
                    itemRef = "61fdf3df:uo0hunwt",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 105,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 20655
            },
            {
                category = "",
                description = "",
                id = "lahifh1d",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:c7urqe23",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 5
                    }
                },
                learnMode = "trainer",
                name = "Rough Bronze Shoulders",
                output = {
                    itemRef = "61fdf3df:kg9aep85",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 110,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 22515
            },
            {
                category = "",
                description = "",
                id = "8slb34ft",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:c7urqe23",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "4999dcec:s9lu5jap",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Pearl-handled Dagger",
                output = {
                    itemRef = "61fdf3df:d83dlv7u",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 115,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 24455
            },
            {
                category = "",
                description = "",
                id = "cbqkhwmd",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:c7urqe23",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 5
                    }
                },
                learnMode = "trainer",
                name = "Patterned Bronze Bracers",
                output = {
                    itemRef = "61fdf3df:jg3tuoxe",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 120,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 26475
            },
            {
                category = "",
                description = "",
                id = "19qwqpji",
                inputs = {
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 3
                    }
                },
                learnMode = "trainer",
                name = "Heavy Sharpening Stone",
                output = {
                    itemRef = "61fdf3df:zdoehl40",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 125,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 28575
            },
            {
                category = "",
                description = "",
                id = "if5aaco7",
                inputs = {
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "7259f1d3:jt6ktqiu",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Heavy Weightstone",
                output = {
                    itemRef = "61fdf3df:7ovx0a64",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 125,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 28575
            },
            {
                category = "",
                description = "",
                id = "92djebjn",
                inputs = {
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "61fdf3df:nvc1anz9",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:qcah9yrg",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Silvered Bronze Shoulders",
                output = {
                    itemRef = "61fdf3df:3ekhevbe",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 125,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 28575
            },
            {
                category = "",
                description = "",
                id = "rdmbg58y",
                inputs = {
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "61fdf3df:nvc1anz9",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:qcah9yrg",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Silvered Bronze Breastplate",
                output = {
                    itemRef = "61fdf3df:qcfxifb8",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 130,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 30755
            },
            {
                category = "",
                description = "",
                id = "u5kwzicm",
                inputs = {
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:nvc1anz9",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:qcah9yrg",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Silvered Bronze Boots",
                output = {
                    itemRef = "61fdf3df:orqaw603",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 130,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 30755
            },
            {
                category = "",
                description = "",
                id = "doq8llpd",
                inputs = {
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "4999dcec:l3c8nzh7",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:qcah9yrg",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "538a54a0:84y6qzsn",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Deadly Bronze Poinard",
                output = {
                    itemRef = "61fdf3df:c4frv7vq",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 125,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 28575
            },
            {
                category = "",
                description = "",
                id = "6my9ynv0",
                inputs = {
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "4999dcec:l3c8nzh7",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:qcah9yrg",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "538a54a0:84y6qzsn",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:gw6wflop",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Heavy Bronze Mace",
                output = {
                    itemRef = "61fdf3df:p0wjao14",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 130,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 30755
            },
            {
                category = "",
                description = "",
                id = "auq6ogzn",
                inputs = {
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "61fdf3df:nvc1anz9",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:qcah9yrg",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Silvered Bronze Gauntlets",
                output = {
                    itemRef = "61fdf3df:6xws2b6w",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 135,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 33015
            },
            {
                category = "",
                description = "",
                id = "m7cn44nq",
                inputs = {
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "61fdf3df:qcah9yrg",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "538a54a0:84y6qzsn",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:ms6y0fi0",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Iridescent Hammer",
                output = {
                    itemRef = "61fdf3df:jmbdhlih",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 140,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 35355
            },
            {
                category = "",
                description = "",
                id = "9254de80",
                inputs = {
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "61fdf3df:nvc1anz9",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "4999dcec:gw6wflop",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:w1ryslhj",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:ms6y0fi0",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Shining Silver Breastplate",
                output = {
                    itemRef = "61fdf3df:vgyjt86n",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 145,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 37775
            },
            {
                category = "",
                description = "",
                id = "rbqabcu5",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:qcah9yrg",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "7259f1d3:m3m72ds8",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Green Steel Boots",
                output = {
                    itemRef = "61fdf3df:cgh5tv7w",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 145,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 37775
            },
            {
                category = "",
                description = "",
                id = "2sb98cu5",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:qcah9yrg",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "538a54a0:84y6qzsn",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:w1ryslhj",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Mighty Steel Hammer",
                output = {
                    itemRef = "61fdf3df:si0uloh3",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 145,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 37775
            },
            {
                category = "",
                description = "",
                id = "pssfnkyr",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:qcah9yrg",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Iron Shield Spike",
                output = {
                    itemRef = "61fdf3df:drrm1215",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 150,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 40275
            },
            {
                category = "",
                description = "",
                id = "yfj1paqi",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:qcah9yrg",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:s9lu5jap",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "7259f1d3:m3m72ds8",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Green Steel Gauntlets",
                output = {
                    itemRef = "61fdf3df:y7ct6ztr",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 150,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 40275
            },
            {
                category = "",
                description = "",
                id = "d8kd03uu",
                inputs = {
                    {
                        itemRef = "61fdf3df:qcah9yrg",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "61fdf3df:nvc1anz9",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Silvered Bronze Leggings",
                output = {
                    itemRef = "61fdf3df:606sogr2",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 155,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 42855
            },
            {
                category = "",
                description = "",
                id = "91ziujoo",
                inputs = {
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "7259f1d3:m3m72ds8",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Green Steel Leggings",
                output = {
                    itemRef = "61fdf3df:zjpw1cnm",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 155,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 42855
            },
            {
                category = "",
                description = "",
                id = "kha9ulj2",
                inputs = {
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "538a54a0:55k8gjup",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:nvc1anz9",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Solid Iron Maul",
                output = {
                    itemRef = "61fdf3df:eiuaqmbm",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 155,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 42855
            },
            {
                category = "",
                description = "",
                id = "fcvnltje",
                inputs = {
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 7
                    },
                    {
                        itemRef = "7259f1d3:m3m72ds8",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Green Steel Shoulders",
                output = {
                    itemRef = "61fdf3df:t2ytpwde",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 160,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 45515
            },
            {
                category = "",
                description = "",
                id = "gqde64p7",
                inputs = {
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Barbaric Steel Shoulders",
                output = {
                    itemRef = "61fdf3df:t5hzhzlo",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 160,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 45515
            },
            {
                category = "",
                description = "",
                id = "lpzztjk1",
                inputs = {
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Barbaric Steel Chestplate",
                output = {
                    itemRef = "61fdf3df:cksgzwog",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 160,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 45515
            },
            {
                category = "",
                description = "",
                id = "hpqa113o",
                inputs = {
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "4999dcec:w1ryslhj",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "538a54a0:55k8gjup",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Hardened Steel Shortsword",
                output = {
                    itemRef = "61fdf3df:ny43jsvb",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 160,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 45515
            },
            {
                category = "",
                description = "",
                id = "gbjb9ax2",
                inputs = {
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "4999dcec:w1ryslhj",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Iron Counterweight",
                output = {
                    itemRef = "61fdf3df:c91tdk98",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 165,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 48255
            },
            {
                category = "",
                description = "",
                id = "0kwn49gw",
                inputs = {
                    {
                        itemRef = "7259f1d3:m3m72ds8",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "4999dcec:ht59o8mx",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Green Steel Helmet",
                output = {
                    itemRef = "61fdf3df:vqfe7ri4",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 170,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 51075
            },
            {
                category = "",
                description = "",
                id = "sqqwxrug",
                inputs = {
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "61fdf3df:hqook9xe",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Green Steel Leggings",
                output = {
                    itemRef = "61fdf3df:zjpw1cnm",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 170,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 51075
            },
            {
                category = "",
                description = "",
                id = "uj7d29cq",
                inputs = {
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "4999dcec:w1ryslhj",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "538a54a0:55k8gjup",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:hqook9xe",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Golden Steel Destroyer",
                output = {
                    itemRef = "61fdf3df:8wv368lv",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 170,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 51075
            },
            {
                category = "",
                description = "",
                id = "g70vme9v",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 14
                    },
                    {
                        itemRef = "538a54a0:55k8gjup",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Barbaric Steel Helm",
                output = {
                    itemRef = "61fdf3df:0s4n0m2j",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 175,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 53975
            },
            {
                category = "",
                description = "",
                id = "wk8o56xf",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:hqook9xe",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Golden Scale Shoulders",
                output = {
                    itemRef = "61fdf3df:73nd7h4h",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 175,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 53975
            },
            {
                category = "",
                description = "",
                id = "usf3ghxf",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "538a54a0:55k8gjup",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:qgjc3m5m",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Jade Serpentblade",
                output = {
                    itemRef = "61fdf3df:byxtguye",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 175,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 53975
            },
            {
                category = "",
                description = "",
                id = "61848np1",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "4999dcec:gw6wflop",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "4999dcec:qgjc3m5m",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Green Steel Hauberk",
                output = {
                    itemRef = "61fdf3df:xvi0gf16",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 180,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 56955
            },
            {
                category = "",
                description = "",
                id = "hwa2dznm",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "538a54a0:55k8gjup",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Barbaric Steel Boots",
                output = {
                    itemRef = "61fdf3df:5eujrwfi",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 180,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 56955
            },
            {
                category = "",
                description = "",
                id = "2p5qtzqk",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "4999dcec:gw6wflop",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "538a54a0:55k8gjup",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "732368d4:ku9j8vhw",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Glinting Steel Dagger",
                output = {
                    itemRef = "61fdf3df:5bh3c0m6",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 180,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 56955
            },
            {
                category = "",
                description = "",
                id = "wfhpq8ap",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "4999dcec:w1ryslhj",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "538a54a0:55k8gjup",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Moonsteel Broadsword",
                output = {
                    itemRef = "61fdf3df:tyw2yswi",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 180,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 56955
            },
            {
                category = "",
                description = "",
                id = "m5uaovlo",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "4999dcec:ht59o8mx",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:w1ryslhj",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Polished Steel Boots",
                output = {
                    itemRef = "61fdf3df:03moyy1v",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 185,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 60015
            },
            {
                category = "",
                description = "",
                id = "sd0ov22g",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 14
                    },
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Barbaric Steel Gloves",
                output = {
                    itemRef = "61fdf3df:o95sn68u",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 185,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 60015
            },
            {
                category = "",
                description = "",
                id = "ail3rgpe",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 14
                    },
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "538a54a0:55k8gjup",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "61fdf3df:hqook9xe",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Massive Steel Axe",
                output = {
                    itemRef = "61fdf3df:9u2dm9bm",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 185,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 60015
            },
            {
                category = "",
                description = "",
                id = "85brhx0x",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "538a54a0:55k8gjup",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Steel Weapon Chain",
                output = {
                    itemRef = "61fdf3df:wpb8yq2y",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 190,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 63155
            },
            {
                category = "",
                description = "",
                id = "54v35wmc",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:hqook9xe",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Golden Scale Coif",
                output = {
                    itemRef = "61fdf3df:xyqeiyd9",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 190,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 63155
            },
            {
                category = "",
                description = "",
                id = "1y4d1g1k",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "538a54a0:55k8gjup",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "732368d4:vlwvpmfx",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "732368d4:2616xh4v",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Edge of Winter",
                output = {
                    itemRef = "61fdf3df:ibzdwels",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 190,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 63155
            },
            {
                category = "",
                description = "",
                id = "kf4mwqr1",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:hqook9xe",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Golden Scale Curiass",
                output = {
                    itemRef = "61fdf3df:eugizgo2",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 195,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 66375
            },
            {
                category = "",
                description = "",
                id = "mwluwrty",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "538a54a0:55k8gjup",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "732368d4:sclalidn",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:hqook9xe",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Searing Golden Blade",
                output = {
                    itemRef = "61fdf3df:n3r95yhf",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 190,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 63155
            },
            {
                category = "",
                description = "",
                id = "61ym9h85",
                inputs = {
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 3
                    }
                },
                learnMode = "trainer",
                name = "Solid Sharpening Stone",
                output = {
                    itemRef = "61fdf3df:chvq05c4",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 200,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 69675
            },
            {
                category = "",
                description = "",
                id = "qmjriu61",
                inputs = {
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "7259f1d3:jt6ktqiu",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Solid Weightstone",
                output = {
                    itemRef = "61fdf3df:bpzrl6bz",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 200,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 69675
            },
            {
                category = "",
                description = "",
                id = "mc8bnow3",
                inputs = {
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "538a54a0:55k8gjup",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 5
                    },
                    {
                        itemRef = "732368d4:2616xh4v",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Whirling Steel Axes",
                output = {
                    itemRef = "61fdf3df:o9lv0aod",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 200,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 69675
            },
            {
                category = "",
                description = "",
                id = "29p6soyr",
                inputs = {
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Steel Breastplate",
                output = {
                    itemRef = "61fdf3df:yc0b74rs",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 200,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 69675
            },
            {
                category = "",
                description = "",
                id = "pc7ni1yr",
                inputs = {
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "61fdf3df:hqook9xe",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Golden Scale Boots",
                output = {
                    itemRef = "61fdf3df:wn3qs2dl",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 200,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 69675
            },
            {
                category = "",
                description = "",
                id = "vixipfr8",
                inputs = {
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "4999dcec:ht59o8mx",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "538a54a0:55k8gjup",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "732368d4:xtnbjwzj",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Shadow Crescent Axe",
                output = {
                    itemRef = "61fdf3df:njvkrtvf",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 200,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 69675
            },
            {
                category = "",
                description = "",
                id = "ivzxvwzd",
                inputs = {
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "4999dcec:qgjc3m5m",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "538a54a0:55k8gjup",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "732368d4:7z1lti71",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Frost Tiger Blade",
                output = {
                    itemRef = "61fdf3df:j9vfvg5m",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 200,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 69675
            },
            {
                category = "",
                description = "",
                id = "lgsx83eb",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "538a54a0:55k8gjup",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Heavy Mithril Shoulder",
                output = {
                    itemRef = "61fdf3df:41ra4g5n",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 205,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 73055
            },
            {
                category = "",
                description = "",
                id = "ybw7sb2r",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "7259f1d3:edth2zu1",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Heavy Mithril Gauntlet",
                output = {
                    itemRef = "61fdf3df:4s7vch2u",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 205,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 73055
            },
            {
                category = "",
                description = "",
                id = "tcde6ftf",
                inputs = {
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "61fdf3df:hqook9xe",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:u8qtuhfq",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Golden Scale Gauntlets",
                output = {
                    itemRef = "61fdf3df:o1p0jx6u",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 205,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 73055
            },
            {
                category = "",
                description = "",
                id = "vi5jkvce",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Heavy Mithril Pants",
                output = {
                    itemRef = "61fdf3df:rr281vk6",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 210,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 76515
            },
            {
                category = "",
                description = "",
                id = "jejbinuq",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Mithril Scale Pants",
                output = {
                    itemRef = "61fdf3df:u49zms89",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 210,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 76515
            },
            {
                category = "",
                description = "",
                id = "0mx2dig6",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:ht59o8mx",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "538a54a0:55k8gjup",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Heavy Mithril Axe",
                output = {
                    itemRef = "61fdf3df:dnw6g52l",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 210,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 76515
            },
            {
                category = "",
                description = "",
                id = "rxp9hzaj",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Mithril Shield Spike",
                output = {
                    itemRef = "61fdf3df:gp7ft2s1",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 215,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 80055
            },
            {
                category = "",
                description = "",
                id = "kh3dtaui",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Mithril Scale Bracers",
                output = {
                    itemRef = "61fdf3df:ken7rmiw",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 215,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 80055
            },
            {
                category = "",
                description = "",
                id = "frj970v2",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Ornate Mithril Pants",
                output = {
                    itemRef = "61fdf3df:7ebhc61t",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 220,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 83675
            },
            {
                category = "",
                description = "",
                id = "6vssut4x",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "7259f1d3:edth2zu1",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Ornate Mithril Gloves",
                output = {
                    itemRef = "61fdf3df:0x0tsxhr",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 220,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 83675
            },
            {
                category = "",
                description = "",
                id = "p1vc8llf",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "4999dcec:5nrqhg0t",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "538a54a0:u0wy9jz1",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Blue Glittering Axe",
                output = {
                    itemRef = "61fdf3df:3pyjmrn1",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 220,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 83675
            },
            {
                category = "",
                description = "",
                id = "apvygm39",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "538a54a0:u0wy9jz1",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Ornate Mithril Shoulder",
                output = {
                    itemRef = "61fdf3df:e6nypjtr",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 225,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 87375
            },
            {
                category = "",
                description = "",
                id = "8j5k4iyn",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:ht59o8mx",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "4999dcec:5nrqhg0t",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Truesilver Gauntlets",
                output = {
                    itemRef = "61fdf3df:bygojy13",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 225,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 87375
            },
            {
                category = "",
                description = "",
                id = "bo3torrv",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 14
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "538a54a0:u0wy9jz1",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Wicked Mithril Blade",
                output = {
                    itemRef = "61fdf3df:dfj2fhoq",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 225,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 87375
            },
            {
                category = "",
                description = "",
                id = "ryx1b31r",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "732368d4:ku9j8vhw",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Orcish War Leggings",
                output = {
                    itemRef = "61fdf3df:i35x1al5",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 230,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 91155
            },
            {
                category = "",
                description = "",
                id = "835wiah7",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "7259f1d3:edth2zu1",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Ornate Mithril Coif",
                output = {
                    itemRef = "61fdf3df:836rxkhj",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 230,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 91155
            },
            {
                category = "",
                description = "",
                id = "5o4mrg9k",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Heavy Mithril Breastplate",
                output = {
                    itemRef = "61fdf3df:vdtmfmn8",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 230,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 91155
            },
            {
                category = "",
                description = "",
                id = "vqqa9hg1",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "4999dcec:l3c8nzh7",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "4999dcec:6b4o47go",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "538a54a0:u0wy9jz1",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Big Black Mace",
                output = {
                    itemRef = "61fdf3df:wzdlo97u",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 230,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 91155
            },
            {
                category = "",
                description = "",
                id = "t5oytdxq",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 3
                    }
                },
                learnMode = "trainer",
                name = "Mithril Spurs",
                output = {
                    itemRef = "61fdf3df:jt7tm4z1",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 235,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 95015
            },
            {
                category = "",
                description = "",
                id = "0jzgnu9x",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 14
                    },
                    {
                        itemRef = "538a54a0:u0wy9jz1",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Mithril Scale Shoulders",
                output = {
                    itemRef = "61fdf3df:m0w5ulmv",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 235,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 95015
            },
            {
                category = "",
                description = "",
                id = "2ma9ufy5",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 14
                    },
                    {
                        itemRef = "538a54a0:u0wy9jz1",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Heavy Mithril Boots",
                output = {
                    itemRef = "61fdf3df:6qw94g2f",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 235,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 95015
            },
            {
                category = "",
                description = "",
                id = "rt1g88b8",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 24
                    },
                    {
                        itemRef = "538a54a0:u0wy9jz1",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "4999dcec:qgjc3m5m",
                        kind = "rpe_item",
                        quantity = 5
                    },
                    {
                        itemRef = "4999dcec:ht59o8mx",
                        kind = "rpe_item",
                        quantity = 5
                    },
                    {
                        itemRef = "732368d4:ku9j8vhw",
                        kind = "rpe_item",
                        quantity = 5
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "The Shatterer",
                output = {
                    itemRef = "61fdf3df:p2yq2n1d",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 235,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 95015
            },
            {
                category = "",
                description = "",
                id = "41licllm",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "732368d4:sclalidn",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Ornate Mithril Breastplate",
                output = {
                    itemRef = "61fdf3df:xt3otnm9",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 240,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 98955
            },
            {
                category = "",
                description = "",
                id = "uni165vl",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 14
                    },
                    {
                        itemRef = "4999dcec:5nrqhg0t",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "7259f1d3:edth2zu1",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:gw6wflop",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:w1ryslhj",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Dazzling Mithril Rapier",
                output = {
                    itemRef = "61fdf3df:w47ofap2",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 240,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 98955
            },
            {
                category = "",
                description = "",
                id = "j9q2be7d",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 14
                    },
                    {
                        itemRef = "4999dcec:5nrqhg0t",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Heavy Mithril Helm",
                output = {
                    itemRef = "61fdf3df:j7jkiwxm",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 245,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 102975
            },
            {
                category = "",
                description = "",
                id = "1oeshhjr",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Ornate Mithril Helm",
                output = {
                    itemRef = "61fdf3df:yldu4bmt",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 245,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 102975
            },
            {
                category = "",
                description = "",
                id = "lz5khrjs",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:6b4o47go",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:mr1cbt76",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Truesilver Breastplate",
                output = {
                    itemRef = "61fdf3df:yes6wowr",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 245,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 102975
            },
            {
                category = "",
                description = "",
                id = "mt7m6x5l",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 14
                    },
                    {
                        itemRef = "4999dcec:5nrqhg0t",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "538a54a0:u0wy9jz1",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Ornate Mithril Boots",
                output = {
                    itemRef = "61fdf3df:qwbyig3d",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 245,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 102975
            },
            {
                category = "",
                description = "",
                id = "1qrn1han",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 18
                    },
                    {
                        itemRef = "538a54a0:u0wy9jz1",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "732368d4:ku9j8vhw",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Runed Mithril Hammer",
                output = {
                    itemRef = "61fdf3df:8j022vl5",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 245,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 102975
            },
            {
                category = "",
                description = "",
                id = "j0z17n7q",
                inputs = {
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 28
                    },
                    {
                        itemRef = "538a54a0:u0wy9jz1",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "732368d4:ku9j8vhw",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "4999dcec:5nrqhg0t",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "732368d4:2616xh4v",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Phantom Blade",
                output = {
                    itemRef = "61fdf3df:spclk4k7",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 245,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 102975
            },
            {
                category = "",
                description = "",
                id = "iqimicwb",
                inputs = {
                    {
                        itemRef = "61fdf3df:a4kj24o4",
                        kind = "rpe_item",
                        quantity = 3
                    }
                },
                learnMode = "trainer",
                name = "Dense Sharpening Stone",
                output = {
                    itemRef = "61fdf3df:speqlqeq",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 250,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 107075
            },
            {
                category = "",
                description = "",
                id = "0iengnmt",
                inputs = {
                    {
                        itemRef = "61fdf3df:a4kj24o4",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "7259f1d3:dx7zh3l2",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Dense Weightstone",
                output = {
                    itemRef = "61fdf3df:5qbru4im",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 250,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 107075
            },
            {
                category = "",
                description = "",
                id = "52whc7ag",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "4999dcec:sviqeucv",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Thorium Armor",
                output = {
                    itemRef = "61fdf3df:ssgofy9r",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 250,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 107075
            },
            {
                category = "",
                description = "",
                id = "msbuln19",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 12
                    }
                },
                learnMode = "trainer",
                name = "Thorium Belt",
                output = {
                    itemRef = "61fdf3df:1emq5i46",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 250,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 107075
            },
            {
                category = "",
                description = "",
                id = "ra0031oz",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 12
                    }
                },
                learnMode = "trainer",
                name = "Thorium Bracers",
                output = {
                    itemRef = "61fdf3df:foxaurkf",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 255,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 111255
            },
            {
                category = "",
                description = "",
                id = "es53ums1",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 28
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "538a54a0:u0wy9jz1",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "732368d4:xtnbjwzj",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Blight",
                output = {
                    itemRef = "61fdf3df:9gxl3cdw",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 250,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 107075
            },
            {
                category = "",
                description = "",
                id = "cjlbx8v9",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "538a54a0:u0wy9jz1",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:mr1cbt76",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Ebon Shiv",
                output = {
                    itemRef = "61fdf3df:2wc54pn0",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 255,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 111255
            },
            {
                category = "",
                description = "",
                id = "bj1joiwv",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "732368d4:2616xh4v",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Windforged Leggings",
                output = {
                    itemRef = "61fdf3df:hmddllyn",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 260,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 115515
            },
            {
                category = "",
                description = "",
                id = "rk7llb6z",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "732368d4:ku9j8vhw",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Earthforged Leggings",
                output = {
                    itemRef = "61fdf3df:t1rzn5e5",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 260,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 115515
            },
            {
                category = "",
                description = "",
                id = "ww9g3mcj",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "732368d4:2616xh4v",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Light Skyforged Axe",
                output = {
                    itemRef = "61fdf3df:w2o8k74r",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 260,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 115515
            },
            {
                category = "",
                description = "",
                id = "2my0dr2z",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "732368d4:ku9j8vhw",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Light Earthforged Blade",
                output = {
                    itemRef = "61fdf3df:kibg02xb",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 260,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 115515
            },
            {
                category = "",
                description = "",
                id = "z991tdb3",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "732368d4:sclalidn",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Light Emberforged Hammer",
                output = {
                    itemRef = "61fdf3df:32v5izp8",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 260,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 115515
            },
            {
                category = "",
                description = "",
                id = "lntikkq2",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 30
                    },
                    {
                        itemRef = "538a54a0:u0wy9jz1",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "732368d4:2616xh4v",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "4999dcec:mr1cbt76",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:o1ogtdcq",
                        kind = "rpe_item",
                        quantity = 8
                    }
                },
                learnMode = "trainer",
                name = "Truesilver Champion",
                output = {
                    itemRef = "61fdf3df:v2evl4fo",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 260,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 115515
            },
            {
                category = "",
                description = "",
                id = "h92l8c4h",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:pb24e7k5",
                        kind = "rpe_item",
                        quantity = 18
                    },
                    {
                        itemRef = "732368d4:sclalidn",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Dark Iron Pulverizer",
                output = {
                    itemRef = "61fdf3df:m1z9ck13",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 265,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 119855
            },
            {
                category = "",
                description = "",
                id = "ka4fi2fq",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:pb24e7k5",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "732368d4:sclalidn",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Dark Iron Mail",
                output = {
                    itemRef = "61fdf3df:5tgbmo9j",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 270,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 124275
            },
            {
                category = "",
                description = "",
                id = "vqm0dmdb",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 40
                    },
                    {
                        itemRef = "732368d4:lxqnh3pp",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "3eb7e9bb:2hbdmyj4",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "732368d4:4mu0nvut",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:bw8sfpgw",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Wildthorn Mail",
                output = {
                    itemRef = "61fdf3df:2sleu35z",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 270,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 124275
            },
            {
                category = "",
                description = "",
                id = "ut4nv0py",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "732368d4:tfwg197j",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:a4kj24o4",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Thorium Shield Spike",
                output = {
                    itemRef = "61fdf3df:o3h5ce22",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 275,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 128775
            },
            {
                category = "",
                description = "",
                id = "g4egtvkf",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:pb24e7k5",
                        kind = "rpe_item",
                        quantity = 26
                    },
                    {
                        itemRef = "732368d4:sclalidn",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Dark Iron Sunderer",
                output = {
                    itemRef = "61fdf3df:txrat1ru",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 275,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 128775
            },
            {
                category = "",
                description = "",
                id = "dv8wt00v",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 30
                    },
                    {
                        itemRef = "4999dcec:mr1cbt76",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "538a54a0:4gnkyr9f",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "4999dcec:sviqeucv",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:a4kj24o4",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "732368d4:4mu0nvut",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Dawn's Edge",
                output = {
                    itemRef = "61fdf3df:t1wjgvya",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 275,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 128775
            },
            {
                category = "",
                description = "",
                id = "07pajq1e",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "4999dcec:pkgfp4sl",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "538a54a0:4gnkyr9f",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:a4kj24o4",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Ornate Thorium Handaxe",
                output = {
                    itemRef = "61fdf3df:lkogtqzt",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 275,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 128775
            },
            {
                category = "",
                description = "",
                id = "69nql7pz",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 24
                    },
                    {
                        itemRef = "4999dcec:mr1cbt76",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Thorium Helm",
                output = {
                    itemRef = "61fdf3df:45wqzn9f",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 280,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 133355
            },
            {
                category = "",
                description = "",
                id = "sw2k6ce2",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "538a54a0:4gnkyr9f",
                        kind = "rpe_item",
                        quantity = 8
                    }
                },
                learnMode = "trainer",
                name = "Thorium Boots",
                output = {
                    itemRef = "61fdf3df:sohazja8",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 280,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 133355
            },
            {
                category = "",
                description = "",
                id = "72x6hp87",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "732368d4:4mu0nvut",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "4999dcec:atpvfzht",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "732368d4:50qj8dzw",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:a4kj24o4",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "732368d4:sclalidn",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Blazing Rapier",
                output = {
                    itemRef = "61fdf3df:xv52dwvs",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 280,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 133355
            },
            {
                category = "",
                description = "",
                id = "g5i9ajn2",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 40
                    },
                    {
                        itemRef = "538a54a0:4gnkyr9f",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:a4kj24o4",
                        kind = "rpe_item",
                        quantity = 6
                    }
                },
                learnMode = "trainer",
                name = "Huge Thorium Battleaxe",
                output = {
                    itemRef = "61fdf3df:3o0e7cdk",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 280,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 133355
            },
            {
                category = "",
                description = "",
                id = "2henjyxp",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "538a54a0:4gnkyr9f",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "732368d4:4mu0nvut",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "4999dcec:bw8sfpgw",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Enchanted Battlehammer",
                output = {
                    itemRef = "61fdf3df:i3fy0hpi",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 280,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 133355
            },
            {
                category = "",
                description = "",
                id = "1cvf6wjl",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:pb24e7k5",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "732368d4:sclalidn",
                        kind = "rpe_item",
                        quantity = 8
                    }
                },
                learnMode = "trainer",
                name = "Dark Iron Plate",
                output = {
                    itemRef = "61fdf3df:7tqwv2h0",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 285,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 138015
            },
            {
                category = "",
                description = "",
                id = "47swgijm",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "732368d4:7z1lti71",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "4999dcec:bw8sfpgw",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Dawnbringer Shoulders",
                output = {
                    itemRef = "61fdf3df:rf8zblfk",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 290,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 142755
            },
            {
                category = "",
                description = "",
                id = "mk6oj0w8",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "732368d4:tfwg197j",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "732368d4:lxqnh3pp",
                        kind = "rpe_item",
                        quantity = 3
                    }
                },
                learnMode = "trainer",
                name = "Heavy Timbermaw Belt",
                output = {
                    itemRef = "61fdf3df:l5lf2i61",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 290,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 142755
            },
            {
                category = "",
                description = "",
                id = "v5wvnwoh",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "732368d4:yts9s57i",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Girdle of the Dawn",
                output = {
                    itemRef = "61fdf3df:8pjjbq20",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 290,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 142755
            },
            {
                category = "",
                description = "",
                id = "k1frta7l",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "4999dcec:mr1cbt76",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "732368d4:4mu0nvut",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "732368d4:50qj8dzw",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Fiery Plate Gauntlets",
                output = {
                    itemRef = "61fdf3df:44j20j6y",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 290,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 142755
            },
            {
                category = "",
                description = "",
                id = "w06b2rnj",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 40
                    },
                    {
                        itemRef = "538a54a0:4gnkyr9f",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "732368d4:xtnbjwzj",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:sviqeucv",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:a4kj24o4",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "3eb7e9bb:qivy73u4",
                        kind = "rpe_item",
                        quantity = 16
                    }
                },
                learnMode = "trainer",
                name = "Corruption",
                output = {
                    itemRef = "61fdf3df:q5u2p8yf",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 290,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 142755
            },
            {
                category = "",
                description = "",
                id = "xz9xn3bw",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 30
                    },
                    {
                        itemRef = "4999dcec:mr1cbt76",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "538a54a0:4gnkyr9f",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "732368d4:sclalidn",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Volcanic Hammer",
                output = {
                    itemRef = "61fdf3df:6308fgwh",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 290,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 142755
            },
            {
                category = "",
                description = "",
                id = "aos6wi06",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:pb24e7k5",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "3eb7e9bb:e0tarf0p",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "3eb7e9bb:g3ytywfw",
                        kind = "rpe_item",
                        quantity = 3
                    }
                },
                learnMode = "trainer",
                name = "Fiery Chain Girdle",
                output = {
                    itemRef = "61fdf3df:kb1ljv4c",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 295,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 147575
            },
            {
                category = "",
                description = "",
                id = "mfy7shl2",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:pb24e7k5",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "3eb7e9bb:e0tarf0p",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "3eb7e9bb:g3ytywfw",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Dark Iron Bracers",
                output = {
                    itemRef = "61fdf3df:1e2dayyu",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 295,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 147575
            },
            {
                category = "",
                description = "",
                id = "gnyisosr",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "732368d4:7z1lti71",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "732368d4:4mu0nvut",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "4999dcec:sviqeucv",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Storm Gauntlets",
                output = {
                    itemRef = "61fdf3df:k4xav5wd",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 295,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 147575
            },
            {
                category = "",
                description = "",
                id = "brb2r7in",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:a4kj24o4",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "732368d4:ku9j8vhw",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Elemental Sharpening Stone",
                output = {
                    itemRef = "61fdf3df:wus2dp8n",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 295,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 147575
            },
            {
                category = "",
                description = "",
                id = "6k4qtw3u",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 26
                    }
                },
                learnMode = "trainer",
                name = "Thorium Leggings",
                output = {
                    itemRef = "61fdf3df:wkm2lyl7",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "oiod56rg",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:pb24e7k5",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "3eb7e9bb:e0tarf0p",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "3eb7e9bb:g3ytywfw",
                        kind = "rpe_item",
                        quantity = 6
                    }
                },
                learnMode = "trainer",
                name = "Dark Iron Leggings",
                output = {
                    itemRef = "61fdf3df:58g10o8n",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "aez4u5k0",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "732368d4:4mu0nvut",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "732368d4:tfwg197j",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 12
                    }
                },
                learnMode = "trainer",
                name = "Titanic Leggings",
                output = {
                    itemRef = "61fdf3df:3vcoyfp4",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "2wi0l1sl",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "732368d4:4mu0nvut",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:hqook9xe",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "4999dcec:atpvfzht",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Whitesoul Helm",
                output = {
                    itemRef = "61fdf3df:5rtbdx5b",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "nrctfvfa",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "732368d4:4mu0nvut",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "538a54a0:4gnkyr9f",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Enchanted Thorium Blades",
                output = {
                    itemRef = "61fdf3df:aieu8td6",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "k80bfnhk",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "4999dcec:sviqeucv",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 80
                    },
                    {
                        itemRef = "4999dcec:atpvfzht",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Lionheart Helm",
                output = {
                    itemRef = "61fdf3df:qvczjily",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "cfuqc8it",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "732368d4:4mu0nvut",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "732368d4:tfwg197j",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "4999dcec:atpvfzht",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:pkgfp4sl",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Enchanted Thorium Helm",
                output = {
                    itemRef = "61fdf3df:ldfq8j9c",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "g3ioatut",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:pb24e7k5",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "3eb7e9bb:e0tarf0p",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "3eb7e9bb:g3ytywfw",
                        kind = "rpe_item",
                        quantity = 5
                    }
                },
                learnMode = "trainer",
                name = "Fiery Chain Shoulders",
                output = {
                    itemRef = "61fdf3df:objdbnrr",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "7v4x0x86",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 15
                    },
                    {
                        itemRef = "732368d4:4mu0nvut",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "732368d4:tfwg197j",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "4999dcec:sviqeucv",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "4999dcec:pkgfp4sl",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Stronghold Gauntlets",
                output = {
                    itemRef = "61fdf3df:xbn1r8tg",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "2ajxlsj8",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "4999dcec:cjo7ed11",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "3eb7e9bb:c1i4aecn",
                        kind = "rpe_item",
                        quantity = 8
                    }
                },
                learnMode = "trainer",
                name = "Darkrune Helm",
                output = {
                    itemRef = "61fdf3df:dju4r2mj",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "oc3x0nmj",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "732368d4:4mu0nvut",
                        kind = "rpe_item",
                        quantity = 24
                    },
                    {
                        itemRef = "732368d4:tfwg197j",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "4999dcec:atpvfzht",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:bw8sfpgw",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "732368d4:7z1lti71",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Enchanted Thorium Breastplate",
                output = {
                    itemRef = "61fdf3df:emqbmk5g",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "9cscr1bz",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "3eb7e9bb:c1i4aecn",
                        kind = "rpe_item",
                        quantity = 10
                    }
                },
                learnMode = "trainer",
                name = "Darkrune Breastplate",
                output = {
                    itemRef = "61fdf3df:3k11jbcy",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "jcseptoy",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "732368d4:4mu0nvut",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "732368d4:7z1lti71",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "4999dcec:sviqeucv",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:bw8sfpgw",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Enchanted Thorium Leggings",
                output = {
                    itemRef = "61fdf3df:qu0vkjyp",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "p44kyrcr",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "3eb7e9bb:c1i4aecn",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "732368d4:x5hz6tby",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Darkrune Gauntlets",
                output = {
                    itemRef = "61fdf3df:0ei4gv14",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "66ohci4o",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "4999dcec:mr1cbt76",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:a4kj24o4",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "732368d4:x5hz6tby",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "732368d4:4mu0nvut",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "4999dcec:atpvfzht",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "4999dcec:pkgfp4sl",
                        kind = "rpe_item",
                        quantity = 6
                    }
                },
                learnMode = "trainer",
                name = "Heartseeker",
                output = {
                    itemRef = "61fdf3df:uzxq31hq",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "zd30b7ro",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "732368d4:x5hz6tby",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:a4kj24o4",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Arcanite Reaper",
                output = {
                    itemRef = "61fdf3df:8qkr89o4",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "qwmupr8i",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 15
                    },
                    {
                        itemRef = "732368d4:x5hz6tby",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "61fdf3df:a4kj24o4",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:pkgfp4sl",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "4999dcec:atpvfzht",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "732368d4:yts9s57i",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Arcanite Champion",
                output = {
                    itemRef = "61fdf3df:oiw5pyea",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "qxw3zp1e",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 15
                    },
                    {
                        itemRef = "732368d4:x5hz6tby",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "3eb7e9bb:hq608hly",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 50
                    },
                    {
                        itemRef = "732368d4:tfwg197j",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Hammer of the Titans",
                output = {
                    itemRef = "61fdf3df:ubltkvfl",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "2rljslwj",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "732368d4:x5hz6tby",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "732368d4:xtnbjwzj",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 40
                    },
                    {
                        itemRef = "61fdf3df:a4kj24o4",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:bw8sfpgw",
                        kind = "rpe_item",
                        quantity = 8
                    }
                },
                learnMode = "trainer",
                name = "Annihilator",
                output = {
                    itemRef = "61fdf3df:sr0gfxld",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "4xl2aczr",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 15
                    },
                    {
                        itemRef = "61fdf3df:pb24e7k5",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "732368d4:xtnbjwzj",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "538a54a0:4gnkyr9f",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "3eb7e9bb:c1i4aecn",
                        kind = "rpe_item",
                        quantity = 20
                    }
                },
                learnMode = "trainer",
                name = "Persuader",
                output = {
                    itemRef = "61fdf3df:c2e0gqt2",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "opmd47hb",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 18
                    },
                    {
                        itemRef = "732368d4:7z1lti71",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "4999dcec:sviqeucv",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "61fdf3df:a4kj24o4",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "732368d4:x5hz6tby",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "4999dcec:atpvfzht",
                        kind = "rpe_item",
                        quantity = 8
                    }
                },
                learnMode = "trainer",
                name = "Frostguard",
                output = {
                    itemRef = "61fdf3df:cn7ppx1l",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "ifpk2ats",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "732368d4:tfwg197j",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "732368d4:lxqnh3pp",
                        kind = "rpe_item",
                        quantity = 6
                    }
                },
                learnMode = "trainer",
                name = "Heavy Timbermaw Boots",
                output = {
                    itemRef = "61fdf3df:dis60p68",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "v86gbtkr",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "732368d4:yts9s57i",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Gloves of the Dawn",
                output = {
                    itemRef = "61fdf3df:2ck5q11k",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "iux5ag7z",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "732368d4:x5hz6tby",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "732368d4:ag52o52t",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Sageblade",
                output = {
                    itemRef = "61fdf3df:sp17wnlk",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "s27kd01x",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "4999dcec:mr1cbt76",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "3eb7e9bb:8eummju4",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:icf700is",
                        kind = "rpe_item",
                        quantity = 8
                    }
                },
                learnMode = "trainer",
                name = "Bloodsoul Shoulders",
                output = {
                    itemRef = "61fdf3df:v13n72tk",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "jyjaox43",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "4999dcec:pkgfp4sl",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:icf700is",
                        kind = "rpe_item",
                        quantity = 10
                    }
                },
                learnMode = "trainer",
                name = "Darksoul Shoulders",
                output = {
                    itemRef = "61fdf3df:031xwjd6",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "cccooyec",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "4999dcec:mr1cbt76",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "3eb7e9bb:8eummju4",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:icf700is",
                        kind = "rpe_item",
                        quantity = 10
                    }
                },
                learnMode = "trainer",
                name = "Bloodsoul Breastplate",
                output = {
                    itemRef = "61fdf3df:0kn4xk2l",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "l13evupg",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 20
                    },
                    {
                        itemRef = "4999dcec:pkgfp4sl",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:icf700is",
                        kind = "rpe_item",
                        quantity = 14
                    }
                },
                learnMode = "trainer",
                name = "Darksoul Breastplate",
                output = {
                    itemRef = "61fdf3df:fkpc6s0o",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "q4nc62f9",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 18
                    },
                    {
                        itemRef = "4999dcec:pkgfp4sl",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:icf700is",
                        kind = "rpe_item",
                        quantity = 12
                    }
                },
                learnMode = "trainer",
                name = "Darksoul Leggings",
                output = {
                    itemRef = "61fdf3df:2pjh04pf",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "8zc7tsd1",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "3eb7e9bb:8eummju4",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:icf700is",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "732368d4:x5hz6tby",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Bloodsoul Gauntlets",
                output = {
                    itemRef = "61fdf3df:ykq1a4jv",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "9ek6p4rd",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:pb24e7k5",
                        kind = "rpe_item",
                        quantity = 18
                    },
                    {
                        itemRef = "4999dcec:m4wt0wk3",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "732368d4:x5hz6tby",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "3eb7e9bb:g3ytywfw",
                        kind = "rpe_item",
                        quantity = 12
                    }
                },
                learnMode = "trainer",
                name = "Dark Iron Destroyer",
                output = {
                    itemRef = "61fdf3df:ikj9jawz",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "ncc9rr1c",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:pb24e7k5",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "4999dcec:m4wt0wk3",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "732368d4:x5hz6tby",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "3eb7e9bb:e0tarf0p",
                        kind = "rpe_item",
                        quantity = 12
                    }
                },
                learnMode = "trainer",
                name = "Dark Iron Reaver",
                output = {
                    itemRef = "61fdf3df:g3hsjfqw",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "7bt3s3iw",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:pb24e7k5",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "3eb7e9bb:e0tarf0p",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "3eb7e9bb:g3ytywfw",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Dark Iron Helm",
                output = {
                    itemRef = "61fdf3df:24bjwmah",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "ihhvthk7",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:pb24e7k5",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "3eb7e9bb:e0tarf0p",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "3eb7e9bb:g3ytywfw",
                        kind = "rpe_item",
                        quantity = 5
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 16
                    }
                },
                learnMode = "trainer",
                name = "Blackfury",
                output = {
                    itemRef = "61fdf3df:6rfc7i6h",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "dd2no90f",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "732368d4:4mu0nvut",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "732368d4:lxqnh3pp",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "3eb7e9bb:8eummju4",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Ironvine Breastplate",
                output = {
                    itemRef = "61fdf3df:ytlkngbc",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "pp0ex5lj",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "732368d4:4mu0nvut",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "732368d4:lxqnh3pp",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Ironvine Belt",
                output = {
                    itemRef = "61fdf3df:eib0cvip",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "hblnr02r",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:pb24e7k5",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "3eb7e9bb:e0tarf0p",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "3eb7e9bb:g3ytywfw",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "538a54a0:4gnkyr9f",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Dark Iron Boots",
                output = {
                    itemRef = "61fdf3df:dcl6258y",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "pa3ybt07",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:pb24e7k5",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "3eb7e9bb:e0tarf0p",
                        kind = "rpe_item",
                        quantity = 5
                    },
                    {
                        itemRef = "3eb7e9bb:g3ytywfw",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "538a54a0:4gnkyr9f",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "4999dcec:m4wt0wk3",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Dark Iron Gauntlets",
                output = {
                    itemRef = "61fdf3df:lpdpfbda",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "12x45yck",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "732368d4:4mu0nvut",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "732368d4:lxqnh3pp",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "3eb7e9bb:8eummju4",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Ironvine Gloves",
                output = {
                    itemRef = "61fdf3df:yl92l79e",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "53skvu3p",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:pb24e7k5",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "3eb7e9bb:hq608hly",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "3eb7e9bb:e0tarf0p",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "3eb7e9bb:g3ytywfw",
                        kind = "rpe_item",
                        quantity = 6
                    }
                },
                learnMode = "trainer",
                name = "Blackguard",
                output = {
                    itemRef = "61fdf3df:a2pb1qhp",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "ma7hfrmm",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:pb24e7k5",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "4999dcec:atpvfzht",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "3eb7e9bb:e0tarf0p",
                        kind = "rpe_item",
                        quantity = 7
                    },
                    {
                        itemRef = "3eb7e9bb:g3ytywfw",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Ebon Hand",
                output = {
                    itemRef = "61fdf3df:3b5fjgnc",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "be9ratva",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:pb24e7k5",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 10
                    },
                    {
                        itemRef = "4999dcec:bw8sfpgw",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "3eb7e9bb:e0tarf0p",
                        kind = "rpe_item",
                        quantity = 5
                    },
                    {
                        itemRef = "3eb7e9bb:g3ytywfw",
                        kind = "rpe_item",
                        quantity = 8
                    }
                },
                learnMode = "trainer",
                name = "Nightfall",
                output = {
                    itemRef = "61fdf3df:kfusej8c",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "pxypscuj",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 16
                    },
                    {
                        itemRef = "732368d4:7z1lti71",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "3eb7e9bb:06vxv3hh",
                        kind = "rpe_item",
                        quantity = 7
                    }
                },
                learnMode = "trainer",
                name = "Icebane Breastplate",
                output = {
                    itemRef = "61fdf3df:r41xfk05",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "1z8sdtf8",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "732368d4:7z1lti71",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "3eb7e9bb:06vxv3hh",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Icebane Bracers",
                output = {
                    itemRef = "61fdf3df:hjmxq16x",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "f63w1lmb",
                inputs = {
                    {
                        itemRef = "61fdf3df:518sbr8g",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 12
                    },
                    {
                        itemRef = "732368d4:7z1lti71",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "3eb7e9bb:06vxv3hh",
                        kind = "rpe_item",
                        quantity = 5
                    }
                },
                learnMode = "trainer",
                name = "Icebane Gauntlets",
                output = {
                    itemRef = "61fdf3df:rwohpfqh",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:6hydytdf",
                tags = {},
                trainerCostCopper = 152475
            }
        },
        resources = {},
        skills = {},
        spells = {},
        stats = {},
        traits = {},
        units = {},
        weaponTypes = {}
    },
})
