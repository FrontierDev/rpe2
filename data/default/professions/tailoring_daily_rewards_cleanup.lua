local _, Addon = ...

local DefaultDatasets = Addon.Data and Addon.Data.DefaultDatasets or nil
local definitions = DefaultDatasets and DefaultDatasets.Definitions or nil
local tailoring = type(definitions) == "table" and definitions["7259f1d3"] or nil
local dataset = type(tailoring) == "table" and tailoring.dataset or nil

if type(dataset) == "table" then
    for _, loot in ipairs(type(dataset.loot) == "table" and dataset.loot or {}) do
        if type(loot) == "table" and tostring(loot.id or "") == "q8m2v7kc" then
            local entries = type(loot.entries) == "table" and loot.entries or {}
            for index = #entries, 1, -1 do
                local entry = entries[index]
                if type(entry) == "table" and tostring(entry.id or "") == "mooncloth" then
                    table.remove(entries, index)
                end
            end

            loot.description = "Daily Tailoring material cache. Guarantees one cloth reward, weighted toward ordinary cloth with a rare Felcloth outcome."
            loot.icon = "interface/icons/inv_fabric_purplefire_01.blp"
            break
        end
    end

    tailoring.version = math.max(10, math.floor(tonumber(tailoring.version) or 1))
end
