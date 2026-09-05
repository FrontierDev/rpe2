local _, Addon = ...

local definition = Addon.Data.DefaultDatasets.Definitions["3eb7e9bb"]
if not definition or not definition.dataset then
    error("Misc default dataset must be registered before misc_213_cleanup.lua", 2)
end

if definition.version < 4 then
    definition.version = 4
end

local removeIds = {
    a6m2f8pv = true, -- Small Flame Sac; use Enchanting Elemental Fire instead.
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
