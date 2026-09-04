local _, Addon = ...

local definitions = Addon.Data
    and Addon.Data.DefaultDatasets
    and Addon.Data.DefaultDatasets.Definitions
    or nil
local definition = definitions and definitions["538a54a0"] or nil

if type(definition) ~= "table" or type(definition.dataset) ~= "table" then
    error("Leatherworking default dataset must be registered before loading the 270-295 extension.")
end

definition.version = math.max(tonumber(definition.version) or 0, 7)

local dataset = definition.dataset
dataset.items = dataset.items or {}
dataset.recipes = dataset.recipes or {}

local STAT = {
    armor = "f82db71a:v42albuv",
    agility = "f82db71a:xqz0daz2",
    strength = "f82db71a:zfqm8dxp",
    stamina = "f82db71a:ygjno50i",
    intellect = "f82db71a:75y3a8ib",
    spirit = "f82db71a:kec9rhli",
    healingPower = "f82db71a:hj6d4kvy",
    spellPower = "f82db71a:7t7xgzcx",
    meleeAttackPower = "f82db71a:u7b49vs9",
    meleeCrit = "f82db71a:jslmczbi",
    dodge = "f82db71a:o6113cir",
    fireResistance = "f82db71a:0w7c7p09",
    natureResistance = "f82db71a:pg0ytacb",
    arcaneResistance = "f82db71a:954yunb9",
}

local SLOT = {
    head = "f82db71a:bgvs1zx6",
    shoulder = "f82db71a:66i80qm1",
    chest = "f82db71a:nwfvxbto",
    wrists = "f82db71a:crezt6ix",
    hands = "f82db71a:wasvuom2",
    waist = "f82db71a:haks0gz4",
    legs = "f82db71a:obmt4ntq",
    feet = "f82db71a:raiu9t05",
}

local RUGGED_LEATHER_REF = "538a54a0:4gnkyr9f"
local GUARDIAN_STONE_REF = "3eb7e9bb:hq608hly"
local FIERY_CORE_REF = "3eb7e9bb:e0tarf0p"
local LAVA_CORE_REF = "3eb7e9bb:g3ytywfw"

local function findPackagedItemRef(datasetId, itemName)
    local packaged = definitions and definitions[datasetId] or nil
    local sourceDataset = packaged and packaged.dataset or nil
    for index = 1, #(sourceDataset and sourceDataset.items or {}) do
        local item = sourceDataset.items[index]
        if type(item) == "table" and item.name == itemName and type(item.id) == "string" and item.id ~= "" then
            return datasetId .. ":" .. item.id
        end
    end

    error(("Packaged material '%s' was not found in dataset '%s'."):format(itemName, datasetId))
end

local function findLeatherworkingItemRef(itemName)
    for index = 1, #dataset.items do
        local item = dataset.items[index]
        if type(item) == "table" and item.name == itemName and type(item.id) == "string" and item.id ~= "" then
            return "538a54a0:" .. item.id
        end
    end

    error(("Leatherworking material '%s' was not found."):format(itemName))
end

local JEWEL = {
    blackPearl = findPackagedItemRef("4999dcec", "Black Pearl"),
    jade = findPackagedItemRef("4999dcec", "Jade"),
}

local ENCHANTING = {
    elementalWater = findPackagedItemRef("732368d4", "Elemental Water"),
    elementalAir = findPackagedItemRef("732368d4", "Elemental Air"),
    livingEssence = findPackagedItemRef("732368d4", "Living Essence"),
    enchantedLeather = findPackagedItemRef("732368d4", "Enchanted Leather"),
}

local GREEN_DRAGONSCALE_REF = findLeatherworkingItemRef("Green Dragonscale")
local BLUE_DRAGONSCALE_REF = findLeatherworkingItemRef("Blue Dragonscale")
local BLACK_DRAGONSCALE_REF = findLeatherworkingItemRef("Black Dragonscale")

local function input(itemRef, quantity)
    return {
        itemRef = itemRef,
        kind = "rpe_item",
        quantity = quantity,
    }
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

local function convertCombatRating(kind, rating)
    local refs = {
        critical_strike = STAT.meleeCrit,
        dodge = STAT.dodge,
    }
    local statRef = refs[kind]
    if not statRef then
        error(("Unsupported combat rating kind '%s'."):format(tostring(kind)))
    end
    return statRef, math.floor(math.max(0, tonumber(rating) or 0) / 10)
end

local function makeStats(entries, ratingBonuses)
    local stats = {}
    for index = 1, #(entries or {}) do
        local entry = entries[index]
        stats[#stats + 1] = {
            sourceStatRef = entry[1],
            value = entry[2],
        }
    end
    for index = 1, #(ratingBonuses or {}) do
        local rating = ratingBonuses[index]
        local statRef, value = convertCombatRating(rating.kind, rating.rating)
        if value > 0 then
            stats[#stats + 1] = {
                sourceStatRef = statRef,
                value = value,
            }
        end
    end
    return stats
end

local function cappedItemLevel(requiredLevel, quality)
    local sourceLevel = math.max(1, math.floor(tonumber(requiredLevel) or 1)) + 5
    local cap = quality == "epic" and 60 or 55
    return math.min(sourceLevel, cap)
end

local function makeArmorItem(options)
    local quality = options.quality or "uncommon"
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
        itemLevel = cappedItemLevel(options.requiredLevel, quality),
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
        quality = quality,
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = {},
        socketTypes = {},
        sockets = {},
        stats = makeStats(options.stats, options.ratingBonuses),
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
    local quality = options.quality or "uncommon"
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
    item.itemLevel = cappedItemLevel(options.requiredLevel, quality)
    item.itemType = "armor"
    item.quality = quality
    item.stats = makeStats(options.stats, options.ratingBonuses)
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
    [275] = 128775,
    [280] = 133355,
    [285] = 138015,
    [290] = 142755,
    [295] = 147575,
}

-- These items already exist in the base package. Correct them in place rather
-- than adding duplicate records. The uncommon/rare item-level cap is 55.
correctExistingArmorItem("Wicked Leather Headband", {
    armorWeight = "leather",
    slotRef = SLOT.head,
    requiredLevel = 51,
    stats = {
        { STAT.armor, 118 },
        { STAT.agility, 16 },
        { STAT.stamina, 16 },
    },
})
correctExistingRecipe("Wicked Leather Headband", {
    skill = 280,
    inputs = { input(RUGGED_LEATHER_REF, 12) },
    trainerCostCopper = TRAINER_COST[280],
})

correctExistingArmorItem("Wicked Leather Pants", {
    armorWeight = "leather",
    slotRef = SLOT.legs,
    requiredLevel = 53,
    stats = {
        { STAT.armor, 131 },
        { STAT.agility, 20 },
        { STAT.stamina, 12 },
    },
})
correctExistingRecipe("Wicked Leather Pants", {
    skill = 290,
    inputs = { input(RUGGED_LEATHER_REF, 20) },
    trainerCostCopper = TRAINER_COST[290],
})

local newItems = {
    makeArmorItem({ id = "2q7dgadx", name = "Heavy Scorpid Gauntlet", armorWeight = "mail", slotRef = SLOT.hands, requiredLevel = 50, icon = "interface/icons/inv_gauntlets_24.blp", stats = { { STAT.armor, 186 }, { STAT.stamina, 12 }, { STAT.spirit, 12 } } }),
    makeArmorItem({ id = "hclssw0e", name = "Runic Leather Bracers", armorWeight = "leather", slotRef = SLOT.wrists, requiredLevel = 50, icon = "interface/icons/inv_bracer_11.blp", stats = { { STAT.armor, 63 }, { STAT.intellect, 10 }, { STAT.spirit, 10 } } }),
    makeArmorItem({ id = "tmv0pu1u", name = "Stormshroud Pants", armorWeight = "leather", slotRef = SLOT.legs, requiredLevel = 50, icon = "interface/icons/inv_pants_09.blp", quality = "rare", stats = { { STAT.armor, 138 } }, ratingBonuses = { { kind = "critical_strike", rating = 28 }, { kind = "dodge", rating = 12 } } }),
    makeArmorItem({ id = "9oubdxly", name = "Warbear Harness", armorWeight = "leather", slotRef = SLOT.chest, requiredLevel = 50, icon = "interface/icons/inv_chest_leather_04.blp", quality = "rare", stats = { { STAT.armor, 158 }, { STAT.strength, 11 }, { STAT.stamina, 27 } } }),
    makeArmorItem({ id = "hiaxkufq", name = "Green Dragonscale Gauntlets", armorWeight = "mail", slotRef = SLOT.hands, requiredLevel = 51, icon = "interface/icons/inv_gauntlets_12.blp", quality = "rare", stats = { { STAT.armor, 208 }, { STAT.stamina, 5 }, { STAT.spirit, 18 }, { STAT.natureResistance, 9 } } }),
    makeArmorItem({ id = "xvi3ut31", name = "Heavy Scorpid Belt", armorWeight = "mail", slotRef = SLOT.waist, requiredLevel = 51, icon = "interface/icons/inv_belt_03.blp", stats = { { STAT.armor, 170 }, { STAT.stamina, 12 }, { STAT.spirit, 12 } } }),
    makeArmorItem({ id = "03tc8aq5", name = "Runic Leather Belt", armorWeight = "leather", slotRef = SLOT.waist, requiredLevel = 51, icon = "interface/icons/inv_belt_23.blp", stats = { { STAT.armor, 82 }, { STAT.intellect, 14 }, { STAT.spirit, 9 } } }),
    makeArmorItem({ id = "ra69ai5u", name = "Blue Dragonscale Breastplate", armorWeight = "mail", slotRef = SLOT.chest, requiredLevel = 52, icon = "interface/icons/inv_chest_chain_04.blp", quality = "rare", stats = { { STAT.armor, 338 }, { STAT.intellect, 28 }, { STAT.spirit, 8 }, { STAT.arcaneResistance, 8 } } }),
    makeArmorItem({ id = "oewffbj4", name = "Living Leggings", armorWeight = "leather", slotRef = SLOT.legs, requiredLevel = 52, icon = "interface/icons/inv_pants_11.blp", quality = "rare", stats = { { STAT.armor, 142 }, { STAT.stamina, 8 }, { STAT.spirit, 25 }, { STAT.natureResistance, 5 }, { STAT.healingPower, 26 }, { STAT.spellPower, 9 } } }),
    makeArmorItem({ id = "nanqe7nt", name = "Stormshroud Armor", armorWeight = "leather", slotRef = SLOT.chest, requiredLevel = 52, icon = "interface/icons/inv_chest_leather_08.blp", quality = "rare", stats = { { STAT.armor, 163 } }, ratingBonuses = { { kind = "critical_strike", rating = 28 }, { kind = "dodge", rating = 12 } } }),
    makeArmorItem({ id = "l0m62g4z", name = "Warbear Woolies", armorWeight = "leather", slotRef = SLOT.legs, requiredLevel = 52, icon = "interface/icons/inv_pants_12.blp", quality = "rare", stats = { { STAT.armor, 142 }, { STAT.strength, 28 }, { STAT.stamina, 12 } } }),
    makeArmorItem({ id = "bitqvvq4", name = "Black Dragonscale Breastplate", armorWeight = "mail", slotRef = SLOT.chest, requiredLevel = 53, icon = "interface/icons/inv_chest_chain_07.blp", quality = "rare", stats = { { STAT.armor, 344 }, { STAT.stamina, 8 }, { STAT.fireResistance, 12 }, { STAT.meleeAttackPower, 50 } } }),
    makeArmorItem({ id = "fvqbcdu6", name = "Dawn Treaders", armorWeight = "leather", slotRef = SLOT.feet, requiredLevel = 53, icon = "interface/icons/inv_boots_08.blp", quality = "rare", stats = { { STAT.armor, 114 }, { STAT.stamina, 18 } }, ratingBonuses = { { kind = "dodge", rating = 12 } } }),
    makeArmorItem({ id = "ks88fs1b", name = "Devilsaur Gauntlets", armorWeight = "leather", slotRef = SLOT.hands, requiredLevel = 53, icon = "interface/icons/inv_gauntlets_26.blp", quality = "rare", stats = { { STAT.armor, 103 }, { STAT.stamina, 9 }, { STAT.meleeAttackPower, 28 } }, ratingBonuses = { { kind = "critical_strike", rating = 14 } } }),
    makeArmorItem({ id = "x87dzazi", name = "Ironfeather Breastplate", armorWeight = "leather", slotRef = SLOT.chest, requiredLevel = 53, icon = "interface/icons/inv_chest_leather_06.blp", quality = "rare", stats = { { STAT.armor, 165 }, { STAT.intellect, 12 }, { STAT.spirit, 28 } } }),
    makeArmorItem({ id = "tdwjdyz6", name = "Might of the Timbermaw", armorWeight = "leather", slotRef = SLOT.waist, requiredLevel = 53, icon = "interface/icons/inv_belt_09.blp", quality = "rare", stats = { { STAT.armor, 93 }, { STAT.strength, 21 }, { STAT.stamina, 9 } } }),
    makeArmorItem({ id = "tw0g1cvc", name = "Runic Leather Headband", armorWeight = "leather", slotRef = SLOT.head, requiredLevel = 53, icon = "interface/icons/inv_helmet_04.blp", stats = { { STAT.armor, 122 }, { STAT.intellect, 20 }, { STAT.spirit, 12 } } }),
    makeArmorItem({ id = "rkpmrmia", name = "Blue Dragonscale Shoulders", armorWeight = "mail", slotRef = SLOT.shoulder, requiredLevel = 54, icon = "interface/icons/inv_shoulder_18.blp", quality = "rare", stats = { { STAT.armor, 262 }, { STAT.intellect, 21 }, { STAT.spirit, 6 }, { STAT.arcaneResistance, 6 } } }),
    makeArmorItem({ id = "a2c6cukq", name = "Corehound Boots", armorWeight = "leather", slotRef = SLOT.feet, requiredLevel = 54, icon = "interface/icons/inv_boots_07.blp", quality = "epic", stats = { { STAT.armor, 144 }, { STAT.agility, 13 }, { STAT.stamina, 10 }, { STAT.fireResistance, 24 } } }),
    makeArmorItem({ id = "4uu60rsl", name = "Heavy Scorpid Helm", armorWeight = "mail", slotRef = SLOT.head, requiredLevel = 54, icon = "interface/icons/inv_helmet_20.blp", stats = { { STAT.armor, 258 }, { STAT.stamina, 20 }, { STAT.spirit, 13 } } }),
    makeArmorItem({ id = "ei28au20", name = "Stormshroud Shoulders", armorWeight = "leather", slotRef = SLOT.shoulder, requiredLevel = 54, icon = "interface/icons/inv_shoulder_05.blp", quality = "rare", stats = { { STAT.armor, 126 }, { STAT.stamina, 12 } }, ratingBonuses = { { kind = "critical_strike", rating = 14 }, { kind = "dodge", rating = 12 } } }),
}

for index = 1, #newItems do
    appendUnique(dataset.items, newItems[index], "item")
end

-- Scorpid scales, Warbear Leather and Devilsaur Leather are normalized 1:1 to
-- Rugged Leather. Cured Rugged Hide contributes four Rugged Leather. Core
-- Leather contributes five Rugged Leather. Mojo, thread, cloth, dyes and other
-- absent miscellaneous reagents are omitted. Explicit dragonscales, gems,
-- enchanting materials and known Misc materials remain distinct inputs.
local newRecipes = {
    makeRecipe({ id = "xm8l9f5z", name = "Heavy Scorpid Gauntlet", outputId = "2q7dgadx", skill = 275, inputs = { input(RUGGED_LEATHER_REF, 14) }, trainerCostCopper = TRAINER_COST[275] }),
    makeRecipe({ id = "w4fgi0t2", name = "Runic Leather Bracers", outputId = "hclssw0e", skill = 275, inputs = { input(RUGGED_LEATHER_REF, 6), input(JEWEL.blackPearl, 1) }, trainerCostCopper = TRAINER_COST[275] }),
    makeRecipe({ id = "uelugxmz", name = "Stormshroud Pants", outputId = "tmv0pu1u", skill = 275, inputs = { input(RUGGED_LEATHER_REF, 16), input(ENCHANTING.elementalWater, 2), input(ENCHANTING.elementalAir, 2) }, trainerCostCopper = TRAINER_COST[275] }),
    makeRecipe({ id = "vds6pvf4", name = "Warbear Harness", outputId = "9oubdxly", skill = 275, inputs = { input(RUGGED_LEATHER_REF, 40) }, trainerCostCopper = TRAINER_COST[275] }),
    makeRecipe({ id = "tp4yc2yk", name = "Green Dragonscale Gauntlets", outputId = "hiaxkufq", skill = 280, inputs = { input(RUGGED_LEATHER_REF, 24), input(GREEN_DRAGONSCALE_REF, 30) }, trainerCostCopper = TRAINER_COST[280] }),
    makeRecipe({ id = "kmbe6hwp", name = "Heavy Scorpid Belt", outputId = "xvi3ut31", skill = 280, inputs = { input(RUGGED_LEATHER_REF, 14) }, trainerCostCopper = TRAINER_COST[280] }),
    makeRecipe({ id = "uriphvw2", name = "Runic Leather Belt", outputId = "03tc8aq5", skill = 280, inputs = { input(RUGGED_LEATHER_REF, 12) }, trainerCostCopper = TRAINER_COST[280] }),
    makeRecipe({ id = "rbenmzxp", name = "Blue Dragonscale Breastplate", outputId = "ra69ai5u", skill = 285, inputs = { input(RUGGED_LEATHER_REF, 32), input(BLUE_DRAGONSCALE_REF, 30) }, trainerCostCopper = TRAINER_COST[285] }),
    makeRecipe({ id = "i7lp9jtr", name = "Living Leggings", outputId = "oewffbj4", skill = 285, inputs = { input(RUGGED_LEATHER_REF, 20), input(ENCHANTING.livingEssence, 6) }, trainerCostCopper = TRAINER_COST[285] }),
    makeRecipe({ id = "akay3rx4", name = "Stormshroud Armor", outputId = "nanqe7nt", skill = 285, inputs = { input(RUGGED_LEATHER_REF, 20), input(ENCHANTING.elementalWater, 3), input(ENCHANTING.elementalAir, 3) }, trainerCostCopper = TRAINER_COST[285] }),
    makeRecipe({ id = "6xyq22ju", name = "Warbear Woolies", outputId = "l0m62g4z", skill = 285, inputs = { input(RUGGED_LEATHER_REF, 38) }, trainerCostCopper = TRAINER_COST[285] }),
    makeRecipe({ id = "xb3h5tvh", name = "Black Dragonscale Breastplate", outputId = "bitqvvq4", skill = 290, inputs = { input(RUGGED_LEATHER_REF, 44), input(BLACK_DRAGONSCALE_REF, 60) }, trainerCostCopper = TRAINER_COST[290] }),
    makeRecipe({ id = "33kc1u12", name = "Dawn Treaders", outputId = "fvqbcdu6", skill = 290, inputs = { input(RUGGED_LEATHER_REF, 38), input(GUARDIAN_STONE_REF, 2), input(ENCHANTING.elementalWater, 4) }, trainerCostCopper = TRAINER_COST[290] }),
    makeRecipe({ id = "lcwx2hvt", name = "Devilsaur Gauntlets", outputId = "ks88fs1b", skill = 290, inputs = { input(RUGGED_LEATHER_REF, 38) }, trainerCostCopper = TRAINER_COST[290] }),
    makeRecipe({ id = "s5mqalkw", name = "Ironfeather Breastplate", outputId = "x87dzazi", skill = 290, inputs = { input(RUGGED_LEATHER_REF, 44), input(JEWEL.jade, 1) }, trainerCostCopper = TRAINER_COST[290] }),
    makeRecipe({ id = "bnwh5pwg", name = "Might of the Timbermaw", outputId = "tdwjdyz6", skill = 290, inputs = { input(RUGGED_LEATHER_REF, 38), input(ENCHANTING.livingEssence, 4) }, trainerCostCopper = TRAINER_COST[290] }),
    makeRecipe({ id = "ie4mursx", name = "Runic Leather Headband", outputId = "tw0g1cvc", skill = 290, inputs = { input(RUGGED_LEATHER_REF, 14) }, trainerCostCopper = TRAINER_COST[290] }),
    makeRecipe({ id = "yqhccg08", name = "Blue Dragonscale Shoulders", outputId = "rkpmrmia", skill = 295, inputs = { input(RUGGED_LEATHER_REF, 32), input(BLUE_DRAGONSCALE_REF, 30), input(ENCHANTING.enchantedLeather, 2) }, trainerCostCopper = TRAINER_COST[295] }),
    makeRecipe({ id = "iux26h8b", name = "Corehound Boots", outputId = "a2c6cukq", skill = 295, inputs = { input(RUGGED_LEATHER_REF, 100), input(FIERY_CORE_REF, 6), input(LAVA_CORE_REF, 2) }, trainerCostCopper = TRAINER_COST[295] }),
    makeRecipe({ id = "rf6c00uo", name = "Heavy Scorpid Helm", outputId = "4uu60rsl", skill = 295, inputs = { input(RUGGED_LEATHER_REF, 24) }, trainerCostCopper = TRAINER_COST[295] }),
    makeRecipe({ id = "yh7x0i34", name = "Stormshroud Shoulders", outputId = "ei28au20", skill = 295, inputs = { input(RUGGED_LEATHER_REF, 12), input(ENCHANTING.elementalWater, 3), input(ENCHANTING.elementalAir, 3), input(ENCHANTING.enchantedLeather, 2) }, trainerCostCopper = TRAINER_COST[295] }),
}

for index = 1, #newRecipes do
    appendUnique(dataset.recipes, newRecipes[index], "recipe")
end
