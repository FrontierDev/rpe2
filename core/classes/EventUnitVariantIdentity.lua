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
