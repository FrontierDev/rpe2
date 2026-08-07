local addonName, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI
local Registry = Addon.Internal and Addon.Internal.Registry or {}

local ActionBarWidget = ClientUI.ActionBarWidget or {}
ClientUI.ActionBarWidget = ActionBarWidget
ActionBarWidget.__index = ActionBarWidget

local DEFAULT_CAST_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local DEFAULT_CAST_BAR_COLOR = { r = 0.93, g = 0.63, b = 0.22, a = 1 }

local function formatTurnLabel(value)
    local numericValue = math.max(0, math.floor(tonumber(value) or 0))
    if numericValue == 1 then
        return "1 turn"
    end

    return ("%d turns"):format(numericValue)
end

function ActionBarWidget:ResolveActionBarCastState(eventUnit, eventState)
    if type(eventUnit) ~= "table" or type(eventState) ~= "table" then
        return nil
    end

    if type(Client.GetSpellcastEntry) ~= "function" then
        return nil
    end

    local eventId = tostring(eventState.id or "")
    local casterEventId = tonumber(eventUnit.eventID)
    if eventId == "" or casterEventId == nil then
        return nil
    end

    local entry = Client:GetSpellcastEntry(eventId, casterEventId)
    if type(entry) ~= "table" then
        return nil
    end

    local spellName = tostring(entry.spellName or "")
    local spellIcon = ""
    if type(Registry.ResolveSpellReference) == "function" then
        local _, spell = Registry:ResolveSpellReference(entry.spellRef)
        if type(spell) == "table" then
            spellName = spellName ~= "" and spellName or tostring(spell.name or "")
            spellIcon = tostring(spell.icon or "")
        end
    end
    if spellName == "" and type(Registry.ResolveSpellName) == "function" then
        spellName = tostring(Registry:ResolveSpellName(entry.spellRef) or "")
    end
    if spellName == "" then
        spellName = "Casting"
    end
    if spellIcon == "" then
        spellIcon = DEFAULT_CAST_ICON
    end

    local turnsTotal = tonumber(entry.turnsTotal)
    if turnsTotal == nil or turnsTotal <= 0 then
        return nil
    end
    turnsTotal = math.max(1, math.floor(turnsTotal))
    local turnsElapsed = math.max(0, math.floor(tonumber(entry.turnsElapsed) or 0))
    if turnsElapsed > turnsTotal then
        turnsElapsed = turnsTotal
    end
    local turnsRemaining = math.max(0, turnsTotal - turnsElapsed)

    return {
        kind = "cast",
        castEntry = entry,
        casterEventId = casterEventId,
        spellRef = entry.spellRef,
        name = spellName,
        icon = spellIcon,
        color = { r = DEFAULT_CAST_BAR_COLOR.r, g = DEFAULT_CAST_BAR_COLOR.g, b = DEFAULT_CAST_BAR_COLOR.b, a = DEFAULT_CAST_BAR_COLOR.a },
        currentValue = turnsElapsed,
        maxValue = turnsTotal,
        currentText = formatTurnLabel(turnsRemaining),
        progressText = spellName,
    }
end

return ActionBarWidget
