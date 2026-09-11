local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local EventWidget = Client.UI.EventWidget
local Common = Addon.Utils and Addon.Utils.Common or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Ruleset = Addon.Internal and Addon.Internal.Ruleset or {}
local Database = Addon.Internal and Addon.Internal.Database or {}

if type(EventWidget) ~= "table" or EventWidget.PrimaryResourcePresentationWrapped == true then
    return
end
EventWidget.PrimaryResourcePresentationWrapped = true

local function normalizeRef(value)
    return type(value) == "string" and value ~= "" and value or nil
end

local function resolveHealthResourceRef(eventState)
    local eventRef = normalizeRef(type(eventState) == "table" and eventState.healthResourceRef or nil)
    if eventRef then
        return eventRef
    end

    if type(Profile.GetHealthResourceRef) == "function" then
        local profileRef = normalizeRef(Profile.GetHealthResourceRef())
        if profileRef then
            return profileRef
        end
    end

    local activeRuleset = type(Ruleset.GetActiveRuleset) == "function" and Ruleset.GetActiveRuleset() or nil
    local ruleDefinition = type(Ruleset.GetRulesetRuleDefinition) == "function"
        and Ruleset.GetRulesetRuleDefinition("resources", "health_stat")
        or nil
    return normalizeRef(
        ruleDefinition
        and type(Ruleset.GetRulesetRuleValue) == "function"
        and Ruleset.GetRulesetRuleValue(activeRuleset, "resources", ruleDefinition)
        or nil
    )
end

local function resolveKnownPrimary(eventUnit, eventState)
    if type(eventUnit) ~= "table" or eventUnit.isPlayer ~= true then
        return false, nil
    end

    local localUnit = type(Client.ResolveLocalEventUnit) == "function" and Client:ResolveLocalEventUnit(eventState) or nil
    if tonumber(localUnit and localUnit.eventID) == tonumber(eventUnit.eventID) then
        if type(Profile.GetPrimaryResourceRef) ~= "function" then
            return false, nil
        end
        return true, normalizeRef(Profile.GetPrimaryResourceRef())
    end

    if eventUnit.primaryResourceKnown == true then
        return true, normalizeRef(eventUnit.primaryResourceRef)
    end

    return false, nil
end

local function findResourceEntry(resources, resourceRef)
    if not resourceRef then
        return nil
    end
    for index = 1, #(resources or {}) do
        local entry = resources[index]
        if type(entry) == "table" and tostring(entry.resourceRef or "") == resourceRef then
            return entry
        end
    end
    return nil
end

local function resolveResourceDefinition(resourceRef)
    local ref = normalizeRef(resourceRef)
    if not ref or type(Database.GetDatasetByID) ~= "function" then
        return nil
    end
    local separatorIndex = string.find(ref, ":", 1, true)
    if not separatorIndex then
        return nil
    end
    local datasetId = string.sub(ref, 1, separatorIndex - 1)
    local resourceId = string.sub(ref, separatorIndex + 1)
    if datasetId == "" or resourceId == "" then
        return nil
    end
    local dataset = Database.GetDatasetByID(datasetId)
    for index = 1, #((dataset and dataset.resources) or {}) do
        local resource = dataset.resources[index]
        if type(resource) == "table" and tostring(resource.id or "") == resourceId then
            return resource
        end
    end
    return nil
end

local function cloneColor(value)
    if type(value) ~= "table" then
        return { r = 0.18, g = 0.68, b = 0.2, a = 1 }
    end
    return {
        r = tonumber(value.r) or 0.18,
        g = tonumber(value.g) or 0.68,
        b = tonumber(value.b) or 0.2,
        a = tonumber(value.a) or 1,
    }
end

local function buildPrimaryState(eventUnit, primaryRef)
    if not primaryRef then
        return nil
    end
    local entry = findResourceEntry(eventUnit and eventUnit.resources, primaryRef)
    if type(entry) ~= "table" then
        return nil
    end
    local currentValue = tonumber(entry.currentValue)
    local maxValue = tonumber(entry.maxValue)
    if currentValue == nil and maxValue ~= nil then
        currentValue = maxValue
    end
    if maxValue == nil and currentValue ~= nil then
        maxValue = currentValue
    end
    if currentValue == nil or maxValue == nil then
        return nil
    end
    local definition = resolveResourceDefinition(primaryRef)
    return {
        resourceRef = primaryRef,
        icon = tostring(definition and definition.icon or ""),
        color = cloneColor(definition and definition.color or nil),
        currentValue = currentValue,
        maxValue = math.max(1, maxValue),
    }
end

local function buildPresentationResources(eventUnit, eventState, primaryRef)
    local resources = type(eventUnit) == "table" and type(eventUnit.resources) == "table" and eventUnit.resources or {}
    local healthRef = resolveHealthResourceRef(eventState)
    local healthEntry = findResourceEntry(resources, healthRef)
    local primaryEntry = primaryRef and findResourceEntry(resources, primaryRef) or nil
    local presentation = {}

    if healthEntry then
        presentation[#presentation + 1] = healthEntry
    end
    if primaryEntry and primaryEntry ~= healthEntry then
        presentation[#presentation + 1] = primaryEntry
    end

    if primaryRef then
        for index = 1, #resources do
            local entry = resources[index]
            if entry ~= healthEntry and entry ~= primaryEntry then
                presentation[#presentation + 1] = entry
            end
        end
    end

    return presentation
end

local function callWithPresentationResources(eventUnit, eventState, fn, ...)
    local known, primaryRef = resolveKnownPrimary(eventUnit, eventState)
    if not known or type(eventUnit) ~= "table" then
        return fn(...)
    end

    local originalResources = eventUnit.resources
    eventUnit.resources = buildPresentationResources(eventUnit, eventState, primaryRef)
    local results = { pcall(fn, ...) }
    eventUnit.resources = originalResources

    local ok = table.remove(results, 1)
    if not ok then
        error(results[1], 0)
    end
    return unpack(results)
end

if type(EventWidget.BuildPortraitTooltip) == "function" then
    local nativeBuildPortraitTooltip = EventWidget.BuildPortraitTooltip
    function EventWidget:BuildPortraitTooltip(eventUnit, eventState)
        return callWithPresentationResources(eventUnit, eventState, function()
            return nativeBuildPortraitTooltip(self, eventUnit, eventState)
        end)
    end
end

if type(EventWidget.RefreshPortraitSlot) == "function" then
    local nativeRefreshPortraitSlot = EventWidget.RefreshPortraitSlot
    function EventWidget:RefreshPortraitSlot(index, eventUnit, state, context, options)
        local result = callWithPresentationResources(eventUnit, state, function()
            return nativeRefreshPortraitSlot(self, index, eventUnit, state, context, options)
        end)

        local known, primaryRef = resolveKnownPrimary(eventUnit, state)
        if known then
            local portrait = nil
            if type(options) == "table" and type(options.ensureSlot) == "function" then
                portrait = options.ensureSlot(self, index)
            elseif type(self.portraitSlots) == "table" then
                portrait = self.portraitSlots[index]
            end
            if type(portrait) == "table" and type(portrait.SetSecondaryProgressState) == "function" then
                portrait:SetSecondaryProgressState(buildPrimaryState(eventUnit, primaryRef))
            end
        end

        return result
    end
end
