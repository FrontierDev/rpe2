local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Server = Addon.Server
local Registry = Addon.Internal.Registry or {}
local Classes = Addon.Internal.Database.Classes
local UnitClass = Classes.Unit
local EventUnit = Classes.EventUnit

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

local function normalizeVariantIndex(value)
    if EventUnit and type(EventUnit.NormalizeVariantIndex) == "function" then
        return EventUnit.NormalizeVariantIndex(value)
    end

    local numericValue = tonumber(value)
    if numericValue == nil or numericValue ~= numericValue or numericValue == math.huge or numericValue == -math.huge then
        return 0
    end
    return math.max(0, math.floor(numericValue))
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
    if EventUnit and type(EventUnit.CoerceBoolean) == "function" then
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

local function buildPlayerScaledResourceValues(baseUnit, playerCount, presetIndex)
    if not EventUnit or type(EventUnit.BuildUnitDerivedResources) ~= "function" then
        return {}
    end

    local resources = EventUnit.BuildUnitDerivedResources(baseUnit, presetIndex, playerCount, {
        difficulty = "normal",
        healthPercent = 0,
    })
    return resources or {}
end

local function findEventUnitById(units, eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 then
        return nil
    end

    for index = 1, #((units) or {}) do
        local unit = units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit
        end
    end
    return nil
end

local function applyRuntimeVariantIdentity(unit, presetIndex, appearanceIndex)
    if type(unit) ~= "table" then
        return unit
    end

    unit.presetIndex = normalizeVariantIndex(presetIndex)
    unit.appearanceIndex = normalizeVariantIndex(appearanceIndex)
    return unit
end

local function applyIdentityToDraftCopy(server, eventId, presetIndex, appearanceIndex)
    local draftUnit = findEventUnitById(server and server.EventDraftState and server.EventDraftState.units or nil, eventId)
    if draftUnit then
        applyRuntimeVariantIdentity(draftUnit, presetIndex, appearanceIndex)
    end
    return draftUnit
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
    local resources = buildPlayerScaledResourceValues(baseUnit, playerCount, presetIndex)
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
    local summonRequest = type(self.PendingNpcSummonPresetRequest) == "table" and self.PendingNpcSummonPresetRequest or nil
    local isSummonMaterialization = summonRequest ~= nil
        and tostring(summonRequest.registryID or "") == tostring(registryId or "")
        and resolvedOptions.presetIndex == nil
    local requestedPresetIndex = isSummonMaterialization and summonRequest.presetIndex or resolvedOptions.presetIndex

    local variant = self:BuildResolvedNpcVariant(registryId, {
        presetIndex = requestedPresetIndex,
        playerCount = countPlayerUnits(eventState and eventState.units or {}),
        selectRandomAppearance = resolvedOptions.selectRandomAppearance == true or isSummonMaterialization,
    })
    if not variant then
        return nil
    end

    if isSummonMaterialization then
        summonRequest.presetIndex = variant.presetIndex
        summonRequest.appearanceIndex = variant.appearanceIndex
        self.PendingNpcVariantMaterialization = {
            registryID = variant.registryID,
            presetIndex = variant.presetIndex,
            appearanceIndex = variant.appearanceIndex,
        }
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

local baseAddEventNpcUnit = Server.AddEventNpcUnit
function Server:AddEventNpcUnit(data)
    local previousPending = self.PendingNpcVariantMaterialization
    local hasVariantIdentity = type(data) == "table" and (data.presetIndex ~= nil or data.appearanceIndex ~= nil)
    if hasVariantIdentity then
        self.PendingNpcVariantMaterialization = {
            registryID = tostring(data.registryID or ""),
            presetIndex = normalizeVariantIndex(data.presetIndex),
            appearanceIndex = normalizeVariantIndex(data.appearanceIndex),
        }
    end

    local unit = baseAddEventNpcUnit and baseAddEventNpcUnit(self, data) or nil
    if unit and hasVariantIdentity then
        applyRuntimeVariantIdentity(unit, data.presetIndex, data.appearanceIndex)
        -- Pre-start draft refreshes can rebuild and renumber EventUnits before
        -- baseAddEventNpcUnit returns. The canonical constructor now preserves
        -- variant identity, so only mirror by eventID when live IDs are stable.
        if self.IsEventActive and self:IsEventActive() then
            applyIdentityToDraftCopy(self, unit.eventID, data.presetIndex, data.appearanceIndex)
        end
    end

    self.PendingNpcVariantMaterialization = previousPending
    return unit
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

    return self:AddEventNpcUnit(unitData)
end

local baseSummonEventPetUnit = Server.SummonEventPetUnit
function Server:SummonEventPetUnit(casterUnit, registryId, options)
    if type(baseSummonEventPetUnit) ~= "function" then
        return nil
    end

    local resolvedOptions = type(options) == "table" and options or {}
    local previousRequest = self.PendingNpcSummonPresetRequest
    local previousPending = self.PendingNpcVariantMaterialization
    local summonRequest = {
        registryID = tostring(registryId or ""),
        presetIndex = normalizeVariantIndex(resolvedOptions.presetIndex),
        appearanceIndex = 0,
    }
    self.PendingNpcSummonPresetRequest = summonRequest

    local unit = baseSummonEventPetUnit(self, casterUnit, registryId, options)

    self.PendingNpcSummonPresetRequest = previousRequest
    self.PendingNpcVariantMaterialization = previousPending

    if unit then
        applyRuntimeVariantIdentity(unit, summonRequest.presetIndex, summonRequest.appearanceIndex)
        applyIdentityToDraftCopy(self, unit.eventID, summonRequest.presetIndex, summonRequest.appearanceIndex)
    end

    return unit
end