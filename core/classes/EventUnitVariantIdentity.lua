local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Classes = Addon.Internal.Database.Classes
local EventUnit = Classes.EventUnit

if type(EventUnit) ~= "table" then
    return
end

local function normalizeVariantIndex(value)
    local numericValue = tonumber(value)
    if numericValue == nil
        or numericValue ~= numericValue
        or numericValue == math.huge
        or numericValue == -math.huge
    then
        return 0
    end

    numericValue = math.floor(numericValue)
    if numericValue < 0 then
        return 0
    end

    return numericValue
end

local baseMerge = EventUnit.Merge
function EventUnit:Merge(data)
    local merged = baseMerge and baseMerge(self, data) or self
    merged.presetIndex = normalizeVariantIndex(merged.presetIndex)
    merged.appearanceIndex = normalizeVariantIndex(merged.appearanceIndex)
    return merged
end

local baseToTable = EventUnit.ToTable
function EventUnit:ToTable()
    local data = baseToTable and baseToTable(self) or {}
    data.presetIndex = normalizeVariantIndex(self.presetIndex)
    data.appearanceIndex = normalizeVariantIndex(self.appearanceIndex)
    return data
end

local function reportIdentityFailure(message, ...)
    if Addon.Debug and type(Addon.Debug.Error) == "function" then
        Addon.Debug.Error(message, ...)
    end
end

local function safelyResolve(unit, methodName)
    if type(unit) ~= "table" or type(unit[methodName]) ~= "function" then
        return nil
    end
    local ok, resolved = pcall(unit[methodName], unit)
    return ok and resolved or nil
end

-- Live unit deltas are applied to an already-rendered EventUnit.  Keep that
-- object (and its presentation identity) instead of replacing it with a
-- deserialized transport object whose optional variant fields may be absent.
function EventUnit:MergeLiveNetworkUpdate(incoming)
    if type(incoming) ~= "table" then
        return false, "incoming-unit-invalid"
    end

    local incomingData = type(incoming.ToTable) == "function" and incoming:ToTable() or incoming
    local candidate = type(EventUnit.FromTable) == "function" and EventUnit.FromTable(incomingData) or nil
    if type(candidate) ~= "table" then
        reportIdentityFailure("Cannot apply Event unit delta %s: incoming unit could not be materialized.", tostring(incoming.eventID or self.eventID or "unknown"))
        return false, "incoming-unit-unreadable"
    end

    -- Versioned variant fields are appended at 24/25.  Older/incomplete
    -- records deserialize as zeroes, which must not erase a selected model.
    if incoming._networkVariantIdentityPresent ~= true then
        candidate.presetIndex = self.presetIndex
        candidate.appearanceIndex = self.appearanceIndex
    end
    if tostring(candidate.registryID or "") == "" then
        candidate.registryID = self.registryID
    end

    local hadResolvedUnit = safelyResolve(self, "GetResolvedUnit")
    local hadResolvedAppearance = safelyResolve(self, "GetResolvedAppearance")
    local resolvedUnit = safelyResolve(candidate, "GetResolvedUnit")
    local resolvedAppearance = safelyResolve(candidate, "GetResolvedAppearance")
    if type(hadResolvedUnit) == "table" and type(resolvedUnit) ~= "table" then
        reportIdentityFailure("Rejected Event unit delta %s: registryID '%s' no longer resolves.", tostring(self.eventID or "unknown"), tostring(candidate.registryID or ""))
        return false, "registry-unresolved"
    end
    if type(hadResolvedAppearance) == "table" and type(resolvedAppearance) ~= "table" then
        reportIdentityFailure("Rejected Event unit delta %s: preset %d / appearance %d no longer resolves.", tostring(self.eventID or "unknown"), normalizeVariantIndex(candidate.presetIndex), normalizeVariantIndex(candidate.appearanceIndex))
        return false, "appearance-unresolved"
    end

    self:Merge(candidate:ToTable())
    return true
end

function EventUnit:GetResolvedPreset()
    local Unit = Classes.Unit
    local unit = self.GetResolvedUnit and self:GetResolvedUnit() or nil
    if not unit or not Unit or type(Unit.ResolvePreset) ~= "function" then
        return nil, 0
    end

    return Unit.ResolvePreset(unit, self.presetIndex)
end

function EventUnit:GetResolvedVariantName()
    local Unit = Classes.Unit
    local runtimeName = tostring(self.name or "")
    local unit = self.GetResolvedUnit and self:GetResolvedUnit() or nil
    if unit and Unit and type(Unit.ResolveVariantName) == "function" then
        local definitionName = Unit.ResolveVariantName(unit, self.presetIndex)
        if runtimeName ~= "" then
            return runtimeName
        end
        return definitionName
    end

    return runtimeName
end

function EventUnit:GetResolvedAppearance()
    local Unit = Classes.Unit
    local unit = self.GetResolvedUnit and self:GetResolvedUnit() or nil
    if not unit or not Unit or type(Unit.ResolveAppearance) ~= "function" then
        return nil
    end

    return Unit.ResolveAppearance(unit, self.presetIndex, self.appearanceIndex)
end

EventUnit.NormalizeVariantIndex = normalizeVariantIndex
