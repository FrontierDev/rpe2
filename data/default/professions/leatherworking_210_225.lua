local _, Addon = ...

local definitions = Addon.Data
    and Addon.Data.DefaultDatasets
    and Addon.Data.DefaultDatasets.Definitions
    or nil
local definition = definitions and definitions["538a54a0"] or nil

if type(definition) ~= "table" or type(definition.dataset) ~= "table" then
    error("Leatherworking default dataset must be registered before loading the 210-225 extension.")
end

-- This extends the packaged Leatherworking data beyond v3. Existing clients
-- must see a new packaged version so the default-dataset synchronizer rewrites it.
definition.version = math.max(tonumber(definition.version) or 0, 4)

local dataset = definition.dataset
dataset.items = dataset.items or {}
dataset.recipes = dataset.recipes or {}

local STAT = {
    armor = "f82db71a:v42albuv",
    agility = "f82db71a:xqz0daz2",
    stamina = "f82db71a:ygjno50i",
    intellect = "f82db71a:75y3a8ib",
    spirit = "f82db71a:kec9rhli",
}

-- Rating-bearing source items are represented with the corresponding RPE
-- percentage stat. The project conversion is 10 rating per whole percentage,
-- truncating partial percentages (14 -> 1%, 20 -> 2%).
local COMBAT_RATING_STAT_REFS = {
    critical_strike = "f82db71a:jslmczbi",
    hit = "f82db71a:wbj4zuf3",
    parry = "f82db71a:tcn0s8kx",
    dodge = "f82db71a:o6113cir",
    block = "f82db71a:p8syz5ba",
}

local function convertCombatRating(ratingKind, rating)
    local statRef = COMBAT_RATING_STAT_REFS[ratingKind]
    if type(statRef) ~= "string" or statRef == "" then
        error(("Unsupported combat rating kind '%s'."):format(tostring(ratingKind)))
    end

    local percent = math.floor(math.max(0, tonumber(rating) or 0) / 10)
    if percent <= 0 then
        return nil, 0
    end

    return statRef, percent
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

local function setItemStat(itemName, statRef, value)
    local item = findItemByName(itemName)
    if type(item) ~= "table" then
        error(("Leatherworking item '%s' was not found for packaged correction."):format(itemName))
    end

    item.stats = item.stats or {}
    for index = 1, #item.stats do
        local stat = item.stats[index]
        if type(stat) == "table" and stat.sourceStatRef == statRef then
            stat.value = value
            return
        end
    end

    item.stats[#item.stats + 1] = {
        sourceStatRef = statRef,
        value = value
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

local function makeStats(entries, ratingBonuses)
    local stats = {}

    for index = 1, #(entries or {}) do
        local entry = entries[index]
        stats[#stats + 1] = {
            sourceStatRef = entry[1],
            value = entry[2]
        }
    end

    for index = 1, #(ratingBonuses or {}) do
        local ratingBonus = ratingBonuses[index]
        local statRef, percent = convertCombatRating(ratingBonus.kind, ratingBonus.rating)
        if statRef and percent > 0 then
            stats[#stats + 1] = {
                sourceStatRef = statRef,
                value = percent
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
        skillBonuses = {},
        socketTypes = {},
        sockets = {},
        stats = makeStats(options.stats, options.ratingBonuses),
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
        inputs = {
            {
                itemRef = "538a54a0:u0wy9jz1",
                kind = "rpe_item",
                quantity = options.thickLeather
            }
        },
        learnMode = "trainer",
        name = options.name,
        output = {
            itemRef = "538a54a0:" .. options.outputId,
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

-- Shadowskin Gloves' +14 critical strike rating was omitted in the preceding
-- package. Convert it to +1% Melee Crit. Chance under the packaged rating rule.
do
    local statRef, percent = convertCombatRating("critical_strike", 14)
    setItemStat("Shadowskin Gloves", statRef, percent)
end

local newItems = {
    -- Backfill the qualifying skill-205 recipe omitted from the preceding range.
    makeArmorItem({
        id = "znxtc7he",
        name = "Nightscape Headband",
        armorWeight = "leather",
        slotRef = "f82db71a:bgvs1zx6",
        requiredLevel = 36,
        icon = "interface/icons/inv_belt_24.blp",
        stats = {
            { STAT.armor, 91 },
            { STAT.agility, 12 },
            { STAT.stamina, 11 },
        },
    }),
    makeArmorItem({
        id = "bq7947yq",
        name = "Turtle Scale Bracers",
        armorWeight = "mail",
        slotRef = "f82db71a:crezt6ix",
        requiredLevel = 37,
        icon = "interface/icons/inv_bracer_06.blp",
        stats = {
            { STAT.armor, 204 },
        },
    }),
    makeArmorItem({
        id = "jlnq2160",
        name = "Turtle Scale Breastplate",
        armorWeight = "mail",
        slotRef = "f82db71a:nwfvxbto",
        requiredLevel = 37,
        icon = "interface/icons/inv_chest_chain_12.blp",
        stats = {
            { STAT.armor, 238 },
            { STAT.stamina, 9 },
            { STAT.intellect, 9 },
            { STAT.spirit, 9 },
        },
    }),
    makeArmorItem({
        id = "n9lzzkem",
        name = "Big Voodoo Robe",
        armorWeight = "leather",
        slotRef = "f82db71a:nwfvxbto",
        requiredLevel = 38,
        icon = "interface/icons/inv_chest_cloth_25.blp",
        stats = {
            { STAT.armor, 117 },
            { STAT.intellect, 14 },
            { STAT.spirit, 9 },
        },
    }),
    makeArmorItem({
        id = "ctzht4zc",
        name = "Big Voodoo Mask",
        armorWeight = "leather",
        slotRef = "f82db71a:bgvs1zx6",
        requiredLevel = 39,
        icon = "interface/icons/inv_banner_01.blp",
        stats = {
            { STAT.armor, 97 },
            { STAT.intellect, 14 },
            { STAT.spirit, 9 },
        },
    }),
    makeArmorItem({
        id = "riyhi71p",
        name = "Tough Scorpid Bracers",
        armorWeight = "mail",
        slotRef = "f82db71a:crezt6ix",
        requiredLevel = 39,
        icon = "interface/icons/inv_bracer_09.blp",
        stats = {
            { STAT.armor, 107 },
            { STAT.agility, 7 },
            { STAT.spirit, 6 },
        },
    }),
    makeArmorItem({
        id = "aku0bj87",
        name = "Tough Scorpid Breastplate",
        armorWeight = "mail",
        slotRef = "f82db71a:nwfvxbto",
        requiredLevel = 39,
        icon = "interface/icons/inv_chest_leather_02.blp",
        stats = {
            { STAT.armor, 245 },
            { STAT.agility, 15 },
            { STAT.spirit, 7 },
        },
    }),
    -- Wild Leather items have random suffixes in TBC. RPE has no equivalent
    -- deterministic random-suffix field here, so only their fixed armor is stored.
    makeArmorItem({
        id = "qfmdvqn9",
        name = "Wild Leather Shoulders",
        armorWeight = "leather",
        slotRef = "f82db71a:66i80qm1",
        requiredLevel = 39,
        icon = "interface/icons/inv_shoulder_18.blp",
        stats = {
            { STAT.armor, 90 },
        },
    }),
    makeArmorItem({
        id = "pou2vmn4",
        name = "Tough Scorpid Gloves",
        armorWeight = "mail",
        slotRef = "f82db71a:wasvuom2",
        requiredLevel = 40,
        icon = "interface/icons/inv_gauntlets_24.blp",
        stats = {
            { STAT.armor, 155 },
            { STAT.agility, 10 },
            { STAT.spirit, 9 },
        },
    }),
    makeArmorItem({
        id = "xaci9gkt",
        name = "Wild Leather Vest",
        armorWeight = "leather",
        slotRef = "f82db71a:nwfvxbto",
        requiredLevel = 40,
        icon = "interface/icons/inv_chest_cloth_06.blp",
        stats = {
            { STAT.armor, 121 },
        },
    }),
    makeArmorItem({
        id = "ws0amunv",
        name = "Wild Leather Helmet",
        armorWeight = "leather",
        slotRef = "f82db71a:bgvs1zx6",
        requiredLevel = 40,
        icon = "interface/icons/inv_helmet_10.blp",
        stats = {
            { STAT.armor, 99 },
        },
    }),
    makeArmorItem({
        id = "3a4bi80s",
        name = "Dragonscale Gauntlets",
        armorWeight = "mail",
        slotRef = "f82db71a:wasvuom2",
        requiredLevel = 40,
        icon = "interface/icons/inv_gauntlets_10.blp",
        quality = "rare",
        stats = {
            { STAT.armor, 171 },
            { STAT.stamina, 7 },
            { STAT.spirit, 6 },
        },
        ratingBonuses = {
            { kind = "critical_strike", rating = 14 },
        },
    }),
    -- TBC's Druid-only shapeshift proc has no supported packaged Druid reference
    -- or shapeshift equipment trigger in the current runtime, so only fixed stats
    -- are represented rather than inventing unsupported behavior.
    makeArmorItem({
        id = "dibi20pl",
        name = "Wolfshead Helm",
        armorWeight = "leather",
        slotRef = "f82db71a:bgvs1zx6",
        requiredLevel = 40,
        icon = "interface/icons/inv_helmet_04.blp",
        quality = "rare",
        stats = {
            { STAT.armor, 109 },
            { STAT.spirit, 10 },
        },
    }),
}

for index = 1, #newItems do
    appendUnique(dataset.items, newItems[index], "item")
end

-- Miscellaneous reagents are intentionally omitted. Scales convert 1:1 to
-- same-tier leather; hides convert at 1 hide -> 4 leather, following the
-- packaged Leatherworking conversion rules established for earlier ranges.
local newRecipes = {
    makeRecipe({
        id = "7bbvb9l0",
        name = "Nightscape Headband",
        outputId = "znxtc7he",
        skill = 205,
        thickLeather = 5,
        trainerCostCopper = 73055,
    }),
    makeRecipe({
        id = "q2h9kugh",
        name = "Turtle Scale Bracers",
        outputId = "bq7947yq",
        skill = 210,
        thickLeather = 20,
        trainerCostCopper = 76515,
    }),
    makeRecipe({
        id = "r9u3ezse",
        name = "Turtle Scale Breastplate",
        outputId = "jlnq2160",
        skill = 210,
        thickLeather = 18,
        trainerCostCopper = 76515,
    }),
    makeRecipe({
        id = "n8m9etlq",
        name = "Big Voodoo Robe",
        outputId = "n9lzzkem",
        skill = 215,
        thickLeather = 10,
        trainerCostCopper = 80055,
    }),
    makeRecipe({
        id = "gjq6rolm",
        name = "Big Voodoo Mask",
        outputId = "ctzht4zc",
        skill = 220,
        thickLeather = 8,
        trainerCostCopper = 83675,
    }),
    makeRecipe({
        id = "bpqp64ev",
        name = "Tough Scorpid Bracers",
        outputId = "riyhi71p",
        skill = 220,
        thickLeather = 14,
        trainerCostCopper = 83675,
    }),
    makeRecipe({
        id = "klt42m3d",
        name = "Tough Scorpid Breastplate",
        outputId = "aku0bj87",
        skill = 220,
        thickLeather = 24,
        trainerCostCopper = 83675,
    }),
    makeRecipe({
        id = "9nhuou23",
        name = "Wild Leather Shoulders",
        outputId = "qfmdvqn9",
        skill = 220,
        thickLeather = 14,
        trainerCostCopper = 83675,
    }),
    makeRecipe({
        id = "49lnm4es",
        name = "Tough Scorpid Gloves",
        outputId = "pou2vmn4",
        skill = 225,
        thickLeather = 14,
        trainerCostCopper = 87375,
    }),
    makeRecipe({
        id = "ka863p8y",
        name = "Wild Leather Vest",
        outputId = "xaci9gkt",
        skill = 225,
        thickLeather = 16,
        trainerCostCopper = 87375,
    }),
    makeRecipe({
        id = "zy896fsa",
        name = "Wild Leather Helmet",
        outputId = "ws0amunv",
        skill = 225,
        thickLeather = 14,
        trainerCostCopper = 87375,
    }),
    makeRecipe({
        id = "lkjl70vm",
        name = "Dragonscale Gauntlets",
        outputId = "3a4bi80s",
        skill = 225,
        thickLeather = 44,
        trainerCostCopper = 87375,
    }),
    makeRecipe({
        id = "8osam5m8",
        name = "Wolfshead Helm",
        outputId = "dibi20pl",
        skill = 225,
        thickLeather = 34,
        trainerCostCopper = 87375,
    }),
}

for index = 1, #newRecipes do
    appendUnique(dataset.recipes, newRecipes[index], "recipe")
end
