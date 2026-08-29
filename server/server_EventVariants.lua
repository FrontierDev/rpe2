local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Server = Addon.Server
local Registry = Addon.Internal.Registry or {}
local UnitClass = Addon.Internal.Database.Classes.Unit

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = deepCopy(nestedValue)
    end
    return copy
end

local function normalizeNonNegativeInteger(value)
    local numericValue = tonumber(value)
    if numericValue == nil or numericValue ~= numericValue or numericValue == math.huge or numericValue == -math.huge then
        return 0
    end

    numericValue = math.floor(numericValue)
    return numericValue > 0 and numericValue or 0
end

local function resolveActivatedUnitDefinition(registryId)
    local normalizedRegistryId = type(registryId) == "string" and registryId or ""
    if normalizedRegistryId == "" then
        return nil, nil
    end

    local separatorIndex = string.find(normalizedRegistryId, ":", 1, true)
    if not separatorIndex then
        return nil, nil
    end

    local datasetId = string.sub(normalizedRegistryId, 1, separatorIndex - 1)
    local unitId = string.sub(normalizedRegistryId, separatorIndex + 1)
    if datasetId == "" or unitId == "" then
        return nil, nil
    end

    local datasets = Registry.GetActivatedDatasets and Registry:GetActivatedDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        if dataset and dataset.id == datasetId then
            for unitIndex = 1, #(dataset.units or {}) do
                local unit = dataset.units[unitIndex]
                if unit and unit.id == unitId then
                    return dataset, unit
                end
            end
        end
    end

    return nil, nil
end

local function countPlayerUnits(units)
    local playerCount = 0
    for index = 1, #((units) or {}) do
        if units[index] and units[index].isPlayer == true then
            playerCount = playerCount + 1
        end
    end
    return playerCount
end

local function clampTeamIndex(eventState, value)
    local teamCount = #(eventState and eventState.teams or {})
    if teamCount <= 0 then
        teamCount = 1
    end

    local numericValue = math.floor(tonumber(value) or 1)
    if numericValue < 1 then
        return 1
    end
    if numericValue > teamCount then
        return teamCount
    end
    return numericValue
end

local function coerceBoolean(value, defaultValue)
    local EventUnit = Addon.Internal.Database.Classes.EventUnit
    if EventUnit and EventUnit.CoerceBoolean then
        return EventUnit.CoerceBoolean(value, defaultValue)
    end

    if value == nil then
        return defaultValue == true
    end
    return value == true
end

local function resolveCurrentPlayerCount(server, options)
    if type(options) == "table" and options.playerCount ~= nil then
        return math.max(0, math.floor(tonumber(options.playerCount) or 0))
    end

    local eventState = server and server.GetEditableEventState and server:GetEditableEventState() or nil
    return countPlayerUnits(eventState and eventState.units or {})
end

local function buildPlayerScaledResourceValues(baseUnit, playerCount, preset)
    local values = {}
    local seen = {}

    for index = 1, #((baseUnit and baseUnit.resources) or {}) do
        local entry = baseUnit.resources[index]
        local resourceRef = type(entry) == "table" and tostring(entry.resourceRef or "") or ""
        if resourceRef ~= "" then
            local baseValue = tonumber(entry.value) or 0
            local scaledValue = baseValue
                + ((tonumber(entry.perPlayer) or 0) * math.max(0, tonumber(playerCount) or 0))
            values[#values + 1] = {
                resourceRef = resourceRef,
                value = scaledValue,
            }
            seen[resourceRef] = true
        end
    end

    -- Unit.ApplyResourceModifiers() deliberately modifies an already-materialized
    -- resource set. Seed missing Preset targets at zero so flat Preset bonuses can
    -- introduce a Resource without moving player-count policy into Unit.lua.
    for index = 1, #((preset and preset.resourceModifiers) or {}) do
        local modifier = preset.resourceModifiers[index]
        local resourceRef = type(modifier) == "table" and tostring(modifier.resourceRef or "") or ""
        if resourceRef ~= "" and not seen[resourceRef] then
            seen[resourceRef] = true
            values[#values + 1] = {
                resourceRef = resourceRef,
                value = 0,
            }
        end
    end

    local resolvedValues = UnitClass and UnitClass.ApplyResourceModifiers
        and UnitClass.ApplyResourceModifiers(values, preset)
        or deepCopy(values)
    local resources = {}

    for index = 1, #(resolvedValues or {}) do
        local entry = resolvedValues[index]
        local resourceRef = type(entry) == "table" and tostring(entry.resourceRef or "") or ""
        if resourceRef ~= "" then
            local value = math.max(0, tonumber(entry.value) or 0)
            resources[#resources + 1] = {
                resourceRef = resourceRef,
                currentValue = value,
                maxValue = value,
            }
        end
    end

    return resources
end

function Server:BuildResolvedNpcVariant(registryId, options)
    local dataset, baseUnit = resolveActivatedUnitDefinition(registryId)
    if not dataset or not baseUnit or not baseUnit.id or not UnitClass then
        return nil
    end

    local resolvedOptions = type(options) == "table" and options or {}
    local presetIndex = UnitClass.NormalizePresetIndex(baseUnit, resolvedOptions.presetIndex)
    local preset = UnitClass.ResolvePreset(baseUnit, presetIndex)
    local playerCount = resolveCurrentPlayerCount(self, resolvedOptions)
    local stats = UnitClass.ApplyStatModifiers(baseUnit.stats or {}, preset)
    local resources = buildPlayerScaledResourceValues(baseUnit, playerCount, preset)
    local effectiveAppearances = UnitClass.ResolveEffectiveAppearances(baseUnit, presetIndex)

    local appearanceIndex = 0
    if #effectiveAppearances > 0 then
        if resolvedOptions.selectRandomAppearance == true then
            appearanceIndex = math.random(1, #effectiveAppearances)
        else
            appearanceIndex = 1
        end
    end

    return {
        dataset = {
            id = dataset.id,
            name = dataset.name,
        },
        baseUnit = deepCopy(baseUnit),
        presetIndex = presetIndex,
        preset = deepCopy(preset),
        registryID = ("%s:%s"):format(dataset.id, baseUnit.id),
        name = UnitClass.ResolveVariantName(baseUnit, presetIndex),
        description = tostring(baseUnit.description or ""),
        spells = deepCopy(baseUnit.spells or {}),
        stats = deepCopy(stats or {}),
        resources = deepCopy(resources or {}),
        effectiveAppearances = deepCopy(effectiveAppearances or {}),
        appearanceIndex = appearanceIndex,
        appearance = appearanceIndex > 0 and UnitClass.ResolveAppearance(baseUnit, presetIndex, appearanceIndex) or nil,
        challengeLevel = UnitClass.NormalizeChallengeLevel(baseUnit.challengeLevel),
        playerCount = playerCount,
    }
end

function Server:BuildEventNpcUnitDataFromDefinition(registryId, options)
    local resolvedOptions = type(options) == "table" and options or {
        team = options,
    }
    local eventState = self.GetEditableEventState and self:GetEditableEventState() or nil
    local variant = self:BuildResolvedNpcVariant(registryId, {
        presetIndex = resolvedOptions.presetIndex,
        playerCount = countPlayerUnits(eventState and eventState.units or {}),
        selectRandomAppearance = resolvedOptions.selectRandomAppearance == true,
    })
    if not variant then
        return nil
    end

    return {
        name = variant.name ~= "" and variant.name or "Unnamed Unit",
        description = variant.description or "",
        registryID = variant.registryID,
        presetIndex = variant.presetIndex,
        appearanceIndex = variant.appearanceIndex,
        team = clampTeamIndex(eventState, resolvedOptions.team),
        raidMarker = math.max(0, math.floor(tonumber(resolvedOptions.raidMarker) or 0)),
        active = coerceBoolean(resolvedOptions.active, true),
        hidden = coerceBoolean(resolvedOptions.hidden, false),
        boss = coerceBoolean(resolvedOptions.boss, false),
        spells = deepCopy(variant.spells or {}),
        stats = deepCopy(variant.stats or {}),
        resources = deepCopy(variant.resources or {}),
    }
end

local function applyRuntimeVariantIdentity(unit, presetIndex, appearanceIndex)
    if type(unit) ~= "table" then
        return unit
    end

    unit.presetIndex = normalizeNonNegativeInteger(presetIndex)
    unit.appearanceIndex = normalizeNonNegativeInteger(appearanceIndex)
    return unit
end

local function applyIdentityToDraftCopy(server, eventId, presetIndex, appearanceIndex)
    local draft = server and server.EventDraftState or nil
    for index = 1, #((draft and draft.units) or {}) do
        local unit = draft.units[index]
        if tonumber(unit and unit.eventID) == tonumber(eventId) then
            applyRuntimeVariantIdentity(unit, presetIndex, appearanceIndex)
            return unit
        end
    end
    return nil
end

local function collectNpcVariantIdentities(units)
    local identities = {}
    for index = 1, #((units) or {}) do
        local unit = units[index]
        if unit and unit.isPlayer ~= true then
            identities[#identities + 1] = {
                presetIndex = normalizeNonNegativeInteger(unit.presetIndex),
                appearanceIndex = normalizeNonNegativeInteger(unit.appearanceIndex),
            }
        end
    end
    return identities
end

local function collectNpcUnitsByEventId(units)
    local npcs = {}
    for index = 1, #((units) or {}) do
        local unit = units[index]
        if unit and unit.isPlayer ~= true then
            npcs[#npcs + 1] = unit
        end
    end
    table.sort(npcs, function(left, right)
        return (tonumber(left and left.eventID) or 0) < (tonumber(right and right.eventID) or 0)
    end)
    return npcs
end

local function restoreNpcVariantIdentitiesByEventOrder(units, identities)
    local npcs = collectNpcUnitsByEventId(units)
    for index = 1, math.min(#npcs, #(identities or {})) do
        local identity = identities[index]
        applyRuntimeVariantIdentity(npcs[index], identity.presetIndex, identity.appearanceIndex)
    end
    return npcs
end

local function syncLiveNpcVariantIdentitiesToDraft(server)
    local live = server and server.EventState or nil
    local draft = server and server.EventDraftState or nil
    if not live or not draft then
        return false
    end

    local identityByEventId = {}
    for index = 1, #((live and live.units) or {}) do
        local unit = live.units[index]
        local eventId = tonumber(unit and unit.eventID) or 0
        if unit and unit.isPlayer ~= true and eventId > 0 then
            identityByEventId[eventId] = {
                presetIndex = normalizeNonNegativeInteger(unit.presetIndex),
                appearanceIndex = normalizeNonNegativeInteger(unit.appearanceIndex),
            }
        end
    end

    for index = 1, #((draft and draft.units) or {}) do
        local unit = draft.units[index]
        local identity = identityByEventId[tonumber(unit and unit.eventID) or 0]
        if identity then
            applyRuntimeVariantIdentity(unit, identity.presetIndex, identity.appearanceIndex)
        end
    end
    return true
end

local baseGetEventDraftState = Server.GetEventDraftState
function Server:GetEventDraftState()
    local previousIdentities = collectNpcVariantIdentities(self.EventDraftState and self.EventDraftState.units or nil)
    local draftState = baseGetEventDraftState and baseGetEventDraftState(self) or nil
    if draftState and #previousIdentities > 0 then
        restoreNpcVariantIdentitiesByEventOrder(draftState.units, previousIdentities)
    end
    return draftState
end

function Server:AddEventNpcUnitFromDefinition(registryId, options)
    local resolvedOptions = type(options) == "table" and deepCopy(options) or {
        team = options,
    }
    resolvedOptions.selectRandomAppearance = true

    local unitData = self:BuildEventNpcUnitDataFromDefinition(registryId, resolvedOptions)
    if not unitData then
        return nil
    end

    local unit = self:AddEventNpcUnit(unitData)
    if not unit then
        return nil
    end

    applyRuntimeVariantIdentity(unit, unitData.presetIndex, unitData.appearanceIndex)
    applyIdentityToDraftCopy(self, unit.eventID, unitData.presetIndex, unitData.appearanceIndex)
    return unit
end

local baseStartEvent = Server.StartEvent
function Server:StartEvent(data)
    local draft = self.GetEventDraftState and self:GetEventDraftState() or self.EventDraftState
    local sourceUnits = type(data) == "table" and type(data.units) == "table" and #data.units > 0
        and data.units
        or (draft and draft.units or nil)
    local identities = collectNpcVariantIdentities(sourceUnits)

    local eventState = baseStartEvent and baseStartEvent(self, data) or nil
    if not eventState then
        return eventState
    end

    restoreNpcVariantIdentitiesByEventOrder(eventState.units, identities)
    restoreNpcVariantIdentitiesByEventOrder(self.EventDraftState and self.EventDraftState.units or nil, identities)
    return eventState
end

local baseCopyLiveEventToDraftState = Server.CopyLiveEventToDraftState
function Server:CopyLiveEventToDraftState()
    local copied = baseCopyLiveEventToDraftState and baseCopyLiveEventToDraftState(self) or false
    if copied then
        syncLiveNpcVariantIdentitiesToDraft(self)
    end
    return copied
end

local baseReconcileClientEventSession = Server.ReconcileClientEventSession
function Server:ReconcileClientEventSession(clientName)
    local result = baseReconcileClientEventSession and baseReconcileClientEventSession(self, clientName) or false
    syncLiveNpcVariantIdentitiesToDraft(self)
    return result
end

local function wrapEventUnitMutation(methodName)
    local baseMethod = Server[methodName]
    if type(baseMethod) ~= "function" then
        return
    end

    Server[methodName] = function(self, ...)
        local result = baseMethod(self, ...)
        syncLiveNpcVariantIdentitiesToDraft(self)
        return result
    end
end

wrapEventUnitMutation("SetEventUnitActive")
wrapEventUnitMutation("SetEventUnitHidden")
wrapEventUnitMutation("SetEventUnitBoss")
wrapEventUnitMutation("SetEventUnitTeam")
wrapEventUnitMutation("SetEventUnitRaidMarker")
