local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}
Addon.Internal = Addon.Internal or {}

local DataEditor = Addon.Client.UI.Editor
local LootLogic = Addon.Internal.Loot or {}

if type(DataEditor) ~= "table" or DataEditor._lootSharedDiagnosticsInstalled == true then
    return
end

local baseValidateLootTableAuthoring = DataEditor.ValidateLootTableAuthoring

local function appendUnique(messages, seen, value)
    local text = tostring(value or "")
    if text == "" or seen[text] then
        return
    end
    seen[text] = true
    messages[#messages + 1] = text
end

function DataEditor:ValidateLootTableAuthoring(loot)
    if type(LootLogic.DiagnoseLootTable) ~= "function" then
        if type(baseValidateLootTableAuthoring) == "function" then
            return baseValidateLootTableAuthoring(self, loot)
        end
        return {
            errors = { "Loot Table diagnostics are unavailable." },
            warnings = {},
        }
    end

    local diagnosis = LootLogic.DiagnoseLootTable(loot)
    local result = {
        errors = {},
        warnings = {},
        diagnostic = diagnosis,
    }
    local seen = {}

    for index = 1, #(diagnosis and diagnosis.issues or {}) do
        appendUnique(result.errors, seen, diagnosis.issues[index] and diagnosis.issues[index].message)
    end
    if type(diagnosis) == "table" and diagnosis.valid ~= true and #result.errors == 0 then
        appendUnique(result.errors, seen, diagnosis.message or diagnosis.reason)
    end

    if type(diagnosis) == "table" and diagnosis.legacyItemsPresent == true then
        result.warnings[#result.warnings + 1] = "Legacy items data is preserved read-only and is not converted by this editor."
    end
    return result
end

DataEditor._lootSharedDiagnosticsInstalled = true
