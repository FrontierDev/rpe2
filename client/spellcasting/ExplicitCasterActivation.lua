local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Spellcasting = Client.Spellcasting
local Event = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil

local baseBuildSpellActivationSnapshot = Spellcasting.BuildSpellActivationSnapshot

if type(baseBuildSpellActivationSnapshot) ~= "function"
    or type(Client.ResolveSpellActivation) ~= "function"
then
    return
end

local function normalizeEventUnitId(value)
    local eventId = math.floor(tonumber(value) or 0)
    return eventId > 0 and eventId or nil
end

local function findEventUnitById(units, eventId)
    local numericEventId = normalizeEventUnitId(eventId)
    if not numericEventId then
        return nil
    end

    for index = 1, #(units or {}) do
        local unit = units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit
        end
    end

    return nil
end

local function isActiveNpcUnit(unit)
    if type(unit) ~= "table" or unit.isPlayer == true then
        return false
    end

    if type(Event) == "table" and type(Event.IsUnitActive) == "function" then
        return Event.IsUnitActive(unit) == true
    end

    return unit.active ~= false
end

local function normalizeSpellRef(value)
    if type(value) == "string" then
        return value ~= "" and value or nil
    end
    if type(value) ~= "table" then
        return nil
    end

    local spellRef = value.spellRef or value.spellID or value.id or value.name
    if type(spellRef) ~= "string" or spellRef == "" then
        return nil
    end
    return spellRef
end

local function listResolvedSpellRefs(casterUnit)
    if type(casterUnit) ~= "table" then
        return {}
    end

    local values = casterUnit.spells or {}
    if type(casterUnit.GetResolvedValue) == "function" then
        local ok, resolved = pcall(casterUnit.GetResolvedValue, casterUnit, "spells", values)
        if ok and resolved ~= nil then
            values = resolved
        end
    end

    if type(values) == "string" then
        return values ~= "" and { values } or {}
    end
    if type(values) ~= "table" then
        return {}
    end

    local refs = {}
    local seen = {}
    for index = 1, #values do
        local spellRef = normalizeSpellRef(values[index])
        if spellRef and seen[spellRef] ~= true then
            seen[spellRef] = true
            refs[#refs + 1] = spellRef
        end
    end
    return refs
end

local function hasResolvedSpellRef(casterUnit, spellRef)
    local normalizedSpellRef = normalizeSpellRef(spellRef)
    if not normalizedSpellRef then
        return false
    end

    local refs = listResolvedSpellRefs(casterUnit)
    for index = 1, #refs do
        if refs[index] == normalizedSpellRef then
            return true
        end
    end
    return false
end

function Spellcasting.ListEventUnitResolvedSpellRefs(self, eventState, casterEventId)
    if type(eventState) ~= "table" or eventState.active ~= true then
        return {}
    end

    local casterUnit = findEventUnitById(eventState.units, casterEventId)
    if not isActiveNpcUnit(casterUnit) then
        return {}
    end

    return listResolvedSpellRefs(casterUnit)
end

function Client:ListEventUnitResolvedSpellRefs(casterEventId, eventStateOverride)
    local eventState = eventStateOverride or (self.GetEventState and self:GetEventState() or nil)
    return Spellcasting.ListEventUnitResolvedSpellRefs(self, eventState, casterEventId)
end

local function buildExplicitCasterProxy(client, eventState, casterUnit)
    local proxy = {
        ResolveActiveSpellcasterUnit = function(_, requestedEventState)
            if requestedEventState ~= eventState then
                return nil
            end
            return casterUnit
        end,
        GetActionBarControlContext = function(_, requestedEventState)
            if requestedEventState ~= eventState then
                return nil
            end
            return {
                isControlled = true,
                controlledUnit = casterUnit,
                controlledEventId = tonumber(casterUnit.eventID),
            }
        end,
    }

    return setmetatable(proxy, {
        __index = client,
    })
end

local function resolveExplicitCasterContext(client, options)
    local casterEventId = normalizeEventUnitId(type(options) == "table" and options.casterEventId or nil)
    if not casterEventId then
        return nil, nil
    end

    local eventState = client.GetEventState and client:GetEventState() or nil
    if type(eventState) ~= "table" or eventState.active ~= true then
        return nil, nil
    end

    local casterUnit = findEventUnitById(eventState.units, casterEventId)
    if not isActiveNpcUnit(casterUnit) then
        return eventState, nil
    end

    return eventState, casterUnit
end

function Spellcasting.BuildSpellActivationSnapshot(self, spellRef, options)
    local resolvedOptions = type(options) == "table" and options or nil
    local hasExplicitCaster = resolvedOptions ~= nil and resolvedOptions.casterEventId ~= nil
    if not hasExplicitCaster then
        return baseBuildSpellActivationSnapshot(self, spellRef, options)
    end

    if normalizeEventUnitId(resolvedOptions.casterEventId) == nil then
        return nil
    end

    local eventState, casterUnit = resolveExplicitCasterContext(self, resolvedOptions)
    if type(eventState) ~= "table" or type(casterUnit) ~= "table" then
        return nil
    end
    if not hasResolvedSpellRef(casterUnit, spellRef) then
        return nil
    end

    local proxy = buildExplicitCasterProxy(self, eventState, casterUnit)
    local snapshot = baseBuildSpellActivationSnapshot(proxy, spellRef, resolvedOptions)
    if self ~= Client and type(snapshot) == "table" and snapshot.canCast ~= true then
        return nil
    end
    return snapshot
end

return Spellcasting
