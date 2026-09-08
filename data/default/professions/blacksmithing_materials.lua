local _, Addon = ...

local definition = Addon.Data.DefaultDatasets.Definitions["61fdf3df"]
if not definition or not definition.dataset then
    error("Blacksmithing default dataset must be registered before blacksmithing_materials.lua", 2)
end

if definition.version < 2 then
    definition.version = 2
end

local items = definition.dataset.items
local existing = {}
for _, item in ipairs(items) do
    existing[item.id] = true
end

local materials = {
    {
        allowWowConversion = true,
        canDisenchant = false,
        icon = "interface/icons/inv_ore_mithril_02.blp",
        id = "g3m8o5vb",
        itemLevel = 40,
        itemType = "material",
        maxStackSize = 10,
        name = "Mithril Ore",
        quality = "common",
    },
    {
        allowWowConversion = true,
        canDisenchant = false,
        icon = "interface/icons/inv_ingot_iron.blp",
        id = "h4i9b6wc",
        itemLevel = 30,
        itemType = "material",
        maxStackSize = 20,
        name = "Iron Bar",
        quality = "common",
    },
    {
        allowWowConversion = true,
        canDisenchant = false,
        icon = "interface/icons/inv_ingot_06.blp",
        id = "i5m1b7xd",
        itemLevel = 40,
        itemType = "material",
        maxStackSize = 20,
        name = "Mithril Bar",
        quality = "common",
    },
    {
        allowWowConversion = true,
        canDisenchant = false,
        icon = "interface/icons/inv_ingot_03.blp",
        id = "j6g2b8ye",
        itemLevel = 30,
        itemType = "material",
        maxStackSize = 20,
        name = "Gold Bar",
        quality = "common",
    },
    {
        allowWowConversion = true,
        canDisenchant = false,
        icon = "interface/icons/inv_ingot_08.blp",
        id = "k7t3b9zf",
        itemLevel = 50,
        itemType = "material",
        maxStackSize = 20,
        name = "Truesilver Bar",
        quality = "common",
    },
}

for _, item in ipairs(materials) do
    if not existing[item.id] then
        items[#items + 1] = item
    end
end
