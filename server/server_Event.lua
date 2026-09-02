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
    local metadata = {
        opcode = opcode,
        scope = "server",
    }
    local operation = Operations and Operations.Get and Operations:Get(opcode) or nil
    if type(operation) == "table" and tostring(operation.key or "") == "EVENT_STATE" then
        local eventState = Server.EventState
        local eventId = tostring(eventState and eventState.id or "")
        if eventId ~= "" then
            local turnNumber = math.max(0, math.floor(tonumber(eventState.turnNumber) or 0))
            local tickNumber = math.max(0, math.floor(tonumber(eventState.tickNumber) or 0))
            metadata.replaceKey = ("event-state:%s:%d:%d"):format(eventId, turnNumber, tickNumber)
        end
    end
    return metadata
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
    local activeRuleset = Ruleset and Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset("event", "max_event_units") or nil
    local ruleDefinition = Ruleset and Ruleset.GetRulesetRuleDefinition and Ruleset.GetRulesetRuleDefinition("event", "max_event_units") or nil
    local maxEventUnits = Ruleset and Ruleset.GetRulesetRuleValue and Ruleset.GetRulesetRuleValue(activeRuleset, "event", ruleDefinition) or nil
    maxEventUnits = math.floor(tonumber(maxEventUnits) or DEFAULT_MAX_EVENT_UNITS)
    if maxEventUnits <= 0 then
        return DEFAULT_MAX_EVENT_UNITS
    end

    return maxEventUnits
end

return Server
