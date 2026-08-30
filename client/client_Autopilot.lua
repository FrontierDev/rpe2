local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Server = Addon.Server
local Common = Addon.Utils.Common or {}
local Autopilot = Addon.Internal.Autopilot or {}
local Ruleset = Addon.Internal.Ruleset or {}
local Event = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil
local Spatial = Client.AutopilotSpatial or {}

if type(Event) ~= "table" or type(Spatial) ~= "table" then
    return
end

local DEFAULT_MAX_EVENT_UNITS = 5

Client.AutopilotRuntimeByEventId = Client.AutopilotRuntimeByEventId or {}

local captureStartCapability = false
local capturedStartCapabilityDetails = nil

local function pack(...)
    return { n = select("#", ...), ... }
end

local function normalizeTurnMode(value)
    if type(Event.NormalizeTurnMode) == "function" then
        return Event.NormalizeTurnMode(value)
    end
    if type(Autopilot.NormalizeTurnMode) == "function" then
        return Autopilot.NormalizeTurnMode(value)
    end
    return tostring(value or "") == "autopilot" and "autopilot" or "manual"
end

local function normalizeName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end
    return type(value) == "string" and value or ""
end

local function normalizeFiniteNumber(value)
    local numeric = tonumber(value)
    if numeric == nil or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return nil
    end
    return numeric
end

local function getEventId(eventState)
    return tostring(type(eventState) == "table" and eventState.id or "")
end

local function getMaxEventUnits()
    local activeRuleset = Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local definition = Ruleset.GetRulesetRuleDefinition
        and Ruleset.GetRulesetRuleDefinition("event", "max_event_units")
        or nil
    local value = Ruleset.GetRulesetRuleValue
        and Ruleset.GetRulesetRuleValue(activeRuleset, "event", definition)
        or nil
    local resolved = math.floor(tonumber(value) or DEFAULT_MAX_EVENT_UNITS)
    if resolved <= 0 then
        return DEFAULT_MAX_EVENT_UNITS
    end
    return resolved
end

local function isHostAutopilotEvent(eventState)
    return type(eventState) == "table"
        and eventState.active == true
        and normalizeTurnMode(eventState.turnMode) == "autopilot"
        and type(Client.IsLocalEventHost) == "function"
        and Client:IsLocalEventHost(eventState) == true
end

local function resolveApi(options)
    local api = type(options) == "table" and options.api or nil
    return type(api) == "table" and api or {}
end

local function getUnitNameForToken(token, api)
    local getUnitName = api.getUnitName
    if type(getUnitName) ~= "function" then
        getUnitName = GetUnitName
    end
    if type(getUnitName) == "function" then
        local name = getUnitName(token, true)
        local normalized = normalizeName(name)
        if normalized ~= "" then
            return normalized
        end
    end

    local unitName = api.unitName
    if type(unitName) ~= "function" then
        unitName = UnitName
    end
    if type(unitName) == "function" then
        local name = unitName(token)
        return normalizeName(name)
    end

    return ""
end

local function getGroupType(api)
    if type(api.getGroupType) == "function" then
        return api.getGroupType()
    end
    if type(Common.GetGroupType) == "function" then
        return Common.GetGroupType()
    end
    return nil
end

local function getGroupCount(api, groupType)
    if groupType == "RAID" then
        local getNumGroupMembers = api.getNumGroupMembers
        if type(getNumGroupMembers) ~= "function" then
            getNumGroupMembers = GetNumGroupMembers
        end
        return type(getNumGroupMembers) == "function" and math.max(0, math.floor(tonumber(getNumGroupMembers()) or 0)) or 0
    end

    if groupType == "PARTY" then
        local getNumSubgroupMembers = api.getNumSubgroupMembers
        if type(getNumSubgroupMembers) ~= "function" then
            getNumSubgroupMembers = GetNumSubgroupMembers
        end
        return type(getNumSubgroupMembers) == "function" and math.max(0, math.floor(tonumber(getNumSubgroupMembers()) or 0)) or 0
    end

    return 0
end

local function buildGroupTokenMap(api)
    local tokenByName = {}

    local function addToken(token)
        local name = getUnitNameForToken(token, api)
        if name ~= "" and tokenByName[name] == nil then
            tokenByName[name] = token
        end
    end

    addToken("player")

    local groupType = getGroupType(api)
    local memberCount = getGroupCount(api, groupType)
    if groupType == "RAID" then
        for index = 1, memberCount do
            addToken("raid" .. tostring(index))
        end
    elseif groupType == "PARTY" then
        for index = 1, memberCount do
            addToken("party" .. tostring(index))
        end
    end

    return tokenByName
end

local function getEventPlayerName(eventUnit)
    if type(eventUnit) ~= "table" then
        return ""
    end

    local name = normalizeName(eventUnit.name)
    if name ~= "" then
        return name
    end
    name = normalizeName(eventUnit.ownerID)
    if name ~= "" then
        return name
    end
    return normalizeName(eventUnit.controllerID)
end

local function newUnavailablePlayerPosition(eventUnit, unitToken, reason, turnNumber, tickNumber)
    return {
        eventID = tonumber(eventUnit and eventUnit.eventID) or 0,
        available = false,
        reason = tostring(reason or "position-unavailable"),
        unitToken = unitToken,
        sampledTurnNumber = math.max(0, math.floor(tonumber(turnNumber) or 0)),
        sampledTickNumber = math.max(0, math.floor(tonumber(tickNumber) or 0)),
    }
end

local function markRuntimeUnavailable(runtime, reason, details)
    if type(runtime) ~= "table" then
        return false
    end

    runtime.status = "unavailable"
    runtime.unavailableReason = tostring(reason or "position-unavailable")
    runtime.unavailableDetails = type(details) == "table" and details or nil
    return true
end

local function setRuntimeInstance(runtime, instanceID)
    if type(runtime) ~= "table" or instanceID == nil then
        return true
    end

    if runtime.instanceID == nil then
        runtime.instanceID = instanceID
        return true
    end

    if type(Spatial.AreInstancesEqual) == "function"
        and Spatial.AreInstancesEqual(runtime.instanceID, instanceID) ~= true
    then
        return false
    end

    return tostring(runtime.instanceID) == tostring(instanceID)
end

local function buildAvailablePlayerPosition(runtime, eventUnit, unitToken, x, y, instanceID, turnNumber, tickNumber)
    local numericX = normalizeFiniteNumber(x)
    local numericY = normalizeFiniteNumber(y)
    if numericX == nil or numericY == nil then
        return nil, "position-unavailable"
    end
    if instanceID == nil then
        return nil, "instance-unavailable"
    end
    if not setRuntimeInstance(runtime, instanceID) then
        return nil, "instance-mismatch"
    end

    return {
        eventID = tonumber(eventUnit and eventUnit.eventID) or 0,
        available = true,
        unitToken = unitToken,
        x = numericX,
        y = numericY,
        instanceID = instanceID,
        sampledTurnNumber = math.max(0, math.floor(tonumber(turnNumber) or 0)),
        sampledTickNumber = math.max(0, math.floor(tonumber(tickNumber) or 0)),
    }
end

local function resolveCurrentPlayerToken(runtime, eventUnit, api)
    if type(runtime) ~= "table" or type(eventUnit) ~= "table" then
        return nil
    end

    local eventId = tonumber(eventUnit.eventID) or 0
    local playerName = getEventPlayerName(eventUnit)
    if eventId <= 0 or playerName == "" then
        return nil
    end

    runtime.playerTokenByEventId = runtime.playerTokenByEventId or {}
    local cachedToken = runtime.playerTokenByEventId[eventId]
    if type(cachedToken) == "string" and cachedToken ~= "" then
        if getUnitNameForToken(cachedToken, api) == playerName then
            return cachedToken
        end
        runtime.playerTokenByEventId[eventId] = nil
    end

    local tokenByName = buildGroupTokenMap(api)
    local token = tokenByName[playerName]
    if token then
        runtime.playerTokenByEventId[eventId] = token
    end
    return token
end

local function samplePlayerByToken(runtime, eventState, eventUnit, unitToken, turnNumber, tickNumber, options)
    if type(runtime) ~= "table" or type(eventUnit) ~= "table" then
        return false, "runtime-unavailable"
    end

    local eventId = tonumber(eventUnit.eventID) or 0
    if eventId <= 0 then
        return false, "player-unavailable"
    end

    runtime.playerPositionByEventId = runtime.playerPositionByEventId or {}
    if type(unitToken) ~= "string" or unitToken == "" then
        runtime.playerPositionByEventId[eventId] = newUnavailablePlayerPosition(
            eventUnit,
            nil,
            "unit-token-unresolved",
            turnNumber,
            tickNumber
        )
        return false, "unit-token-unresolved"
    end

    local api = resolveApi(options)
    local isInInstance = api.isInInstance
    if type(isInInstance) ~= "function" then
        isInInstance = IsInInstance
    end
    if type(isInInstance) == "function" then
        local inInstance, instanceType = isInInstance()
        if inInstance == true then
            local details = { instanceType = tostring(instanceType or "") }
            markRuntimeUnavailable(runtime, "instance", details)
            runtime.playerPositionByEventId[eventId] = newUnavailablePlayerPosition(
                eventUnit,
                unitToken,
                "instance",
                turnNumber,
                tickNumber
            )
            return false, "instance"
        end
    end

    local unitPosition = api.unitPosition
    if type(unitPosition) ~= "function" then
        unitPosition = UnitPosition
    end
    if type(unitPosition) ~= "function" then
        markRuntimeUnavailable(runtime, "position-api-unavailable")
        runtime.playerPositionByEventId[eventId] = newUnavailablePlayerPosition(
            eventUnit,
            unitToken,
            "position-api-unavailable",
            turnNumber,
            tickNumber
        )
        return false, "position-api-unavailable"
    end

    local x, y, _, instanceID = unitPosition(unitToken)
    local position, reason = buildAvailablePlayerPosition(
        runtime,
        eventUnit,
        unitToken,
        x,
        y,
        instanceID,
        turnNumber,
        tickNumber
    )
    if not position then
        runtime.playerPositionByEventId[eventId] = newUnavailablePlayerPosition(
            eventUnit,
            unitToken,
            reason,
            turnNumber,
            tickNumber
        )
        if reason == "instance-mismatch" then
            markRuntimeUnavailable(runtime, reason, {
                expectedInstanceID = runtime.instanceID,
                receivedInstanceID = instanceID,
            })
        elseif unitToken == "player" then
            markRuntimeUnavailable(runtime, reason)
        end
        return false, reason
    end

    runtime.playerPositionByEventId[eventId] = position
    runtime.playerTokenByEventId = runtime.playerTokenByEventId or {}
    runtime.playerTokenByEventId[eventId] = unitToken
    return true, position
end

local function applyProvidedHostSample(runtime, eventState, eventUnit, unitToken, details, turnNumber, tickNumber)
    if type(details) ~= "table" or unitToken ~= "player" then
        return false
    end

    local eventId = tonumber(eventUnit and eventUnit.eventID) or 0
    if eventId <= 0 then
        return false
    end

    local position, reason = buildAvailablePlayerPosition(
        runtime,
        eventUnit,
        unitToken,
        details.x,
        details.y,
        details.instanceID,
        turnNumber,
        tickNumber
    )
    runtime.playerPositionByEventId = runtime.playerPositionByEventId or {}
    if not position then
        runtime.playerPositionByEventId[eventId] = newUnavailablePlayerPosition(
            eventUnit,
            unitToken,
            reason,
            turnNumber,
            tickNumber
        )
        markRuntimeUnavailable(runtime, reason)
        return false
    end

    runtime.playerPositionByEventId[eventId] = position
    runtime.playerTokenByEventId[eventId] = unitToken
    return true
end

local function seedPlayerPositions(runtime, eventState, options)
    local api = resolveApi(options)
    local tokenByName = buildGroupTokenMap(api)
    local turnNumber = tonumber(eventState and eventState.turnNumber) or 0
    local tickNumber = tonumber(eventState and eventState.tickNumber) or 0
    local hostName = normalizeName(eventState and eventState.hostName or "")
    local initialHostSample = type(options) == "table" and options.initialHostSample or nil

    for index = 1, #((eventState and eventState.units) or {}) do
        local unit = eventState.units[index]
        if type(unit) == "table" and unit.isPlayer == true then
            local eventId = tonumber(unit.eventID) or 0
            local playerName = getEventPlayerName(unit)
            local unitToken = tokenByName[playerName]
            if eventId > 0 and unitToken then
                runtime.playerTokenByEventId[eventId] = unitToken
            end

            local usedProvidedSample = playerName ~= ""
                and playerName == hostName
                and unitToken == "player"
                and applyProvidedHostSample(
                    runtime,
                    eventState,
                    unit,
                    unitToken,
                    initialHostSample,
                    turnNumber,
                    tickNumber
                )

            if not usedProvidedSample then
                samplePlayerByToken(
                    runtime,
                    eventState,
                    unit,
                    unitToken,
                    turnNumber,
                    tickNumber,
                    options
                )
            end
        end
    end
end

local function collectPlayersForTurnStep(eventState, tickNumber)
    local players = {}
    if type(Event.GetUnitsForTurnStep) ~= "function" then
        return players
    end

    local stepUnits = Event.GetUnitsForTurnStep(eventState, tickNumber, getMaxEventUnits())
    for index = 1, #(stepUnits or {}) do
        local unit = stepUnits[index]
        if type(unit) == "table" and unit.isPlayer == true then
            players[#players + 1] = unit
        end
    end
    return players
end

local function refreshPlayerUnits(runtime, eventState, players, turnNumber, tickNumber, options)
    local attempted = 0
    local updated = 0
    local api = resolveApi(options)

    for index = 1, #(players or {}) do
        local unit = players[index]
        local eventId = tonumber(unit and unit.eventID) or 0
        if eventId > 0 then
            attempted = attempted + 1
            local unitToken = resolveCurrentPlayerToken(runtime, unit, api)
            local ok = samplePlayerByToken(
                runtime,
                eventState,
                unit,
                unitToken,
                turnNumber,
                tickNumber,
                options
            )
            if ok then
                updated = updated + 1
            end
        end
    end

    return updated, attempted
end

function Client:BuildAutopilotGroupTokenMap(options)
    return buildGroupTokenMap(resolveApi(options))
end

function Client:GetAutopilotSpatialRuntime(eventState)
    if not isHostAutopilotEvent(eventState) then
        return nil, "not-host-autopilot"
    end

    local eventId = getEventId(eventState)
    local runtime = eventId ~= "" and self.AutopilotRuntimeByEventId[eventId] or nil
    if type(runtime) ~= "table" then
        return nil, "runtime-unavailable"
    end

    if type(Spatial.ReconcileVirtualPositions) == "function" then
        Spatial.ReconcileVirtualPositions(runtime, eventState)
    end
    return runtime
end

function Client:InitializeAutopilotSpatialRuntime(eventState, options)
    if not isHostAutopilotEvent(eventState) then
        return nil, "not-host-autopilot"
    end

    local eventId = getEventId(eventState)
    if eventId == "" then
        return nil, "event-unavailable"
    end

    local existing = self.AutopilotRuntimeByEventId[eventId]
    if type(existing) == "table" and existing.seeded == true then
        if type(Spatial.ReconcileVirtualPositions) == "function" then
            Spatial.ReconcileVirtualPositions(existing, eventState)
        end
        return existing
    end

    local runtime = {
        eventId = eventId,
        status = "ready",
        unavailableReason = nil,
        unavailableDetails = nil,
        instanceID = nil,
        playerPositionByEventId = {},
        playerTokenByEventId = {},
        positionByActorKey = {},
        seeded = false,
    }
    self.AutopilotRuntimeByEventId[eventId] = runtime

    if type(Spatial.ReconcileVirtualPositions) == "function" then
        Spatial.ReconcileVirtualPositions(runtime, eventState)
    end
    seedPlayerPositions(runtime, eventState, options)
    runtime.seeded = true
    return runtime
end

function Client:ClearAutopilotSpatialRuntime(eventId)
    local normalizedEventId = tostring(eventId or "")
    if normalizedEventId == "" then
        return false
    end

    local existed = self.AutopilotRuntimeByEventId[normalizedEventId] ~= nil
    self.AutopilotRuntimeByEventId[normalizedEventId] = nil
    return existed
end

function Client:ReconcileAutopilotSpatialRuntime(eventState)
    local runtime = self:GetAutopilotSpatialRuntime(eventState)
    if type(runtime) ~= "table" or type(Spatial.ReconcileVirtualPositions) ~= "function" then
        return false
    end

    Spatial.ReconcileVirtualPositions(runtime, eventState)
    return true
end

function Client:GetAutopilotSpatialAvailability(eventState)
    local runtime, reason = self:GetAutopilotSpatialRuntime(eventState)
    if type(runtime) ~= "table" then
        return false, reason
    end
    if runtime.status ~= "ready" then
        return false, tostring(runtime.unavailableReason or "position-unavailable"), runtime.unavailableDetails
    end
    return true
end

function Client:GetAutopilotPlayerPosition(eventState, playerEventId)
    local runtime, reason = self:GetAutopilotSpatialRuntime(eventState)
    if type(runtime) ~= "table" then
        return nil, reason
    end
    if runtime.status ~= "ready" then
        return nil, tostring(runtime.unavailableReason or "position-unavailable")
    end

    local eventId = tonumber(playerEventId) or 0
    local position = eventId > 0 and runtime.playerPositionByEventId[eventId] or nil
    if type(position) ~= "table" or position.available ~= true then
        return nil, type(position) == "table" and tostring(position.reason or "position-unavailable") or "position-unavailable"
    end
    return position
end

function Client:GetAutopilotNpcPosition(eventState, eventUnit)
    local runtime, reason = self:GetAutopilotSpatialRuntime(eventState)
    if type(runtime) ~= "table" then
        return nil, reason
    end
    if runtime.status ~= "ready" then
        return nil, tostring(runtime.unavailableReason or "position-unavailable")
    end
    if type(Spatial.GetNpcPosition) ~= "function" then
        return nil, "spatial-api-unavailable"
    end
    return Spatial.GetNpcPosition(runtime, eventState, eventUnit)
end

function Client:SetAutopilotNpcPosition(eventState, eventUnit, position)
    local runtime, reason = self:GetAutopilotSpatialRuntime(eventState)
    if type(runtime) ~= "table" then
        return false, reason
    end
    if runtime.status ~= "ready" then
        return false, tostring(runtime.unavailableReason or "position-unavailable")
    end
    if type(Spatial.SetNpcPosition) ~= "function" then
        return false, "spatial-api-unavailable"
    end
    return Spatial.SetNpcPosition(runtime, eventState, eventUnit, position)
end

function Client:RefreshAutopilotPlayerPositionsForCompletedStep(eventState, turnNumber, tickNumber, options)
    local runtime, reason = self:GetAutopilotSpatialRuntime(eventState)
    if type(runtime) ~= "table" then
        return 0, 0, reason
    end
    if runtime.status ~= "ready" then
        return 0, 0, tostring(runtime.unavailableReason or "position-unavailable")
    end

    local players = collectPlayersForTurnStep(eventState, tickNumber)
    local updated, attempted = refreshPlayerUnits(
        runtime,
        eventState,
        players,
        turnNumber,
        tickNumber,
        options
    )
    return updated, attempted
end

local baseGetNpcAutopilotCapability = Server.GetNpcAutopilotCapability
if type(baseGetNpcAutopilotCapability) == "function" then
    function Server:GetNpcAutopilotCapability(...)
        local results = pack(baseGetNpcAutopilotCapability(self, ...))
        if captureStartCapability == true then
            if results[1] == true and type(results[3]) == "table" then
                capturedStartCapabilityDetails = {
                    x = results[3].x,
                    y = results[3].y,
                    z = results[3].z,
                    instanceID = results[3].instanceID,
                }
            else
                capturedStartCapabilityDetails = nil
            end
        end
        return unpack(results, 1, results.n)
    end
end

local baseStartEvent = Server.StartEvent
if type(baseStartEvent) == "function" then
    function Server:StartEvent(...)
        captureStartCapability = true
        capturedStartCapabilityDetails = nil
        local results = pack(pcall(baseStartEvent, self, ...))
        captureStartCapability = false
        local initialHostSample = capturedStartCapabilityDetails
        capturedStartCapabilityDetails = nil

        if results[1] ~= true then
            error(results[2], 0)
        end

        local eventState = results[2]
        if isHostAutopilotEvent(eventState) then
            Client:InitializeAutopilotSpatialRuntime(eventState, {
                initialHostSample = initialHostSample,
            })
        end

        return unpack(results, 2, results.n)
    end
end

local baseEndEvent = Server.EndEvent
if type(baseEndEvent) == "function" then
    function Server:EndEvent(...)
        local eventId = getEventId(self.EventState)
        local results = pack(pcall(baseEndEvent, self, ...))
        if eventId ~= "" then
            Client:ClearAutopilotSpatialRuntime(eventId)
        end

        if results[1] ~= true then
            error(results[2], 0)
        end
        return unpack(results, 2, results.n)
    end
end

local baseAdvanceEventStepAfterCommit = Server._AdvanceEventStepAfterCommit
if type(baseAdvanceEventStepAfterCommit) == "function" then
    function Server:_AdvanceEventStepAfterCommit(commit, completed, ...)
        local eventState = self.EventState
        local sourceTurnNumber = tonumber(commit and commit.sourceTurnNumber) or tonumber(eventState and eventState.turnNumber) or 0
        local sourceTickNumber = tonumber(commit and commit.sourceTickNumber) or tonumber(eventState and eventState.tickNumber) or 0
        local sourceEventId = tostring(commit and commit.eventId or getEventId(eventState))
        local completedPlayers = {}

        if completed == true
            and isHostAutopilotEvent(eventState)
            and sourceEventId ~= ""
            and sourceEventId == getEventId(eventState)
        then
            completedPlayers = collectPlayersForTurnStep(eventState, sourceTickNumber)
        end

        local results = pack(pcall(baseAdvanceEventStepAfterCommit, self, commit, completed, ...))
        if results[1] ~= true then
            error(results[2], 0)
        end

        if results[2] == true and #completedPlayers > 0 then
            local runtime = Client.AutopilotRuntimeByEventId[sourceEventId]
            if type(runtime) == "table" and runtime.status == "ready" then
                refreshPlayerUnits(
                    runtime,
                    eventState,
                    completedPlayers,
                    sourceTurnNumber,
                    sourceTickNumber,
                    nil
                )
            end
        end

        return unpack(results, 2, results.n)
    end
end

local baseSetEventUnitRaidMarker = Server.SetEventUnitRaidMarker
if type(baseSetEventUnitRaidMarker) == "function" then
    function Server:SetEventUnitRaidMarker(...)
        local results = pack(baseSetEventUnitRaidMarker(self, ...))
        if results[1] == true and isHostAutopilotEvent(self.EventState) then
            Client:ReconcileAutopilotSpatialRuntime(self.EventState)
        end
        return unpack(results, 1, results.n)
    end
end

return Client
