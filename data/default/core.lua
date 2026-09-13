local _, Addon = ...

Addon.Data.DefaultDatasets:Register({
    version = 5,
    dataset = {
        achievements = {},
        auras = {},
        authorName = "Schutzenberg-ArgentDawn",
        classes = {},
        currencies = {
            {
                category = "",
                description = "",
                icon = "interface/icons/item_holyspark.blp",
                id = "k3aulg3o",
                max = 100,
                name = "Spark of Inspiration",
                tags = {}
            }
        },
        damageSchools = {
            {
                color = {
                    a = 1,
                    b = 0.18,
                    g = 0.58,
                    r = 1
                },
                description = "",
                icon = "interface/icons/ability_golemthunderclap.blp",
                id = "v1azo4j6",
                mitigationCoefficient = 0.1,
                mitigationMode = "percent",
                mitigationReferenceAmount = 10000,
                mitigationReferencePercent = 40,
                mitigationStatRef = "f82db71a:v42albuv",
                name = "Physical",
                tags = {}
            },
            {
                color = {
                    a = 1,
                    b = 0.35,
                    g = 0.35,
                    r = 0.95
                },
                description = "",
                icon = "interface/icons/spell_fire_sealoffire.blp",
                id = "esjguw6d",
                mitigationCoefficient = 0.1,
                mitigationMode = "percent",
                mitigationReferenceAmount = 300,
                mitigationReferencePercent = 75,
                mitigationStatRef = "f82db71a:0w7c7p09",
                name = "Fire",
                tags = {}
            },
            {
                color = {
                    a = 1,
                    b = 0.98,
                    g = 0.66,
                    r = 0.42
                },
                description = "",
                icon = "interface/icons/spell_frost_wizardmark.blp",
                id = "hx7pnwv4",
                mitigationCoefficient = 0.1,
                mitigationMode = "percent",
                mitigationReferenceAmount = 300,
                mitigationReferencePercent = 75,
                mitigationStatRef = "f82db71a:jjn0my8k",
                name = "Frost",
                tags = {}
            },
            {
                color = {
                    a = 1,
                    b = 0.45,
                    g = 0.9,
                    r = 0.35
                },
                description = "",
                icon = "interface/icons/spell_nature_abolishmagic.blp",
                id = "qtr10qyj",
                mitigationCoefficient = 0.1,
                mitigationMode = "percent",
                mitigationReferenceAmount = 300,
                mitigationReferencePercent = 75,
                mitigationStatRef = "f82db71a:pg0ytacb",
                name = "Nature",
                tags = {}
            },
            {
                color = {
                    a = 1,
                    b = 0.78,
                    g = 0.48,
                    r = 0.96
                },
                description = "",
                icon = "interface/icons/spell_arcane_arcane04.blp",
                id = "dtxhglqg",
                mitigationCoefficient = 0.1,
                mitigationMode = "percent",
                mitigationReferenceAmount = 300,
                mitigationReferencePercent = 75,
                mitigationStatRef = "f82db71a:954yunb9",
                name = "Arcane",
                tags = {}
            },
            {
                color = {
                    a = 1,
                    b = 0.96,
                    g = 0.48,
                    r = 0.72
                },
                description = "",
                icon = "interface/icons/spell_shadow_antishadow.blp",
                id = "1ggt4t3v",
                mitigationCoefficient = 0.1,
                mitigationMode = "percent",
                mitigationReferenceAmount = 300,
                mitigationReferencePercent = 75,
                mitigationStatRef = "f82db71a:itpo751d",
                name = "Shadow",
                tags = {}
            },
            {
                color = {
                    a = 1,
                    b = 0.25,
                    g = 0.9,
                    r = 1
                },
                description = "",
                icon = "interface/icons/spell_holy_holybolt.blp",
                id = "wwctys5s",
                mitigationCoefficient = 1,
                mitigationMode = "direct",
                name = "Holy",
                tags = {}
            }
        },
        datasetType = "general",
        dependencies = {
            "61fdf3df"
        },
        description = "",
        groupName = "Core",
        guildSettings = {},
        id = "f82db71a",
        interactions = {},
        itemSlots = {
            {
                icon = "",
                id = "bgvs1zx6",
                name = "Head",
                panelSide = "left",
                priority = 0
            },
            {
                icon = "",
                id = "ujxndj4q",
                name = "Neck",
                panelSide = "left",
                priority = 1
            },
            {
                icon = "",
                id = "66i80qm1",
                name = "Shoulder",
                panelSide = "left",
                priority = 2
            },
            {
                icon = "",
                id = "bqwhrw0g",
                name = "Back",
                panelSide = "left",
                priority = 3
            },
            {
                icon = "",
                id = "nwfvxbto",
                name = "Chest",
                panelSide = "left",
                priority = 4
            },
            {
                icon = "",
                id = "crezt6ix",
                name = "Wrists",
                panelSide = "left",
                priority = 5
            },
            {
                icon = "",
                id = "wasvuom2",
                name = "Hands",
                panelSide = "right",
                priority = 0
            },
            {
                icon = "",
                id = "haks0gz4",
                name = "Waist",
                panelSide = "right",
                priority = 1
            },
            {
                icon = "",
                id = "obmt4ntq",
                name = "Legs",
                panelSide = "right",
                priority = 2
            },
            {
                icon = "",
                id = "raiu9t05",
                name = "Feet",
                panelSide = "right",
                priority = 3
            },
            {
                icon = "",
                id = "cpkcof3z",
                name = "Finger",
                panelSide = "right",
                priority = 4
            },
            {
                icon = "",
                id = "139phg06",
                name = "Trinket",
                panelSide = "right",
                priority = 5
            },
            {
                icon = "",
                id = "d212x0h1",
                name = "Main Hand",
                panelSide = "bottom",
                priority = 0
            },
            {
                icon = "",
                id = "l1hvib8g",
                name = "Off Hand",
                panelSide = "bottom",
                priority = 1
            },
            {
                icon = "",
                id = "q8ve6n6t",
                name = "Ranged",
                panelSide = "bottom",
                priority = 2
            },
            {
                icon = "",
                id = "jsldk6qa",
                name = "Barding",
                panelSide = "bottom",
                priority = 0,
                slotType = "mount"
            },
            {
                icon = "",
                id = "uw353kk1",
                name = "Stirrups",
                panelSide = "bottom",
                priority = 1,
                slotType = "mount"
            },
            {
                icon = "",
                id = "wvzsyfo7",
                name = "Reins",
                panelSide = "bottom",
                priority = 2,
                slotType = "mount"
            },
            {
                icon = "",
                id = "08bs5p7e",
                name = "Banner",
                panelSide = "bottom",
                priority = 3,
                slotType = "mount"
            },
            {
                icon = "",
                id = "a5n86jqc",
                name = "Harness",
                panelSide = "bottom",
                priority = 0,
                slotType = "pet"
            },
            {
                icon = "",
                id = "t2p61bjc",
                name = "Relic",
                panelSide = "bottom",
                priority = 5,
                slotType = "character"
            },
            {
                icon = "",
                id = "atsoi5vr",
                name = "Ammo",
                panelSide = "bottom",
                priority = 4,
                slotType = "character"
            }
        },
        items = {
            {
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
                        minimumValue = 21,
                        showOnTooltip = true,
                        tooltipTextOverride = "",
                        type = "level"
                    }
                },
                consumableElixirType = "",
                consumableType = "",
                damageMode = "range",
                damagePerTurn = 10,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_04.blp",
                id = "iqi3b00q",
                isTwoHanded = false,
                itemLevel = 26,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 37,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 19,
                modificationKind = "generic",
                name = "Longsword",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                armorWeight = "plate",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_chest_plate04.blp",
                id = "tsxyzh5c",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Platemail Armor",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 456
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "plate",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_helmet_03.blp",
                id = "bpgtmi0c",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Platemail Helmet",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 371
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "plate",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_pants_04.blp",
                id = "nyfkkdrd",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Platemail Leggings",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 399
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "plate",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_belt_15.blp",
                id = "apwfqygl",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Platemail Belt",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 257
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "plate",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_boots_plate_08.blp",
                id = "90kb8rco",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Platemail Boots",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 314
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "plate",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_bracer_14.blp",
                id = "1h43t85i",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Platemail Bracers",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 200
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "plate",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_gauntlets_29.blp",
                id = "g0ihm2ol",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Platemail Gloves",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 285
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "mail",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_chest_plate13.blp",
                id = "oitgl14i",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Brigandine Vest",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 259
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "mail",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_helmet_03.blp",
                id = "wct48c4m",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Brigandine Helm",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 211
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "mail",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_pants_03.blp",
                id = "0dza1k5m",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Brigandine Leggings",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 227
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "mail",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_belt_03.blp",
                id = "xb6bgvsg",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Brigandine Belt",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 146
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "mail",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_boots_01.blp",
                id = "619mj8i5",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Brigandine Boots",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 178
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "mail",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_bracer_03.blp",
                id = "ad6b0ofz",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Brigandine Bracers",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 113
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "mail",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_gauntlets_04.blp",
                id = "fxfijg2c",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Brigandine Gloves",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 162
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "shield",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_shield_06.blp",
                id = "bxj40u1t",
                isTwoHanded = false,
                itemLevel = 0,
                itemSetKey = "",
                itemType = "armor",
                maxDamagePerTurn = 0,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 0,
                modificationKind = "generic",
                name = "Crested Heater Shield",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 1457
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:l1hvib8g"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "leather",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_chest_cloth_05.blp",
                id = "3qg6fog7",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Reinforced Leather Vest",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 126
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "leather",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_helmet_15.blp",
                id = "cd0ipx2o",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Reinforced Leather Cap",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 102
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "leather",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_pants_09.blp",
                id = "w6djdp80",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Reinforced Leather Pants",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 110
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "leather",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_belt_16.blp",
                id = "l1z4woqp",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Reinforced Leather Belt",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 71
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "leather",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_boots_08.blp",
                id = "vh03gyim",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Reinforced Leather Boots",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 86
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "leather",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_bracer_03.blp",
                id = "j8fuclxg",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Reinforced Leather Bracers",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 55
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "leather",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_gauntlets_05.blp",
                id = "3ump8rjg",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Reinforced Leather Gloves",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 79
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "cloth",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_shirt_02.blp",
                id = "cq2pqmiv",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Thick Cloth Vest",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 34
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:nwfvxbto"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "cloth",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_helmet_33.blp",
                id = "pw6v2qz0",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Thick Cloth Hood",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:bgvs1zx6"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "cloth",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_pants_12.blp",
                id = "9g9rukio",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Thick Cloth Pants",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 30
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:obmt4ntq"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "cloth",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_belt_06.blp",
                id = "43vskvlk",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Thick Cloth Belt",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 19
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:haks0gz4"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "cloth",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_boots_05.blp",
                id = "se85v47g",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Thick Cloth Shoes",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 24
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:raiu9t05"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "cloth",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_bracer_11.blp",
                id = "u62ewm7z",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Thick Cloth Bracers",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 15
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:crezt6ix"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "cloth",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                icon = "interface/icons/inv_gauntlets_21.blp",
                id = "kzl0zykm",
                isTwoHanded = false,
                itemLevel = 0,
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
                name = "Thick Cloth Gloves",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {
                    {
                        sourceStatRef = "f82db71a:v42albuv",
                        value = 21
                    }
                },
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:wasvuom2"
                },
                yellowSockets = 0
            },
            {
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                damageMode = "range",
                damagePerTurn = 10,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_hammer_07.blp",
                id = "aw608j56",
                isTwoHanded = true,
                itemLevel = 26,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 56,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 37,
                modificationKind = "generic",
                name = "Maul",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:i4pivdig",
                yellowSockets = 0
            },
            {
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                damageMode = "range",
                damagePerTurn = 10,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_throwingaxe_05.blp",
                id = "trn7grs6",
                isTwoHanded = true,
                itemLevel = 26,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 70,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 46,
                modificationKind = "generic",
                name = "Battle Axe",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:9ni3vfas",
                yellowSockets = 0
            },
            {
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                damageMode = "range",
                damagePerTurn = 10,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_throwingaxe_05.blp",
                id = "f2b7c9mc",
                isTwoHanded = true,
                itemLevel = 26,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 60,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 39,
                modificationKind = "generic",
                name = "Dacian Falx",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:z6nh3znw",
                yellowSockets = 0
            },
            {
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                damageMode = "range",
                damagePerTurn = 10,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_mace_01.blp",
                id = "02xhfnwy",
                isTwoHanded = false,
                itemLevel = 26,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 34,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 18,
                modificationKind = "generic",
                name = "Flail",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:i4pivdig",
                yellowSockets = 0
            },
            {
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                damageMode = "range",
                damagePerTurn = 10,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_axe_21.blp",
                id = "m51wfzf0",
                isTwoHanded = false,
                itemLevel = 26,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 36,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 19,
                modificationKind = "generic",
                name = "Double Axe",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:9ni3vfas",
                yellowSockets = 0
            },
            {
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                damageMode = "range",
                damagePerTurn = 10,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_sword_32.blp",
                id = "loxcpw47",
                isTwoHanded = false,
                itemLevel = 26,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 23,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 12,
                modificationKind = "generic",
                name = "Kris",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:y0dnlo8g",
                yellowSockets = 0
            },
            {
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                damageMode = "range",
                damagePerTurn = 10,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_spear_05.blp",
                id = "umj0toyi",
                isTwoHanded = true,
                itemLevel = 26,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 60,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 40,
                modificationKind = "generic",
                name = "Short Spear",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:25s5wyry",
                yellowSockets = 0
            },
            {
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                damageMode = "range",
                damagePerTurn = 10,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_staff_20.blp",
                id = "5u0q9ysm",
                isTwoHanded = true,
                itemLevel = 26,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 55,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 36,
                modificationKind = "generic",
                name = "Long Staff",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                weaponTypeRef = "f82db71a:3y1v01e4",
                yellowSockets = 0
            },
            {
                armorWeight = "cosmetic",
                bindingFlag = "none",
                blueSockets = 0,
                canDisenchant = false,
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
                damagePerTurn = 20,
                damageSchoolRef = "f82db71a:v1azo4j6",
                description = "",
                gemColor = "none",
                genericModificationKey = "",
                greenSockets = 0,
                icon = "interface/icons/inv_weapon_crossbow_02.blp",
                id = "fl1c57hx",
                isTwoHanded = false,
                itemLevel = 21,
                itemSetKey = "",
                itemType = "weapon",
                maxDamagePerTurn = 55,
                maxGenericModificationCounts = {},
                maxModificationCounts = {},
                maxStackSize = 1,
                metaSockets = 0,
                minDamagePerTurn = 36,
                modificationKind = "generic",
                name = "Fine Light Crossbow",
                prismaticSockets = 0,
                quality = "common",
                redSockets = 0,
                sellPrice = 0,
                skillBonuses = {},
                socketTypes = {},
                sockets = {},
                stats = {},
                tags = {
                    "starter"
                },
                targetArmorWeight = "none",
                targetSlotRefs = {},
                uniqueFlag = "none",
                validSlotRefs = {
                    "f82db71a:q8ve6n6t"
                },
                weaponTypeRef = "f82db71a:j2gceby4",
                yellowSockets = 0
            }
        },
        loot = {},
        mounts = {
            {
                description = "",
                icon = "interface/icons/ability_mount_charger.blp",
                id = "fbeqezdx",
                name = "Charger",
                spells = {
                    "f82db71a:wydraqj8"
                },
                stats = {
                    {
                        statRef = "f82db71a:rmtjscxc",
                        value = 40
                    },
                    {
                        statRef = "f82db71a:s1mt6jh9",
                        value = 30
                    }
                }
            }
        },
        name = "_Core",
        pets = {},
        races = {
            {
                description = "The humans are the most populous and the youngest race in Azeroth. The humans have become the de facto leaders of the Alliance, with their youthful ambitions and resilience. The humans are the founders of the Alliance. Their diplomacy skills go back to the Second War, where the seven kingdoms joined together to defeat the Horde.",
                icon = "interface/icons/achievement_character_human_male.blp",
                id = "v17z463g",
                name = "Human",
                resourceProgressions = {},
                skillBonuses = {
                    {
                        skillRef = "f82db71a:b0sh5zo7",
                        value = 5
                    }
                },
                statProgressions = {
                    {
                        initialValue = 20,
                        perLevelValue = 0,
                        statRef = "f82db71a:zfqm8dxp"
                    },
                    {
                        initialValue = 20,
                        perLevelValue = 0,
                        statRef = "f82db71a:xqz0daz2"
                    },
                    {
                        initialValue = 20,
                        perLevelValue = 0,
                        statRef = "f82db71a:75y3a8ib"
                    },
                    {
                        initialValue = 20,
                        perLevelValue = 0,
                        statRef = "f82db71a:kec9rhli"
                    },
                    {
                        initialValue = 20,
                        perLevelValue = 0,
                        statRef = "f82db71a:ygjno50i"
                    }
                },
                traitRefs = {}
            },
            {
                description = "The dwarves are a hardy race, hailing from Khaz Modan in the Eastern Kingdoms. They can trace their heritage back to the Titans; a mutated version of the Earthen servants turned mortal by the Curse of Flesh, originally designed to help shape Azeroth. They went into hibernation in Titan cities for thousands of years following the Sundering, emerging to find themselves mortal.",
                icon = "interface/icons/achievement_character_dwarf_male.blp",
                id = "xx3padtj",
                name = "Dwarf",
                resourceProgressions = {},
                skillBonuses = {
                    {
                        skillRef = "f82db71a:ux4ac40t",
                        value = 5
                    }
                },
                statProgressions = {
                    {
                        initialValue = 22,
                        perLevelValue = 0,
                        statRef = "f82db71a:zfqm8dxp"
                    },
                    {
                        initialValue = 16,
                        perLevelValue = 0,
                        statRef = "f82db71a:xqz0daz2"
                    },
                    {
                        initialValue = 19,
                        perLevelValue = 0,
                        statRef = "f82db71a:75y3a8ib"
                    },
                    {
                        initialValue = 23,
                        perLevelValue = 0,
                        statRef = "f82db71a:ygjno50i"
                    },
                    {
                        initialValue = 19,
                        perLevelValue = 0,
                        statRef = "f82db71a:kec9rhli"
                    }
                }
            }
        },
        recipes = {},
        resources = {
            {
                baseValue = 0,
                color = {
                    a = 1,
                    b = 0.45098039215686,
                    g = 0.90196078431373,
                    r = 0.34901960784314
                },
                description = "Your maximum hitpoints. If you reach zero, you are knocked unconscious or die, depending on your event system.",
                icon = "interface/icons/petbattle_health.blp",
                id = "q2ktkztt",
                multiplier = 10,
                name = "Health",
                regenMode = "derived",
                regenMultiplier = 0.2,
                regenPerSecond = 0,
                regenSourceStatRef = "f82db71a:kec9rhli",
                seedNPCResource = true,
                sourceStatRef = "f82db71a:ygjno50i",
                startsAtZero = false,
                tags = {},
                valueMode = "derived"
            },
            {
                baseValue = 0,
                color = {
                    a = 1,
                    b = 0.98039215686275,
                    g = 0.65882352941176,
                    r = 0.41960784313725
                },
                description = "",
                icon = "interface/icons/inv_misc_ancient_mana.blp",
                id = "4c8mfm99",
                multiplier = 10,
                name = "Mana",
                regenMode = "derived",
                regenMultiplier = 0.2,
                regenPerSecond = 0,
                regenSourceStatRef = "f82db71a:kec9rhli",
                seedNPCResource = true,
                sourceStatRef = "f82db71a:75y3a8ib",
                startsAtZero = false,
                tags = {},
                valueMode = "derived"
            },
            {
                baseValue = 3,
                color = {
                    a = 1,
                    b = 0.65490196078431,
                    g = 0.90196078431373,
                    r = 1
                },
                description = "",
                icon = "interface/icons/spell_holy_holybolt.blp",
                id = "cbjzgaby",
                multiplier = 0,
                name = "Holy Power",
                regenMode = "manual",
                regenMultiplier = 0,
                regenPerSecond = 0,
                seedNPCResource = false,
                special = true,
                startsAtZero = true,
                tags = {},
                valueMode = "manual"
            },
            {
                baseValue = 100,
                color = {
                    a = 1,
                    b = 0.25,
                    g = 0.9,
                    r = 1
                },
                description = "",
                icon = "interface/icons/spell_nature_earthbindtotem.blp",
                id = "c3gaf7dd",
                multiplier = 0,
                name = "Energy",
                regenMode = "manual",
                regenMultiplier = 0,
                regenPerSecond = 10,
                seedNPCResource = false,
                special = false,
                startsAtZero = false,
                tags = {},
                valueMode = "manual"
            },
            {
                baseValue = 100,
                color = {
                    a = 1,
                    b = 0.18039215686275,
                    g = 0.58039215686275,
                    r = 1
                },
                description = "",
                icon = "interface/icons/ability_hunter_mastermarksman.blp",
                id = "soshw4o6",
                multiplier = 0,
                name = "Focus",
                regenMode = "manual",
                regenMultiplier = 0,
                regenPerSecond = 10,
                seedNPCResource = false,
                special = false,
                startsAtZero = false,
                tags = {},
                valueMode = "manual"
            },
            {
                baseValue = 100,
                color = {
                    a = 1,
                    b = 0,
                    g = 0,
                    r = 0.94901960784314
                },
                description = "",
                icon = "interface/icons/ability_racial_bloodrage.blp",
                id = "e2tfklq7",
                multiplier = 0,
                name = "Rage",
                regenMode = "manual",
                regenMultiplier = 0,
                regenPerSecond = 0,
                seedNPCResource = false,
                special = false,
                startsAtZero = true,
                tags = {},
                valueMode = "manual"
            },
            {
                baseValue = 100,
                color = {
                    a = 1,
                    b = 0.92156862745098,
                    g = 0.87843137254902,
                    r = 0.51764705882353
                },
                description = "",
                icon = "interface/icons/spell_deathknight_frozenruneweapon.blp",
                id = "jolh6o6e",
                multiplier = 0,
                name = "Runic Power",
                regenMode = "manual",
                regenMultiplier = 0,
                regenPerSecond = 0,
                seedNPCResource = false,
                special = false,
                startsAtZero = true,
                tags = {},
                valueMode = "manual"
            },
            {
                baseValue = 4,
                color = {
                    a = 1,
                    b = 0.72941176470588,
                    g = 0.90196078431373,
                    r = 0.61176470588235
                },
                description = "",
                icon = "interface/icons/ability_monk_healthsphere.blp",
                id = "p8kik0ep",
                multiplier = 0,
                name = "Chi",
                regenMode = "manual",
                regenMultiplier = 0,
                regenPerSecond = 0,
                seedNPCResource = false,
                special = true,
                startsAtZero = true,
                tags = {},
                valueMode = "manual"
            },
            {
                baseValue = 4,
                color = {
                    a = 1,
                    b = 0.96078431372549,
                    g = 0.67450980392157,
                    r = 0.73333333333333
                },
                description = "",
                icon = "interface/icons/spell_nature_wispsplode.blp",
                id = "v7uxqb9z",
                multiplier = 0,
                name = "Arcane Charge",
                regenMode = "manual",
                regenMultiplier = 0,
                regenPerSecond = 0,
                seedNPCResource = false,
                special = true,
                startsAtZero = true,
                tags = {},
                valueMode = "manual"
            },
            {
                baseValue = 5,
                color = {
                    a = 1,
                    b = 0.34901960784314,
                    g = 0.34901960784314,
                    r = 0.94901960784314
                },
                description = "",
                icon = "interface/icons/ability_backstab.blp",
                id = "1h7yfxff",
                multiplier = 0,
                name = "Combo Points",
                regenMode = "manual",
                regenMultiplier = 0,
                regenPerSecond = 0,
                seedNPCResource = false,
                special = true,
                startsAtZero = true,
                tags = {},
                valueMode = "manual"
            }
        },
        skills = {
            {
                derivedMultiplier = 0.1,
                derivedStatRef = "f82db71a:xqz0daz2",
                description = "This is a test description.",
                icon = "interface/icons/ability_heroicleap.blp",
                id = "65v0ycbw",
                learnMode = "always_available",
                name = "Acrobatics",
                rollable = true,
                skillType = "noncombat"
            },
            {
                derivedMultiplier = 0.1,
                derivedStatRef = "f82db71a:zfqm8dxp",
                description = "",
                icon = "interface/icons/ability_rogue_sprint.blp",
                id = "00kjiotp",
                learnMode = "always_available",
                name = "Athletics",
                rollable = true,
                skillType = "noncombat"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_sword_04.blp",
                id = "t5wlibfx",
                learnMode = "always_available",
                name = "Swords",
                rollable = false,
                skillType = "weapon",
                weaponTypeRef = "f82db71a:z6nh3znw"
            },
            {
                derivedMultiplier = 0.1,
                derivedStatRef = "f82db71a:75y3a8ib",
                description = "",
                icon = "interface/icons/ability_eyeoftheowl.blp",
                id = "b0sh5zo7",
                learnMode = "always_available",
                name = "Perception",
                rollable = true,
                skillType = "noncombat"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_weapon_rifle_01.blp",
                id = "ux4ac40t",
                learnMode = "always_available",
                name = "Guns",
                rollable = false,
                skillType = "weapon",
                weaponType = "none"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_10_specialization_professionbook_blacksmithing_orig.blp",
                id = "6hydytdf",
                learnMode = "always_available",
                name = "Blacksmithing",
                rollable = false,
                skillType = "crafting"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_mace_14.blp",
                id = "rv0tmq5b",
                learnMode = "always_available",
                name = "Maces",
                rollable = false,
                skillType = "weapon",
                weaponTypeRef = "f82db71a:i4pivdig"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_axe_04.blp",
                id = "jeeso2wd",
                learnMode = "always_available",
                name = "Axes",
                rollable = false,
                skillType = "weapon",
                weaponTypeRef = "f82db71a:9ni3vfas"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_weapon_shortblade_05.blp",
                id = "3z6vlkhn",
                learnMode = "always_available",
                name = "Daggers",
                rollable = false,
                skillType = "weapon",
                weaponTypeRef = "f82db71a:y0dnlo8g"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_spear_05.blp",
                id = "nx1avna0",
                learnMode = "always_available",
                name = "Polearms",
                rollable = false,
                skillType = "weapon",
                weaponTypeRef = "f82db71a:25s5wyry"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_staff_21.blp",
                id = "9uqqvzl2",
                learnMode = "always_available",
                name = "Staves",
                rollable = false,
                skillType = "weapon",
                weaponTypeRef = "f82db71a:3y1v01e4"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_gauntlets_04.blp",
                id = "tbvqz1rq",
                learnMode = "always_available",
                name = "Fist Weapons",
                rollable = false,
                skillType = "weapon",
                weaponTypeRef = "f82db71a:gjz2331m"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_weapon_bow_02.blp",
                id = "jn4qbjhu",
                learnMode = "always_available",
                name = "Bows",
                rollable = false,
                skillType = "weapon",
                weaponTypeRef = "f82db71a:l3ce0puc"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_weapon_crossbow_01.blp",
                id = "r80drs6k",
                learnMode = "always_available",
                name = "Crossbows",
                rollable = false,
                skillType = "weapon",
                weaponTypeRef = "f82db71a:j2gceby4"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_weapon_rifle_01.blp",
                id = "9sfjhry4",
                learnMode = "always_available",
                name = "Guns",
                rollable = false,
                skillType = "weapon",
                weaponTypeRef = "f82db71a:anoo8qfp"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/ability_shootwand.blp",
                id = "uakb32ud",
                learnMode = "always_available",
                name = "Wands",
                rollable = false,
                skillType = "weapon",
                weaponTypeRef = "f82db71a:s4q9t5f3"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_throwingknife_02.blp",
                id = "2s4jy7yc",
                learnMode = "always_available",
                name = "Thrown",
                rollable = false,
                skillType = "weapon",
                weaponTypeRef = "f82db71a:we5ul4ne"
            },
            {
                derivedMultiplier = 0.1,
                derivedStatRef = "f82db71a:75y3a8ib",
                description = "",
                icon = "interface/icons/spell_arcane_arcane02.blp",
                id = "m6jng4hl",
                learnMode = "always_available",
                name = "Arcana",
                rollable = true,
                skillType = "noncombat"
            },
            {
                derivedMultiplier = 0.1,
                derivedStatRef = "f82db71a:kec9rhli",
                description = "",
                icon = "interface/icons/spell_holy_sealofsacrifice.blp",
                id = "osdf4q2g",
                learnMode = "always_available",
                name = "Medicine",
                rollable = true,
                skillType = "noncombat"
            },
            {
                derivedMultiplier = 0.1,
                derivedStatRef = "f82db71a:kec9rhli",
                description = "",
                icon = "interface/icons/ability_hunter_beasttaming.blp",
                id = "1rg2ue34",
                learnMode = "always_available",
                name = "Animal Handling",
                rollable = true,
                skillType = "noncombat"
            },
            {
                derivedMultiplier = 0.1,
                derivedStatRef = "f82db71a:75y3a8ib",
                description = "",
                icon = "interface/icons/inv_mask_01.blp",
                id = "8188fykv",
                learnMode = "always_available",
                name = "Deception",
                rollable = true,
                skillType = "noncombat"
            },
            {
                derivedMultiplier = 0.1,
                derivedStatRef = "f82db71a:75y3a8ib",
                description = "",
                icon = "interface/icons/inv_misc_book_11.blp",
                id = "e7mnrzcs",
                learnMode = "always_available",
                name = "History",
                rollable = true,
                skillType = "noncombat"
            },
            {
                derivedMultiplier = 0.1,
                derivedStatRef = "f82db71a:75y3a8ib",
                description = "",
                icon = "interface/icons/spell_shaman_measuredinsight.blp",
                id = "axfdnyb4",
                learnMode = "always_available",
                name = "Insight",
                rollable = true,
                skillType = "noncombat"
            },
            {
                derivedMultiplier = 0.1,
                derivedStatRef = "f82db71a:zfqm8dxp",
                description = "",
                icon = "interface/icons/ability_warrior_endlessrage.blp",
                id = "p559njpu",
                learnMode = "always_available",
                name = "Intimidation",
                rollable = true,
                skillType = "noncombat"
            },
            {
                derivedMultiplier = 0.1,
                derivedStatRef = "f82db71a:75y3a8ib",
                description = "",
                icon = "interface/icons/inv_professions_inscription_scribesmagnifyingglass_gold.blp",
                id = "2eaj9uvp",
                learnMode = "always_available",
                name = "Investigation",
                rollable = true,
                skillType = "noncombat"
            },
            {
                derivedMultiplier = 0.1,
                derivedStatRef = "f82db71a:kec9rhli",
                description = "",
                icon = "interface/icons/spell_nature_protectionformnature.blp",
                id = "cyde874p",
                learnMode = "always_available",
                name = "Nature",
                rollable = true,
                skillType = "noncombat"
            },
            {
                derivedMultiplier = 0.1,
                derivedStatRef = "f82db71a:75y3a8ib",
                description = "",
                icon = "interface/icons/trade_archaeology_delicatemusicbox.blp",
                id = "cgihdd3t",
                learnMode = "always_available",
                name = "Performance",
                rollable = true,
                skillType = "noncombat"
            },
            {
                derivedMultiplier = 0.1,
                derivedStatRef = "f82db71a:75y3a8ib",
                description = "",
                icon = "interface/icons/spell_shadow_seduction.blp",
                id = "6cqclth4",
                learnMode = "always_available",
                name = "Persuasion",
                rollable = true,
                skillType = "noncombat"
            },
            {
                derivedMultiplier = 0.1,
                derivedStatRef = "f82db71a:kec9rhli",
                description = "",
                icon = "interface/icons/spell_holy_prayerofspirit.blp",
                id = "0y7djjai",
                learnMode = "always_available",
                name = "Religion",
                rollable = true,
                skillType = "noncombat"
            },
            {
                derivedMultiplier = 0.1,
                derivedStatRef = "f82db71a:xqz0daz2",
                description = "",
                icon = "interface/icons/inv_misc_bag_11.blp",
                id = "gwgzj5kg",
                learnMode = "always_available",
                name = "Sleight of Hand",
                rollable = true,
                skillType = "noncombat"
            },
            {
                derivedMultiplier = 0.1,
                derivedStatRef = "f82db71a:xqz0daz2",
                description = "",
                icon = "interface/icons/ability_stealth.blp",
                id = "muuwon1r",
                learnMode = "always_available",
                name = "Stealth",
                rollable = true,
                skillType = "noncombat"
            },
            {
                derivedMultiplier = 0.1,
                derivedStatRef = "f82db71a:75y3a8ib",
                description = "",
                icon = "interface/icons/inv_10_dungeonjewelry_explorer_trinket_1compass_color4.blp",
                id = "0ybj39g9",
                learnMode = "always_available",
                name = "Survival",
                rollable = true,
                skillType = "noncombat"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_10_specialization_professionbook_alchemy_color1.blp",
                id = "pdyzyudy",
                learnMode = "always_available",
                name = "Alchemy",
                rollable = false,
                skillType = "crafting"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_10_specialization_professionbook_leatherworking_color1.blp",
                id = "x9qez6bu",
                learnMode = "always_available",
                name = "Leatherworking",
                rollable = false,
                skillType = "crafting"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_10_specialization_professionbook_jewelcrafting_color1.blp",
                id = "fxp3vo4o",
                learnMode = "always_available",
                name = "Jewelcrafting",
                rollable = false,
                skillType = "crafting"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_10_specialization_professionbook_tailoring_color1.blp",
                id = "goqp0alw",
                learnMode = "always_available",
                name = "Tailoring",
                rollable = false,
                skillType = "crafting"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_10_specialization_professionbook_enchanting_color1.blp",
                id = "4keh3nf1",
                learnMode = "always_available",
                name = "Enchanting",
                rollable = false,
                skillType = "crafting"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_misc_profession_book_fishing.blp",
                id = "ahx59weu",
                learnMode = "always_available",
                name = "Fishing",
                rollable = false,
                skillType = "crafting"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_10_specialization_professionbook_cooking_color1.blp",
                id = "l9sc8rji",
                learnMode = "always_available",
                name = "Cooking",
                rollable = false,
                skillType = "crafting"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_10_specialization_professionbook_engineering_color1.blp",
                id = "xprqs3y1",
                learnMode = "always_available",
                name = "Engineering",
                rollable = false,
                skillType = "crafting"
            },
            {
                derivedMultiplier = 1,
                description = "",
                icon = "interface/icons/inv_10_specialization_professionbook_inscription_color1.blp",
                id = "8gf2axb6",
                learnMode = "always_available",
                name = "Inscription",
                rollable = false,
                skillType = "crafting"
            }
        },
        spells = {
            {
                _resourceCostsByPhase = {
                    on_cast_end = {},
                    on_cast_start = {}
                },
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_auto_attack_hit",
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
                            auraRef = "f82db71a:r0r1vl0a",
                            auraStacks = 1,
                            baseDamage = 0,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "auto",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.5,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_auto_attack_taken",
                                "on_critical_hit_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "main_hand"
                        },
                        key = "b7c906d3",
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
                        tooltipTextOverride = "Requires main hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/petbattle_attack.blp",
                id = "z36xzk0w",
                ignoreGCD = false,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Main Hand Attack",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = true,
                spellbookCategory = "",
                tags = {},
                tooltipTemplate = true,
                tooltipTemplateData = {
                    auraSections = {},
                    mainText = "Basic attack. Deal {DAMAGE_1} Physical damage to an enemy.",
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
                triggersGCD = true,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_auto_attack_hit"
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
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "auto",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.8,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_auto_attack_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "main_hand"
                        },
                        key = "5eb0a619",
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
                        tooltipTextOverride = "Must be mounted",
                        type = "mounted",
                        unit = "caster"
                    }
                },
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_rogue_slicedice.blp",
                id = "wydraqj8",
                ignoreGCD = false,
                learnMode = "always_learned",
                mountedCombatOnly = true,
                name = "Mounted Attack",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = false,
                spellbookCategory = "",
                tags = {},
                tooltipTemplate = true,
                totalTicks = 0,
                triggersGCD = true,
                useCooldownCharges = false
            },
            {
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_auto_attack_hit"
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
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "pet",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 1,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_auto_attack_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "none"
                        },
                        key = "b96b0753",
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
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/ability_ghoulfrenzy.blp",
                id = "6uix049h",
                ignoreGCD = false,
                learnMode = "trainer",
                mountedCombatOnly = false,
                name = "Pet Attack",
                range = 0,
                resourceCosts = {
                    {
                        amount = 20,
                        amountMode = "flat",
                        castPhase = "on_cast_end",
                        refundOnInterrupt = 0,
                        resourceRef = "f82db71a:c3gaf7dd"
                    }
                },
                seedNPCSpell = false,
                spellbookCategory = "",
                tags = {},
                tooltipTemplate = true,
                totalTicks = 0,
                triggersGCD = true,
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
                            type = "summon_pet",
                            unitRef = "f82db71a:176uzpns"
                        },
                        key = "9b68b6a9",
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
                icon = "interface/icons/ability_hunter_beastcall.blp",
                id = "gn37lpvz",
                ignoreGCD = true,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Summon Pet",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = false,
                spellbookCategory = "",
                tags = {},
                tooltipTemplate = true,
                totalTicks = 0,
                triggersGCD = false,
                useCooldownCharges = false
            },
            {
                _resourceCostsByPhase = {
                    on_cast_end = {},
                    on_cast_start = {}
                },
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
                            alwaysHits = true,
                            amountMode = "flat",
                            applyAura = false,
                            auraStacks = 1,
                            baseDamage = 10000,
                            damageSchoolRefs = {
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "spell",
                            hitType = "ability",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {},
                            targetEvents = {},
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "none"
                        },
                        key = "23e7b733",
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
                cooldown = 0,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/spell_shadow_demonicfortitude.blp",
                id = "2mxpp23s",
                ignoreGCD = true,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "[TEST] Instant Death",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = false,
                spellbookCategory = "",
                tags = {},
                tooltipTemplate = true,
                totalTicks = 0,
                triggersGCD = false,
                useCooldownCharges = false
            },
            {
                _resourceCostsByPhase = {
                    on_cast_end = {},
                    on_cast_start = {}
                },
                allowDeadTargets = false,
                canMoveWhileCasting = false,
                castTime = 0,
                casterEvents = {
                    "on_auto_attack_hit"
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
                                "f82db71a:v1azo4j6"
                            },
                            damageType = "melee",
                            hitType = "auto",
                            projectilePath = "",
                            projectileSpeed = 0,
                            statScaling = {
                                {
                                    coefficient = 0.5,
                                    statRef = "f82db71a:u7b49vs9"
                                }
                            },
                            targetEvents = {
                                "on_auto_attack_taken"
                            },
                            threatCoefficient = 1,
                            type = "damage",
                            usesProjectile = false,
                            weaponDamageCoefficient = 1,
                            weaponDamageMode = "off_hand"
                        },
                        key = "b7c906d3",
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
                        tooltipTextOverride = "Requires off hand",
                        type = "item_equipped",
                        weaponTypeRefs = {}
                    }
                },
                cooldown = 1,
                cooldownGroup = "",
                cooldownScalesWithHaste = false,
                description = "",
                icon = "interface/icons/petbattle_attack-down.blp",
                id = "zd3t6feq",
                ignoreGCD = true,
                learnMode = "always_learned",
                mountedCombatOnly = false,
                name = "Off Hand Attack",
                range = 0,
                resourceCosts = {},
                seedNPCSpell = true,
                spellbookCategory = "",
                tags = {},
                tooltipTemplate = true,
                totalTicks = 0,
                triggersGCD = false,
                useCooldownCharges = false
            }
        },
        stats = {
            {
                baseValue = 0,
                category = "Primary",
                color = {
                    a = 1,
                    b = 1,
                    g = 1,
                    r = 1
                },
                derivedSources = {},
                description = "Increases your melee attack power, block chance and parry chance.",
                displayMode = "signed_value",
                icon = "interface/icons/spell_nature_strength.blp",
                id = "zfqm8dxp",
                name = "Strength",
                priority = 99,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Primary",
                color = {
                    a = 1,
                    b = 1,
                    g = 1,
                    r = 1
                },
                derivedSources = {},
                description = "Increases your ranged attack power, and slightly increases your melee attack power. Increases your armor, melee critical strike chance and ranged critical strike chance.",
                displayMode = "signed_value",
                icon = "interface/icons/spell_holy_blessingofagility.blp",
                id = "xqz0daz2",
                name = "Agility",
                priority = 98,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Primary",
                color = {
                    a = 1,
                    b = 1,
                    g = 1,
                    r = 1
                },
                derivedSources = {},
                description = "Increases your maximum mana.",
                displayMode = "signed_value",
                icon = "interface/icons/spell_holy_arcaneintellect.blp",
                id = "75y3a8ib",
                name = "Intellect",
                priority = 97,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Primary",
                color = {
                    a = 1,
                    b = 1,
                    g = 1,
                    r = 1
                },
                derivedSources = {},
                description = "Increases your mana and health regeneration.",
                displayMode = "signed_value",
                icon = "interface/icons/spell_shadow_burningspirit.blp",
                id = "kec9rhli",
                name = "Spirit",
                priority = 96,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Primary",
                color = {
                    a = 1,
                    b = 1,
                    g = 1,
                    r = 1
                },
                derivedSources = {},
                description = "Increases your maximum health.",
                displayMode = "signed_value",
                icon = "interface/icons/spell_nature_unyeildingstamina.blp",
                id = "ygjno50i",
                name = "Stamina",
                priority = 98,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Defense",
                color = {
                    a = 1,
                    b = 1,
                    g = 1,
                    r = 1
                },
                derivedSources = {},
                description = "Reduces all physical damage taken.",
                displayMode = "value",
                icon = "interface/icons/garrison_bluearmor.blp",
                id = "v42albuv",
                name = "Armor",
                priority = 101,
                seedNPCStat = true,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Melee",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                derivedSources = {},
                description = "Increases your chance to hit with a melee attack.",
                displayMode = "equip_percent",
                icon = "interface/icons/petbattle_attack.blp",
                id = "wbj4zuf3",
                name = "Melee Hit Chance",
                priority = 29,
                seedNPCStat = true,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Ranged",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                derivedSources = {},
                description = "Increases your chance to hit with a ranged attack.",
                displayMode = "equip_percent",
                icon = "interface/icons/inv_ammo_arrow_04.blp",
                id = "dd88li4c",
                name = "Ranged Hit Chance",
                priority = 28,
                seedNPCStat = true,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Spell",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                derivedSources = {},
                description = "Increases your chance to hit with a spell.",
                displayMode = "equip_percent",
                icon = "interface/icons/inv_enchant_essencemagiclarge.blp",
                id = "v2g0tw0o",
                name = "Spell Hit Chance",
                priority = 27,
                seedNPCStat = true,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Defense",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "Parry",
                derivedSources = {
                    {
                        coefficient = 0.02,
                        sourceStatRef = "f82db71a:zfqm8dxp"
                    }
                },
                description = "Increases your chance to parry an attack.",
                displayMode = "equip_percent",
                icon = "interface/icons/ability_parry.blp",
                id = "tcn0s8kx",
                name = "Parry Chance",
                priority = 26,
                seedNPCStat = true,
                tags = {},
                valueMode = "derived",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Defense",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "Dodge",
                derivedSources = {
                    {
                        coefficient = 0.02,
                        sourceStatRef = "f82db71a:xqz0daz2"
                    }
                },
                description = "Increases your chance to dodge an attack.",
                displayMode = "equip_percent",
                icon = "interface/icons/spell_shadow_shadowward.blp",
                id = "o6113cir",
                name = "Dodge Chance",
                priority = 24,
                seedNPCStat = true,
                tags = {},
                valueMode = "derived",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Defense",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "Block",
                derivedSources = {
                    {
                        coefficient = 0.02,
                        sourceStatRef = "f82db71a:zfqm8dxp"
                    }
                },
                description = "Increases your chance to block an attack.",
                displayMode = "equip_percent",
                icon = "interface/icons/inv_shield_06.blp",
                id = "p8syz5ba",
                name = "Block Chance",
                priority = 23,
                seedNPCStat = true,
                tags = {},
                valueMode = "derived",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Defense",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "Resist",
                derivedSources = {
                    {
                        coefficient = 0.02,
                        sourceStatRef = "f82db71a:75y3a8ib"
                    }
                },
                description = "Increases your chance to fully resist a harmful spell.",
                displayMode = "equip_percent",
                icon = "interface/icons/spell_arcane_arcaneresilience.blp",
                id = "zs1nbz13",
                name = "Magic Resistance",
                priority = 22,
                seedNPCStat = true,
                tags = {},
                valueMode = "derived",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Melee",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {
                    {
                        coefficient = 2,
                        sourceStatRef = "f82db71a:zfqm8dxp"
                    },
                    {
                        coefficient = 1,
                        sourceStatRef = "f82db71a:xqz0daz2"
                    }
                },
                description = "Increases the damage of your melee-based attacks.",
                displayMode = "equip",
                icon = "interface/icons/petbattle_attack.blp",
                id = "u7b49vs9",
                name = "Melee Attack Power",
                priority = 39,
                seedNPCStat = true,
                tags = {},
                valueMode = "derived",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Ranged",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {
                    {
                        coefficient = 2,
                        sourceStatRef = "f82db71a:xqz0daz2"
                    }
                },
                description = "Increases the damage of your ranged attacks.",
                displayMode = "equip",
                icon = "interface/icons/inv_ammo_arrow_04.blp",
                id = "v2rs9cpy",
                name = "Ranged Attack Power",
                priority = 38,
                seedNPCStat = true,
                tags = {},
                valueMode = "derived",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Spell",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "Increases the damage of your damaging spells.",
                displayMode = "equip",
                icon = "interface/icons/inv_enchant_essencemagiclarge.blp",
                id = "7t7xgzcx",
                name = "Spell Power",
                priority = 37,
                seedNPCStat = true,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Melee",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {
                    {
                        coefficient = 0.02,
                        sourceStatRef = "f82db71a:xqz0daz2"
                    }
                },
                description = "",
                displayMode = "equip_percent",
                icon = "interface/icons/petbattle_attack.blp",
                id = "jslmczbi",
                name = "Melee Crit. Chance",
                priority = 35,
                seedNPCStat = true,
                tags = {},
                valueMode = "derived",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Ranged",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {
                    {
                        coefficient = 0.02,
                        sourceStatRef = "f82db71a:xqz0daz2"
                    }
                },
                description = "",
                displayMode = "equip_percent",
                icon = "interface/icons/inv_ammo_arrow_04.blp",
                id = "fercjhm5",
                name = "Ranged Crit. Chance",
                priority = 34,
                seedNPCStat = true,
                tags = {},
                valueMode = "derived",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Spell",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {
                    {
                        coefficient = 0.02,
                        sourceStatRef = "f82db71a:75y3a8ib"
                    }
                },
                description = "",
                displayMode = "equip_percent",
                icon = "interface/icons/inv_enchant_essencemagiclarge.blp",
                id = "69hfqhne",
                name = "Spell Crit. Chance",
                priority = 33,
                seedNPCStat = true,
                tags = {},
                valueMode = "derived",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Resistances",
                color = {
                    a = 1,
                    b = 1,
                    g = 1,
                    r = 1
                },
                defenceLabel = "Resist",
                derivedSources = {},
                description = "",
                displayMode = "signed_value",
                icon = "interface/icons/spell_fire_sealoffire.blp",
                id = "0w7c7p09",
                name = "Fire Resistance",
                priority = 75,
                seedNPCStat = true,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Mounted",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "",
                displayMode = "equip_percent",
                icon = "interface/icons/ability_mount_nightmarehorse.blp",
                id = "rmtjscxc",
                itemLevelWeight = 0,
                name = "Dismount Resistance",
                priority = 19,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 30,
                category = "Utility",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "",
                displayMode = "equip",
                icon = "interface/icons/ability_druid_dash.blp",
                id = "s1mt6jh9",
                itemLevelWeight = 0,
                name = "Movement Speed",
                priority = 85,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Spell",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "",
                displayMode = "equip",
                icon = "interface/icons/spell_holy_greaterheal.blp",
                id = "hj6d4kvy",
                itemLevelWeight = 0,
                name = "Healing Power",
                priority = 36,
                seedNPCStat = true,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Resistances",
                color = {
                    a = 1,
                    b = 1,
                    g = 1,
                    r = 1
                },
                defenceLabel = "Resist",
                derivedSources = {},
                description = "",
                displayMode = "signed_value",
                icon = "interface/icons/spell_frost_wizardmark.blp",
                id = "jjn0my8k",
                name = "Frost Resistance",
                priority = 74,
                seedNPCStat = true,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Resistances",
                color = {
                    a = 1,
                    b = 1,
                    g = 1,
                    r = 1
                },
                defenceLabel = "Resist",
                derivedSources = {},
                description = "",
                displayMode = "signed_value",
                icon = "interface/icons/spell_nature_abolishmagic.blp",
                id = "pg0ytacb",
                name = "Nature Resistance",
                priority = 75,
                seedNPCStat = true,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Resistances",
                color = {
                    a = 1,
                    b = 1,
                    g = 1,
                    r = 1
                },
                defenceLabel = "Resist",
                derivedSources = {},
                description = "",
                displayMode = "signed_value",
                icon = "interface/icons/spell_arcane_blast.blp",
                id = "954yunb9",
                name = "Arcane Resistance",
                priority = 73,
                seedNPCStat = true,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Resistances",
                color = {
                    a = 1,
                    b = 1,
                    g = 1,
                    r = 1
                },
                defenceLabel = "",
                derivedSources = {},
                description = "",
                displayMode = "signed_value",
                icon = "interface/icons/spell_shadow_antishadow.blp",
                id = "itpo751d",
                itemLevelWeight = 0,
                name = "Shadow Resistance",
                priority = 72,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Special",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "",
                displayMode = "equip_percent",
                icon = "interface/icons/ability_dualwieldspecialization.blp",
                id = "gj9wxb0x",
                itemLevelWeight = 0,
                name = "Damage Done",
                priority = 4,
                seedNPCStat = true,
                tags = {},
                valueMode = "manual",
                visibility = false
            },
            {
                baseValue = 0,
                category = "Special",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "",
                displayMode = "equip_percent",
                icon = "interface/icons/ability_dualwieldspecialization.blp",
                id = "pu05li08",
                itemLevelWeight = 0,
                name = "Damage Reduction",
                priority = 3,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Special",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "",
                displayMode = "equip_percent",
                icon = "interface/icons/ability_dualwieldspecialization.blp",
                id = "5pxmfw02",
                itemLevelWeight = 0,
                name = "Healing Done",
                priority = 2,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Special",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "",
                displayMode = "equip_percent",
                icon = "interface/icons/ability_dualwieldspecialization.blp",
                id = "ok80ohz3",
                itemLevelWeight = 0,
                name = "Healing Received",
                priority = 1,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Special",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "",
                displayMode = "equip_percent",
                icon = "interface/icons/ability_dualwieldspecialization.blp",
                id = "j8n012e6",
                itemLevelWeight = 0,
                name = "Threat Generated",
                priority = 0,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = true
            },
            {
                baseValue = 0,
                category = "Special",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "",
                displayMode = "equip_percent",
                icon = "interface/icons/spell_nature_focusedmind.blp",
                id = "i52j0tj3",
                itemLevelWeight = 0,
                name = "Damage vs. Aberrations",
                priority = 0,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = false
            },
            {
                baseValue = 0,
                category = "Special",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "",
                displayMode = "equip_percent",
                icon = "interface/icons/spell_nature_focusedmind.blp",
                id = "vgzlnifw",
                itemLevelWeight = 0,
                name = "Damage vs. Beasts",
                priority = 0,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = false
            },
            {
                baseValue = 0,
                category = "Special",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "",
                displayMode = "equip_percent",
                icon = "interface/icons/spell_nature_focusedmind.blp",
                id = "8mwchweb",
                itemLevelWeight = 0,
                name = "Damage vs. Dragonkin",
                priority = 0,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = false
            },
            {
                baseValue = 0,
                category = "Special",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "",
                displayMode = "equip_percent",
                icon = "interface/icons/spell_nature_focusedmind.blp",
                id = "x1lxi8cf",
                itemLevelWeight = 0,
                name = "Damage vs. Giants",
                priority = 0,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = false
            },
            {
                baseValue = 0,
                category = "Special",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "",
                displayMode = "equip_percent",
                icon = "interface/icons/spell_nature_focusedmind.blp",
                id = "bj6h5ikw",
                itemLevelWeight = 0,
                name = "Damage vs. Humanoids",
                priority = 0,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = false
            },
            {
                baseValue = 0,
                category = "Special",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "",
                displayMode = "equip_percent",
                icon = "interface/icons/spell_nature_focusedmind.blp",
                id = "bh4yvi9u",
                itemLevelWeight = 0,
                name = "Damage vs. Elementals",
                priority = 0,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = false
            },
            {
                baseValue = 0,
                category = "Special",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "",
                displayMode = "equip_percent",
                icon = "interface/icons/spell_nature_focusedmind.blp",
                id = "qh534ffl",
                itemLevelWeight = 0,
                name = "Damage vs. Demons",
                priority = 0,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = false
            },
            {
                baseValue = 0,
                category = "Special",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "",
                displayMode = "equip_percent",
                icon = "interface/icons/spell_nature_focusedmind.blp",
                id = "k66l7jr4",
                itemLevelWeight = 0,
                name = "Damage vs. Mechanical",
                priority = 0,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = false
            },
            {
                baseValue = 0,
                category = "Special",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "",
                displayMode = "equip_percent",
                icon = "interface/icons/spell_nature_focusedmind.blp",
                id = "qi323bx3",
                itemLevelWeight = 0,
                name = "Damage vs. Undead",
                priority = 0,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = false
            },
            {
                baseValue = 0,
                category = "Defense",
                color = {
                    a = 1,
                    b = 0,
                    g = 1,
                    r = 0
                },
                defenceLabel = "",
                derivedSources = {},
                description = "Reduces all critical damage taken.",
                displayMode = "equip",
                icon = "interface/icons/ability_warrior_criticalblock.blp",
                id = "0wyp78x9",
                itemLevelWeight = 0,
                name = "Defense Rating",
                priority = 0,
                seedNPCStat = false,
                tags = {},
                valueMode = "manual",
                visibility = true
            }
        },
        traits = {
            {
                automaticAuras = {},
                category = "",
                conditions = {},
                description = "",
                events = {},
                icon = "interface/icons/inv_enchant_shardbrilliantsmall.blp",
                id = "dm2h660e",
                isClass = false,
                isEnvironmental = false,
                isRacial = true,
                isTalent = false,
                name = "The Human Spirit",
                skillBonuses = {},
                statBonuses = {
                    {
                        operation = "flat",
                        statRef = "f82db71a:kec9rhli",
                        value = 10
                    }
                },
                unlockLevel = 1
            }
        },
        units = {
            {
                __rpeResourceEntryCache = {
                    byRef = {
                        ["f82db71a:4c8mfm99"] = {
                            resourceRef = "f82db71a:4c8mfm99",
                            value = 2250
                        },
                        ["f82db71a:q2ktkztt"] = {
                            resourceRef = "f82db71a:q2ktkztt",
                            value = 2250
                        }
                    },
                    entries = {
                        {
                            resourceRef = "f82db71a:q2ktkztt",
                            value = 2250
                        },
                        {
                            resourceRef = "f82db71a:4c8mfm99",
                            value = 2250
                        }
                    },
                    indexByRef = {
                        ["f82db71a:4c8mfm99"] = 2,
                        ["f82db71a:q2ktkztt"] = 1
                    }
                },
                __rpeStatEntryCache = {
                    byRef = {
                        ["f82db71a:0w7c7p09"] = {
                            statRef = "f82db71a:0w7c7p09",
                            value = 0
                        },
                        ["f82db71a:69hfqhne"] = {
                            statRef = "f82db71a:69hfqhne",
                            value = 5
                        },
                        ["f82db71a:7t7xgzcx"] = {
                            statRef = "f82db71a:7t7xgzcx",
                            value = 300
                        },
                        ["f82db71a:954yunb9"] = {
                            statRef = "f82db71a:954yunb9",
                            value = 0
                        },
                        ["f82db71a:dd88li4c"] = {
                            statRef = "f82db71a:dd88li4c",
                            value = 0
                        },
                        ["f82db71a:fercjhm5"] = {
                            statRef = "f82db71a:fercjhm5",
                            value = 5
                        },
                        ["f82db71a:gj9wxb0x"] = {
                            statRef = "f82db71a:gj9wxb0x",
                            value = 0
                        },
                        ["f82db71a:hj6d4kvy"] = {
                            statRef = "f82db71a:hj6d4kvy",
                            value = 0
                        },
                        ["f82db71a:jjn0my8k"] = {
                            statRef = "f82db71a:jjn0my8k",
                            value = 0
                        },
                        ["f82db71a:jslmczbi"] = {
                            statRef = "f82db71a:jslmczbi",
                            value = 5
                        },
                        ["f82db71a:o6113cir"] = {
                            statRef = "f82db71a:o6113cir",
                            value = 0
                        },
                        ["f82db71a:p8syz5ba"] = {
                            statRef = "f82db71a:p8syz5ba",
                            value = 0
                        },
                        ["f82db71a:pg0ytacb"] = {
                            statRef = "f82db71a:pg0ytacb",
                            value = 0
                        },
                        ["f82db71a:s1mt6jh9"] = {
                            statRef = "f82db71a:s1mt6jh9",
                            value = 30
                        },
                        ["f82db71a:tcn0s8kx"] = {
                            statRef = "f82db71a:tcn0s8kx",
                            value = 0
                        },
                        ["f82db71a:u7b49vs9"] = {
                            statRef = "f82db71a:u7b49vs9",
                            value = 300
                        },
                        ["f82db71a:v2g0tw0o"] = {
                            statRef = "f82db71a:v2g0tw0o",
                            value = 0
                        },
                        ["f82db71a:v2rs9cpy"] = {
                            statRef = "f82db71a:v2rs9cpy",
                            value = 300
                        },
                        ["f82db71a:v42albuv"] = {
                            statRef = "f82db71a:v42albuv",
                            value = 0
                        },
                        ["f82db71a:wbj4zuf3"] = {
                            statRef = "f82db71a:wbj4zuf3",
                            value = 0
                        },
                        ["f82db71a:zs1nbz13"] = {
                            statRef = "f82db71a:zs1nbz13",
                            value = 0
                        }
                    },
                    entries = {
                        {
                            statRef = "f82db71a:v42albuv",
                            value = 0
                        },
                        {
                            statRef = "f82db71a:wbj4zuf3",
                            value = 0
                        },
                        {
                            statRef = "f82db71a:dd88li4c",
                            value = 0
                        },
                        {
                            statRef = "f82db71a:v2g0tw0o",
                            value = 0
                        },
                        {
                            statRef = "f82db71a:tcn0s8kx",
                            value = 0
                        },
                        {
                            statRef = "f82db71a:o6113cir",
                            value = 0
                        },
                        {
                            statRef = "f82db71a:p8syz5ba",
                            value = 0
                        },
                        {
                            statRef = "f82db71a:zs1nbz13",
                            value = 0
                        },
                        {
                            statRef = "f82db71a:u7b49vs9",
                            value = 300
                        },
                        {
                            statRef = "f82db71a:v2rs9cpy",
                            value = 300
                        },
                        {
                            statRef = "f82db71a:7t7xgzcx",
                            value = 300
                        },
                        {
                            statRef = "f82db71a:jslmczbi",
                            value = 5
                        },
                        {
                            statRef = "f82db71a:fercjhm5",
                            value = 5
                        },
                        {
                            statRef = "f82db71a:69hfqhne",
                            value = 5
                        },
                        {
                            statRef = "f82db71a:0w7c7p09",
                            value = 0
                        },
                        {
                            statRef = "f82db71a:hj6d4kvy",
                            value = 0
                        },
                        {
                            statRef = "f82db71a:jjn0my8k",
                            value = 0
                        },
                        {
                            statRef = "f82db71a:pg0ytacb",
                            value = 0
                        },
                        {
                            statRef = "f82db71a:954yunb9",
                            value = 0
                        },
                        {
                            statRef = "f82db71a:gj9wxb0x",
                            value = 0
                        },
                        {
                            statRef = "f82db71a:s1mt6jh9",
                            value = 30
                        }
                    },
                    indexByRef = {
                        ["f82db71a:0w7c7p09"] = 15,
                        ["f82db71a:69hfqhne"] = 14,
                        ["f82db71a:7t7xgzcx"] = 11,
                        ["f82db71a:954yunb9"] = 19,
                        ["f82db71a:dd88li4c"] = 3,
                        ["f82db71a:fercjhm5"] = 13,
                        ["f82db71a:gj9wxb0x"] = 20,
                        ["f82db71a:hj6d4kvy"] = 16,
                        ["f82db71a:jjn0my8k"] = 17,
                        ["f82db71a:jslmczbi"] = 12,
                        ["f82db71a:o6113cir"] = 6,
                        ["f82db71a:p8syz5ba"] = 7,
                        ["f82db71a:pg0ytacb"] = 18,
                        ["f82db71a:s1mt6jh9"] = 21,
                        ["f82db71a:tcn0s8kx"] = 5,
                        ["f82db71a:u7b49vs9"] = 9,
                        ["f82db71a:v2g0tw0o"] = 4,
                        ["f82db71a:v2rs9cpy"] = 10,
                        ["f82db71a:v42albuv"] = 1,
                        ["f82db71a:wbj4zuf3"] = 2,
                        ["f82db71a:zs1nbz13"] = 8
                    }
                },
                appearances = {},
                attributes = {},
                challengeLevel = "normal",
                creatureSize = "medium",
                creatureType = "humanoid",
                id = "dtb3fwk2",
                mainHandWeapon = "61fdf3df:8fp9w74u",
                name = "Darkblade",
                presets = {
                    {
                        appearances = {
                            {
                                cam = 0.4,
                                displayId = 4765,
                                fileDataId = 120294,
                                rot = 0,
                                z = -0.35
                            },
                            {
                                cam = 0.4,
                                displayId = 4762,
                                fileDataId = 120294,
                                rot = 0,
                                z = -0.35
                            }
                        },
                        equipment = {
                            mainHandWeapon = "61fdf3df:8wv368lv"
                        },
                        name = "Marauder",
                        resourceModifiers = {
                            {
                                flatBonus = 0,
                                percentBonus = 10,
                                resourceRef = "f82db71a:q2ktkztt"
                            }
                        },
                        spells = {
                            "f82db71a:z36xzk0w",
                            "f82db71a:zd3t6feq",
                            "7bbb4cb9:0jiq0uoc"
                        },
                        statModifiers = {
                            {
                                flatBonus = 5,
                                percentBonus = 0,
                                statRef = "f82db71a:tcn0s8kx"
                            },
                            {
                                flatBonus = 0,
                                percentBonus = 10,
                                statRef = "f82db71a:u7b49vs9"
                            },
                            {
                                flatBonus = 0,
                                percentBonus = -5,
                                statRef = "f82db71a:zs1nbz13"
                            }
                        }
                    },
                    {
                        appearances = {
                            {
                                cam = 0.45,
                                displayId = 4980,
                                fileDataId = 120263,
                                rot = 0,
                                z = -0.35
                            },
                            {
                                cam = 0.35,
                                displayId = 4973,
                                fileDataId = 120263,
                                rot = 0,
                                z = -0.35
                            }
                        },
                        name = "Sorceress",
                        resourceModifiers = {
                            {
                                flatBonus = 0,
                                percentBonus = -20,
                                resourceRef = "f82db71a:q2ktkztt"
                            }
                        },
                        spells = {
                            "f82db71a:z36xzk0w",
                            "f82db71a:zd3t6feq",
                            "d7c874c4:n6jbep9e",
                            "d7c874c4:300h0gls"
                        },
                        statModifiers = {
                            {
                                flatBonus = 0,
                                percentBonus = 10,
                                statRef = "f82db71a:7t7xgzcx"
                            },
                            {
                                flatBonus = 0,
                                percentBonus = 5,
                                statRef = "f82db71a:69hfqhne"
                            },
                            {
                                flatBonus = 0,
                                percentBonus = 5,
                                statRef = "f82db71a:zs1nbz13"
                            }
                        }
                    },
                    {
                        appearances = {
                            {
                                cam = 0.45,
                                displayId = 4980,
                                fileDataId = 120263,
                                rot = 0,
                                z = -0.35
                            },
                            {
                                cam = 0.35,
                                displayId = 4973,
                                fileDataId = 120263,
                                rot = 0,
                                z = -0.35
                            }
                        },
                        name = "Priestess",
                        resourceModifiers = {
                            {
                                flatBonus = 0,
                                percentBonus = -20,
                                resourceRef = "f82db71a:q2ktkztt"
                            },
                            {
                                flatBonus = 0,
                                percentBonus = 10,
                                resourceRef = "f82db71a:4c8mfm99"
                            }
                        },
                        spells = {
                            "f82db71a:z36xzk0w",
                            "f82db71a:zd3t6feq",
                            "1c1038a7:eet5xd4t",
                            "1c1038a7:rm9rekvj",
                            "1c1038a7:drza38ax"
                        },
                        statModifiers = {
                            {
                                flatBonus = 0,
                                percentBonus = 10,
                                statRef = "f82db71a:hj6d4kvy"
                            },
                            {
                                flatBonus = 0,
                                percentBonus = 5,
                                statRef = "f82db71a:69hfqhne"
                            },
                            {
                                flatBonus = 0,
                                percentBonus = 5,
                                statRef = "f82db71a:zs1nbz13"
                            },
                            {
                                flatBonus = 0,
                                percentBonus = 20,
                                statRef = "f82db71a:7t7xgzcx"
                            }
                        }
                    }
                },
                resistances = {},
                resources = {
                    {
                        resourceRef = "f82db71a:q2ktkztt",
                        value = 2250
                    },
                    {
                        resourceRef = "f82db71a:4c8mfm99",
                        value = 2250
                    }
                },
                spells = {
                    "f82db71a:z36xzk0w",
                    "f82db71a:zd3t6feq"
                },
                stats = {
                    {
                        statRef = "f82db71a:v42albuv",
                        value = 0
                    },
                    {
                        statRef = "f82db71a:wbj4zuf3",
                        value = 0
                    },
                    {
                        statRef = "f82db71a:dd88li4c",
                        value = 0
                    },
                    {
                        statRef = "f82db71a:v2g0tw0o",
                        value = 0
                    },
                    {
                        statRef = "f82db71a:tcn0s8kx",
                        value = 0
                    },
                    {
                        statRef = "f82db71a:o6113cir",
                        value = 0
                    },
                    {
                        statRef = "f82db71a:p8syz5ba",
                        value = 0
                    },
                    {
                        statRef = "f82db71a:zs1nbz13",
                        value = 0
                    },
                    {
                        statRef = "f82db71a:u7b49vs9",
                        value = 300
                    },
                    {
                        statRef = "f82db71a:v2rs9cpy",
                        value = 300
                    },
                    {
                        statRef = "f82db71a:7t7xgzcx",
                        value = 300
                    },
                    {
                        statRef = "f82db71a:jslmczbi",
                        value = 5
                    },
                    {
                        statRef = "f82db71a:fercjhm5",
                        value = 5
                    },
                    {
                        statRef = "f82db71a:69hfqhne",
                        value = 5
                    },
                    {
                        statRef = "f82db71a:0w7c7p09",
                        value = 0
                    },
                    {
                        statRef = "f82db71a:hj6d4kvy",
                        value = 0
                    },
                    {
                        statRef = "f82db71a:jjn0my8k",
                        value = 0
                    },
                    {
                        statRef = "f82db71a:pg0ytacb",
                        value = 0
                    },
                    {
                        statRef = "f82db71a:954yunb9",
                        value = 0
                    },
                    {
                        statRef = "f82db71a:gj9wxb0x",
                        value = 0
                    },
                    {
                        statRef = "f82db71a:s1mt6jh9",
                        value = 30
                    }
                },
                tags = {}
            }
        },
        weaponTypes = {
            {
                allowedSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                icon = "",
                id = "z6nh3znw",
                name = "Sword"
            },
            {
                allowedSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                icon = "",
                id = "i4pivdig",
                name = "Mace"
            },
            {
                allowedSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                icon = "",
                id = "9ni3vfas",
                name = "Axe"
            },
            {
                allowedSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                icon = "",
                id = "y0dnlo8g",
                name = "Dagger"
            },
            {
                allowedSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                icon = "",
                id = "25s5wyry",
                name = "Polearm"
            },
            {
                allowedSlotRefs = {
                    "f82db71a:d212x0h1"
                },
                icon = "",
                id = "3y1v01e4",
                name = "Staff"
            },
            {
                allowedSlotRefs = {
                    "f82db71a:q8ve6n6t"
                },
                icon = "",
                id = "l3ce0puc",
                name = "Bow"
            },
            {
                allowedSlotRefs = {
                    "f82db71a:q8ve6n6t"
                },
                icon = "",
                id = "j2gceby4",
                name = "Crossbow"
            },
            {
                allowedSlotRefs = {
                    "f82db71a:q8ve6n6t"
                },
                icon = "",
                id = "anoo8qfp",
                name = "Gun"
            },
            {
                allowedSlotRefs = {
                    "f82db71a:q8ve6n6t"
                },
                icon = "",
                id = "s4q9t5f3",
                name = "Wand"
            },
            {
                allowedSlotRefs = {
                    "f82db71a:d212x0h1",
                    "f82db71a:l1hvib8g"
                },
                icon = "",
                id = "gjz2331m",
                name = "Fist Weapon"
            },
            {
                allowedSlotRefs = {
                    "f82db71a:q8ve6n6t"
                },
                icon = "",
                id = "we5ul4ne",
                name = "Thrown"
            }
        }
    },
})
