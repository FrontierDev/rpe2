local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Server = Addon.Server
local Client = Addon.Client
local Common = Addon.Utils.Common
local Comms = Addon.Internal.Comms
local Operations = Comms.Operations
local ResourceSync = Comms.ResourceSync or {}
local Ruleset = Addon.Internal.Ruleset or {}
local Database = Addon.Internal.Database or {}
local Event = Addon.Internal.Database.Classes.Event
local EventUnit = Addon.Internal.Database.Classes.EventUnit
local DEFAULT_TEAM_COLORS = Event and Event.GetDefaultTeamColors and Event.GetDefaultTeamColors()
local DEFAULT_MAX_EVENT_UNITS = 5
local MAX_EVENT_INITIATIVE = 20
local EVENT_DIFFICULTY_ORDER = { "normal", "heroic", "mythic" }

local function refreshEventManagePage()
    local eventManage = Addon.Server and Addon.Server.UI and Addon.Server.UI.EventManage or nil
    if type(eventManage) == "table" and type(eventManage.RefreshActivePage) == "function" then
        eventManage:RefreshActivePage()
    end
end

local function getTimings()
    return Addon.Debug and Addon.Debug.Timings or nil
end

local function startTiming(label, options)
    local timings = getTimings()
    if type(timings) ~= "table" or type(timings.Start) ~= "function" then
        return nil
    end

    return timings:Start(label, options)
end

local function stopTiming(timer)
    local timings = getTimings()
    if type(timer) == "table" and type(timings) == "table" and type(timings.Stop) == "function" then
        return timings:Stop(timer)
    end

    return 0, false
end

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

local function findActivatedUnitDefinition(registryId)
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

    local datasets = Addon.Internal and Addon.Internal.Registry and Addon.Internal.Registry.GetActivatedDatasets and Addon.Internal.Registry:GetActivatedDatasets() or {}
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

local function buildSendMetadata(opcode)
    return {
        opcode = opcode,
        scope = "server",
    }
end

local function buildEventId()
    local now = tonumber(Common.GetNow()) or 0
    local randomA = math.random(0, 0xffff)
    local randomB = math.random(0, 0xffff)
    return ("evt%04x%04x%04x"):format(now % 0x10000, randomA, randomB)
end

local function buildEventState(data)
    local values = {
        id = data.id,
        name = data.name or "",
        subtext = data.subtext or "",
        description = data.description or "",
        hostName = data.hostName or "",
        channelName = data.channelName or "",
        startedAt = data.startedAt or 0,
        endedAt = data.endedAt or 0,
        active = data.active == true,
        difficulty = data.difficulty or "normal",
        level = tonumber(data.level) or 1,
        turnNumber = tonumber(data.turnNumber) or 0,
        tickNumber = tonumber(data.tickNumber) or 0,
        totalTicks = tonumber(data.totalTicks) or 0,
        unitsReady = data.unitsReady == true,
        units = data.units or {},
        teams = data.teams,
        eventAuras = data.eventAuras or {},
        lootRefs = data.lootRefs or {},
        teamColors = data.teamColors or DEFAULT_TEAM_COLORS,
    }

    return Event:New(values)
end

local function isLevelSystemEnabled()
    local activeRuleset = Ruleset and Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local ruleDefinition = Ruleset and Ruleset.GetRulesetRuleDefinition and Ruleset.GetRulesetRuleDefinition("character", "use_level_system") or nil
    return Ruleset and Ruleset.GetRulesetRuleValue and Ruleset.GetRulesetRuleValue(activeRuleset, "character", ruleDefinition) == true
end

local function normalizeEventLevel(value)
    if not isLevelSystemEnabled() then
        return 1
    end

    local level = math.floor(tonumber(value) or 1)
    if level < 1 then
        level = 1
    end

    return level
end

local function getAllowedEventDifficulties()
    local activeRuleset = Ruleset and Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local ruleDefinition = Ruleset and Ruleset.GetRulesetRuleDefinition and Ruleset.GetRulesetRuleDefinition("event", "allowed_event_difficulties") or nil
    local configured = Ruleset and Ruleset.GetRulesetRuleValue and Ruleset.GetRulesetRuleValue(activeRuleset, "event", ruleDefinition) or nil
    local allowedLookup = {}
    local allowed = {}

    for index = 1, #(type(configured) == "table" and configured or {}) do
        local difficulty = string.lower(tostring(configured[index] or ""))
        for orderIndex = 1, #EVENT_DIFFICULTY_ORDER do
            if difficulty == EVENT_DIFFICULTY_ORDER[orderIndex] and not allowedLookup[difficulty] then
                allowedLookup[difficulty] = true
                allowed[#allowed + 1] = difficulty
            end
        end
    end

    if #allowed == 0 then
        allowed[1] = "normal"
    end

    return allowed, allowedLookup
end

local function normalizeEventDifficulty(value)
    local allowed, allowedLookup = getAllowedEventDifficulties()
    local normalized = string.lower(tostring(value or "normal"))
    if allowedLookup[normalized] then
        return normalized
    end

    for index = 1, #EVENT_DIFFICULTY_ORDER do
        local candidate = EVENT_DIFFICULTY_ORDER[index]
        if allowedLookup[candidate] then
            return candidate
        end
    end

    return allowed[1] or "normal"
end

local function clampEventTeamIndex(eventState, value)
    local teamCount = #(eventState and eventState.teams or {})
    if teamCount <= 0 then
        teamCount = 1
    end

    local numericValue = math.floor(tonumber(value) or 1)
    if numericValue < 1 then
        numericValue = 1
    elseif numericValue > teamCount then
        numericValue = teamCount
    end

    return numericValue
end

local function cloneStringList(values)
    local cloned = {}

    for index = 1, #(values or {}) do
        local value = tostring(values[index] or "")
        if value ~= "" then
            cloned[#cloned + 1] = value
        end
    end

    return cloned
end

local function cloneTeams(teams)
    local clones = {}

    for index = 1, #(teams or {}) do
        local team = teams[index]
        if type(team) == "table" then
            clones[index] = {
                id = tostring(team.id or ("team%d"):format(index)),
                name = tostring(team.name or ("Team %d"):format(index)),
                color = deepCopy(team.color),
            }
        end
    end

    return clones
end

local function cloneEventAuras(values)
    local cloned = {}

    for index = 1, #(values or {}) do
        local entry = values[index]
        local auraRef = type(entry) == "table" and tostring(entry.auraRef or entry.ref or "") or ""
        if auraRef ~= "" then
            local sourceTeams = type(entry) == "table" and (entry.teamIndices or entry.teams) or nil
            local teamIndices = {}
            local seen = {}
            for teamIndex = 1, #(sourceTeams or {}) do
                local numericValue = math.floor(tonumber(sourceTeams[teamIndex]) or 0)
                if numericValue > 0 and not seen[numericValue] then
                    seen[numericValue] = true
                    teamIndices[#teamIndices + 1] = numericValue
                end
            end
            table.sort(teamIndices)
            cloned[#cloned + 1] = {
                auraRef = auraRef,
                teamIndices = teamIndices,
            }
        end
    end

    return cloned
end

local function getDefaultDraftEventLevel()
    if not isLevelSystemEnabled() then
        return 1
    end

    local profile = Database and Database.GetActiveProfile and Database.GetActiveProfile() or nil
    return normalizeEventLevel(profile and profile.level or 1)
end

local function getMaxEventUnits()
    local activeRuleset = Ruleset and Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local ruleDefinition = Ruleset and Ruleset.GetRulesetRuleDefinition and Ruleset.GetRulesetRuleDefinition("event", "max_event_units") or nil
    local maxEventUnits = Ruleset and Ruleset.GetRulesetRuleValue and Ruleset.GetRulesetRuleValue(activeRuleset, "event", ruleDefinition) or nil
    maxEventUnits = math.floor(tonumber(maxEventUnits) or DEFAULT_MAX_EVENT_UNITS)
    if maxEventUnits <= 0 then
        return DEFAULT_MAX_EVENT_UNITS
    end

    return maxEventUnits
end

local function computeTotalTicks(units, maxEventUnits)
    local unitCount = Event and Event.CountActiveUnits and Event.CountActiveUnits(units) or #((units) or {})
    if unitCount <= 0 then
        return 1
    end

    local pageSize = math.max(1, math.floor(tonumber(maxEventUnits) or DEFAULT_MAX_EVENT_UNITS))
    return math.max(1, math.ceil(unitCount / pageSize))
end

local function normalizeEventStepState(eventState)
    if not eventState then
        return nil
    end

    local totalTicks = computeTotalTicks(eventState.units, getMaxEventUnits())
    eventState.totalTicks = totalTicks

    local turnNumber = math.floor(tonumber(eventState.turnNumber) or 0)
    if turnNumber <= 0 then
        turnNumber = 1
    end
    eventState.turnNumber = turnNumber

    local tickNumber = math.floor(tonumber(eventState.tickNumber) or 0)
    if tickNumber <= 0 then
        tickNumber = 1
    elseif tickNumber > totalTicks then
        tickNumber = totalTicks
    end
    eventState.tickNumber = tickNumber
    return eventState
end

local function markEventUnitsPending(eventState)
    if not eventState then
        return nil
    end

    eventState.unitsReady = false
    eventState.resourcesReady = false
    eventState.rosterReady = false
    eventState.unitsChunkExpected = 0
    eventState.unitsChunkReceived = 0
    eventState.healthResourcesExpected = 0
    eventState.healthResourcesReceived = 0
    eventState.readyProgressExpected = 0
    eventState.readyProgressReceived = 0
    return eventState
end

local function normalizeEventUnitInitiative(unit)
    if not unit then
        return nil
    end

    local initiative = tonumber(unit.initiative)
    if initiative == nil then
        initiative = math.random(1, MAX_EVENT_INITIATIVE)
    end

    unit.initiative = math.floor(initiative)
    return unit
end

local function sortEventUnits(units)
    if Event and Event.SortUnitsByInitiative then
        return Event.SortUnitsByInitiative(units)
    end

    return units or {}
end

local function cloneUnit(unit)
    if not unit then
        return nil
    end

    if unit.ToTable and EventUnit and EventUnit.FromTable then
        return EventUnit.FromTable(unit:ToTable())
    end

    if EventUnit and EventUnit.FromTable then
        return EventUnit.FromTable(unit)
    end

    return deepCopy(unit)
end

local function cloneUnits(units)
    local copies = {}

    for index = 1, #((units) or {}) do
        local copy = cloneUnit(units[index])
        if copy then
            copies[#copies + 1] = copy
        end
    end

    return copies
end

local function normalizeStatRows(stats)
    if EventUnit and EventUnit.SerializeStatsForNetwork and EventUnit.DeserializeStatsFromNetwork then
        return EventUnit.DeserializeStatsFromNetwork(EventUnit.SerializeStatsForNetwork(stats))
    end

    return deepCopy(stats or {})
end

local function buildStatBonusRows(baseStats, runtimeStats)
    local normalizedBase = normalizeStatRows(baseStats)
    local normalizedRuntime = normalizeStatRows(runtimeStats)
    local baseByRef = {}
    local bonuses = {}

    for index = 1, #normalizedBase do
        local entry = normalizedBase[index]
        local statRef = type(entry) == "table" and tostring(entry.statRef or "") or ""
        if statRef ~= "" then
            baseByRef[statRef] = entry
        end
    end

    for index = 1, #normalizedRuntime do
        local entry = normalizedRuntime[index]
        local statRef = type(entry) == "table" and tostring(entry.statRef or "") or ""
        if statRef ~= "" then
            local baseEntry = baseByRef[statRef]
            local baseValue = tonumber(baseEntry and baseEntry.value) or 0
            local baseCurrent = tonumber(baseEntry and baseEntry.currentValue ~= nil and baseEntry.currentValue or baseEntry and baseEntry.value) or 0
            local runtimeValue = tonumber(entry.value) or 0
            local runtimeCurrent = tonumber(entry.currentValue ~= nil and entry.currentValue or entry.value) or 0
            local bonusValue = runtimeValue - baseValue
            local bonusCurrent = runtimeCurrent - baseCurrent
            if bonusValue ~= 0 or bonusCurrent ~= 0 then
                bonuses[#bonuses + 1] = {
                    statRef = statRef,
                    value = bonusValue,
                    currentValue = bonusCurrent,
                }
            end
        end
    end

    return bonuses
end

local function buildCompactSummonedUnitDelta(unit)
    if not unit or tostring(unit.registryID or "") == "" or tostring(unit.petRef or "") == "" then
        return unit
    end

    local compactUnit = cloneUnit(unit)
    if not compactUnit then
        return unit
    end

    local resolvedUnit = compactUnit.GetResolvedUnit and compactUnit:GetResolvedUnit() or nil
    compactUnit.resources = {}
    compactUnit.spells = {}
    compactUnit.stats = buildStatBonusRows(resolvedUnit and resolvedUnit.stats or nil, compactUnit.stats)
    compactUnit._networkResourceMode = "inherit"
    compactUnit._networkSpellMode = "inherit"
    compactUnit._networkStatMode = "bonus"
    return compactUnit
end

local function coerceEventUnitBoolean(value, defaultValue)
    if EventUnit and EventUnit.CoerceBoolean then
        return EventUnit.CoerceBoolean(value, defaultValue)
    end

    if value == nil then
        return defaultValue == true
    end

    if value == true or value == false then
        return value
    end

    local numericValue = tonumber(value)
    if numericValue ~= nil then
        return numericValue ~= 0
    end

    if type(value) == "string" then
        local normalized = string.lower(value)
        if normalized == "true" or normalized == "yes" or normalized == "on" then
            return true
        end
        if normalized == "false" or normalized == "no" or normalized == "off" then
            return false
        end
    end

    return defaultValue == true
end

local function findPlayerUnitByName(units, playerName)
    local normalizedPlayerName = Common.NormalizeName(playerName)
    if normalizedPlayerName == "" then
        return nil, nil
    end

    for index = 1, #((units) or {}) do
        local unit = units[index]
        if unit and unit.isPlayer == true then
            local candidateName = Common.NormalizeName(unit.ownerID or unit.controllerID or unit.name)
            if candidateName == normalizedPlayerName then
                return unit, index
            end
        end
    end

    return nil, nil
end

local function findEventUnitById(units, eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 then
        return nil, nil
    end

    for index = 1, #((units) or {}) do
        local unit = units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit, index
        end
    end

    return nil, nil
end

local function buildPlayerUnit(playerName, nextEventUnitId)
    return EventUnit:New({
        eventID = nextEventUnitId,
        name = playerName,
        isPlayer = true,
        registryID = nil,
        raidMarker = 0,
        team = 1,
        ownerID = playerName,
        controllerID = playerName,
        resources = {},
        active = true,
        hidden = false,
    })
end

local buildNpcResources

local function buildNpcUnit(unitData, ownerName, nextEventUnitId, playerCount)
    local values = type(unitData) == "table" and unitData or {}
    return EventUnit:New({
        name = values.name or "",
        description = values.description or "",
        eventID = nextEventUnitId,
        isPlayer = false,
        registryID = values.registryID,
        raidMarker = tonumber(values.raidMarker) or 0,
        team = math.max(1, math.floor(tonumber(values.team) or 1)),
        ownerID = values.ownerID or ownerName,
        controllerID = values.controllerID,
        resources = buildNpcResources(values, playerCount),
        spells = values.spells,
        stats = values.stats,
        active = coerceEventUnitBoolean(values.active, true),
        hidden = coerceEventUnitBoolean(values.hidden, false),
        boss = coerceEventUnitBoolean(values.boss, false),
        petRef = values.petRef,
        summonedByEventID = values.summonedByEventID,
        mainHandWeapon = values.mainHandWeapon,
        offHandWeapon = values.offHandWeapon,
        rangedWeapon = values.rangedWeapon,
        shield = values.shield,
    })
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

local function resolveControllingPlayerEventId(casterUnit)
    if type(casterUnit) ~= "table" then
        return nil
    end

    if casterUnit.isPlayer == true then
        return tonumber(casterUnit.eventID) or nil
    end

    return tonumber(casterUnit.controllerID) or nil
end

local function resolveControllerEventID(controllerValue, playerEventIds, fallbackEventId)
    local numericControllerId = tonumber(controllerValue) or 0
    if numericControllerId > 0 then
        return numericControllerId
    end

    local normalizedControllerName = Common.NormalizeName(controllerValue)
    if normalizedControllerName ~= "" and playerEventIds and playerEventIds[normalizedControllerName] then
        return playerEventIds[normalizedControllerName]
    end

    return fallbackEventId
end

local function normalizeNpcResourceEntry(entry, playerCount)
    if type(entry) ~= "table" then
        return nil
    end

    local resourceRef = type(entry.resourceRef) == "string" and entry.resourceRef or nil
    if not resourceRef or resourceRef == "" then
        return nil
    end

    local currentValue = entry.currentValue
    local maxValue = entry.maxValue
    if currentValue ~= nil or maxValue ~= nil then
        currentValue = tonumber(currentValue ~= nil and currentValue or maxValue) or 0
        maxValue = tonumber(maxValue ~= nil and maxValue or currentValue) or 0
        return {
            resourceRef = resourceRef,
            currentValue = currentValue,
            maxValue = maxValue,
        }
    end

    local baseValue = tonumber(entry.value) or 0
    local scaledValue = baseValue + ((tonumber(entry.perPlayer) or 0) * math.max(0, tonumber(playerCount) or 0))
    return {
        resourceRef = resourceRef,
        currentValue = scaledValue,
        maxValue = scaledValue,
    }
end

buildNpcResources = function(unitData, playerCount)
    local resources = {}
    local sourceEntries = type(unitData) == "table" and unitData.resources or nil

    if type(sourceEntries) ~= "table" or #sourceEntries == 0 then
        local _, resolvedUnit = findActivatedUnitDefinition(type(unitData) == "table" and unitData.registryID or nil)
        sourceEntries = resolvedUnit and resolvedUnit.resources or nil
    end

    for index = 1, #((sourceEntries) or {}) do
        local normalized = normalizeNpcResourceEntry(sourceEntries[index], playerCount)
        if normalized then
            resources[#resources + 1] = normalized
        end
    end

    return resources
end

local function buildEventUnits(sessionState, sourceUnits, hostName)
    local units = {}
    local nextEventUnitId = 1
    local seenPlayers = {}
    local playerOrder = {}
    local groupedPlayerOrder = {}
    local trackedPlayerOrder = {}
    local trackedPlayersSeen = {}
    local sourcePlayerUnitsByName = {}
    local sourceNpcUnits = {}
    local groupedPlayers = Common.GetGroupMemberNames and Common.GetGroupMemberNames() or {}
    local playerCount = 0
    local playerEventIds = {}

    local function appendUniqueName(target, seen, name)
        local normalizedName = Common.NormalizeName(name)
        if normalizedName == "" or seen[normalizedName] then
            return
        end

        seen[normalizedName] = true
        target[#target + 1] = normalizedName
    end

    for index = 1, #groupedPlayers do
        appendUniqueName(groupedPlayerOrder, seenPlayers, groupedPlayers[index])
    end

    seenPlayers = {}
    for index = 1, #((sessionState and sessionState.clientOrder) or {}) do
        appendUniqueName(trackedPlayerOrder, trackedPlayersSeen, sessionState.clientOrder[index])
    end

    for index = 1, #((sourceUnits) or {}) do
        local unit = sourceUnits[index]
        if unit and unit.isPlayer == true then
            local playerName = Common.NormalizeName(unit.ownerID or unit.controllerID or unit.name)
            if playerName ~= "" and not sourcePlayerUnitsByName[playerName] then
                sourcePlayerUnitsByName[playerName] = unit
            end
        elseif unit then
            sourceNpcUnits[#sourceNpcUnits + 1] = unit
        end
    end

    if #trackedPlayerOrder > 1 then
        for index = 1, #trackedPlayerOrder do
            playerOrder[#playerOrder + 1] = trackedPlayerOrder[index]
        end
    else
        local playerOrderSeen = {}
        for index = 1, #groupedPlayerOrder do
            appendUniqueName(playerOrder, playerOrderSeen, groupedPlayerOrder[index])
        end
        for index = 1, #trackedPlayerOrder do
            appendUniqueName(playerOrder, playerOrderSeen, trackedPlayerOrder[index])
        end
    end

    seenPlayers = {}
    for index = 1, #playerOrder do
        local playerName = Common.NormalizeName(playerOrder[index])
        if playerName ~= "" and not seenPlayers[playerName] then
            local playerUnit = cloneUnit(sourcePlayerUnitsByName[playerName]) or buildPlayerUnit(playerName, nextEventUnitId)
            local clientState = sessionState and sessionState.clientsByName and sessionState.clientsByName[playerName] or nil
            playerUnit.eventID = nextEventUnitId
            playerUnit.name = playerName
            playerUnit.isPlayer = true
            playerUnit.registryID = nil
            playerUnit.ownerID = playerName
            playerUnit.controllerID = playerName
            playerUnit.resources = ResourceSync.CloneResources and ResourceSync.CloneResources(clientState and clientState.resources or {}) or {}
            playerUnit.active = true
            units[#units + 1] = playerUnit
            seenPlayers[playerName] = true
            playerEventIds[playerName] = nextEventUnitId
            nextEventUnitId = nextEventUnitId + 1
        end
    end

    if not seenPlayers[hostName] then
        local hostUnit = cloneUnit(sourcePlayerUnitsByName[hostName]) or buildPlayerUnit(hostName, nextEventUnitId)
        local hostClientState = sessionState and sessionState.clientsByName and sessionState.clientsByName[hostName] or nil
        hostUnit.eventID = nextEventUnitId
        hostUnit.name = hostName
        hostUnit.isPlayer = true
        hostUnit.registryID = nil
        hostUnit.ownerID = hostName
        hostUnit.controllerID = hostName
        hostUnit.resources = ResourceSync.CloneResources and ResourceSync.CloneResources(hostClientState and hostClientState.resources or {}) or {}
        hostUnit.active = true
        units[#units + 1] = hostUnit
        seenPlayers[hostName] = true
        playerEventIds[hostName] = nextEventUnitId
        nextEventUnitId = nextEventUnitId + 1
    end

    playerCount = #units

    for index = 1, #sourceNpcUnits do
        local unitData = sourceNpcUnits[index]
        if type(unitData) == "table" then
            local unit = cloneUnit(unitData) or buildNpcUnit(unitData, hostName, nextEventUnitId, playerCount)
            unit.eventID = nextEventUnitId
            unit.isPlayer = false
            unit.ownerID = unit.ownerID or hostName
            unit.controllerID = resolveControllerEventID(unit.controllerID, playerEventIds, playerEventIds[hostName] or nextEventUnitId)
            unit.resources = buildNpcResources(unitData, playerCount)
            units[#units + 1] = unit
            nextEventUnitId = nextEventUnitId + 1
        end
    end

    for index = 1, #units do
        normalizeEventUnitInitiative(units[index])
    end
    sortEventUnits(units)
    return units
end

local function buildLivePlayerUnit(sessionState, playerName, nextEventUnitId, sourceUnit)
    local playerUnit = cloneUnit(sourceUnit) or buildPlayerUnit(playerName, nextEventUnitId)
    local clientState = sessionState and sessionState.clientsByName and sessionState.clientsByName[playerName] or nil

    playerUnit.eventID = nextEventUnitId
    playerUnit.name = playerName
    playerUnit.isPlayer = true
    playerUnit.registryID = nil
    playerUnit.ownerID = playerName
    playerUnit.controllerID = playerName
    playerUnit.resources = ResourceSync.CloneResources and ResourceSync.CloneResources(clientState and clientState.resources or {}) or {}
    playerUnit.active = true
    playerUnit.hidden = sourceUnit and sourceUnit.hidden == true or false
    normalizeEventUnitInitiative(playerUnit)
    return playerUnit
end

local function upsertSortedEventUnit(units, unit)
    if type(units) ~= "table" or not unit then
        return nil
    end

    local _, existingIndex = findEventUnitById(units, unit.eventID)
    if existingIndex then
        units[existingIndex] = unit
    else
        units[#units + 1] = unit
    end

    sortEventUnits(units)
    return unit
end

local function upsertAppendedEventUnit(units, unit)
    if type(units) ~= "table" or not unit then
        return nil
    end

    local _, existingIndex = findEventUnitById(units, unit.eventID)
    if existingIndex then
        units[existingIndex] = unit
    else
        units[#units + 1] = unit
    end

    return unit
end

local function removeEventUnitById(units, eventId)
    if type(units) ~= "table" then
        return nil
    end

    local _, index = findEventUnitById(units, eventId)
    if not index then
        return nil
    end

    local removed = units[index]
    table.remove(units, index)
    return removed
end

local function getNextEventUnitId(units)
    local nextEventUnitId = 1

    for index = 1, #((units) or {}) do
        local unit = units[index]
        local eventID = tonumber(unit and unit.eventID) or 0
        if eventID >= nextEventUnitId then
            nextEventUnitId = eventID + 1
        end
    end

    return nextEventUnitId
end

local function buildStartArguments(eventState)
    if eventState and eventState.ToStartArguments then
        return eventState:ToStartArguments(false)
    end

    return {
        eventState and eventState.channelName or "",
        eventState and eventState.id or nil,
        eventState and eventState.name or "",
        eventState and eventState.description or "",
        eventState and eventState.hostName or "",
        eventState and eventState.startedAt or 0,
        "",
        eventState and eventState.subtext or "",
        eventState and eventState.SerializeTeamColorsForNetwork and eventState.SerializeTeamColorsForNetwork(eventState.teamColors) or "",
        eventState and eventState.difficulty or "normal",
        eventState and eventState.SerializeTeamsForNetwork and eventState.SerializeTeamsForNetwork(eventState.teams) or "",
        eventState and eventState.SerializeEventAurasForNetwork and eventState.SerializeEventAurasForNetwork(eventState.eventAuras) or "",
        eventState and eventState.SerializeRefListForNetwork and eventState.SerializeRefListForNetwork(eventState.lootRefs) or "",
        eventState and eventState.level or 1,
        eventState and eventState.turnNumber or 0,
        eventState and eventState.tickNumber or 0,
        eventState and eventState.totalTicks or 0,
    }
end

local function buildEndArguments(eventState, reason)
    if eventState and eventState.ToEndArguments then
        return eventState:ToEndArguments(reason)
    end

    return {
        eventState and eventState.channelName or "",
        eventState and eventState.id or nil,
        tostring(reason or ""),
    }
end

local EVENT_START_OPCODE = Operations:GetOpcode("EVENT_START")
local EVENT_END_OPCODE = Operations:GetOpcode("EVENT_END")
local EVENT_UNITS_OPCODE = Operations:GetOpcode("EVENT_UNITS")
local EVENT_STATE_OPCODE = Operations:GetOpcode("EVENT_STATE")
local EVENT_UNIT_DELTA_BATCH_OPCODE = Operations:GetOpcode("EVENT_UNIT_DELTA_BATCH")

local function buildEventUnitsArguments(eventState)
    return {
        eventState and eventState.channelName or "",
        eventState and eventState.id or nil,
        eventState and eventState.SerializeUnitsForNetwork and eventState:SerializeUnitsForNetwork() or "",
    }
end

local function buildEventStateArguments(eventState)
    if eventState and eventState.ToStateArguments then
        return eventState:ToStateArguments()
    end

    return {
        eventState and eventState.channelName or "",
        eventState and eventState.id or nil,
        eventState and eventState.turnNumber or 0,
        eventState and eventState.tickNumber or 0,
        eventState and eventState.totalTicks or 0,
    }
end

local function buildEventUnitDeltaBatchArguments(eventState, entries)
    return {
        eventState and eventState.channelName or "",
        eventState and eventState.id or nil,
        Event and Event.SerializeUnitDeltaBatchForNetwork and Event.SerializeUnitDeltaBatchForNetwork(entries) or "",
    }
end

local function resolveEventChannelId(sessionState, eventState)
    local channelName = eventState and eventState.channelName or (sessionState and sessionState.channelName) or nil
    local channelId = nil
    if type(channelName) == "string" and channelName ~= "" and Comms.ResolveChannelId then
        channelId = Comms:ResolveChannelId(channelName)
    end

    if (channelId == nil or channelId == "") and sessionState then
        channelId = sessionState.channelId
    end

    if sessionState and channelId ~= nil and channelId ~= "" then
        sessionState.channelId = channelId
    end
    if eventState and channelId ~= nil and channelId ~= "" then
        eventState.channelId = channelId
    end

    return channelId
end

local function copyLiveEventToDraft(server, eventState)
    if not server or not server.EventDraftState or not eventState then
        return false
    end

    server.EventDraftState.hostName = eventState.hostName
    server.EventDraftState.channelName = eventState.channelName
    server.EventDraftState.name = eventState.name or ""
    server.EventDraftState.subtext = eventState.subtext or ""
    server.EventDraftState.description = eventState.description or ""
    server.EventDraftState.difficulty = normalizeEventDifficulty(eventState.difficulty)
    server.EventDraftState.level = normalizeEventLevel(eventState.level)
    server.EventDraftState.turnNumber = eventState.turnNumber
    server.EventDraftState.tickNumber = eventState.tickNumber
    server.EventDraftState.totalTicks = eventState.totalTicks
    server.EventDraftState.units = cloneUnits(eventState.units)
    server.EventDraftState.teams = cloneTeams(eventState.teams)
    server.EventDraftState.teamColors = eventState.ToTable and eventState:ToTable().teamColors or deepCopy(eventState.teamColors)
    server.EventDraftState.eventAuras = cloneEventAuras(eventState.eventAuras)
    server.EventDraftState.lootRefs = cloneStringList(eventState.lootRefs)
    return true
end

local function broadcastEventDeltaBatch(server, eventState, entries, includeState)
    if not server or not eventState or eventState.active ~= true then
        return false
    end

    local arguments = buildEventUnitDeltaBatchArguments(eventState, entries)
    if type(arguments[3]) ~= "string" or arguments[3] == "" then
        return false
    end

    local sessionState = server.GetState and server:GetState() or nil
    local channelId = resolveEventChannelId(sessionState, eventState)
    if not channelId then
        return false
    end

    local sent = Comms:SendToChannel(
        channelId,
        EVENT_UNIT_DELTA_BATCH_OPCODE,
        arguments,
        buildSendMetadata(EVENT_UNIT_DELTA_BATCH_OPCODE)
    ) and true or false

    if includeState then
        Comms:SendToChannel(
            channelId,
            EVENT_STATE_OPCODE,
            buildEventStateArguments(eventState),
            buildSendMetadata(EVENT_STATE_OPCODE)
        )
    end

    return sent
end

function Server:BroadcastEventDeltaBatch(entries, includeState)
    return broadcastEventDeltaBatch(self, self.EventState, entries, includeState)
end

function Server:CopyLiveEventToDraftState()
    return copyLiveEventToDraft(self, self.EventState)
end

local function sendEventSnapshotToClient(eventState, clientName)
    local normalizedClientName = Common.NormalizeName(clientName)
    if not eventState or eventState.active ~= true or normalizedClientName == "" then
        return false
    end

    local sentStart = Comms:SendMessage("WHISPER", EVENT_START_OPCODE, buildStartArguments(eventState), normalizedClientName, buildSendMetadata(EVENT_START_OPCODE))
    Comms:SendMessage("WHISPER", EVENT_UNITS_OPCODE, buildEventUnitsArguments(eventState), normalizedClientName, buildSendMetadata(EVENT_UNITS_OPCODE))
    Comms:SendMessage("WHISPER", EVENT_STATE_OPCODE, buildEventStateArguments(eventState), normalizedClientName, buildSendMetadata(EVENT_STATE_OPCODE))
    return sentStart and true or false
end

Server.EventState = Server.EventState or nil
Server.EventDraftState = Server.EventDraftState or nil

function Server:GetEventState()
    return self.EventState
end

function Server:IsEventActive()
    return self.EventState ~= nil and self.EventState.active == true
end

function Server:IsEventUnitsReady()
    local eventState = self.EventState
    return eventState ~= nil and eventState.active == true and eventState.unitsReady == true
end

function Server:GetEventDraftState()
    local sessionState = self:GetState()
    if not sessionState or sessionState.active ~= true or not sessionState.channelName then
        self.EventDraftState = nil
        return nil
    end

    local hostName = Common.NormalizeName(Common.GetPlayerName())
    local draftState = self.EventDraftState
    local sourceUnits = draftState and draftState.units or nil
    local units = buildEventUnits(sessionState, sourceUnits, hostName)

    if draftState then
        draftState.hostName = hostName
        draftState.channelName = sessionState.channelName
        draftState.units = units
        draftState.totalTicks = computeTotalTicks(units, getMaxEventUnits())
        draftState.difficulty = normalizeEventDifficulty(draftState.difficulty)
        draftState.level = normalizeEventLevel(draftState.level)
    else
        draftState = buildEventState({
            id = nil,
            name = "",
            subtext = "",
            description = "",
            hostName = hostName,
            channelName = sessionState.channelName,
            startedAt = 0,
            endedAt = 0,
            active = false,
            difficulty = normalizeEventDifficulty("normal"),
            level = getDefaultDraftEventLevel(),
            turnNumber = 0,
            tickNumber = 0,
            totalTicks = computeTotalTicks(units, getMaxEventUnits()),
            units = units,
            teamColors = DEFAULT_TEAM_COLORS,
        })
        self.EventDraftState = draftState
    end

    return draftState
end

function Server:GetEditableEventState()
    if self:IsEventActive() then
        return self.EventState
    end

    return self:GetEventDraftState()
end

function Server:ReconcileClientEventSession(clientName)
    local sessionState = self:GetState()
    local normalizedClientName = Common.NormalizeName(clientName)
    if not sessionState or sessionState.active ~= true or normalizedClientName == "" then
        return false
    end

    local clientState = sessionState.clientsByName and sessionState.clientsByName[normalizedClientName] or nil
    if not clientState then
        return false
    end

    if self.ClientHashesMatch and not self:ClientHashesMatch(normalizedClientName, sessionState) then
        return false
    end

    local eventState = self.EventState
    if not eventState or eventState.active ~= true then
        return true
    end

    local existingUnit = findPlayerUnitByName(eventState.units, normalizedClientName)
    local rosterChanged = false
    local deltaEntries = nil
    local includeState = false

    if not existingUnit then
        local previousTurnNumber = tonumber(eventState.turnNumber) or 0
        local previousTickNumber = tonumber(eventState.tickNumber) or 0
        local previousTotalTicks = tonumber(eventState.totalTicks) or 0
        local sourcePlayerUnit = findPlayerUnitByName(
            self.EventDraftState and self.EventDraftState.units or eventState.units,
            normalizedClientName
        )
        local nextEventUnitId = getNextEventUnitId(eventState.units)
        local livePlayerUnit = buildLivePlayerUnit(sessionState, normalizedClientName, nextEventUnitId, sourcePlayerUnit)
        upsertAppendedEventUnit(eventState.units, livePlayerUnit)
        normalizeEventStepState(eventState)
        deltaEntries = {
            {
                operation = "upsert",
                eventID = livePlayerUnit.eventID,
                unit = livePlayerUnit,
            },
        }
        includeState = previousTurnNumber ~= (tonumber(eventState.turnNumber) or 0)
            or previousTickNumber ~= (tonumber(eventState.tickNumber) or 0)
            or previousTotalTicks ~= (tonumber(eventState.totalTicks) or 0)
        rosterChanged = true
    end

    copyLiveEventToDraft(self, eventState)

    sendEventSnapshotToClient(eventState, normalizedClientName)

    if rosterChanged and deltaEntries then
        broadcastEventDeltaBatch(self, eventState, deltaEntries, includeState)
    end

    return true
end

function Server:AddEventNpcUnit(data)
    local eventState = self:GetEditableEventState()
    if not eventState then
        return nil
    end

    local hostName = Common.NormalizeName(eventState.hostName ~= "" and eventState.hostName or Common.GetPlayerName())
    eventState.units = eventState.units or {}
    local previousTurnNumber = tonumber(eventState.turnNumber) or 0
    local previousTickNumber = tonumber(eventState.tickNumber) or 0
    local previousTotalTicks = tonumber(eventState.totalTicks) or 0

    local nextEventUnitId = getNextEventUnitId(eventState.units)
    local unit = buildNpcUnit(data, hostName, nextEventUnitId, countPlayerUnits(eventState.units))
    unit.controllerID = unit.controllerID or hostName
    normalizeEventUnitInitiative(unit)
    if eventState.active == true then
        upsertAppendedEventUnit(eventState.units, unit)
    else
        upsertSortedEventUnit(eventState.units, unit)
    end
    normalizeEventStepState(eventState)
    if eventState.active == true then
        copyLiveEventToDraft(self, eventState)
        broadcastEventDeltaBatch(self, eventState, {
            {
                operation = "upsert",
                eventID = unit.eventID,
                unit = unit,
            },
        }, previousTurnNumber ~= (tonumber(eventState.turnNumber) or 0)
            or previousTickNumber ~= (tonumber(eventState.tickNumber) or 0)
            or previousTotalTicks ~= (tonumber(eventState.totalTicks) or 0))
    end
    refreshEventManagePage()
    return unit
end

function Server:SummonEventPetUnit(casterUnit, registryId, options)
    local eventState = self:GetEditableEventState()
    if not eventState or eventState.active ~= true or type(casterUnit) ~= "table" then
        return nil
    end

    local resolvedRegistryId = tostring(registryId or "")
    if resolvedRegistryId == "" then
        return nil
    end

    local _, resolvedUnit = findActivatedUnitDefinition(resolvedRegistryId)
    if not resolvedUnit then
        return nil
    end

    local controllingPlayerEventId = resolveControllingPlayerEventId(casterUnit)
    if not controllingPlayerEventId or controllingPlayerEventId <= 0 then
        return nil
    end

    local resolvedOptions = type(options) == "table" and options or {}
    local previousTurnNumber = tonumber(eventState.turnNumber) or 0
    local previousTickNumber = tonumber(eventState.tickNumber) or 0
    local previousTotalTicks = tonumber(eventState.totalTicks) or 0
    local removedEntries = {}
    local casterEventId = tonumber(casterUnit.eventID) or 0

    for index = #(eventState.units or {}), 1, -1 do
        local unit = eventState.units[index]
        if unit and unit.isPlayer ~= true and tonumber(unit.summonedByEventID) == casterEventId then
            removedEntries[#removedEntries + 1] = {
                operation = "remove",
                eventID = tonumber(unit.eventID) or 0,
            }
            table.remove(eventState.units, index)
        end
    end

    local summonData = self:BuildEventNpcUnitDataFromDefinition(resolvedRegistryId, {
        team = tonumber(casterUnit.team) or 1,
        active = true,
        hidden = false,
    })
    if not summonData then
        return nil
    end

    summonData.ownerID = resolvedOptions.ownerID
    summonData.controllerID = controllingPlayerEventId
    summonData.summonedByEventID = casterEventId > 0 and casterEventId or nil
    summonData.petRef = type(resolvedOptions.petRef) == "string" and resolvedOptions.petRef or nil
    if type(resolvedOptions.spells) == "table" then
        summonData.spells = deepCopy(resolvedOptions.spells)
    else
        summonData.spells = nil
    end
    if type(resolvedOptions.stats) == "table" then
        summonData.stats = deepCopy(resolvedOptions.stats)
    end

    local hostName = Common.NormalizeName(eventState.hostName ~= "" and eventState.hostName or Common.GetPlayerName())
    local nextEventUnitId = getNextEventUnitId(eventState.units)
    local unit = buildNpcUnit(summonData, hostName, nextEventUnitId, countPlayerUnits(eventState.units))
    normalizeEventUnitInitiative(unit)
    upsertAppendedEventUnit(eventState.units, unit)
    normalizeEventStepState(eventState)
    if not unit then
        return nil
    end

    if eventState.active == true then
        copyLiveEventToDraft(self, eventState)
        local entries = removedEntries
        entries[#entries + 1] = {
            operation = "upsert",
            eventID = unit.eventID,
            unit = buildCompactSummonedUnitDelta(unit),
        }
        broadcastEventDeltaBatch(self, eventState, entries, previousTurnNumber ~= (tonumber(eventState.turnNumber) or 0)
            or previousTickNumber ~= (tonumber(eventState.tickNumber) or 0)
            or previousTotalTicks ~= (tonumber(eventState.totalTicks) or 0))
    end

    refreshEventManagePage()
    return unit
end

function Server:BuildEventNpcUnitDataFromDefinition(registryId, options)
    local dataset, unit = findActivatedUnitDefinition(registryId)
    if not dataset or not unit or not unit.id then
        return nil
    end

    local resolvedOptions = type(options) == "table" and options or {
        team = options,
    }
    local eventState = self.GetEditableEventState and self:GetEditableEventState() or nil
    return {
        name = unit.name or "Unnamed Unit",
        description = unit.description or "",
        registryID = ("%s:%s"):format(dataset.id, unit.id),
        team = clampEventTeamIndex(eventState, resolvedOptions.team),
        raidMarker = math.max(0, math.floor(tonumber(resolvedOptions.raidMarker) or 0)),
        active = coerceEventUnitBoolean(resolvedOptions.active, true),
        hidden = coerceEventUnitBoolean(resolvedOptions.hidden, false),
        boss = coerceEventUnitBoolean(resolvedOptions.boss, false),
        spells = deepCopy(unit.spells or {}),
    }
end

function Server:AddEventNpcUnitFromDefinition(registryId, options)
    local unitData = self:BuildEventNpcUnitDataFromDefinition(registryId, options)
    if not unitData then
        return nil
    end

    return self:AddEventNpcUnit(unitData)
end

function Server:SetEventUnitActive(eventId, isActive)
    local eventState = self:GetEditableEventState()
    if not eventState then
        return false
    end

    local unit = findEventUnitById(eventState.units, eventId)
    if not unit then
        return false
    end

    local nextActive = unit.isPlayer == true and true or isActive == true
    if unit.active == nextActive then
        return true
    end

    local previousTurnNumber = tonumber(eventState.turnNumber) or 0
    local previousTickNumber = tonumber(eventState.tickNumber) or 0
    local previousTotalTicks = tonumber(eventState.totalTicks) or 0
    unit.active = nextActive
    normalizeEventStepState(eventState)

    if eventState.active == true then
        copyLiveEventToDraft(self, eventState)
        broadcastEventDeltaBatch(self, eventState, {
            {
                operation = "upsert",
                eventID = unit.eventID,
                unit = unit,
            },
        }, previousTurnNumber ~= (tonumber(eventState.turnNumber) or 0)
            or previousTickNumber ~= (tonumber(eventState.tickNumber) or 0)
            or previousTotalTicks ~= (tonumber(eventState.totalTicks) or 0))
    end

    refreshEventManagePage()
    return true
end

function Server:SetEventUnitHidden(eventId, isHidden)
    local eventState = self:GetEditableEventState()
    if not eventState then
        return false
    end

    local unit = findEventUnitById(eventState.units, eventId)
    if not unit then
        return false
    end

    local nextHidden = isHidden == true
    if unit.hidden == nextHidden then
        return true
    end

    unit.hidden = nextHidden
    if eventState.active == true then
        copyLiveEventToDraft(self, eventState)
        broadcastEventDeltaBatch(self, eventState, {
            {
                operation = "upsert",
                eventID = unit.eventID,
                unit = unit,
            },
        }, false)
    end

    refreshEventManagePage()
    return true
end

function Server:SetEventUnitBoss(eventId, isBoss)
    local eventState = self:GetEditableEventState()
    if not eventState then
        return false
    end

    local unit = findEventUnitById(eventState.units, eventId)
    if not unit then
        return false
    end

    local nextBoss = isBoss == true
    if unit.boss == nextBoss then
        return true
    end

    unit.boss = nextBoss
    if eventState.active == true then
        copyLiveEventToDraft(self, eventState)
        broadcastEventDeltaBatch(self, eventState, {
            {
                operation = "upsert",
                eventID = unit.eventID,
                unit = unit,
            },
        }, false)
    end

    refreshEventManagePage()
    return true
end

function Server:SetEventUnitTeam(eventId, team)
    local eventState = self:GetEditableEventState()
    if not eventState then
        return false
    end

    local unit = findEventUnitById(eventState.units, eventId)
    if not unit then
        return false
    end

    local nextTeam = clampEventTeamIndex(eventState, team)
    if unit.team == nextTeam then
        return true
    end

    unit.team = nextTeam
    if eventState.active == true then
        copyLiveEventToDraft(self, eventState)
        broadcastEventDeltaBatch(self, eventState, {
            {
                operation = "upsert",
                eventID = unit.eventID,
                unit = unit,
            },
        }, false)
    end

    refreshEventManagePage()
    return true
end

function Server:SetEventUnitRaidMarker(eventId, raidMarker)
    local eventState = self:GetEditableEventState()
    if not eventState then
        return false
    end

    local unit = findEventUnitById(eventState.units, eventId)
    if not unit then
        return false
    end

    local nextRaidMarker = math.max(0, math.floor(tonumber(raidMarker) or 0))
    if unit.raidMarker == nextRaidMarker then
        return true
    end

    unit.raidMarker = nextRaidMarker
    if eventState.active == true then
        copyLiveEventToDraft(self, eventState)
        broadcastEventDeltaBatch(self, eventState, {
            {
                operation = "upsert",
                eventID = unit.eventID,
                unit = unit,
            },
        }, false)
    end

    refreshEventManagePage()
    return true
end

function Server:ClearEventNpcUnits()
    local eventState = self:GetEditableEventState()
    if not eventState then
        return 0
    end

    local keptUnits = {}
    local removedCount = 0
    local removedEntries = {}
    local previousTurnNumber = tonumber(eventState.turnNumber) or 0
    local previousTickNumber = tonumber(eventState.tickNumber) or 0
    local previousTotalTicks = tonumber(eventState.totalTicks) or 0

    for index = 1, #((eventState and eventState.units) or {}) do
        local unit = eventState.units[index]
        if unit and unit.isPlayer == true then
            keptUnits[#keptUnits + 1] = unit
        else
            removedCount = removedCount + 1
            removedEntries[#removedEntries + 1] = {
                operation = "remove",
                eventID = unit and unit.eventID or 0,
            }
        end
    end

    eventState.units = keptUnits
    normalizeEventStepState(eventState)
    if eventState.active == true and #removedEntries > 0 then
        copyLiveEventToDraft(self, eventState)
        broadcastEventDeltaBatch(self, eventState, removedEntries, previousTurnNumber ~= (tonumber(eventState.turnNumber) or 0)
            or previousTickNumber ~= (tonumber(eventState.tickNumber) or 0)
            or previousTotalTicks ~= (tonumber(eventState.totalTicks) or 0))
    end
    refreshEventManagePage()
    return removedCount
end

function Server:StartEvent(data)
    local totalTimer = startTiming("Server:StartEvent", {
        context = "event-start",
        thresholdMs = 50,
    })
    local sessionState = self:GetState()
    if not sessionState or sessionState.active ~= true or not sessionState.channelName then
        stopTiming(totalTimer)
        return nil
    end

    if self.HasClientHashMismatch and self:HasClientHashMismatch(sessionState) then
        if Addon.Debug and Addon.Debug.Warn then
            Addon.Debug.Warn("StartEvent blocked: one or more connected clients have dataset or ruleset hash mismatches.")
        end
        stopTiming(totalTimer)
        return nil
    end

    if self:IsEventActive() then
        self:EndEvent("replaced")
    end

    if self.ResetSpellcastingState then
        self:ResetSpellcastingState()
    end

    if sessionState.channelId == nil or sessionState.channelId == "" then
        sessionState.channelId = Comms:ResolveChannelId(sessionState.channelName)
    end

    local hostName = Common.NormalizeName(Common.GetPlayerName())
    local eventData = type(data) == "table" and data or {}
    local draftState = self:GetEventDraftState()
    local eventName = eventData.name or (draftState and draftState.name) or ""
    local eventSubtext = eventData.subtext or (draftState and draftState.subtext) or ""
    local eventDescription = eventData.description or (draftState and draftState.description) or ""
    local eventDifficulty = normalizeEventDifficulty(eventData.difficulty or (draftState and draftState.difficulty) or "normal")
    local eventTeams = cloneTeams(eventData.teams or (draftState and draftState.teams) or nil)
    local eventTeamColors = eventData.teamColors or (draftState and draftState.teamColors) or DEFAULT_TEAM_COLORS
    local eventAuras = cloneEventAuras(eventData.eventAuras or (draftState and draftState.eventAuras) or {})
    local eventLootRefs = cloneStringList(eventData.lootRefs or (draftState and draftState.lootRefs) or {})
    local sourceUnits = nil
    if type(eventData.units) == "table" and #eventData.units > 0 then
        sourceUnits = eventData.units
    elseif draftState then
        sourceUnits = draftState.units
    end
    local buildUnitsTimer = startTiming("buildEventUnits", {
        context = "event-start",
        thresholdMs = 15,
    })
    local eventUnits = buildEventUnits(sessionState, sourceUnits, hostName)
    stopTiming(buildUnitsTimer)

    local buildStateTimer = startTiming("buildEventState", {
        context = "event-start",
        thresholdMs = 10,
    })
    local eventState = buildEventState({
        id = eventData.id or buildEventId(),
        name = eventName,
        subtext = eventSubtext,
        description = eventDescription,
        hostName = hostName,
        channelName = sessionState.channelName,
        startedAt = tonumber(eventData.startedAt) or Common.GetNow(),
        endedAt = 0,
        active = true,
        units = eventUnits,
        difficulty = eventDifficulty,
        teams = eventTeams,
        eventAuras = eventAuras,
        lootRefs = eventLootRefs,
        teamColors = eventTeamColors,
        level = normalizeEventLevel(eventData.level or (draftState and draftState.level) or 1),
        turnNumber = tonumber(eventData.turnNumber) or 1,
        tickNumber = tonumber(eventData.tickNumber) or 1,
        unitsReady = false,
    })
    markEventUnitsPending(eventState)
    normalizeEventStepState(eventState)
    stopTiming(buildStateTimer)

    self.EventState = eventState
    local buildDraftTimer = startTiming("buildEventDraftState", {
        context = "event-start",
        thresholdMs = 10,
    })
    self.EventDraftState = buildEventState({
        id = nil,
        name = eventName,
        subtext = eventSubtext,
        description = eventDescription,
        hostName = hostName,
        channelName = sessionState.channelName,
        startedAt = 0,
        endedAt = 0,
        active = false,
        difficulty = eventState.difficulty,
        level = eventState.level,
        turnNumber = eventState.turnNumber,
        tickNumber = eventState.tickNumber,
        totalTicks = eventState.totalTicks,
        unitsReady = eventState.unitsReady == true,
        units = cloneUnits(eventState.units),
        teams = cloneTeams(eventState.teams),
        eventAuras = cloneEventAuras(eventState.eventAuras),
        lootRefs = cloneStringList(eventState.lootRefs),
        teamColors = eventTeamColors,
    })
    stopTiming(buildDraftTimer)

    local broadcasted = false
    if sessionState.channelId then
        local broadcastTimer = startTiming("broadcastEventStart", {
            context = "event-start",
            thresholdMs = 15,
        })
        broadcasted = Comms:SendToChannel(
            sessionState.channelId,
            EVENT_START_OPCODE,
            buildStartArguments(eventState),
            buildSendMetadata(EVENT_START_OPCODE)
        ) and true or false

        Comms:SendToChannel(
            sessionState.channelId,
            EVENT_UNITS_OPCODE,
            buildEventUnitsArguments(eventState),
            buildSendMetadata(EVENT_UNITS_OPCODE)
        )

        Comms:SendToChannel(
            sessionState.channelId,
            EVENT_STATE_OPCODE,
            buildEventStateArguments(eventState),
            buildSendMetadata(EVENT_STATE_OPCODE)
        )
        stopTiming(broadcastTimer)
    end

    eventState.broadcasted = broadcasted
    refreshEventManagePage()
    stopTiming(totalTimer)
    return eventState
end

function Server:EndEvent(reason)
    local eventState = self.EventState
    if not eventState then
        return false
    end

    eventState.active = false
    eventState.endedAt = Common.GetNow()

    local channelId = nil
    local sessionState = self:GetState()
    if sessionState and sessionState.channelName == eventState.channelName then
        channelId = sessionState.channelId
    end

    if channelId == nil or channelId == "" then
        channelId = Comms:ResolveChannelId(eventState.channelName)
    end

    if channelId then
        Comms:SendToChannel(
            channelId,
            EVENT_END_OPCODE,
            buildEndArguments(eventState, reason or "ended"),
            buildSendMetadata(EVENT_END_OPCODE)
        )
    end

    if self.ResetSpellcastingState then
        self:ResetSpellcastingState(eventState.id)
    end
    self.EventState = nil
    refreshEventManagePage()
    return true
end

function Server:AdvanceEventStep()
    local eventState = self.EventState
    if not eventState or eventState.active ~= true or eventState.unitsReady ~= true then
        return false
    end

    if Client and type(Client.IsLocalEventHost) == "function" and Client:IsLocalEventHost(eventState) and type(Client.FlushPendingTurnChanges) == "function" then
        Client:FlushPendingTurnChanges(Client.GetState and Client:GetState() or nil, eventState)
    end

    normalizeEventStepState(eventState)

    if eventState.tickNumber < eventState.totalTicks then
        eventState.tickNumber = eventState.tickNumber + 1
    else
        eventState.turnNumber = eventState.turnNumber + 1
        eventState.tickNumber = 1
    end

    normalizeEventStepState(eventState)

    if self.EventDraftState then
        self.EventDraftState.turnNumber = eventState.turnNumber
        self.EventDraftState.tickNumber = eventState.tickNumber
        self.EventDraftState.totalTicks = eventState.totalTicks
    end

    local stateArguments = buildEventStateArguments(eventState)

    local sessionState = self:GetState()
    local channelId = sessionState and sessionState.channelId or nil
    if (channelId == nil or channelId == "") and eventState.channelName and eventState.channelName ~= "" then
        channelId = Comms:ResolveChannelId(eventState.channelName)
    end

    if channelId then
        Comms:SendToChannel(
            channelId,
            EVENT_STATE_OPCODE,
            stateArguments,
            buildSendMetadata(EVENT_STATE_OPCODE)
        )
    end

    refreshEventManagePage()
    return true
end
