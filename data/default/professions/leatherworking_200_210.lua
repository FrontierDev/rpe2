local _, Addon = ...

local definitions = Addon.Data
    and Addon.Data.DefaultDatasets
    and Addon.Data.DefaultDatasets.Definitions
    or nil
local definition = definitions and definitions["538a54a0"] or nil

if type(definition) ~= "table" or type(definition.dataset) ~= "table" then
    error("Leatherworking default dataset must be registered before loading the 200-210 extension.")
end

-- This extends the Leatherworking package beyond the previously shipped v2
-- contents. Keep the packaged version authoritative so existing clients update.
definition.version = math.max(tonumber(definition.version) or 0, 3)

local dataset = definition.dataset
dataset.items = dataset.items or {}
dataset.recipes = dataset.recipes or {}

local function replaceRecipeInputs(recipeName, inputs)
    for index = 1, #dataset.recipes do
        local recipe = dataset.recipes[index]
        if type(recipe) == "table" and recipe.name == recipeName then
            recipe.inputs = inputs
            return
        end
    end

    error(("Leatherworking recipe '%s' was not found for packaged correction."):format(recipeName))
end

local function appendUnique(target, entry, entryKind)
    for index = 1, #target do
        local existing = target[index]
        if type(existing) == "table" and existing.id == entry.id then
            error(("Duplicate Leatherworking %s id '%s'."):format(entryKind, tostring(entry.id)))
        end
    end

    target[#target + 1] = entry
end

-- Green Whelp Scales are represented by the existing Green Dragonscale
-- material rather than being flattened into Heavy Leather.
replaceRecipeInputs("Green Whelp Bracers", {
    {
        itemRef = "538a54a0:55k8gjup",
        kind = "rpe_item",
        quantity = 8
    },
    {
        itemRef = "538a54a0:9vp6roos",
        kind = "rpe_item",
        quantity = 1
    }
})

local newItems = {
    {
        allowWowConversion = false,
        armorWeight = "leather",
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
        icon = "interface/icons/inv_gauntlets_32.blp",
        id = "lu2f3kfd",
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
        name = "Shadowskin Gloves",
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
                value = 76
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
            "f82db71a:wasvuom2"
        },
        yellowSockets = 0
    },
    {
        allowWowConversion = false,
        armorWeight = "leather",
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
                            amount = 8,
                            amountMode = "flat",
                            resourceRef = "f82db71a:e2tfklq7",
                            type = "resource"
                        }
                    },
                    triggerTarget = "event_source"
                },
                {
                    chance = 3,
                    combatEventId = "on_melee_hit",
                    effects = {
                        {
                            amount = 8,
                            amountMode = "flat",
                            resourceRef = "f82db71a:e2tfklq7",
                            type = "resource"
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
        icon = "interface/icons/inv_belt_09.blp",
        id = "0lboph96",
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
        name = "Barbaric Belt",
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
                value = 62
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
            "f82db71a:haks0gz4"
        },
        yellowSockets = 0
    },
    {
        allowWowConversion = false,
        armorWeight = "leather",
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
        icon = "interface/icons/inv_helmet_15.blp",
        id = "zxaispjx",
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
        name = "Comfortable Leather Hat",
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
                sourceStatRef = "f82db71a:ygjno50i",
                value = 11
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
            "f82db71a:bgvs1zx6"
        },
        yellowSockets = 0
    },
    {
        allowWowConversion = false,
        armorWeight = "leather",
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
        icon = "interface/icons/inv_boots_07.blp",
        id = "kh5as5nc",
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
        name = "Dusky Boots",
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
                value = 76
            },
            {
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 11
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
            "f82db71a:raiu9t05"
        },
        yellowSockets = 0
    },
    {
        allowWowConversion = false,
        armorWeight = "leather",
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
        icon = "interface/icons/inv_boots_08.blp",
        id = "xwmucx64",
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
        name = "Swift Boots",
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
                value = 76
            },
            {
                sourceStatRef = "f82db71a:ygjno50i",
                value = 10
            },
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
        icon = "interface/icons/inv_gauntlets_05.blp",
        id = "alwzv0yi",
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
        name = "Turtle Scale Gloves",
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
                sourceStatRef = "f82db71a:ygjno50i",
                value = 7
            },
            {
                sourceStatRef = "f82db71a:75y3a8ib",
                value = 6
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
            "f82db71a:wasvuom2"
        },
        yellowSockets = 0
    },
    {
        allowWowConversion = false,
        armorWeight = "leather",
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
        icon = "interface/icons/inv_chest_leather_03.blp",
        id = "bp7hqyc1",
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
        name = "Nightscape Tunic",
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
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 15
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
            "f82db71a:nwfvxbto"
        },
        yellowSockets = 0
    },
    {
        allowWowConversion = false,
        armorWeight = "leather",
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
        icon = "interface/icons/inv_shoulder_07.blp",
        id = "bhfwi0g1",
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
        name = "Nightscape Shoulders",
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
                sourceStatRef = "f82db71a:xqz0daz2",
                value = 11
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
        uniqueFlag = "none",
        validSlotRefs = {
            "f82db71a:66i80qm1"
        },
        yellowSockets = 0
    }
}

for index = 1, #newItems do
    appendUnique(dataset.items, newItems[index], "item")
end

local newRecipes = {
    {
        category = "",
        description = "",
        id = "59k34zl0",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 38
            },
            {
                itemRef = "538a54a0:55k8gjup",
                kind = "rpe_item",
                quantity = 8
            }
        },
        learnMode = "trainer",
        name = "Shadowskin Gloves",
        output = {
            itemRef = "538a54a0:lu2f3kfd",
            maxQuantity = 1,
            minQuantity = 1
        },
        reagents = {},
        requiredSkillLevel = 200,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 69675
    },
    {
        category = "",
        description = "",
        id = "yyd0yjsb",
        inputs = {
            {
                itemRef = "538a54a0:55k8gjup",
                kind = "rpe_item",
                quantity = 14
            },
            {
                itemRef = "61fdf3df:ov027km6",
                kind = "rpe_item",
                quantity = 1
            }
        },
        learnMode = "trainer",
        name = "Barbaric Belt",
        output = {
            itemRef = "538a54a0:0lboph96",
            maxQuantity = 1,
            minQuantity = 1
        },
        reagents = {},
        requiredSkillLevel = 200,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 69675
    },
    {
        category = "",
        description = "",
        id = "jf0j3x6w",
        inputs = {
            {
                itemRef = "538a54a0:55k8gjup",
                kind = "rpe_item",
                quantity = 20
            }
        },
        learnMode = "trainer",
        name = "Comfortable Leather Hat",
        output = {
            itemRef = "538a54a0:zxaispjx",
            maxQuantity = 1,
            minQuantity = 1
        },
        reagents = {},
        requiredSkillLevel = 200,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 69675
    },
    {
        category = "",
        description = "",
        id = "fdm1u0ed",
        inputs = {
            {
                itemRef = "538a54a0:55k8gjup",
                kind = "rpe_item",
                quantity = 8
            },
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 8
            }
        },
        learnMode = "trainer",
        name = "Dusky Boots",
        output = {
            itemRef = "538a54a0:kh5as5nc",
            maxQuantity = 1,
            minQuantity = 1
        },
        reagents = {},
        requiredSkillLevel = 200,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 69675
    },
    {
        category = "",
        description = "",
        id = "qkffy7be",
        inputs = {
            {
                itemRef = "538a54a0:55k8gjup",
                kind = "rpe_item",
                quantity = 10
            }
        },
        learnMode = "trainer",
        name = "Swift Boots",
        output = {
            itemRef = "538a54a0:xwmucx64",
            maxQuantity = 1,
            minQuantity = 1
        },
        reagents = {},
        requiredSkillLevel = 200,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 69675
    },
    {
        category = "",
        description = "",
        id = "aru40ght",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 14
            }
        },
        learnMode = "trainer",
        name = "Turtle Scale Gloves",
        output = {
            itemRef = "538a54a0:alwzv0yi",
            maxQuantity = 1,
            minQuantity = 1
        },
        reagents = {},
        requiredSkillLevel = 205,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 73055
    },
    {
        category = "",
        description = "",
        id = "6npqubrj",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 7
            }
        },
        learnMode = "trainer",
        name = "Nightscape Tunic",
        output = {
            itemRef = "538a54a0:bp7hqyc1",
            maxQuantity = 1,
            minQuantity = 1
        },
        reagents = {},
        requiredSkillLevel = 205,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 73055
    },
    {
        category = "",
        description = "",
        id = "3oo6sxuy",
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = 8
            }
        },
        learnMode = "trainer",
        name = "Nightscape Shoulders",
        output = {
            itemRef = "538a54a0:bhfwi0g1",
            maxQuantity = 1,
            minQuantity = 1
        },
        reagents = {},
        requiredSkillLevel = 210,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = 76515
    }
}

for index = 1, #newRecipes do
    appendUnique(dataset.recipes, newRecipes[index], "recipe")
end
