local _, Addon = ...

local definitions = Addon.Data and Addon.Data.DefaultDatasets and Addon.Data.DefaultDatasets.Definitions or nil
local definition = definitions and definitions["538a54a0"] or nil
if type(definition) ~= "table" or type(definition.dataset) ~= "table" then
    error("Leatherworking default dataset must be registered before loading the skill-300 recipe extension.")
end

definition.version = math.max(tonumber(definition.version) or 0, 10)
local dataset = definition.dataset
dataset.items = dataset.items or {}
dataset.recipes = dataset.recipes or {}

local RUGGED_LEATHER_REF = "538a54a0:4gnkyr9f"
local LEATHERWORKING_SKILL_REF = "f82db71a:x9qez6bu"
local MATERIAL_DATASETS = {
    "7259f1d3", -- Tailoring
    "732368d4", -- Enchanting
    "4999dcec", -- Jewelcrafting
    "3eb7e9bb", -- Miscellaneous
}
local MATERIAL_ALIASES = {
    ["Essence of Air"] = "Elemental Air",
    ["Essence of Water"] = "Elemental Water",
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

local function findPackagedMaterialRef(name)
    if name == "Rugged Leather" then
        return RUGGED_LEATHER_REF
    end

    local lookupName = MATERIAL_ALIASES[name] or name
    for datasetIndex = 1, #MATERIAL_DATASETS do
        local datasetId = MATERIAL_DATASETS[datasetIndex]
        local packaged = definitions and definitions[datasetId] or nil
        local sourceDataset = packaged and packaged.dataset or nil
        for itemIndex = 1, #(sourceDataset and sourceDataset.items or {}) do
            local item = sourceDataset.items[itemIndex]
            if type(item) == "table" and item.name == lookupName and type(item.id) == "string" and item.id ~= "" then
                return datasetId .. ":" .. item.id
            end
        end
    end

    return nil
end

local function stableId(prefix, name)
    local value = 2166136261
    local text = prefix .. name
    for index = 1, #text do
        value = (value * 16777619 + string.byte(text, index)) % 4294967296
    end
    return string.format("%08x", value)
end

local function buildInputs(text)
    local inputs = {}
    if text == "" then
        return inputs
    end

    for _, pair in ipairs(split(text, ",")) do
        local parts = split(pair, "=")
        local materialName = parts[1]
        local quantity = tonumber(parts[2])
        local itemRef = findPackagedMaterialRef(materialName)
        if itemRef and quantity and quantity > 0 then
            inputs[#inputs + 1] = {
                itemRef = itemRef,
                kind = "rpe_item",
                quantity = quantity,
            }
        end
    end

    return inputs
end

local function applyRecipe(name, learnMode, materialText)
    local outputItem = findByName(dataset.items, name)
    if type(outputItem) ~= "table" or type(outputItem.id) ~= "string" or outputItem.id == "" then
        error(("Leatherworking skill-300 output item '%s' was not found."):format(tostring(name)))
    end

    local recipe = findByName(dataset.recipes, name)
    if not recipe then
        recipe = {
            id = stableId("recipe:", name),
            name = name,
        }
        dataset.recipes[#dataset.recipes + 1] = recipe
    end

    recipe.category = ""
    recipe.description = ""
    recipe.inputs = buildInputs(materialText)
    recipe.learnMode = learnMode
    recipe.output = {
        itemRef = "538a54a0:" .. outputItem.id,
        maxQuantity = 1,
        minQuantity = 1,
    }
    recipe.reagents = {}
    recipe.requiredSkillLevel = 300
    recipe.results = {}
    recipe.skillRef = LEATHERWORKING_SKILL_REF
    recipe.tags = {}
    recipe.trainerCostCopper = 0
end

-- Hides and scales are normalized to Rugged Leather. Cured Rugged Hide counts
-- as four Rugged Leather; Core Leather counts as five Rugged Leather. Other
-- reagents that are absent from the packaged datasets are intentionally omitted.
local RECIPE_DATA = [==[
Red Dragonscale Breastplate|book|Rugged Leather=70,Rune Thread=1
Runic Leather Pants|book|Rugged Leather=18,Runecloth=12,Enchanted Leather=2,Rune Thread=1
Wicked Leather Belt|book|Rugged Leather=14,Black Dye=2,Rune Thread=2
Onyxia Scale Cloak|book|Rugged Leather=1,Cindercloth Cloak=1,Rune Thread=1
Black Dragonscale Shoulders|book|Rugged Leather=93,Enchanted Leather=2,Rune Thread=1
Living Breastplate|book|Rugged Leather=20,Living Essence=8,Mooncloth=2,Rune Thread=2
Devilsaur Leggings|book|Rugged Leather=48,Rune Thread=1
Wicked Leather Armor|book|Rugged Leather=28,Felcloth=2,Black Dye=4,Rune Thread=2
Heavy Scorpid Shoulders|book|Rugged Leather=32,Rune Thread=2
Volcanic Shoulders|book|Rugged Leather=10,Essence of Fire=1,Essence of Earth=1,Rune Thread=2
Runic Leather Armor|book|Rugged Leather=26,Enchanted Leather=4,Runecloth=16,Rune Thread=2
Runic Leather Shoulders|book|Rugged Leather=20,Enchanted Leather=4,Runecloth=18,Rune Thread=2
Frostsaber Tunic|book|Rugged Leather=28,Rune Thread=2
Black Dragonscale Leggings|book|Rugged Leather=104,Enchanted Leather=4,Rune Thread=2
Molten Helm|book|Rugged Leather=75,Fiery Core=3,Lava Core=6,Rune Thread=2
Black Dragonscale Boots|book|Rugged Leather=30,Enchanted Leather=6,Fiery Core=4,Lava Core=3,Rune Thread=2
Core Armor Kit|book|Rugged Leather=15,Rune Thread=2
Girdle of Insight|book|Rugged Leather=20,Powerful Mojo=12,Rune Thread=4
Mongoose Boots|book|Rugged Leather=20,Essence of Air=6,Black Diamond=4,Rune Thread=4
Swift Flight Bracers|book|Rugged Leather=28,Larval Acid=8,Ironfeather=60,Rune Thread=4
Chromatic Cloak|book|Rugged Leather=122,Rune Thread=8
Hide of the Wild|book|Rugged Leather=42,Living Essence=12,Essence of Water=10,Larval Acid=8,Rune Thread=8
Shifting Cloak|book|Rugged Leather=46,Essence of Air=12,Skin of Shadow=4,Guardian Stone=8,Rune Thread=8
Timbermaw Brawlers|book|Rugged Leather=8,Enchanted Leather=8,Powerful Mojo=6,Living Essence=6,Ironweb Spider Silk=2
Golden Mantle of the Dawn|book|Rugged Leather=8,Enchanted Leather=8,Living Essence=4,Guardian Stone=4,Rune Thread=2
Lava Belt|book|Rugged Leather=16,Lava Core=5,Ironweb Spider Silk=4
Chromatic Gauntlets|book|Rugged Leather=40,Fiery Core=5,Lava Core=2,Ironweb Spider Silk=4
Corehound Belt|book|Rugged Leather=76,Fiery Core=8,Enchanted Leather=10,Ironweb Spider Silk=4
Molten Belt|book|Rugged Leather=16,Fiery Core=2,Lava Core=7,Essence of Earth=6,Ironweb Spider Silk=4
Primal Batskin Jerkin|book|Rugged Leather=34,Living Essence=4,Rune Thread=4
Primal Batskin Gloves|book|Rugged Leather=26,Living Essence=4,Rune Thread=3
Primal Batskin Bracers|book|Rugged Leather=20,Living Essence=4,Rune Thread=3
Blood Tiger Breastplate|book|Rugged Leather=47,Bloodvine=2,Rune Thread=3
Blood Tiger Shoulders|book|Rugged Leather=37,Bloodvine=2,Rune Thread=3
Blue Dragonscale Leggings|trainer|Rugged Leather=72,Rune Thread=2
Dreamscale Breastplate|book|Rugged Leather=22,Enchanted Leather=12,Living Essence=4,Ironweb Spider Silk=6
Spitfire Bracers|book|Essence of Fire=2
Spitfire Gauntlets|book|Rugged Leather=4,Essence of Fire=2
Spitfire Breastplate|book|Rugged Leather=8,Essence of Fire=2
Sandstalker Bracers|book|Larval Acid=2
Sandstalker Gauntlets|book|Rugged Leather=4,Larval Acid=2
Sandstalker Breastplate|book|Rugged Leather=8,Larval Acid=2
Stormshroud Gloves|book|Rugged Leather=8,Enchanted Leather=6,Essence of Water=4,Essence of Air=4,Ironweb Spider Silk=2
Polar Tunic|book|Rugged Leather=16,Frozen Rune=7,Enchanted Leather=16,Essence of Water=2,Ironweb Spider Silk=4
Polar Gloves|book|Rugged Leather=12,Frozen Rune=5,Enchanted Leather=12,Essence of Water=2,Ironweb Spider Silk=4
Polar Bracers|book|Rugged Leather=8,Frozen Rune=4,Enchanted Leather=12,Essence of Water=2,Ironweb Spider Silk=4
Icy Scale Breastplate|book|Rugged Leather=40,Frozen Rune=7,Essence of Water=2,Ironweb Spider Silk=4
Icy Scale Gauntlets|book|Rugged Leather=28,Frozen Rune=5,Essence of Water=2,Ironweb Spider Silk=4
Icy Scale Bracers|book|Rugged Leather=24,Frozen Rune=4,Essence of Water=2,Ironweb Spider Silk=4
Bramblewood Helm|book|Rugged Leather=8,Enchanted Leather=12,Bloodvine=2,Living Essence=2
Bramblewood Boots|book|Rugged Leather=8,Enchanted Leather=6,Larval Acid=2,Living Essence=2
Bramblewood Belt|book|Rugged Leather=4,Enchanted Leather=4,Living Essence=2
]==]

local loadedNames = {}
local loadedCount = 0
for line in string.gmatch(RECIPE_DATA, "[^\r\n]+") do
    local fields = split(line, "|")
    local name = fields[1]
    if loadedNames[name] then
        error(("Duplicate Leatherworking skill-300 recipe '%s'."):format(tostring(name)))
    end
    loadedNames[name] = true
    loadedCount = loadedCount + 1
    applyRecipe(name, fields[2], fields[3] or "")
end

if loadedCount ~= 52 then
    error(("Expected 52 Leatherworking skill-300 recipes, found %d."):format(loadedCount))
end
