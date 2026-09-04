local _, Addon = ...

local definitions = Addon.Data
    and Addon.Data.DefaultDatasets
    and Addon.Data.DefaultDatasets.Definitions
    or nil
local definition = definitions and definitions["538a54a0"] or nil

if type(definition) ~= "table" or type(definition.dataset) ~= "table" then
    error("Leatherworking default dataset must be registered before loading the 230-250 extension.")
end

definition.version = math.max(tonumber(definition.version) or 0, 5)

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
}

local SLOT = {
    head = "f82db71a:bgvs1zx6",
    shoulder = "f82db71a:66i80qm1",
    back = "f82db71a:bqwhrw0g",
    chest = "f82db71a:nwfvxbto",
    hands = "f82db71a:wasvuom2",
    legs = "f82db71a:obmt4ntq",
    feet = "f82db71a:raiu9t05",
}

local LEATHERWORKING_DATASET_ID = "538a54a0"
local JEWELCRAFTING_DATASET_ID = "4999dcec"
local ENCHANTING_DATASET_ID = "732368d4"
local THICK_LEATHER_REF = "538a54a0:u0wy9jz1"
local WILDVINE_REF = "3eb7e9bb:2hbdmyj4"
local STEALTH_SKILL_REF = "f82db71a:muuwon1r"
local FIRE_DAMAGE_SCHOOL_REF = "f82db71a:esjguw6d"
local WORN_DRAGONSCALE_ID = "wd5k2n7q"
local WORN_DRAGONSCALE_REF = LEATHERWORKING_DATASET_ID .. ":" .. WORN_DRAGONSCALE_ID

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

local JEWEL = {
    blackPearl = findPackagedItemRef(JEWELCRAFTING_DATASET_ID, "Black Pearl"),
    shadowgem = findPackagedItemRef(JEWELCRAFTING_DATASET_ID, "Shadowgem"),
}

-- Older elemental reagents are represented by the common elemental materials
-- from the Enchanting dataset: Core -> Earth, Breath -> Air, Heart -> Fire,
-- Globe -> Water.
local ELEMENTAL = {
    earth = findPackagedItemRef(ENCHANTING_DATASET_ID, "Elemental Earth"),
    air = findPackagedItemRef(ENCHANTING_DATASET_ID, "Elemental Air"),
    fire = findPackagedItemRef(ENCHANTING_DATASET_ID, "Elemental Fire"),
    water = findPackagedItemRef(ENCHANTING_DATASET_ID, "Elemental Water"),
}

local function input(itemRef, quantity)
    return {
        itemRef = itemRef,
        kind = "rpe_item",
        quantity = quantity
    }
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

local function replaceRecipeInputs(recipeName, inputs)
    local recipe = findRecipeByName(recipeName)
    if type(recipe) ~= "table" then
        error(("Leatherworking recipe '%s' was not found for packaged correction."):format(recipeName))
    end

    recipe.inputs = inputs
end

local function setItemStats(itemName, stats)
    local item = findItemByName(itemName)
    if type(item) ~= "table" then
        error(("Leatherworking item '%s' was not found for packaged correction."):format(itemName))
    end

    item.stats = stats
end

local function makeStats(entries)
    local stats = {}
    for index = 1, #(entries or {}) do
        local entry = entries[index]
        stats[#stats + 1] = {
            sourceStatRef = entry[1],
            value = entry[2]
        }
    end
    return stats
end

local function makeEquipmentTrait(events)
    return {
        automaticAuras = {},
        category = "",
        conditions = {},
        description = "",
        events = events or {},
        icon = "",
        name = "",
        skillBonuses = {},
        statBonuses = {},
        unlockLevel = 1
    }
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
                type = "level"
            }
        },
        consumableElixirType = "",
        consumableType = "",
        damageMode = "fixed",
        damagePerTurn = 0,
        description = "",
        equipmentTrait = options.equipmentTrait,
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
        name = options.name,
        prismaticSockets = 0,
        quality = options.quality or "uncommon",
        redSockets = 0,
        sellPrice = 0,
        skillBonuses = options.skillBonuses or {},
        socketTypes = {},
        sockets = {},
        stats = makeStats(options.stats),
        tags = {},
        targetArmorWeight = "none",
        targetSlotRefs = {},
        targetTwoHandedOnly = false,
        uniqueFlag = "none",
        validSlotRefs = {
            options.slotRef
        },
        yellowSockets = 0
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
            itemRef = LEATHERWORKING_DATASET_ID .. ":" .. options.outputId,
            maxQuantity = 1,
            minQuantity = 1
        },
        reagents = {},
        requiredSkillLevel = options.skill,
        results = {},
        skillRef = "f82db71a:x9qez6bu",
        tags = {},
        trainerCostCopper = options.trainerCostCopper
    }
end

-- Worn Dragonscale remains a distinct leatherworking material rather than
-- collapsing into Thick Leather.
appendUnique(dataset.items, {
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
    icon = "interface/icons/inv_misc_monsterscales_17.blp",
    id = WORN_DRAGONSCALE_ID,
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
    name = "Worn Dragonscale",
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
    wowConversionSkillRef = "f82db71a:x9qez6bu",
    yellowSockets = 0
}, "item")

-- Correct earlier recipes now that gems, pearls, special dragonscales and
-- existing Misc materials are retained instead of discarded.
replaceRecipeInputs("Shadowskin Gloves", {
    input(THICK_LEATHER_REF, 38),
    input("538a54a0:55k8gjup", 8),
    input(JEWEL.blackPearl, 2),
    input(JEWEL.shadowgem, 4),
})

replaceRecipeInputs("Wild Leather Shoulders", {
    input(THICK_LEATHER_REF, 14),
    input(WILDVINE_REF, 1),
})

replaceRecipeInputs("Wild Leather Vest", {
    input(THICK_LEATHER_REF, 16),
    input(WILDVINE_REF, 2),
})

replaceRecipeInputs("Wild Leather Helmet", {
    input(THICK_LEATHER_REF, 14),
    input(WILDVINE_REF, 2),
})

replaceRecipeInputs("Dragonscale Gauntlets", {
    input(THICK_LEATHER_REF, 32),
    input(WORN_DRAGONSCALE_REF, 12),
})

-- Wild Leather random suffixes are standardized as level-appropriate healing
-- gear. Healing suffixes in this level band also grant approximately one-third
-- of their healing value as generic spell power.
setItemStats("Wild Leather Shoulders", makeStats({
    { STAT.armor, 90 },
    { STAT.healingPower, 30 },
    { STAT.spellPower, 10 },
}))
setItemStats("Wild Leather Vest", makeStats({
    { STAT.armor, 121 },
    { STAT.healingPower, 41 },
    { STAT.spellPower, 14 },
}))
setItemStats("Wild Leather Helmet", makeStats({
    { STAT.armor, 99 },
    { STAT.healingPower, 41 },
    { STAT.spellPower, 14 },
}))

local gauntletsOfTheSeaTrait = makeEquipmentTrait({
    {
        chance = 3,
        combatEventId = "on_heal",
        effects = {
            {
                amountMode = "flat",
                baseHealing = 300,
                statScaling = {},
                type = "heal"
            }
        },
        triggerTarget = "event_other"
    }
})

local helmOfFireTrait = makeEquipmentTrait({
    {
        chance = 3,
        combatEventId = "on_melee_hit",
        effects = {
            {
                amountMode = "flat",
                baseDamage = 320,
                damageSchoolRefs = {
                    FIRE_DAMAGE_SCHOOL_REF
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
                baseDamage = 320,
                damageSchoolRefs = {
                    FIRE_DAMAGE_SCHOOL_REF
                },
                statScaling = {},
                type = "damage"
            }
        },
        triggerTarget = "event_other"
    }
})

local newItems = {
    makeArmorItem({
        id = "k8j2vh4m",
        name = "Nightscape Pants",
        armorWeight = "leather",
        slotRef = SLOT.legs,
        requiredLevel = 41,
        icon = "interface/icons/inv_pants_11.blp",
        stats = {
            { STAT.armor, 108 },
            { STAT.agility, 16 },
            { STAT.stamina, 7 },
        },
    }),
    makeArmorItem({
        id = "rq6b9x2c",
        name = "Turtle Scale Helm",
        armorWeight = "mail",
        slotRef = SLOT.head,
        requiredLevel = 41,
        icon = "interface/icons/inv_helmet_40.blp",
        stats = {
            { STAT.armor, 206 },
            { STAT.stamina, 10 },
            { STAT.intellect, 10 },
            { STAT.spirit, 10 },
        },
    }),
    makeArmorItem({
        id = "m3fp7zq1",
        name = "Gauntlets of the Sea",
        armorWeight = "leather",
        slotRef = SLOT.hands,
        requiredLevel = 41,
        icon = "interface/icons/inv_gauntlets_30.blp",
        quality = "rare",
        equipmentTrait = gauntletsOfTheSeaTrait,
        stats = {
            { STAT.armor, 85 },
            { STAT.agility, 7 },
        },
    }),
    makeArmorItem({
        id = "v7cn4j2s",
        name = "Nightscape Boots",
        armorWeight = "leather",
        slotRef = SLOT.feet,
        requiredLevel = 42,
        icon = "interface/icons/inv_boots_05.blp",
        skillBonuses = {
            {
                skillRef = STEALTH_SKILL_REF,
                value = 3
            }
        },
        stats = {
            { STAT.armor, 87 },
            { STAT.agility, 12 },
        },
    }),
    makeArmorItem({
        id = "h5kw8p3d",
        name = "Turtle Scale Leggings",
        armorWeight = "mail",
        slotRef = SLOT.legs,
        requiredLevel = 42,
        icon = "interface/icons/inv_pants_02.blp",
        stats = {
            { STAT.armor, 226 },
            { STAT.stamina, 11 },
            { STAT.intellect, 10 },
            { STAT.spirit, 11 },
        },
    }),
    makeArmorItem({
        id = "t2gx9m6r",
        name = "Tough Scorpid Boots",
        armorWeight = "mail",
        slotRef = SLOT.feet,
        requiredLevel = 42,
        icon = "interface/icons/inv_boots_05.blp",
        stats = {
            { STAT.armor, 178 },
            { STAT.agility, 12 },
            { STAT.spirit, 7 },
        },
    }),
    makeArmorItem({
        id = "b4ny7q1e",
        name = "Big Voodoo Pants",
        armorWeight = "leather",
        slotRef = SLOT.legs,
        requiredLevel = 42,
        icon = "interface/icons/inv_pants_02.blp",
        stats = {
            { STAT.armor, 110 },
            { STAT.intellect, 10 },
            { STAT.spirit, 15 },
        },
    }),
    makeArmorItem({
        id = "c8pv3k5a",
        name = "Big Voodoo Cloak",
        armorWeight = "cosmetic",
        slotRef = SLOT.back,
        requiredLevel = 43,
        icon = "interface/icons/inv_misc_cape_02.blp",
        stats = {
            { STAT.armor, 31 },
            { STAT.intellect, 9 },
            { STAT.spirit, 5 },
        },
    }),
    makeArmorItem({
        id = "u6mf2z9w",
        name = "Tough Scorpid Shoulders",
        armorWeight = "mail",
        slotRef = SLOT.shoulder,
        requiredLevel = 43,
        icon = "interface/icons/inv_shoulder_04.blp",
        stats = {
            { STAT.armor, 197 },
            { STAT.agility, 10 },
            { STAT.spirit, 10 },
        },
    }),
    makeArmorItem({
        id = "e3jr8x4n",
        name = "Wild Leather Boots",
        armorWeight = "leather",
        slotRef = SLOT.feet,
        requiredLevel = 44,
        icon = "interface/icons/inv_boots_07.blp",
        stats = {
            { STAT.armor, 90 },
            { STAT.healingPower, 35 },
            { STAT.spellPower, 12 },
        },
    }),
    makeArmorItem({
        id = "p7hd5v2q",
        name = "Tough Scorpid Leggings",
        armorWeight = "mail",
        slotRef = SLOT.legs,
        requiredLevel = 44,
        icon = "interface/icons/inv_pants_12.blp",
        stats = {
            { STAT.armor, 235 },
            { STAT.agility, 17 },
            { STAT.spirit, 10 },
        },
    }),
    makeArmorItem({
        id = "g9sk1m6c",
        name = "Tough Scorpid Helm",
        armorWeight = "mail",
        slotRef = SLOT.head,
        requiredLevel = 45,
        icon = "interface/icons/inv_helmet_20.blp",
        stats = {
            { STAT.armor, 222 },
            { STAT.agility, 14 },
            { STAT.spirit, 14 },
        },
    }),
    makeArmorItem({
        id = "w4zt8r3b",
        name = "Wild Leather Leggings",
        armorWeight = "leather",
        slotRef = SLOT.legs,
        requiredLevel = 45,
        icon = "interface/icons/inv_pants_14.blp",
        stats = {
            { STAT.armor, 116 },
            { STAT.healingPower, 47 },
            { STAT.spellPower, 16 },
        },
    }),
    makeArmorItem({
        id = "a2vx6n9j",
        name = "Wild Leather Cloak",
        armorWeight = "cosmetic",
        slotRef = SLOT.back,
        requiredLevel = 45,
        icon = "interface/icons/inv_misc_cape_03.blp",
        stats = {
            { STAT.armor, 33 },
            { STAT.healingPower, 26 },
            { STAT.spellPower, 9 },
        },
    }),
    makeArmorItem({
        id = "f5qc7k1u",
        name = "Helm of Fire",
        armorWeight = "leather",
        slotRef = SLOT.head,
        requiredLevel = 45,
        icon = "interface/icons/inv_helmet_08.blp",
        quality = "rare",
        equipmentTrait = helmOfFireTrait,
        stats = {
            { STAT.armor, 118 },
            { STAT.agility, 17 },
            { STAT.stamina, 10 },
            { STAT.fireResistance, 5 },
        },
    }),
    makeArmorItem({
        id = "d8mp3h4y",
        name = "Feathered Breastplate",
        armorWeight = "leather",
        slotRef = SLOT.chest,
        requiredLevel = 45,
        icon = "interface/icons/inv_chest_leather_06.blp",
        quality = "rare",
        stats = {
            { STAT.armor, 146 },
            { STAT.intellect, 10 },
            { STAT.spirit, 24 },
        },
    }),
}

for index = 1, #newItems do
    appendUnique(dataset.items, newItems[index], "item")
end

local TRAINER_COST = {
    [230] = 91155,
    [235] = 95015,
    [240] = 98955,
    [245] = 102975,
    [250] = 107075,
}

local newRecipes = {
    makeRecipe({
        id = "j7qm2v5x",
        name = "Nightscape Pants",
        outputId = "k8j2vh4m",
        skill = 230,
        inputs = { input(THICK_LEATHER_REF, 14) },
        trainerCostCopper = TRAINER_COST[230],
    }),
    makeRecipe({
        id = "r4ck8n1p",
        name = "Turtle Scale Helm",
        outputId = "rq6b9x2c",
        skill = 230,
        inputs = { input(THICK_LEATHER_REF, 38) },
        trainerCostCopper = TRAINER_COST[230],
    }),
    makeRecipe({
        id = "z2wh6f9m",
        name = "Gauntlets of the Sea",
        outputId = "m3fp7zq1",
        skill = 230,
        inputs = {
            input(THICK_LEATHER_REF, 24),
            input(ELEMENTAL.water, 8),
            input(ELEMENTAL.earth, 2),
        },
        trainerCostCopper = TRAINER_COST[230],
    }),
    makeRecipe({
        id = "c5tb9x3q",
        name = "Nightscape Boots",
        outputId = "v7cn4j2s",
        skill = 235,
        inputs = { input(THICK_LEATHER_REF, 16) },
        trainerCostCopper = TRAINER_COST[235],
    }),
    makeRecipe({
        id = "m8pk1d6v",
        name = "Turtle Scale Leggings",
        outputId = "h5kw8p3d",
        skill = 235,
        inputs = { input(THICK_LEATHER_REF, 42) },
        trainerCostCopper = TRAINER_COST[235],
    }),
    makeRecipe({
        id = "q6nr4y2h",
        name = "Tough Scorpid Boots",
        outputId = "t2gx9m6r",
        skill = 235,
        inputs = { input(THICK_LEATHER_REF, 24) },
        trainerCostCopper = TRAINER_COST[235],
    }),
    makeRecipe({
        id = "v3hs7k8e",
        name = "Big Voodoo Pants",
        outputId = "b4ny7q1e",
        skill = 240,
        inputs = { input(THICK_LEATHER_REF, 10) },
        trainerCostCopper = TRAINER_COST[240],
    }),
    makeRecipe({
        id = "x9fj2m5a",
        name = "Big Voodoo Cloak",
        outputId = "c8pv3k5a",
        skill = 240,
        inputs = { input(THICK_LEATHER_REF, 14) },
        trainerCostCopper = TRAINER_COST[240],
    }),
    makeRecipe({
        id = "b7qw1t4n",
        name = "Tough Scorpid Shoulders",
        outputId = "u6mf2z9w",
        skill = 240,
        inputs = { input(THICK_LEATHER_REF, 28) },
        trainerCostCopper = TRAINER_COST[240],
    }),
    makeRecipe({
        id = "h2vc8r6k",
        name = "Wild Leather Boots",
        outputId = "e3jr8x4n",
        skill = 245,
        inputs = {
            input(THICK_LEATHER_REF, 22),
            input(WILDVINE_REF, 4),
        },
        trainerCostCopper = TRAINER_COST[245],
    }),
    makeRecipe({
        id = "n5mz3p9w",
        name = "Tough Scorpid Leggings",
        outputId = "p7hd5v2q",
        skill = 245,
        inputs = { input(THICK_LEATHER_REF, 22) },
        trainerCostCopper = TRAINER_COST[245],
    }),
    makeRecipe({
        id = "p1gx7c4j",
        name = "Tough Scorpid Helm",
        outputId = "g9sk1m6c",
        skill = 250,
        inputs = { input(THICK_LEATHER_REF, 30) },
        trainerCostCopper = TRAINER_COST[250],
    }),
    makeRecipe({
        id = "s8kr2v5d",
        name = "Wild Leather Leggings",
        outputId = "w4zt8r3b",
        skill = 250,
        inputs = {
            input(THICK_LEATHER_REF, 24),
            input(WILDVINE_REF, 6),
        },
        trainerCostCopper = TRAINER_COST[250],
    }),
    makeRecipe({
        id = "u4bn9h1q",
        name = "Wild Leather Cloak",
        outputId = "a2vx6n9j",
        skill = 250,
        inputs = {
            input(THICK_LEATHER_REF, 24),
            input(WILDVINE_REF, 6),
        },
        trainerCostCopper = TRAINER_COST[250],
    }),
    makeRecipe({
        id = "y6td3m8f",
        name = "Helm of Fire",
        outputId = "f5qc7k1u",
        skill = 250,
        inputs = {
            input(THICK_LEATHER_REF, 48),
            input(ELEMENTAL.fire, 8),
            input(ELEMENTAL.earth, 4),
        },
        trainerCostCopper = TRAINER_COST[250],
    }),
    makeRecipe({
        id = "e9wp5k2r",
        name = "Feathered Breastplate",
        outputId = "d8mp3h4y",
        skill = 250,
        inputs = {
            input(THICK_LEATHER_REF, 56),
            input(JEWEL.blackPearl, 2),
        },
        trainerCostCopper = TRAINER_COST[250],
    }),
}

for index = 1, #newRecipes do
    appendUnique(dataset.recipes, newRecipes[index], "recipe")
end
