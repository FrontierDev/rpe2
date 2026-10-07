-- Small, shared helpers for tests that load addon files in isolation.  These
-- keep the bootstrap contract in one place without duplicating production
-- implementations or making tests depend on the full WoW runtime.
local Support = {}

function Support.LoadAddonFile(path, addon, addonName)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(addonName or "RPEngine2", addon)
    return addon
end

function Support.CreateAddon(overrides)
    local addon = {
        Name = "RPEngine2",
        Data = {},
        Internal = {},
        Debug = { Internal = function() end },
    }
    for key, value in pairs(overrides or {}) do
        addon[key] = value
    end
    return addon
end

-- Load the default data in the same order as the packaged TOC.  Tests which
-- exercise authored data should use this instead of maintaining a second,
-- inevitably stale list of default-data files.
function Support.LoadPackagedDefaultData(addon)
    Support.LoadAddonFile("core/internal/database/Dependecies.lua", addon)
    Support.LoadAddonFile("core/internal/database/Database.lua", addon)
    Support.LoadAddonFile("data/default/Datasets.lua", addon)

    local toc, openError = io.open("RPEngine2.toc", "r")
    assert(toc, openError)
    for line in toc:lines() do
        local path = line:match("^%s*(data/default/[^%s]+%.lua)%s*$")
        if path and path ~= "data/default/Datasets.lua" and path ~= "data/default/Install.lua" then
            Support.LoadAddonFile(path, addon)
        end
    end
    toc:close()
    return addon.Data.DefaultDatasets.Definitions
end

function Support.IndexDatasetEntries(definitions, collections)
    local entries = {}
    for datasetId, definition in pairs(definitions or {}) do
        local dataset = definition and definition.dataset or {}
        for _, collectionName in ipairs(collections or {}) do
            for _, entry in ipairs(dataset[collectionName] or {}) do
                if type(entry) == "table" and type(entry.id) == "string" and entry.id ~= "" then
                    entries[tostring(datasetId) .. ":" .. entry.id] = entry
                end
            end
        end
    end
    return entries
end

function Support.EnsureCommsOperations(addon)
    addon.Internal = addon.Internal or {}
    addon.Internal.Comms = addon.Internal.Comms or {}
    addon.Internal.Comms.Operations = addon.Internal.Comms.Operations or {}
    local operations = addon.Internal.Comms.Operations
    operations.GetOpcode = operations.GetOpcode or function()
        return 1
    end
    operations.Get = operations.Get or function()
        return nil
    end
    return operations
end

function Support.EnsureRuleset(addon)
    addon.Internal = addon.Internal or {}
    addon.Internal.Ruleset = addon.Internal.Ruleset or {}
    local ruleset = addon.Internal.Ruleset
    ruleset.GetRulesetRuleValueByKey = ruleset.GetRulesetRuleValueByKey or function(source, category, key, fallback)
        local values = source and source.rules and source.rules[category]
        local value = values and values[key]
        -- `false` is a valid ruleset value and must not be replaced with the
        -- fallback through Lua's `and/or` idiom.
        if value == nil then return fallback end
        return value
    end
    return ruleset
end

function Support.EnsureUI(addon)
    addon.UI = addon.UI or {}
    addon.UI.ResolveColor = addon.UI.ResolveColor or function(_, key)
        return key
    end
    return addon.UI
end

function Support.EnsureCombat(addon)
    addon.Client = addon.Client or {}
    addon.Client.Combat = addon.Client.Combat or {}
    local combat = addon.Client.Combat
    combat.ResolvePrimaryWeaponSlotForEffect = combat.ResolvePrimaryWeaponSlotForEffect or function()
        return "mainHandWeapon", "mainHandWeaponRef"
    end
    combat.ResolveWeaponItemRef = combat.ResolveWeaponItemRef or function(_, unit, _, fallbackField)
        return unit and fallbackField and unit[fallbackField] or nil
    end
    combat.ResolveItemDefinition = combat.ResolveItemDefinition or function()
        return nil
    end
    return combat
end

return Support
