local _, Addon = ...

Addon.Data.DefaultDatasets:Register({
    version = 4,
    dataset = {
        achievements = {},
        auras = {
            {
                description = "",
                duration = 2,
                effects = {
                    {
                        baseAmount = 5,
                        operation = "flat",
                        statRef = "f82db71a:s1mt6jh9",
                        statScaling = {},
                        type = "stat"
                    }
                },
                events = {},
                icon = "interface/icons/inv_jewelcrafting_goldenhare.blp",
                id = "q74ie381",
                maxStacks = 1,
                name = "Golden Hare",
                stackBehavior = "refresh_duration",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    bodyText = "Increases Movement Speed by {AURA_STAT_1}.",
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
        id = "4999dcec",
        interactions = {},
        itemSlots = {},
        items = {
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
                icon = "interface/icons/inv_misc_gem_opal_03.blp",
                id = "n2q67aox",
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
                name = "Tigerseye",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_emerald_03.blp",
                id = "fcj318z0",
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
                name = "Malachite",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_amethyst_01.blp",
                id = "l3c8nzh7",
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
                name = "Shadowgem",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_crystal_01.blp",
                id = "w1ryslhj",
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
                name = "Lesser Moonstone",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_emerald_02.blp",
                id = "gw6wflop",
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
                name = "Moss Agate",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_emerald_01.blp",
                id = "qgjc3m5m",
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
                name = "Jade",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_opal_02.blp",
                id = "ht59o8mx",
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
                name = "Citrine",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_crystal_02.blp",
                id = "5nrqhg0t",
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
                name = "Aquamarine",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_ruby_02.blp",
                id = "mr1cbt76",
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
                name = "Star Ruby",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_opal_01.blp",
                id = "pkgfp4sl",
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
                name = "Large Opal",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_sapphire_02.blp",
                id = "sviqeucv",
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
                name = "Blue Sapphire",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_stone_01.blp",
                id = "bw8sfpgw",
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
                name = "Huge Emerald",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_diamond_01.blp",
                id = "atpvfzht",
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
                name = "Azerothian Diamond",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_topaz_01.blp",
                id = "kzswtd0z",
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
                name = "Arcane Crystal",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_01.blp",
                id = "cjo7ed11",
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
                name = "Black Diamond",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_box_02.blp",
                id = "r0hugqwh",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "tool",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Jeweller's Kit",
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "orange",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_opal_03.blp",
                id = "jhyudpys",
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
                modificationKind = "gem",
                name = "Bold Tigerseye",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "orange"
                },
                sockets = {},
                stats = {
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "orange",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_opal_03.blp",
                id = "o7nwalmu",
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
                modificationKind = "gem",
                name = "Teardrop Tigerseye",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "orange"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 3
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 1
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "orange",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_opal_03.blp",
                id = "bj6hczny",
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
                modificationKind = "gem",
                name = "Delicate Tigerseye",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "orange"
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "orange",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_opal_03.blp",
                id = "de8xm7u1",
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
                modificationKind = "gem",
                name = "Runed Tigerseye",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "orange"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 2
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "orange",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_opal_02.blp",
                id = "gdt0jvsl",
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
                modificationKind = "gem",
                name = "Bold Citrine",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "orange"
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "orange",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_opal_02.blp",
                id = "czng37u2",
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
                modificationKind = "gem",
                name = "Teardrop Citrine",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "orange"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 2
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "orange",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_opal_02.blp",
                id = "zfi5z0qr",
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
                modificationKind = "gem",
                name = "Delicate Citrine",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "orange"
                },
                sockets = {},
                stats = {
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "orange",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_opal_02.blp",
                id = "8dqciung",
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
                modificationKind = "gem",
                name = "Runed Citrine",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "orange"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 4
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "orange",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_opal_01.blp",
                id = "717x7cwd",
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
                modificationKind = "gem",
                name = "Bold Opal",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "orange"
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "orange",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_opal_01.blp",
                id = "ratcz2ip",
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
                modificationKind = "gem",
                name = "Teardrop Opal",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "orange"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 3
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 9
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "orange",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_opal_01.blp",
                id = "nkxle7cu",
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
                modificationKind = "gem",
                name = "Delicate Opal",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "orange"
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "orange",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_opal_01.blp",
                id = "fk566zp8",
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
                modificationKind = "gem",
                name = "Runed Opal",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "orange"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 5
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "green",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_emerald_03.blp",
                id = "z716i2ih",
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
                modificationKind = "gem",
                name = "Rigid Malachite",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "green"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 0.2
                    },
                    {
                        sourceStatRef = "f82db71a:dd88li4c",
                        value = 0.2
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "green",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_emerald_03.blp",
                id = "sxnvc1o4",
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
                modificationKind = "gem",
                name = "Thick Malachite",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "green"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zs1nbz13",
                        value = 0.2
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "green",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_emerald_03.blp",
                id = "mmz27cx6",
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
                modificationKind = "gem",
                name = "Smooth Malachite",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "green"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 0.2
                    },
                    {
                        sourceStatRef = "f82db71a:fercjhm5",
                        value = 0.2
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "green",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_emerald_03.blp",
                id = "wh7d8idy",
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
                modificationKind = "gem",
                name = "Gleaming Malachite",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "green"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 0.2
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "green",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_emerald_03.blp",
                id = "8qvdycto",
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
                modificationKind = "gem",
                name = "Brilliant Malachite",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "green"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 1
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "green",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_stone_01.blp",
                id = "k7pplvff",
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
                modificationKind = "gem",
                name = "Rigid Jade",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "green"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 0.3
                    },
                    {
                        sourceStatRef = "f82db71a:dd88li4c",
                        value = 0.3
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "green",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_stone_01.blp",
                id = "omo1xbjb",
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
                modificationKind = "gem",
                name = "Smooth Jade",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "green"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 0.4
                    },
                    {
                        sourceStatRef = "f82db71a:fercjhm5",
                        value = 0.4
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "green",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_stone_01.blp",
                id = "r1flmhok",
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
                modificationKind = "gem",
                name = "Thick Jade",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "green"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zs1nbz13",
                        value = 0.4
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "green",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_stone_01.blp",
                id = "ijouef0r",
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
                modificationKind = "gem",
                name = "Gleaming Jade",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "green"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 0.4
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "green",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_emerald_01.blp",
                id = "cg7309xb",
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
                modificationKind = "gem",
                name = "Brilliant Jade",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "green"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 2
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "green",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_emerald_01.blp",
                id = "5dvj6axi",
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
                modificationKind = "gem",
                name = "Rigid Emerald",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "green"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 0.5
                    },
                    {
                        sourceStatRef = "f82db71a:dd88li4c",
                        value = 0.5
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "green",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_stone_01.blp",
                id = "nmga0fkh",
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
                modificationKind = "gem",
                name = "Thick Emerald",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "green"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zs1nbz13",
                        value = 0.5
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "green",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_emerald_01.blp",
                id = "k7wxx4mx",
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
                modificationKind = "gem",
                name = "Smooth Emerald",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "green"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 0.5
                    },
                    {
                        sourceStatRef = "f82db71a:fercjhm5",
                        value = 0.5
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "green",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_emerald_01.blp",
                id = "nbyjll3v",
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
                modificationKind = "gem",
                name = "Gleaming Emerald",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "green"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 0.5
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "green",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_emerald_01.blp",
                id = "p991jkrx",
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
                modificationKind = "gem",
                name = "Brilliant Emerald",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "green"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 4
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "purple",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_amethyst_01.blp",
                id = "yoebbzgi",
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
                modificationKind = "gem",
                name = "Lustrous Shadowgem",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "purple"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 4
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "purple",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_amethyst_01.blp",
                id = "10pgv0ac",
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
                modificationKind = "gem",
                name = "Solid Shadowgem",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "purple"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 2
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "purple",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_amethyst_01.blp",
                id = "7fut16hb",
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
                modificationKind = "gem",
                name = "Sparkling Shadowgem",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "purple"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 1
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "blue",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_crystal_02.blp",
                id = "75oj6vol",
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
                modificationKind = "gem",
                name = "Lustrous Aquamarine",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "blue"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 7
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "blue",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_crystal_02.blp",
                id = "zv15msup",
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
                modificationKind = "gem",
                name = "Solid Aquamarine",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "blue"
                },
                sockets = {},
                stats = {
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "blue",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_crystal_02.blp",
                id = "t9y01t59",
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
                modificationKind = "gem",
                name = "Sparkling Aquamarine",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "blue"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 2
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "blue",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_sapphire_02.blp",
                id = "81ktklz6",
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
                modificationKind = "gem",
                name = "Lustrous Sapphire",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "blue"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 10
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "blue",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_sapphire_02.blp",
                id = "xiaaodqr",
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
                modificationKind = "gem",
                name = "Solid Sapphire",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "blue"
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "blue",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_sapphire_02.blp",
                id = "k128wciq",
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
                modificationKind = "gem",
                name = "Sparkling Sapphire",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "blue"
                },
                sockets = {},
                stats = {
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "red",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_ruby_02.blp",
                id = "m9iz6u1s",
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
                modificationKind = "gem",
                name = "Teardrop Star Ruby",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "red"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 11
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 4
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "red",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_ruby_02.blp",
                id = "sa1ac8sl",
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
                modificationKind = "gem",
                name = "Delicate Star Ruby",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "red"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 5
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "red",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_ruby_02.blp",
                id = "l1xq7i60",
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
                modificationKind = "gem",
                name = "Runed Star Ruby",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "red"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 6
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "red",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_ruby_02.blp",
                id = "2o4djsc2",
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
                modificationKind = "gem",
                name = "Bright Star Ruby",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "red"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:u7b49vs9",
                        value = 10
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "yellow",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_topaz_01.blp",
                id = "09sj0l3r",
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
                modificationKind = "gem",
                name = "Smooth Arcane Crystal",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "yellow"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:jslmczbi",
                        value = 0.6
                    },
                    {
                        sourceStatRef = "f82db71a:fercjhm5",
                        value = 0.6
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "yellow",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_topaz_01.blp",
                id = "b8gkxiy5",
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
                modificationKind = "gem",
                name = "Rigid Arcane Crystal",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "yellow"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 0.6
                    },
                    {
                        sourceStatRef = "f82db71a:dd88li4c",
                        value = 0.6
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "yellow",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_topaz_01.blp",
                id = "620kfem0",
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
                modificationKind = "gem",
                name = "Great Arcane Crystal",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "yellow"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v2g0tw0o",
                        value = 0.6
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "yellow",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_topaz_01.blp",
                id = "23y8nl9v",
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
                modificationKind = "gem",
                name = "Gleaming Arcane Crystal",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "yellow"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 0.6
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "yellow",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_topaz_01.blp",
                id = "i0yywybp",
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
                modificationKind = "gem",
                name = "Thick Arcane Crystal",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "yellow"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:zs1nbz13",
                        value = 0.6
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "yellow",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_topaz_01.blp",
                id = "ojy5ftfn",
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
                modificationKind = "gem",
                name = "Brilliant Arcane Crystal",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "yellow"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 5
                    }
                },
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "meta",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_01.blp",
                id = "ixjcs4a3",
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
                modificationKind = "gem",
                name = "Swift Black Diamond",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "meta"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:u7b49vs9",
                        value = 20
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "meta",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_01.blp",
                id = "at6l62ui",
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
                modificationKind = "gem",
                name = "Thundering Black Diamond",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "meta"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v2rs9cpy",
                        value = 20
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
                canStack = false,
                canTrade = true,
                cogSockets = 0,
                conditions = {},
                consumableElixirType = "",
                consumableType = "",
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "meta",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_misc_gem_01.blp",
                id = "7a81l4yr",
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
                modificationKind = "gem",
                name = "Bracing Black Diamond",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {
                    "meta"
                },
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 22
                    },
                    {
                        sourceStatRef = "f82db71a:j8n012e6",
                        value = -2
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 6
                    }
                },
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
                icon = "interface/icons/inv_belt_19.blp",
                id = "myjwvrpn",
                isTwoHanded = false,
                itemLevel = 22,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Thick Bronze Necklace",
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
                    "f82db71a:ujxndj4q"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_equip",
                blueSockets = 1,
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
                icon = "interface/icons/inv_jewelry_ring_14.blp",
                id = "3a28xic7",
                isTwoHanded = false,
                itemLevel = 22,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Solid Bronze Ring",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "blue"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 30
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_equip",
                blueSockets = 1,
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
                icon = "interface/icons/inv_jewelry_ring_01.blp",
                id = "i24s59ih",
                isTwoHanded = false,
                itemLevel = 22,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Elegant Silver Ring",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "blue"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 2
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 2
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_pickup",
                blueSockets = 1,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = false,
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
                icon = "interface/icons/inv_jewelry_ring_34.blp",
                id = "9vc8kxod",
                isTwoHanded = false,
                itemLevel = 23,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bronze Band of Force",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "blue"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:u7b49vs9",
                        value = 8
                    },
                    {
                        sourceStatRef = "f82db71a:gj9wxb0x",
                        value = 1
                    },
                    {
                        sourceStatRef = "f82db71a:5pxmfw02",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
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
                icon = "interface/icons/inv_jewelry_necklace_01.blp",
                id = "j9k51ouo",
                isTwoHanded = false,
                itemLevel = 25,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Brilliant Necklace",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "yellow"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 1
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 2
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 2
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 2
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 2
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:ujxndj4q"
                },
                yellowSockets = 1
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
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
                icon = "interface/icons/inv_jewelry_necklace_29naxxramas.blp",
                id = "a3z4mv5x",
                isTwoHanded = false,
                itemLevel = 26,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Bronze Torc",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "yellow"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:pu05li08",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:ujxndj4q"
                },
                yellowSockets = 1
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
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
                icon = "interface/icons/inv_jewelry_ring_05.blp",
                id = "jsrc8gdn",
                isTwoHanded = false,
                itemLevel = 26,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Ring of Silver Might",
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
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 3
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
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_equip",
                blueSockets = 1,
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
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_jewelry_ring_34.blp",
                id = "nrog69xv",
                isTwoHanded = false,
                itemLevel = 28,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Ring of Twilight Shadows",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "blue"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 4
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
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
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
                icon = "interface/icons/inv_jewelry_ring_08.blp",
                id = "p8uwttif",
                isTwoHanded = false,
                itemLevel = 29,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Heavy Jade Ring",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "yellow"
                    }
                },
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
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 1
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = false,
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
                icon = "interface/icons/inv_jewelry_ring_26.blp",
                id = "qppn0dky",
                isTwoHanded = false,
                itemLevel = 27,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Heavy Silver Ring",
                prismaticSockets = 0,
                quality = "rare",
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
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
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
                icon = "interface/icons/inv_jewelry_necklace_11.blp",
                id = "yuyzsuro",
                isTwoHanded = false,
                itemLevel = 30,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Amulet of the Moon",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "yellow"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 4
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 4
                    },
                    {
                        sourceStatRef = "f82db71a:5pxmfw02",
                        value = 2
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:ujxndj4q"
                },
                yellowSockets = 1
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
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
                icon = "interface/icons/inv_jewelry_necklace_22.blp",
                id = "tmu3w5gs",
                isTwoHanded = false,
                itemLevel = 30,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Barbaric Iron Collar",
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
                        sourceStatRef = "f82db71a:u7b49vs9",
                        value = 10
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:ujxndj4q"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 1,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = false,
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
                icon = "interface/icons/inv_crown_15.blp",
                id = "60nuv7oo",
                isTwoHanded = false,
                itemLevel = 31,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Moonsoul Crown",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "blue"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 39
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 12
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
                armorWeight = "cosmetic",
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
                icon = "interface/icons/inv_shield_21.blp",
                id = "a4v4hlw3",
                isTwoHanded = false,
                itemLevel = 31,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Pendant of the Agate Shield",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "yellow"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 4
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 4
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 6
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:ujxndj4q"
                },
                yellowSockets = 1
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_equip",
                blueSockets = 1,
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
                icon = "interface/icons/inv_jewelry_ring_02.blp",
                id = "roaw553e",
                isTwoHanded = false,
                itemLevel = 32,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Moonstone Ring",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "blue"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 7
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
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
                        minimumValue = 28,
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
                icon = "interface/icons/inv_jewelry_ring_40.blp",
                id = "fyqlzdwg",
                isTwoHanded = false,
                itemLevel = 33,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Golden Dragon Ring",
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
                        sourceStatRef = "f82db71a:u7b49vs9",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 4
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
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
                icon = "interface/icons/inv_jewelry_necklace_08.blp",
                id = "12tzi40o",
                isTwoHanded = false,
                itemLevel = 31,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Heavy Golden Necklace of Battle",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "yellow"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:wbj4zuf3",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:ujxndj4q"
                },
                yellowSockets = 1
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
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
                icon = "interface/icons/inv_jewelry_ring_20.blp",
                id = "fmgf4wy0",
                isTwoHanded = false,
                itemLevel = 35,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Blazing Citrine Ring",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "yellow"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 9
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 9
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:ujxndj4q"
                },
                yellowSockets = 1
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
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
                icon = "interface/icons/inv_jewelry_necklace_01.blp",
                id = "omzu6owk",
                isTwoHanded = false,
                itemLevel = 36,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Jade Pendant of Blasting",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "yellow"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 3
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 8
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:ujxndj4q"
                },
                yellowSockets = 1
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_equip",
                blueSockets = 1,
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
                icon = "interface/icons/inv_jewelry_ring_35.blp",
                id = "dhn24t1r",
                isTwoHanded = false,
                itemLevel = 37,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Engraved Truesilver Ring",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "blue"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 3
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 3
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 3
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
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
                    "f82db71a:ujxndj4q"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_equip",
                blueSockets = 1,
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
                icon = "interface/icons/inv_jewelry_ring_11.blp",
                id = "ea7x1ec9",
                isTwoHanded = false,
                itemLevel = 37,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "The Jade Eye",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "blue"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 6
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:ujxndj4q"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = false,
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
                icon = "interface/icons/inv_jewelry_ring_46.blp",
                id = "t8eqst7e",
                isTwoHanded = false,
                itemLevel = 36,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Golden Ring of Power",
                prismaticSockets = 0,
                quality = "rare",
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
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 4
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 6
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:ujxndj4q"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
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
                icon = "interface/icons/inv_jewelry_ring_29.blp",
                id = "t7icomfa",
                isTwoHanded = false,
                itemLevel = 38,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Citrine Ring of Rapid Healing",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "yellow"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:ok80ohz3",
                        value = 2
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 5
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:ujxndj4q"
                },
                yellowSockets = 1
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_equip",
                blueSockets = 1,
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
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_jewelry_necklace_06.blp",
                id = "dc42qn0v",
                isTwoHanded = false,
                itemLevel = 39,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Citrine Pendant of Golden Healing",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "blue"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 20
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 7
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:ujxndj4q"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_equip",
                blueSockets = 1,
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
                icon = "interface/icons/inv_jewelry_ring_30.blp",
                id = "jrf15k1e",
                isTwoHanded = false,
                itemLevel = 40,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Truesilver Commander Ring",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "blue"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 7
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 7
                    },
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
                    "f82db71a:ujxndj4q"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = false,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 35,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    },
                    {
                        invert = false,
                        minimumValue = 285,
                        showOnTooltip = false,
                        skillRef = "f82db71a:fxp3vo4o",
                        tooltipTextOverride = "",
                        type = "skill_requirement"
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
                            combatEventId = "on_critical_heal",
                            effects = {
                                {
                                    amount = 5,
                                    amountMode = "base_percent",
                                    resourceRef = "f82db71a:4c8mfm99",
                                    type = "resource"
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
                icon = "interface/icons/inv_jewelcrafting_jadeowl.blp",
                id = "si0dqr3p",
                isTwoHanded = false,
                itemLevel = 40,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Jade Owl Figurine",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 3
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 2
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:139phg06"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = false,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 35,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    },
                    {
                        invert = false,
                        minimumValue = 200,
                        showOnTooltip = false,
                        skillRef = "f82db71a:fxp3vo4o",
                        tooltipTextOverride = "",
                        type = "skill_requirement"
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
                            combatEventId = "on_critical_hit",
                            effects = {
                                {
                                    auraRef = "4999dcec:q74ie381",
                                    basePower = 0,
                                    duration = 2,
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
                icon = "interface/icons/inv_jewelcrafting_goldenhare.blp",
                id = "rdmn3b25",
                isTwoHanded = false,
                itemLevel = 40,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Golden Hare Figurine",
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
                    "f82db71a:139phg06"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_pickup",
                blueSockets = 1,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = false,
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
                icon = "interface/icons/inv_jewelry_ring_10.blp",
                id = "2bo3ulm5",
                isTwoHanded = false,
                itemLevel = 42,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Aquamarine Signet",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "blue"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 8
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:v2rs9cpy",
                        value = 20
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_equip",
                blueSockets = 1,
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
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_jewelry_necklace_16.blp",
                id = "ouge9lag",
                isTwoHanded = false,
                itemLevel = 44,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Aquamarine Pendant of the Warrior",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "blue"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:u7b49vs9",
                        value = 20
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 8
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = false,
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
                icon = "interface/icons/inv_crown_13.blp",
                id = "qsdjegxu",
                isTwoHanded = false,
                itemLevel = 45,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Ruby Crown of Restoration",
                prismaticSockets = 0,
                quality = "rare",
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
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 9
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 16
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 48
                    },
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 53
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
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = false,
                cogSockets = 0,
                conditions = {
                    {
                        invert = false,
                        minimumValue = 40,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    },
                    {
                        invert = false,
                        minimumValue = 225,
                        showOnTooltip = false,
                        skillRef = "f82db71a:fxp3vo4o",
                        tooltipTextOverride = "",
                        type = "skill_requirement"
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
                icon = "interface/icons/inv_jewelcrafting_truesilvercrab.blp",
                id = "jbqegzqf",
                isTwoHanded = false,
                itemLevel = 45,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Truesilver Crab Figurine",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:pu05li08",
                        value = 3
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:139phg06"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
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
                icon = "interface/icons/inv_jewelry_ring_25.blp",
                id = "5b6h66b6",
                isTwoHanded = false,
                itemLevel = 46,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Red Ring of Destruction",
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
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
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
                icon = "interface/icons/inv_jewelry_necklace_15.blp",
                id = "x53oxl56",
                isTwoHanded = false,
                itemLevel = 47,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Ruby Pendant of Fire",
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
                        sourceStatRef = "f82db71a:0w7c7p09",
                        value = 10
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 12
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_equip",
                blueSockets = 1,
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
                icon = "interface/icons/inv_jewelry_ring_26.blp",
                id = "1gfq46xr",
                isTwoHanded = false,
                itemLevel = 48,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Truesilver Healing Ring",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "blue"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 24
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 8
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_equip",
                blueSockets = 1,
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
                icon = "interface/icons/inv_jewelry_ring_29.blp",
                id = "qtq4pmjx",
                isTwoHanded = false,
                itemLevel = 48,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "The Aquamarine Ward",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "blue"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:o6113cir",
                        value = 2
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = false,
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
                icon = "interface/icons/inv_jewelry_necklace_15.blp",
                id = "jbdnbbjx",
                isTwoHanded = false,
                itemLevel = 50,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Opal Necklace of Impact",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "yellow"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:u7b49vs9",
                        value = 24
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 1
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = false,
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
                icon = "interface/icons/inv_jewelry_ring_37.blp",
                id = "8dcvumcm",
                isTwoHanded = false,
                itemLevel = 50,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Gem Studded Band",
                prismaticSockets = 0,
                quality = "rare",
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
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 6
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
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
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
                icon = "interface/icons/inv_jewelry_ring_17.blp",
                id = "i397dwhs",
                isTwoHanded = false,
                itemLevel = 52,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Simple Opal Ring",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "yellow"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 12
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 1
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
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
                icon = "interface/icons/inv_jewelry_ring_42.blp",
                id = "rpck2ov0",
                isTwoHanded = false,
                itemLevel = 52,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Diamond Focus Ring",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "yellow"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 8
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 12
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 1
            },
            {
                allowWowConversion = false,
                armorWeight = "cloth",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = false,
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
                damageMode = "fixed",
                damagePerTurn = 0,
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_crown_13.blp",
                id = "9erta8qd",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Emerald Crown of Destruction",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "yellow"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 30
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 30
                    },
                    {
                        sourceStatRef = "f82db71a:69hfqhne",
                        value = 1
                    },
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 64
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
                yellowSockets = 1
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
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
                icon = "interface/icons/inv_jewelry_ring_27.blp",
                id = "p1udd9fm",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Onslaught Ring",
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
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:u7b49vs9",
                        value = 24
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
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
                icon = "interface/icons/inv_jewelry_ring_35.blp",
                id = "jdxq7bzv",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Glowing Thorium Band",
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
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 8
                    },
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 22
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 8
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_pickup",
                blueSockets = 0,
                canDisenchant = true,
                canSell = true,
                canStack = false,
                canTrade = false,
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
                icon = "interface/icons/inv_jewelry_necklace_01.blp",
                id = "bqz47t6w",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Living Emerald Pendant",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "yellow"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:hj6d4kvy",
                        value = 35
                    },
                    {
                        sourceStatRef = "f82db71a:7t7xgzcx",
                        value = 12
                    },
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 12
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 1
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_equip",
                blueSockets = 1,
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
                icon = "interface/icons/inv_jewelry_ring_18.blp",
                id = "a5m2dlbr",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Emerald Lion Ring",
                prismaticSockets = 0,
                quality = "uncommon",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "blue"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:kec9rhli",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:zfqm8dxp",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:75y3a8ib",
                        value = 6
                    },
                    {
                        sourceStatRef = "f82db71a:xqz0daz2",
                        value = 5
                    },
                    {
                        sourceStatRef = "f82db71a:ygjno50i",
                        value = 5
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:cpkcof3z"
                },
                yellowSockets = 0
            },
            {
                allowWowConversion = false,
                armorWeight = "cosmetic",
                bindingFlag = "bind_on_equip",
                blueSockets = 1,
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
                icon = "interface/icons/inv_jewelry_necklace_35.blp",
                id = "xp2zkejw",
                isTwoHanded = false,
                itemLevel = 55,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Necklace of the Diamond Tower",
                prismaticSockets = 0,
                quality = "rare",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {
                    {
                        color = "blue"
                    }
                },
                stats = {
                    {
                        sourceStatRef = "f82db71a:zs1nbz13",
                        value = 1
                    },
                    {
                        sourceStatRef = "f82db71a:0wyp78x9",
                        value = 17
                    }
                },
                tags = {},
                targetArmorWeight = "none",
                targetSlotRefs = {},
                targetTwoHandedOnly = false,
                uniqueFlag = "unique_equipped",
                validSlotRefs = {
                    "f82db71a:ujxndj4q"
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
                icon = "interface/icons/inv_misc_gem_pearl_03.blp",
                id = "s9lu5jap",
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
                name = "Small Lustrous Pearl",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_pearl_02.blp",
                id = "ms6y0fi0",
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
                name = "Iridescent Pearl",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_pearl_04.blp",
                id = "y7998n1r",
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
                name = "Golden Pearl",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_pearl_01.blp",
                id = "6b4o47go",
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
                name = "Black Pearl",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_01.blp",
                id = "icf700is",
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
                name = "Souldarite",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
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
                icon = "interface/icons/inv_misc_gem_bloodstone_03.blp",
                id = "m4wt0wk3",
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
                name = "Blood of the Mountain",
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
                wowConversionSkillRef = "f82db71a:fxp3vo4o",
                yellowSockets = 0
            }
        },
        loot = {},
        mounts = {},
        name = "Jewelcrafting",
        pets = {},
        races = {},
        recipes = {
            {
                category = "",
                description = "",
                id = "2schkl5k",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:n2q67aox",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "always_learned",
                name = "Bold Tigerseye",
                output = {
                    itemRef = "4999dcec:jhyudpys",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 1,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 104
            },
            {
                category = "",
                description = "",
                id = "kjtg67ip",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:n2q67aox",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Delicate Tigerseye",
                output = {
                    itemRef = "4999dcec:bj6hczny",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 20,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 1275
            },
            {
                category = "",
                description = "",
                id = "jsxofxg9",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:n2q67aox",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Runed Tigerseye",
                output = {
                    itemRef = "4999dcec:de8xm7u1",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 40,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 3755
            },
            {
                category = "",
                description = "",
                id = "hm6idbkk",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:n2q67aox",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Teardrop Tigerseye",
                output = {
                    itemRef = "4999dcec:o7nwalmu",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 60,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 7515
            },
            {
                category = "",
                description = "",
                id = "3w33d38d",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:ht59o8mx",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Bold Citrine",
                output = {
                    itemRef = "4999dcec:gdt0jvsl",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 80,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 12555
            },
            {
                category = "",
                description = "",
                id = "1nwjekze",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:ht59o8mx",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Delicate Citrine",
                output = {
                    itemRef = "4999dcec:zfi5z0qr",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 100,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 18875
            },
            {
                category = "",
                description = "",
                id = "kp0t5t5i",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:ht59o8mx",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Teardrop Citrine",
                output = {
                    itemRef = "4999dcec:czng37u2",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 120,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 26475
            },
            {
                category = "",
                description = "",
                id = "q3irfk59",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:ht59o8mx",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Runed Citrine",
                output = {
                    itemRef = "4999dcec:8dqciung",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 140,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 35355
            },
            {
                category = "",
                description = "",
                id = "m8nydear",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:pkgfp4sl",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Bold Opal",
                output = {
                    itemRef = "4999dcec:717x7cwd",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 175,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 53975
            },
            {
                category = "",
                description = "",
                id = "gestbks1",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:pkgfp4sl",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Delicate Opal",
                output = {
                    itemRef = "4999dcec:nkxle7cu",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 195,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 66375
            },
            {
                category = "",
                description = "",
                id = "nc0b3jmn",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:pkgfp4sl",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Teardrop Opal",
                output = {
                    itemRef = "4999dcec:ratcz2ip",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 215,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 80055
            },
            {
                category = "",
                description = "",
                id = "0dcv5xre",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:pkgfp4sl",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Runed Opal",
                output = {
                    itemRef = "4999dcec:fk566zp8",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 235,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 95015
            },
            {
                category = "",
                description = "",
                id = "mpnjfwpy",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:fcj318z0",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Rigid Malachite",
                output = {
                    itemRef = "4999dcec:z716i2ih",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 5,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 255
            },
            {
                category = "",
                description = "",
                id = "d8dlnn2w",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:fcj318z0",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Thick Malachite",
                output = {
                    itemRef = "4999dcec:sxnvc1o4",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 20,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 1275
            },
            {
                category = "",
                description = "",
                id = "mwk3wiv0",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:fcj318z0",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Smooth Malachite",
                output = {
                    itemRef = "4999dcec:mmz27cx6",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 35,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 3015
            },
            {
                category = "",
                description = "",
                id = "wxfory8p",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:fcj318z0",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Gleaming Malachite",
                output = {
                    itemRef = "4999dcec:wh7d8idy",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 50,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 5475
            },
            {
                category = "",
                description = "",
                id = "2uufe05g",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:fcj318z0",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Brilliant Malachite",
                output = {
                    itemRef = "4999dcec:8qvdycto",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 65,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 8655
            },
            {
                category = "",
                description = "",
                id = "l0appqaa",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:qgjc3m5m",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Rigid Jade",
                output = {
                    itemRef = "4999dcec:k7pplvff",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 80,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 12555
            },
            {
                category = "",
                description = "",
                id = "rvxaglyh",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:qgjc3m5m",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Thick Jade",
                output = {
                    itemRef = "4999dcec:r1flmhok",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 95,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 17175
            },
            {
                category = "",
                description = "",
                id = "uofludya",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:qgjc3m5m",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Smooth Jade",
                output = {
                    itemRef = "4999dcec:omo1xbjb",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 110,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 22515
            },
            {
                category = "",
                description = "",
                id = "c3va1ktd",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:qgjc3m5m",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Gleaming Jade",
                output = {
                    itemRef = "4999dcec:ijouef0r",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 125,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 28575
            },
            {
                category = "",
                description = "",
                id = "f9z8e0jc",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:qgjc3m5m",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Brilliant Jade",
                output = {
                    itemRef = "4999dcec:cg7309xb",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 140,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 35355
            },
            {
                category = "",
                description = "",
                id = "7ur1cpiz",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:bw8sfpgw",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Rigid Emerald",
                output = {
                    itemRef = "4999dcec:5dvj6axi",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 155,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 42855
            },
            {
                category = "",
                description = "",
                id = "w0pyp49b",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:bw8sfpgw",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Thick Emerald",
                output = {
                    itemRef = "4999dcec:nmga0fkh",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 170,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 51075
            },
            {
                category = "",
                description = "",
                id = "wm89s9de",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:bw8sfpgw",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Smooth Emerald",
                output = {
                    itemRef = "4999dcec:k7wxx4mx",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 195,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 66375
            },
            {
                category = "",
                description = "",
                id = "1eod783a",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:bw8sfpgw",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Brilliant Emerald",
                output = {
                    itemRef = "4999dcec:p991jkrx",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 210,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 76515
            },
            {
                category = "",
                description = "",
                id = "5kijb5bt",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:bw8sfpgw",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Gleaming Emerald",
                output = {
                    itemRef = "4999dcec:nbyjll3v",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 225,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 87375
            },
            {
                category = "",
                description = "",
                id = "qu50v8zf",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:l3c8nzh7",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Lustrous Shadowgem",
                output = {
                    itemRef = "4999dcec:yoebbzgi",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 15,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 855
            },
            {
                category = "",
                description = "",
                id = "ygu2iwog",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:l3c8nzh7",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Solid Shadowgem",
                output = {
                    itemRef = "4999dcec:10pgv0ac",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 30,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 2355
            },
            {
                category = "",
                description = "",
                id = "451ket0z",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:l3c8nzh7",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Sparkling Shadowgem",
                output = {
                    itemRef = "4999dcec:7fut16hb",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 45,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 4575
            },
            {
                category = "",
                description = "",
                id = "wnqub10l",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:5nrqhg0t",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Lustrous Aquamarine",
                output = {
                    itemRef = "4999dcec:75oj6vol",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 60,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 7515
            },
            {
                category = "",
                description = "",
                id = "pb5a1q1w",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:5nrqhg0t",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Solid Aquamarine",
                output = {
                    itemRef = "4999dcec:zv15msup",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 90,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 15555
            },
            {
                category = "",
                description = "",
                id = "3ppusdmz",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:5nrqhg0t",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Sparkling Aquamarine",
                output = {
                    itemRef = "4999dcec:t9y01t59",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 120,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 26475
            },
            {
                category = "",
                description = "",
                id = "2s86wc4i",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:sviqeucv",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Lustrous Sapphire",
                output = {
                    itemRef = "4999dcec:81ktklz6",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 160,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 45515
            },
            {
                category = "",
                description = "",
                id = "kuorcwu7",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:sviqeucv",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Solid Sapphire",
                output = {
                    itemRef = "4999dcec:xiaaodqr",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 200,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 69675
            },
            {
                category = "",
                description = "",
                id = "yc50okx0",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:sviqeucv",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Sparkling Sapphire",
                output = {
                    itemRef = "4999dcec:k128wciq",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 240,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 98955
            },
            {
                category = "",
                description = "",
                id = "czz3zirr",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
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
                name = "Teardrop Star Ruby",
                output = {
                    itemRef = "4999dcec:m9iz6u1s",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 250,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 107075
            },
            {
                category = "",
                description = "",
                id = "klum5kk2",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
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
                name = "Delicate Star Ruby",
                output = {
                    itemRef = "4999dcec:sa1ac8sl",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 265,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 119855
            },
            {
                category = "",
                description = "",
                id = "i6h1w7q5",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
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
                name = "Runed Star Ruby",
                output = {
                    itemRef = "4999dcec:l1xq7i60",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 280,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 133355
            },
            {
                category = "",
                description = "",
                id = "6bwfqoj3",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
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
                name = "Bright Star Ruby",
                output = {
                    itemRef = "4999dcec:2o4djsc2",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 295,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 147575
            },
            {
                category = "",
                description = "",
                id = "brm55ole",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:kzswtd0z",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Smooth Arcane Crystal",
                output = {
                    itemRef = "4999dcec:09sj0l3r",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 260,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 115515
            },
            {
                category = "",
                description = "",
                id = "ixj3ihim",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:kzswtd0z",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Rigid Arcane Crystal",
                output = {
                    itemRef = "4999dcec:b8gkxiy5",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 270,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 124275
            },
            {
                category = "",
                description = "",
                id = "o04osts4",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:kzswtd0z",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Great Arcane Crystal",
                output = {
                    itemRef = "4999dcec:620kfem0",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 280,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 133355
            },
            {
                category = "",
                description = "",
                id = "b8nrfwcq",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:kzswtd0z",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Gleaming Arcane Crystal",
                output = {
                    itemRef = "4999dcec:23y8nl9v",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 290,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 142755
            },
            {
                category = "",
                description = "",
                id = "hyexvfpz",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:kzswtd0z",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Thick Arcane Crystal",
                output = {
                    itemRef = "4999dcec:i0yywybp",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 295,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 147575
            },
            {
                category = "",
                description = "",
                id = "vyi9mtu1",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:kzswtd0z",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Brilliant Arcane Crystal",
                output = {
                    itemRef = "4999dcec:ojy5ftfn",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "pmy90so7",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:cjo7ed11",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Bracing Black Diamond",
                output = {
                    itemRef = "4999dcec:7a81l4yr",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "8f9aeku6",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:cjo7ed11",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Swift Black Diamond",
                output = {
                    itemRef = "4999dcec:ixjcs4a3",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "xyi31jd7",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:cjo7ed11",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Thundering Black Diamond",
                output = {
                    itemRef = "4999dcec:at6l62ui",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 152475
            },
            {
                category = "",
                description = "",
                id = "8iil45e7",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
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
                name = "Thick Bronze Necklace",
                output = {
                    itemRef = "4999dcec:myjwvrpn",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 50,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 5475
            },
            {
                category = "",
                description = "",
                id = "ivaizelw",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
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
                name = "Solid Bronze Ring",
                output = {
                    itemRef = "4999dcec:3a28xic7",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 50,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 5475
            },
            {
                category = "",
                description = "",
                id = "buojxhkg",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:nvc1anz9",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Elegant Silver Ring",
                output = {
                    itemRef = "4999dcec:i24s59ih",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 50,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 5475
            },
            {
                category = "",
                description = "",
                id = "h5wog2ik",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "4999dcec:n2q67aox",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:fcj318z0",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:l3c8nzh7",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Bronze Band of Force",
                output = {
                    itemRef = "4999dcec:9vc8kxod",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 65,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 8655
            },
            {
                category = "",
                description = "",
                id = "fxh5eve2",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "4999dcec:gw6wflop",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Brilliant Necklace",
                output = {
                    itemRef = "4999dcec:j9k51ouo",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 75,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 11175
            },
            {
                category = "",
                description = "",
                id = "hiz3xpxo",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "4999dcec:w1ryslhj",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Bronze Torc",
                output = {
                    itemRef = "4999dcec:a3z4mv5x",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 80,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 12555
            },
            {
                category = "",
                description = "",
                id = "crfblejr",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:nvc1anz9",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Ring of Silver Might",
                output = {
                    itemRef = "4999dcec:jsrc8gdn",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 80,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 12555
            },
            {
                category = "",
                description = "",
                id = "vvv3jn01",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:l3c8nzh7",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Ring of Twilight Shadows",
                output = {
                    itemRef = "4999dcec:nrog69xv",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 100,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 18875
            },
            {
                category = "",
                description = "",
                id = "f0wz6qm3",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:nvc1anz9",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:w1ryslhj",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:gw6wflop",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Heavy Silver Ring",
                output = {
                    itemRef = "4999dcec:qppn0dky",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 90,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 15555
            },
            {
                category = "",
                description = "",
                id = "udboh8zd",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:qgjc3m5m",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Heavy Jade Ring",
                output = {
                    itemRef = "4999dcec:p8uwttif",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 105,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 20655
            },
            {
                category = "",
                description = "",
                id = "i05zs5kk",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:w1ryslhj",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Amulet of the Moon",
                output = {
                    itemRef = "4999dcec:yuyzsuro",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 110,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 22515
            },
            {
                category = "",
                description = "",
                id = "6ttl2kla",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:ov027km6",
                        kind = "rpe_item",
                        quantity = 8
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Barbaric Iron Collar",
                output = {
                    itemRef = "4999dcec:tmu3w5gs",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 110,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 22515
            },
            {
                category = "",
                description = "",
                id = "rsiagpzy",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:nvc1anz9",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "4999dcec:w1ryslhj",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "732368d4:44gfhd49",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Moonsoul Crown",
                output = {
                    itemRef = "4999dcec:60nuv7oo",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 120,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 26475
            },
            {
                category = "",
                description = "",
                id = "q8dtwrkk",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:gw6wflop",
                        kind = "rpe_item",
                        quantity = 3
                    }
                },
                learnMode = "trainer",
                name = "Pendant of the Agate Shield",
                output = {
                    itemRef = "4999dcec:a4v4hlw3",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 120,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 26475
            },
            {
                category = "",
                description = "",
                id = "dmfpxcvv",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
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
                name = "Moonstone Ring",
                output = {
                    itemRef = "4999dcec:roaw553e",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 125,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 28575
            },
            {
                category = "",
                description = "",
                id = "lxx47rxs",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:hqook9xe",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:qgjc3m5m",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Golden Dragon Ring",
                output = {
                    itemRef = "4999dcec:fyqlzdwg",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 135,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 33015
            },
            {
                category = "",
                description = "",
                id = "xfj4d32v",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:hqook9xe",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:gw6wflop",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Heavy Golden Necklace of Battle",
                output = {
                    itemRef = "4999dcec:12tzi40o",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 150,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 40275
            },
            {
                category = "",
                description = "",
                id = "7nycjpcu",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:ht59o8mx",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Blazing Citrine Ring",
                output = {
                    itemRef = "4999dcec:fmgf4wy0",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 150,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 40275
            },
            {
                category = "",
                description = "",
                id = "a65jtkwy",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:qgjc3m5m",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Jade Pendant of Blasting",
                output = {
                    itemRef = "4999dcec:omzu6owk",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 160,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 45515
            },
            {
                category = "",
                description = "",
                id = "g46nz4if",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:qgjc3m5m",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Engraved Truesilver Ring",
                output = {
                    itemRef = "4999dcec:dhn24t1r",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 170,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 51075
            },
            {
                category = "",
                description = "",
                id = "30wyhbls",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "732368d4:ku9j8vhw",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:qgjc3m5m",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "The Jade Eye",
                output = {
                    itemRef = "4999dcec:ea7x1ec9",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 170,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 51075
            },
            {
                category = "",
                description = "",
                id = "d2zf16zu",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:hqook9xe",
                        kind = "rpe_item",
                        quantity = 4
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
                        itemRef = "4999dcec:qgjc3m5m",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Golden Ring of Power",
                output = {
                    itemRef = "4999dcec:t8eqst7e",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 180,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 56955
            },
            {
                category = "",
                description = "",
                id = "ykrpqed1",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:ht59o8mx",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "732368d4:vlwvpmfx",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Citrine Ring of Rapid Healing",
                output = {
                    itemRef = "4999dcec:t7icomfa",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 180,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 56955
            },
            {
                category = "",
                description = "",
                id = "9lzqcq76",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:hqook9xe",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:ht59o8mx",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "732368d4:vlwvpmfx",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:xegz4i5q",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Citrine Pendant of Golden Healing",
                output = {
                    itemRef = "4999dcec:dc42qn0v",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 190,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 63155
            },
            {
                category = "",
                description = "",
                id = "0ehbugcx",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 3
                    },
                    {
                        itemRef = "4999dcec:ht59o8mx",
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
                name = "Truesilver Commander Ring",
                output = {
                    itemRef = "4999dcec:jrf15k1e",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 200,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 69675
            },
            {
                category = "",
                description = "",
                id = "qkktxsp5",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:hqook9xe",
                        kind = "rpe_item",
                        quantity = 6
                    },
                    {
                        itemRef = "4999dcec:ht59o8mx",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Golden Hare Figurine",
                output = {
                    itemRef = "4999dcec:rdmn3b25",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 200,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 69675
            },
            {
                category = "",
                description = "",
                id = "dvxdh3yn",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:qgjc3m5m",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "732368d4:1aesqm2u",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Jade Owl Figurine",
                output = {
                    itemRef = "4999dcec:si0dqr3p",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 200,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 69675
            },
            {
                category = "",
                description = "",
                id = "rqeee4io",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:5nrqhg0t",
                        kind = "rpe_item",
                        quantity = 3
                    }
                },
                learnMode = "trainer",
                name = "Aquamarine Signet",
                output = {
                    itemRef = "4999dcec:2bo3ulm5",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 210,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 76515
            },
            {
                category = "",
                description = "",
                id = "nzd10t0r",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:5nrqhg0t",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 3
                    }
                },
                learnMode = "trainer",
                name = "Aquamarine Pendant of the Warrior",
                output = {
                    itemRef = "4999dcec:ouge9lag",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 220,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 83675
            },
            {
                category = "",
                description = "",
                id = "xagz31np",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:mr1cbt76",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Ruby Crown of Restoration",
                output = {
                    itemRef = "4999dcec:qsdjegxu",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 225,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 87375
            },
            {
                category = "",
                description = "",
                id = "xpnyvx4u",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:mr1cbt76",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Red Ring of Destruction",
                output = {
                    itemRef = "4999dcec:5b6h66b6",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 230,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 91155
            },
            {
                category = "",
                description = "",
                id = "1ckgdti8",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:mr1cbt76",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Ruby Pendant of Fire",
                output = {
                    itemRef = "4999dcec:x53oxl56",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 235,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 95015
            },
            {
                category = "",
                description = "",
                id = "r1mf586f",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "732368d4:lxqnh3pp",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Truesilver Healing Ring",
                output = {
                    itemRef = "4999dcec:1gfq46xr",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 240,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 98955
            },
            {
                category = "",
                description = "",
                id = "mb5btua1",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:5nrqhg0t",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "The Aquamarine Ward",
                output = {
                    itemRef = "4999dcec:qtq4pmjx",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 245,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 102975
            },
            {
                category = "",
                description = "",
                id = "op0ie7j1",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 4
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "732368d4:1mq60axv",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:225h536c",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:pkgfp4sl",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Opal Necklace of Impact",
                output = {
                    itemRef = "4999dcec:jbdnbbjx",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 250,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 107075
            },
            {
                category = "",
                description = "",
                id = "tq4w64qw",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:ufv4fdnf",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:ht59o8mx",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:5nrqhg0t",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Gem Studded Band",
                output = {
                    itemRef = "4999dcec:8dcvumcm",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 250,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 107075
            },
            {
                category = "",
                description = "",
                id = "69917m2v",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:pkgfp4sl",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Simple Opal Ring",
                output = {
                    itemRef = "4999dcec:i397dwhs",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 260,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 115515
            },
            {
                category = "",
                description = "",
                id = "vs2c1kpi",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:atpvfzht",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Diamond Focus Ring",
                output = {
                    itemRef = "4999dcec:rpck2ov0",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 265,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 119855
            },
            {
                category = "",
                description = "",
                id = "btf3x1m7",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:6hy57ood",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:pkgfp4sl",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:bw8sfpgw",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "4999dcec:sviqeucv",
                        kind = "rpe_item",
                        quantity = 2
                    }
                },
                learnMode = "trainer",
                name = "Emerald Crown of Destruction",
                output = {
                    itemRef = "4999dcec:9erta8qd",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 275,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 128775
            },
            {
                category = "",
                description = "",
                id = "kp0sq396",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "732368d4:tfwg197j",
                        kind = "rpe_item",
                        quantity = 1
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Onslaught Ring",
                output = {
                    itemRef = "4999dcec:p1udd9fm",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 280,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 133355
            },
            {
                category = "",
                description = "",
                id = "2dpmswe5",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:atpvfzht",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Glowing Thorium Band",
                output = {
                    itemRef = "4999dcec:jdxq7bzv",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 280,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 133355
            },
            {
                category = "",
                description = "",
                id = "pp5q5nu7",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:bw8sfpgw",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "732368d4:lxqnh3pp",
                        kind = "rpe_item",
                        quantity = 4
                    }
                },
                learnMode = "trainer",
                name = "Living Emerald Pendant",
                output = {
                    itemRef = "4999dcec:bqz47t6w",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 280,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 133355
            },
            {
                category = "",
                description = "",
                id = "wd9cr528",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:bw8sfpgw",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
                        kind = "rpe_item",
                        quantity = 1
                    }
                },
                learnMode = "trainer",
                name = "Emerald Lion Ring",
                output = {
                    itemRef = "4999dcec:a5m2dlbr",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 290,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
                tags = {},
                trainerCostCopper = 142755
            },
            {
                category = "",
                description = "",
                id = "2pq5v5po",
                inputs = {
                    {
                        itemRef = "4999dcec:r0hugqwh",
                        kind = "tool",
                        quantity = 1
                    },
                    {
                        itemRef = "4999dcec:atpvfzht",
                        kind = "rpe_item",
                        quantity = 2
                    },
                    {
                        itemRef = "61fdf3df:5m4zt99z",
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
                name = "Necklace of the Diamond Tower",
                output = {
                    itemRef = "4999dcec:xp2zkejw",
                    maxQuantity = 1,
                    minQuantity = 1
                },
                reagents = {},
                requiredSkillLevel = 300,
                results = {},
                skillRef = "f82db71a:fxp3vo4o",
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
