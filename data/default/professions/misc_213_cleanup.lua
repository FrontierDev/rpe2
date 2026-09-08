local _, Addon = ...

local definition = Addon.Data.DefaultDatasets.Definitions["3eb7e9bb"]
if not definition or not definition.dataset then
    error("Misc default dataset must be registered before misc_213_cleanup.lua", 2)
end

if definition.version < 6 then
    definition.version = 6
end

local removeIds = {
    a6m2f8pv = true, -- Small Flame Sac; use Enchanting Elemental Fire instead.
    b7l3f9qw = true, -- Large Fang is not used by this Alchemy slice.
    c8i4u1rx = true, -- Ichor of Undeath; use Enchanting Essence of Undeath instead.
    e1v6r3tz = true, -- Volatile Rum is not used by this Alchemy slice.
    f2b7v4ua = true, -- Black Vitriol is not used by this Alchemy slice.
}

local items = definition.dataset.items
for index = #items, 1, -1 do
    if removeIds[items[index].id] then
        table.remove(items, index)
    end
end

local existing = {}
for _, item in ipairs(items) do
    existing[item.id] = true
end

local sharedMaterials = {
    {
        allowWowConversion = true,
        canDisenchant = false,
        icon = "interface/icons/inv_misc_ammo_gunpowder_02.blp",
        id = "3yvy546j",
        itemLevel = 5,
        itemType = "material",
        maxStackSize = 10,
        name = "Weak Flux",
        quality = "common",
    },
    {
        allowWowConversion = true,
        canDisenchant = false,
        icon = "interface/icons/inv_mace_11.blp",
        id = "4wc5b4tv",
        itemLevel = 10,
        itemType = "material",
        maxStackSize = 10,
        name = "Wooden Stock",
        quality = "common",
    },
}

for _, item in ipairs(sharedMaterials) do
    if not existing[item.id] then
        items[#items + 1] = item
    end
end
