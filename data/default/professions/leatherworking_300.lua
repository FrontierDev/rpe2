local _, Addon = ...

local definitions = Addon.Data and Addon.Data.DefaultDatasets and Addon.Data.DefaultDatasets.Definitions or nil
local definition = definitions and definitions["538a54a0"] or nil
if type(definition) ~= "table" or type(definition.dataset) ~= "table" then
    error("Leatherworking default dataset must be registered before loading the skill-300 extension.")
end

definition.version = math.max(tonumber(definition.version) or 0, 9)
local dataset = definition.dataset
dataset.items = dataset.items or {}

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
    rangedAttackPower = "f82db71a:v2rs9cpy",
    meleeHit = "f82db71a:wbj4zuf3",
    rangedHit = "f82db71a:dd88li4c",
    meleeCrit = "f82db71a:jslmczbi",
    rangedCrit = "f82db71a:fercjhm5",
    spellCrit = "f82db71a:69hfqhne",
    dodge = "f82db71a:o6113cir",
    defenseRating = "f82db71a:0wyp78x9",
    fireResistance = "f82db71a:0w7c7p09",
    natureResistance = "f82db71a:pg0ytacb",
    arcaneResistance = "f82db71a:954yunb9",
    frostResistance = "f82db71a:jjn0my8k",
    shadowResistance = "f82db71a:itpo751d",
}

local SLOT = {
    head = "f82db71a:bgvs1zx6",
    shoulder = "f82db71a:66i80qm1",
    back = "f82db71a:bqwhrw0g",
    chest = "f82db71a:nwfvxbto",
    wrists = "f82db71a:crezt6ix",
    hands = "f82db71a:wasvuom2",
    waist = "f82db71a:haks0gz4",
    legs = "f82db71a:obmt4ntq",
    feet = "f82db71a:raiu9t05",
}

local function split(value, separator)
    local result = {}
    local start = 1
    while true do
        local first, last = string.find(value, separator, start, true)
        if not first then
            result[#result + 1] = string.sub(value, start)
            break
        end
        result[#result + 1] = string.sub(value, start, first - 1)
        start = last + 1
    end
    return result
end

local function findByName(entries, name)
    for index = 1, #entries do
        local entry = entries[index]
        if type(entry) == "table" and entry.name == name then
            return entry
        end
    end
    return nil
end

local function parseStats(text)
    local values = {}
    if text == "" then
        return values
    end

    for _, pair in ipairs(split(text, ",")) do
        local parts = split(pair, "=")
        values[parts[1]] = tonumber(parts[2])
    end
    return values
end

local function makeStats(values)
    local stats = {}
    for key, value in pairs(values) do
        local sourceStatRef = STAT[key]
        if sourceStatRef and value and value ~= 0 then
            stats[#stats + 1] = {
                sourceStatRef = sourceStatRef,
                value = value,
            }
        end
    end
    return stats
end

local function itemLevel(requiredLevel, quality)
    local value = requiredLevel + 5
    if quality == "rare" then
        return math.min(value, 55)
    end
    if quality == "epic" then
        return math.min(value, 60)
    end
    return value
end

local function stableId(prefix, name)
    local value = 2166136261
    local text = prefix .. name
    for index = 1, #text do
        value = (value * 16777619 + string.byte(text, index)) % 4294967296
    end
    return string.format("%08x", value)
end

local function applyArmorItem(fields)
    local name = fields[1]
    local quality = fields[2]
    local armorWeight = fields[3]
    local slot = fields[4]
    local requiredLevel = tonumber(fields[5])
    local icon = fields[6]
    local statsText = fields[7]

    local item = findByName(dataset.items, name)
    if not item then
        item = {
            id = stableId("item:", name),
            name = name,
        }
        dataset.items[#dataset.items + 1] = item
    end

    item.allowWowConversion = false
    item.armorWeight = armorWeight
    item.bindingFlag = "bind_on_equip"
    item.blueSockets = 0
    item.canDisenchant = true
    item.canSell = true
    item.canStack = false
    item.canTrade = true
    item.cogSockets = 0
    item.conditions = {
        {
            invert = false,
            minimumValue = requiredLevel,
            showOnTooltip = true,
            tooltipTextOverride = "",
            type = "level",
        },
    }
    item.consumableElixirType = ""
    item.consumableType = ""
    item.damageMode = "fixed"
    item.damagePerTurn = 0
    item.description = ""
    item.gemColor = "none"
    item.genericModificationKey = ""
    item.greenSockets = 0
    item.icon = "interface/icons/" .. icon .. ".blp"
    item.isTwoHanded = false
    item.itemLevel = itemLevel(requiredLevel, quality)
    item.itemSetKey = ""
    item.itemType = "armor"
    item.maxDamagePerTurn = 0
    item.maxGenericModificationCounts = { mod = 1 }
    item.maxModificationCounts = { mod = 1 }
    item.maxStackSize = 1
    item.metaSockets = 0
    item.minDamagePerTurn = 0
    item.modificationKind = "generic"
    item.prismaticSockets = 0
    item.quality = quality
    item.redSockets = 0
    item.sellPrice = 0
    item.skillBonuses = {}
    item.socketTypes = {}
    item.sockets = {}
    item.stats = makeStats(parseStats(statsText))
    item.tags = {}
    item.targetArmorWeight = "none"
    item.targetSlotRefs = {}
    item.targetTwoHandedOnly = false
    item.uniqueFlag = "none"
    item.validSlotRefs = { SLOT[slot] }
    item.yellowSockets = 0
end

local function applyCoreArmorKit()
    local name = "Core Armor Kit"
    local quality = "rare"
    local requiredLevel = 50
    local item = findByName(dataset.items, name)
    if not item then
        item = {
            id = stableId("item:", name),
            name = name,
        }
        dataset.items[#dataset.items + 1] = item
    end

    item.allowWowConversion = false
    item.armorWeight = "cosmetic"
    item.bindingFlag = "none"
    item.blueSockets = 0
    item.canDisenchant = false
    item.canSell = true
    item.canStack = true
    item.canTrade = true
    item.cogSockets = 0
    item.conditions = {
        {
            invert = false,
            minimumValue = requiredLevel,
            showOnTooltip = true,
            tooltipTextOverride = "",
            type = "level",
        },
    }
    item.consumableElixirType = ""
    item.consumableType = ""
    item.damageMode = "fixed"
    item.damagePerTurn = 0
    item.description = "Permanently adds 5 Defense Rating to an item worn on the chest, legs, hands or feet."
    item.gemColor = "none"
    item.genericModificationKey = "mod"
    item.greenSockets = 0
    item.icon = "interface/icons/inv_misc_armorkit_05.blp"
    item.isTwoHanded = false
    item.itemLevel = itemLevel(requiredLevel, quality)
    item.itemSetKey = ""
    item.itemType = "modification"
    item.maxDamagePerTurn = 0
    item.maxGenericModificationCounts = {}
    item.maxModificationCounts = {}
    item.maxStackSize = 10
    item.metaSockets = 0
    item.minDamagePerTurn = 0
    item.modificationKind = "generic"
    item.prismaticSockets = 0
    item.quality = quality
    item.redSockets = 0
    item.sellPrice = 0
    item.skillBonuses = {}
    item.socketTypes = {}
    item.sockets = {}
    item.stats = {
        {
            sourceStatRef = STAT.defenseRating,
            value = 5,
        },
    }
    item.tags = {}
    item.targetArmorWeight = "none"
    item.targetSlotRefs = {
        SLOT.chest,
        SLOT.legs,
        SLOT.hands,
        SLOT.feet,
    }
    item.targetTwoHandedOnly = false
    item.uniqueFlag = "none"
    item.validSlotRefs = {}
    item.yellowSockets = 0
end

-- Skill-300 Leatherworking outputs from the TBC profession data. Knothide
-- Leather recipes are deliberately excluded. Existing packaged items are
-- corrected in place so their stable references remain intact.
local ITEM_DATA = [==[
Red Dragonscale Breastplate|rare|mail|chest|56|inv_chest_chain_06|armor=360,fireResistance=12,healingPower=66,spellPower=22
Runic Leather Pants|uncommon|leather|legs|55|inv_pants_02|armor=135,intellect=13,spirit=20
Wicked Leather Belt|uncommon|leather|waist|55|inv_belt_03|armor=87,agility=14,stamina=13
Onyxia Scale Cloak|rare|cloth|back|55|inv_misc_cape_05|armor=43,stamina=7,fireResistance=16
Black Dragonscale Shoulders|rare|mail|shoulder|55|inv_shoulder_01|armor=266,stamina=9,fireResistance=6,meleeAttackPower=40
Living Breastplate|rare|leather|chest|55|inv_chest_plate07|armor=169,stamina=10,spirit=25,natureResistance=5,healingPower=26,spellPower=9
Devilsaur Leggings|rare|leather|legs|55|inv_pants_wolf|armor=148,stamina=12,meleeAttackPower=46,meleeCrit=1,rangedCrit=1
Wicked Leather Armor|uncommon|leather|chest|56|inv_chest_plate06|armor=156,agility=25,stamina=7
Heavy Scorpid Shoulders|uncommon|mail|shoulder|56|inv_shoulder_07|armor=245,stamina=14,spirit=13
Volcanic Shoulders|uncommon|leather|shoulder|56|inv_shoulder_13|armor=167,fireResistance=18
Runic Leather Armor|uncommon|leather|chest|57|inv_chest_leather_07|armor=158,intellect=21,spirit=13
Runic Leather Shoulders|uncommon|leather|shoulder|57|inv_shoulder_15|armor=119,intellect=15,spirit=10
Frostsaber Tunic|uncommon|leather|chest|57|inv_chest_chain_10|armor=158,frostResistance=18,shadowResistance=18
Black Dragonscale Leggings|rare|mail|legs|57|inv_pants_03|armor=320,stamina=8,fireResistance=13,meleeAttackPower=54
Molten Helm|epic|leather|head|55|inv_helmet_08|armor=171,stamina=16,fireResistance=29,dodge=1
Black Dragonscale Boots|epic|mail|feet|56|inv_boots_plate_09|armor=308,stamina=10,fireResistance=24,meleeAttackPower=28
Girdle of Insight|rare|leather|waist|57|inv_belt_26|armor=98,stamina=9,intellect=23
Mongoose Boots|rare|leather|feet|57|inv_boots_08|armor=120,agility=23,stamina=9
Swift Flight Bracers|rare|mail|wrists|57|inv_bracer_05|armor=160,stamina=7,rangedAttackPower=41
Chromatic Cloak|epic|cloth|back|57|inv_misc_cape_02|armor=55,stamina=10,fireResistance=9,shadowResistance=9,spellCrit=1
Hide of the Wild|epic|cloth|back|57|inv_misc_cape_01|armor=55,stamina=8,intellect=10,healingPower=42,spellPower=14
Shifting Cloak|epic|cloth|back|57|inv_misc_cape_20|armor=55,agility=17,stamina=8,dodge=1
Timbermaw Brawlers|rare|leather|hands|59|inv_gauntlets_26|armor=112,strength=23,stamina=10
Golden Mantle of the Dawn|rare|leather|shoulder|59|inv_shoulder_26|armor=134,stamina=22,dodge=1
Lava Belt|epic|leather|waist|60|inv_belt_32|armor=238,stamina=15,fireResistance=26
Chromatic Gauntlets|epic|mail|hands|60|inv_gauntlets_22|armor=318,fireResistance=5,natureResistance=5,frostResistance=5,shadowResistance=5,meleeAttackPower=44,meleeCrit=1,rangedCrit=1,spellCrit=1
Corehound Belt|epic|leather|waist|60|inv_belt_24|armor=135,intellect=16,fireResistance=12,healingPower=62,spellPower=21
Molten Belt|epic|leather|waist|60|inv_belt_13|armor=135,agility=28,stamina=16,fireResistance=12
Primal Batskin Jerkin|rare|leather|chest|60|inv_chest_leather_03|armor=181,agility=32,stamina=6,meleeHit=1,rangedHit=1
Primal Batskin Gloves|rare|leather|hands|60|inv_gauntlets_31|armor=113,agility=10,stamina=9,meleeHit=2,rangedHit=2
Primal Batskin Bracers|rare|leather|wrists|60|inv_bracer_07|armor=79,agility=14,stamina=7,meleeHit=1,rangedHit=1
Blood Tiger Breastplate|rare|leather|chest|60|inv_chest_leather_07|armor=181,strength=17,stamina=17,intellect=16,spirit=13
Blood Tiger Shoulders|rare|leather|shoulder|60|inv_shoulder_23|armor=136,strength=13,stamina=13,intellect=12,spirit=10
Blue Dragonscale Leggings|rare|mail|legs|55|inv_pants_mail_15|armor=310,intellect=20,spirit=19,arcaneResistance=12
Dreamscale Breastplate|epic|mail|chest|60|inv_chest_plate08|armor=496,agility=15,stamina=15,intellect=14,natureResistance=30
Spitfire Bracers|rare|mail|wrists|57|inv_bracer_05|armor=160,agility=9,intellect=9,spellPower=8
Spitfire Gauntlets|rare|mail|hands|57|inv_gauntlets_11|armor=228,agility=12,intellect=12,spellPower=11
Spitfire Breastplate|rare|mail|chest|57|inv_chest_leather_02|armor=365,agility=16,intellect=16,spellPower=15
Sandstalker Bracers|rare|mail|wrists|57|inv_bracer_12|armor=220,stamina=7,natureResistance=15
Sandstalker Gauntlets|rare|mail|hands|57|inv_gauntlets_11|armor=308,stamina=9,natureResistance=20
Sandstalker Breastplate|rare|mail|chest|57|inv_chest_plate07|armor=485,stamina=13,natureResistance=25
Stormshroud Gloves|rare|leather|hands|50|inv_gauntlets_05|armor=99,meleeHit=1,rangedHit=1,meleeCrit=1,rangedCrit=1
Polar Tunic|epic|leather|chest|60|inv_chest_cloth_08|armor=267,agility=18,stamina=26,frostResistance=40
Polar Gloves|epic|leather|hands|60|inv_gauntlets_06|armor=167,agility=18,stamina=18,frostResistance=30
Polar Bracers|epic|leather|wrists|60|inv_bracer_07|armor=117,agility=12,stamina=20,frostResistance=20
Icy Scale Breastplate|epic|mail|chest|60|inv_chest_plate09|armor=578,stamina=24,frostResistance=40,meleeAttackPower=40
Icy Scale Gauntlets|epic|mail|hands|60|inv_gauntlets_28|armor=361,stamina=22,frostResistance=30,meleeAttackPower=22
Icy Scale Bracers|epic|mail|wrists|60|inv_bracer_07|armor=253,stamina=17,frostResistance=20,meleeAttackPower=32
Bramblewood Helm|rare|leather|head|60|inv_helmet_58|armor=156,stamina=20,natureResistance=30
Bramblewood Boots|rare|leather|feet|60|inv_boots_cloth_04|armor=132,stamina=12,natureResistance=25
Bramblewood Belt|rare|leather|waist|60|inv_belt_17|armor=108,stamina=14,natureResistance=15
]==]

local loadedNames = {}
local loadedCount = 0
for line in string.gmatch(ITEM_DATA, "[^\r\n]+") do
    local fields = split(line, "|")
    local name = fields[1]
    if loadedNames[name] then
        error(("Duplicate Leatherworking skill-300 item '%s'."):format(tostring(name)))
    end
    loadedNames[name] = true
    loadedCount = loadedCount + 1
    applyArmorItem(fields)
end

if loadedCount ~= 51 then
    error(("Expected 51 equippable Leatherworking skill-300 items, found %d."):format(loadedCount))
end

applyCoreArmorKit()
