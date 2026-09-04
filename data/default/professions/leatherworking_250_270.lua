local _, Addon = ...

local definitions = Addon.Data
    and Addon.Data.DefaultDatasets
    and Addon.Data.DefaultDatasets.Definitions
    or nil
local definition = definitions and definitions["538a54a0"] or nil

if type(definition) ~= "table" or type(definition.dataset) ~= "table" then
    error("Leatherworking default dataset must be registered before loading the 250-270 extension.")
end

-- Extend the packaged Leatherworking dataset beyond v5 so existing clients
-- receive the new recipes and corrections through normal default-dataset sync.
definition.version = math.max(tonumber(definition.version) or 0, 6)

local dataset = definition.dataset
dataset.items = dataset.items or {}
dataset.recipes = dataset.recipes or {}

local STAT = {
    armor = "f82db71a:v42albuv",
    agility = "f82db71a:xqz0daz2",
    stamina = "f82db71a:ygjno50i",
    intellect = "f82db71a:75y3a8ib",
    spirit = "f82db71a:kec9rhli",
    healingPower = "f82db71a:hj6d4kvy",
    spellPower = "f82db71a:7t7xgzcx",
    fireResistance = "f82db71a:0w7c7p09",
    frostResistance = "f82db71a:jjn0my8k",
    natureResistance = "f82db71a:pg0ytacb",
    arcaneResistance = "f82db71a:954yunb9",
    shadowResistance = "f82db71a:itpo751d",
}

local SLOT = {
    shoulder = "f82db71a:66i80qm1",
    chest = "f82db71a:nwfvxbto",
    wrists = "f82db71a:crezt6ix",
    hands = "f82db71a:wasvuom2",
    legs = "f82db71a:obmt4ntq",
}

local THICK_LEATHER_REF = "538a54a0:u0wy9jz1"
local RUGGED_LEATHER_REF = "538a54a0:4gnkyr9f"
local WORN_DRAGONSCALE_REF = "538a54a0:wd5k2n7q"
local GREEN_DRAGONSCALE_REF = "538a54a0:9vp6roos"

local function findPackagedItemRef(datasetId, itemName)
    local targetDefinition = definitions and definitions[datasetId] or nil
    local targetDataset = targetDefinition and targetDefinition.dataset or nil
    for index = 1, #(targetDataset and targetDataset.items or {}) do
        local item = targetDataset.items[index]
        if type(item) == "table" and item.name == itemName and type(item.id) == "string" and item.id ~= "" then
            return datasetId .. ":" .. item.id
        end
    end

    error(("Packaged material '%s' was not found in dataset '%s'."):format(itemName, datasetId))
end

local JEWEL = {
    jade = findPackagedItemRef("4999dcec", "Jade"),
}

local ENCHANTING = {
    elementalEarth = findPackagedItemRef("732368d4", "Elemental Earth"),
    elementalFire = findPackagedItemRef("732368d4", "Elemental Fire"),
    livingEssence = findPackagedItemRef("732368d4", "Living Essence"),
}

local function input(itemRef, quantity)
    return {
        itemRef = itemRef,
        kind = "rpe_item",
        quantity = quantity,
    }
end

-- Item MP5 is normalized to Spirit at four mana per 5 seconds per one Spirit.
-- Partial Spirit points are discarded. No individual 255-270 item below has
-- intrinsic MP5, but this is the conversion policy for rating-like source data.
local function convertManaPer5ToSpirit(manaPer5)
    return math.floor(math.max(0, tonumber(manaPer5) or 0) / 4)
end

local function findItemByName(itemName)
    for index = 1, #dataset.items do
        local item = dataset.items[index]
        if type(item) == "table" and item.name == itemName then
            return item
        end
    end

    return nil
end

local function findRecipeByName(recipeName)
    for index = 1, #dataset.recipes do
        local recipe = dataset.recipes[index]
        if type(recipe) == "table" and recipe.name == recipeName then
            return recipe
        end
    end

    return nil
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

local function makeStats(entries, manaPer5)
    local stats = {}
    for index = 1, #(entries or {}) do
        local entry = entries[index]
        stats[#stats + 1] = {
            sourceStatRef = entry[1],
            value = entry[2],
        }
    end

    local spiritFromManaPer5 = convertManaPer5ToSpirit(manaPer5)
    if spiritFromManaPer5 > 0 then
        local existingSpirit = nil
        for index = 1, #stats do
            if stats[index].sourceStatRef == STAT.spirit then
                existingSpirit = stats[index]
                break
            end
        end
        if existingSpirit then
            existingSpirit.value = (tonumber(existingSpirit.value) or 0) + spiritFromManaPer5
        else
            stats[#stats + 1] = {
                sourceStatRef = STAT.spirit,
                value = spiritFromManaPer5,
            }
        end
    end

    return stats
end

local function makeArmorItem(options)
    return {
        allowWowConversion = false,
        armorWeight = options.armorWeight,
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
                minimumValue = options.requiredLevel,
                showOnTooltip = true,
                tooltipTextOverride = "",
                type = "level",
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
        icon = options.icon,
        id = options.id,
        isTwoHanded = false,
        itemLevel = options.requiredLevel + 5,
        itemSetKey = "",
        itemType = "armor",
        maxDamagePerTurn = 0,
        maxGenericModificationCounts = { mod = 1 },
        maxModificationCounts = { mod = 1 },
        maxStackSize = 1,
        metaSockets = 0,
        minDamagePerTurn = 0,
        modificationKind = "generic",
        name = options.name,
        prismaticSockets = 0,
        quality = options.quality or "uncommon",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {},
        socketTypes = {},
        sockets = {},
        stats = makeStats(options.stats, options.manaPer5),
        tags = {},
        targetArmorWeight = "none",
        targetSlotRefs = {},
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = { options.slotRef },
        yellowSockets = 0,
    }
end

local function makeRecipe(options)
    return {
        category = "",
        description = "",
        id = options.id,
        inputs = options.inputs or {},
        learnMode = "trainer",
        name = options.name,
        output = {
            itemRef = "538a54a0:" .. options.outputId,
            maxQuantity = 1,
            minQuantity = 1,
        },
        reagents = {},
        requiredSkillLevel = options.skill,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = options.trainerCostCopper,
    }
end

local function correctExistingArmorItem(itemName, options)
    local item = findItemByName(itemName)
    if type(item) ~= "table" then
        error(("Leatherworking item '%s' was not found for packaged correction."):format(itemName))
    end

    item.allowWowConversion = false
    item.armorWeight = options.armorWeight
    item.bindingFlag = "bind_on_equip"
    item.conditions = {
        {
            invert = false,
            minimumValue = options.requiredLevel,
            showOnTooltip = true,
            tooltipTextOverride = "",
            type = "level",
        },
    }
    item.itemLevel = options.requiredLevel + 5
    item.itemType = "armor"
    item.quality = options.quality or "uncommon"
    item.stats = makeStats(options.stats, options.manaPer5)
    item.validSlotRefs = { options.slotRef }
end

local function correctExistingRecipe(recipeName, options)
    local recipe = findRecipeByName(recipeName)
    if type(recipe) ~= "table" then
        error(("Leatherworking recipe '%s' was not found for packaged correction."):format(recipeName))
    end

    recipe.inputs = options.inputs or {}
    recipe.requiredSkillLevel = options.skill
    recipe.skillRef = "f82db71a:x9qez6bu"
    recipe.trainerCostCopper = options.trainerCostCopper
end

local TRAINER_COST = {
    [255] = 111255,
    [260] = 115515,
    [265] = 119855,
    [270] = 124275,
}

-- The base dataset already contains these two Wicked Leather records. Correct
-- them in-place so the package has the exact TBC level/stats and normalized
-- material costs without introducing duplicate items or recipes.
correctExistingArmorItem("Wicked Leather Gauntlets", {
    armorWeight = "leather",
    slotRef = SLOT.hands,
    requiredLevel = 47,
    stats = {
        { STAT.armor, 86 },
        { STAT.agility, 12 },
        { STAT.stamina, 11 },
    },
})
correctExistingRecipe("Wicked Leather Gauntlets", {
    skill = 260,
    inputs = { input(RUGGED_LEATHER_REF, 8) },
    trainerCostCopper = TRAINER_COST[260],
})

correctExistingArmorItem("Wicked Leather Bracers", {
    armorWeight = "leather",
    slotRef = SLOT.wrists,
    requiredLevel = 48,
    stats = {
        { STAT.armor, 61 },
        { STAT.agility, 11 },
        { STAT.stamina, 5 },
    },
})
correctExistingRecipe("Wicked Leather Bracers", {
    skill = 265,
    inputs = { input(RUGGED_LEATHER_REF, 8) },
    trainerCostCopper = TRAINER_COST[265],
})

local newItems = {
    makeArmorItem({
        id = "eo5iira2",
        name = "Heavy Scorpid Bracers",
        armorWeight = "mail",
        slotRef = SLOT.wrists,
        requiredLevel = 46,
        icon = "interface/icons/inv_bracer_09.blp",
        stats = {
            { STAT.armor, 122 },
            { STAT.stamina, 8 },
            { STAT.spirit, 8 },
        },
    }),
    -- The original one-hour on-use magic absorption effect is intentionally
    -- omitted. Only the TBC passive item stats are represented.
    makeArmorItem({
        id = "8l5byojg",
        name = "Dragonscale Breastplate",
        armorWeight = "mail",
        slotRef = SLOT.chest,
        requiredLevel = 46,
        icon = "interface/icons/inv_chest_chain_07.blp",
        quality = "rare",
        stats = {
            { STAT.armor, 306 },
            { STAT.stamina, 10 },
            { STAT.fireResistance, 13 },
            { STAT.frostResistance, 13 },
            { STAT.shadowResistance, 12 },
        },
    }),
    makeArmorItem({
        id = "a2b45s22",
        name = "Green Dragonscale Breastplate",
        armorWeight = "mail",
        slotRef = SLOT.chest,
        requiredLevel = 47,
        icon = "interface/icons/inv_chest_chain_06.blp",
        quality = "rare",
        stats = {
            { STAT.armor, 311 },
            { STAT.stamina, 10 },
            { STAT.spirit, 21 },
            { STAT.natureResistance, 11 },
        },
    }),
    makeArmorItem({
        id = "sm7pymht",
        name = "Chimeric Gloves",
        armorWeight = "leather",
        slotRef = SLOT.hands,
        requiredLevel = 48,
        icon = "interface/icons/inv_gauntlets_23.blp",
        stats = {
            { STAT.armor, 87 },
            { STAT.arcaneResistance, 11 },
            { STAT.natureResistance, 12 },
        },
    }),
    makeArmorItem({
        id = "5us114e3",
        name = "Heavy Scorpid Vest",
        armorWeight = "mail",
        slotRef = SLOT.chest,
        requiredLevel = 48,
        icon = "interface/icons/inv_chest_chain_15.blp",
        stats = {
            { STAT.armor, 288 },
            { STAT.stamina, 16 },
            { STAT.spirit, 15 },
        },
    }),
    makeArmorItem({
        id = "pq3fcbga",
        name = "Runic Leather Gauntlets",
        armorWeight = "leather",
        slotRef = SLOT.hands,
        requiredLevel = 49,
        icon = "interface/icons/inv_gauntlets_31.blp",
        stats = {
            { STAT.armor, 88 },
            { STAT.intellect, 8 },
            { STAT.spirit, 14 },
        },
    }),
    makeArmorItem({
        id = "8ei6gxrk",
        name = "Green Dragonscale Leggings",
        armorWeight = "mail",
        slotRef = SLOT.legs,
        requiredLevel = 49,
        icon = "interface/icons/inv_pants_05.blp",
        quality = "rare",
        stats = {
            { STAT.armor, 282 },
            { STAT.stamina, 10 },
            { STAT.spirit, 22 },
            { STAT.natureResistance, 11 },
        },
    }),
    makeArmorItem({
        id = "lwysa14u",
        name = "Living Shoulders",
        armorWeight = "leather",
        slotRef = SLOT.shoulder,
        requiredLevel = 49,
        icon = "interface/icons/inv_shoulder_18.blp",
        quality = "rare",
        stats = {
            { STAT.armor, 117 },
            { STAT.stamina, 8 },
            { STAT.spirit, 13 },
            { STAT.natureResistance, 3 },
            { STAT.healingPower, 31 },
            { STAT.spellPower, 11 },
        },
    }),
    makeArmorItem({
        id = "6ej1bpa6",
        name = "Volcanic Leggings",
        armorWeight = "leather",
        slotRef = SLOT.legs,
        requiredLevel = 49,
        icon = "interface/icons/inv_pants_06.blp",
        stats = {
            { STAT.armor, 204 },
            { STAT.fireResistance, 20 },
        },
    }),
    makeArmorItem({
        id = "2op3v3cw",
        name = "Ironfeather Shoulders",
        armorWeight = "leather",
        slotRef = SLOT.shoulder,
        requiredLevel = 49,
        icon = "interface/icons/inv_shoulder_06.blp",
        quality = "rare",
        stats = {
            { STAT.armor, 117 },
            { STAT.intellect, 20 },
            { STAT.spirit, 8 },
        },
    }),
}

for index = 1, #newItems do
    appendUnique(dataset.items, newItems[index], "item")
end

-- Heavy Scorpid Scale and Chimera Leather are normalized 1:1 to Rugged
-- Leather. Cured Thick Hide remains 1 hide -> 4 Thick Leather. Runecloth,
-- thread, dyes and absent miscellaneous reagents remain omitted.
local newRecipes = {
    makeRecipe({
        id = "y0sijcyd",
        name = "Heavy Scorpid Bracers",
        outputId = "eo5iira2",
        skill = 255,
        inputs = {
            input(RUGGED_LEATHER_REF, 8),
        },
        trainerCostCopper = TRAINER_COST[255],
    }),
    makeRecipe({
        id = "x5u9d1n2",
        name = "Dragonscale Breastplate",
        outputId = "8l5byojg",
        skill = 255,
        inputs = {
            input(THICK_LEATHER_REF, 56),
            input(WORN_DRAGONSCALE_REF, 30),
        },
        trainerCostCopper = TRAINER_COST[255],
    }),
    makeRecipe({
        id = "pjj8djmq",
        name = "Green Dragonscale Breastplate",
        outputId = "a2b45s22",
        skill = 260,
        inputs = {
            input(RUGGED_LEATHER_REF, 20),
            input(GREEN_DRAGONSCALE_REF, 25),
        },
        trainerCostCopper = TRAINER_COST[260],
    }),
    makeRecipe({
        id = "iecknb7y",
        name = "Chimeric Gloves",
        outputId = "sm7pymht",
        skill = 265,
        inputs = {
            input(RUGGED_LEATHER_REF, 12),
        },
        trainerCostCopper = TRAINER_COST[265],
    }),
    makeRecipe({
        id = "pbk8u14g",
        name = "Heavy Scorpid Vest",
        outputId = "5us114e3",
        skill = 265,
        inputs = {
            input(RUGGED_LEATHER_REF, 12),
        },
        trainerCostCopper = TRAINER_COST[265],
    }),
    makeRecipe({
        id = "i5e4ona0",
        name = "Runic Leather Gauntlets",
        outputId = "pq3fcbga",
        skill = 270,
        inputs = {
            input(RUGGED_LEATHER_REF, 10),
        },
        trainerCostCopper = TRAINER_COST[270],
    }),
    makeRecipe({
        id = "5bn80xh5",
        name = "Green Dragonscale Leggings",
        outputId = "8ei6gxrk",
        skill = 270,
        inputs = {
            input(RUGGED_LEATHER_REF, 20),
            input(GREEN_DRAGONSCALE_REF, 25),
        },
        trainerCostCopper = TRAINER_COST[270],
    }),
    makeRecipe({
        id = "7ly5zi5s",
        name = "Living Shoulders",
        outputId = "lwysa14u",
        skill = 270,
        inputs = {
            input(RUGGED_LEATHER_REF, 12),
            input(ENCHANTING.livingEssence, 4),
        },
        trainerCostCopper = TRAINER_COST[270],
    }),
    makeRecipe({
        id = "cup9drtq",
        name = "Volcanic Leggings",
        outputId = "6ej1bpa6",
        skill = 270,
        inputs = {
            input(RUGGED_LEATHER_REF, 6),
            input(ENCHANTING.elementalFire, 1),
            input(ENCHANTING.elementalEarth, 1),
        },
        trainerCostCopper = TRAINER_COST[270],
    }),
    makeRecipe({
        id = "n5k9uzfn",
        name = "Ironfeather Shoulders",
        outputId = "2op3v3cw",
        skill = 270,
        inputs = {
            input(RUGGED_LEATHER_REF, 24),
            input(JEWEL.jade, 2),
        },
        trainerCostCopper = TRAINER_COST[270],
    }),
}

for index = 1, #newRecipes do
    appendUnique(dataset.recipes, newRecipes[index], "recipe")
end
