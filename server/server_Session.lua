local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Utils = Addon.Utils or {}
Addon.Internal = Addon.Internal or {}

local Server = Addon.Server
local Client = Addon.Client
local Common = Addon.Utils.Common
local Comms = Addon.Internal.Comms
local Operations = Comms.Operations
local EventTransactions = Comms.EventTransactions
local Registry = Addon.Internal.Registry or {}
local ResourceSync = Comms.ResourceSync or {}
local Debug = Addon.Debug or {}

local function getTasks()
    return Addon.Internal and Addon.Internal.Tasks or nil
end

local SERVER_START_OPCODE = Operations:GetOpcode("SERVER_START")
local SERVER_STOP_OPCODE = Operations:GetOpcode("SERVER_STOP")
local SERVER_QUERY_OPCODE = Operations:GetOpcode("SERVER_QUERY")
local SKILL_ROLL_RESULT_OPCODE = Operations:GetOpcode("SKILL_ROLL_RESULT")
local MAX_START_ATTEMPTS = 5
local START_RETRY_DELAY = 1.5

local function buildChannelName()
    local now = tonumber(Common.GetNow()) or 0
    local randomA = math.random(0, 0xffff)
    local randomB = math.random(0, 0xffff)
    return ("rpe%04x%04x%04x"):format(now % 0x10000, randomA, randomB)
end

local function buildSendMetadata(opcode)
    return {
        opcode = opcode,
        scope = "server",
    }
end

local function buildServerRoute(distribution)
    if distribution == "PARTY" or distribution == "RAID" then
        return distribution, nil
    end

    return "WHISPER", Common.GetPlayerName()
end

local function defer(fn, ...)
    local tasks = getTasks()
    if tasks and tasks.Enqueue then
        tasks:Enqueue(fn, ...)
        return
    end

    if C_Timer and C_Timer.After then
        local args = { ... }
        local argCount = select("#", ...)
        C_Timer.After(START_RETRY_DELAY, function()
            fn(unpack(args, 1, argCount))
        end)
        return
    end

    fn(...)
end

local function refreshEventManagePage()
    local eventManage = Addon.Server and Addon.Server.UI and Addon.Server.UI.EventManage or nil
    if type(eventManage) == "table" and type(eventManage.RefreshActivePage) == "function" then
        eventManage:RefreshActivePage()
    end
end

local function findEventUnitById(units, eventId)
    local numericEventId = tonumber(eventId) or 0
    if type(units) ~= "table" or numericEventId <= 0 then
        return nil
    end

    for index = 1, #units do
        local unit = units[index]
        if unit and tonumber(unit.eventID) == numericEventId then
            return unit
        end
    end

    return nil
end

local function applyThreatUpdatesToUnits(units, threatUpdates, changedByEventId, validSourceUnits)
    local changed = false
    local sourceUnits = validSourceUnits or {}
    for index = 1, #(threatUpdates or {}) do
        local update = threatUpdates[index]
        local unit = findEventUnitById(units, update and update.targetEventId)
        local sourceEventId = math.floor(tonumber(update and update.sourceEventId) or 0)
        local amount = math.max(0, tonumber(update and update.amount) or 0)
        local sourceUnit = findEventUnitById(sourceUnits, sourceEventId)
        if unit and unit.isPlayer ~= true and sourceUnit and sourceEventId > 0 and amount > 0 then
            unit.threatTable = type(unit.threatTable) == "table" and unit.threatTable or {}
            unit.threatTable[sourceEventId] = (tonumber(unit.threatTable[sourceEventId]) or 0) + amount
            changedByEventId[tonumber(unit.eventID) or 0] = unit
            changed = true
        end
    end

    return changed
end

local function applyThreatUpdatesToServerState(server, threatUpdates, changedByEventId)
    local normalizedThreatUpdates = type(threatUpdates) == "table" and threatUpdates or {}
    if #normalizedThreatUpdates == 0 then
        return false, changedByEventId or {}
    end

    changedByEventId = changedByEventId or {}
    local activeUnits = server.EventState and server.EventState.units or nil
    local eventChanged = applyThreatUpdatesToUnits(activeUnits, normalizedThreatUpdates, changedByEventId, activeUnits)
    local draftChanged = applyThreatUpdatesToUnits(
        server.EventDraftState and server.EventDraftState.units,
        normalizedThreatUpdates,
        {},
        activeUnits
    )
    if not eventChanged and not draftChanged then
        return false, changedByEventId
    end
    refreshEventManagePage()
    return true, changedByEventId
end

local function addClient(state, clientName, connectedAt)
    state.clientsByName = state.clientsByName or {}
    state.clientOrder = state.clientOrder or {}

    if state.clientsByName[clientName] then
        return false
    end

    state.clientOrder[#state.clientOrder + 1] = clientName
    state.clientsByName[clientName] = {
        name = clientName,
        connectedAt = connectedAt or Common.GetNow(),
        hashesReceived = false,
    }
    return true
end

local function normalizeHashValue(value)
    if value == nil then
        return nil
    end

    local text = tostring(value)
    if text == "" then
        return nil
    end

    return text
end

local function removeClient(state, clientName)
    state.clientsByName = state.clientsByName or {}
    state.clientOrder = state.clientOrder or {}

    if not state.clientsByName[clientName] then
        return false
    end

    state.clientsByName[clientName] = nil
    for index = #state.clientOrder, 1, -1 do
        if state.clientOrder[index] == clientName then
            table.remove(state.clientOrder, index)
            break
        end
    end

    return true
end

local function applyClientResourceDeltasToServerState(server, state, clientName, targetEventId, resourceDeltas)
    local numericTargetEventId = tonumber(targetEventId) or 0
    if not state or state.active ~= true or clientName == "" or numericTargetEventId <= 0 then
        return false
    end

    local clientState = state.clientsByName and state.clientsByName[clientName] or nil
    if not clientState then
        return false
    end

    local normalizedResourceDeltas = ResourceSync.CoalesceResourceDeltas and ResourceSync.CoalesceResourceDeltas(resourceDeltas) or {}
    if type(normalizedResourceDeltas) ~= "table" or #normalizedResourceDeltas == 0 then
        return false
    end

    local draftUpdated = false
    local eventUpdated = false
    local appliedDeltas = normalizedResourceDeltas
    local targetUnit = nil
    local targetUnitIsPlayer = false
    local targetOwnerName = ""
    if ResourceSync.ApplyResourceDeltasToEventUnitByEventID then
        draftUpdated = select(1, ResourceSync.ApplyResourceDeltasToEventUnitByEventID(
            server.EventDraftState and server.EventDraftState.units or nil,
            numericTargetEventId,
            normalizedResourceDeltas
        )) or false
        eventUpdated, targetUnit, appliedDeltas = ResourceSync.ApplyResourceDeltasToEventUnitByEventID(
            server.EventState and server.EventState.units or nil,
            numericTargetEventId,
            normalizedResourceDeltas
        )
        if not targetUnit then
            targetUnit = findEventUnitById(server.EventDraftState and server.EventDraftState.units, numericTargetEventId)
        end
        targetUnitIsPlayer = targetUnit and targetUnit.isPlayer == true or false
        targetOwnerName = Common.NormalizeName(targetUnit and (targetUnit.ownerID or targetUnit.controllerID or targetUnit.name) or nil)
    end

    local cacheClientName = (targetUnitIsPlayer == true and targetOwnerName ~= "") and targetOwnerName or clientName
    local trackedClientState = state.clientsByName and state.clientsByName[cacheClientName] or nil
    if not trackedClientState and cacheClientName ~= "" then
        addClient(state, cacheClientName)
        trackedClientState = state.clientsByName and state.clientsByName[cacheClientName] or nil
    end

    if trackedClientState and cacheClientName ~= "" then
        local previousResources = trackedClientState.resources
        if targetUnit and type(targetUnit.resources) == "table" then
            trackedClientState.resources = ResourceSync.CloneResources and ResourceSync.CloneResources(targetUnit.resources) or targetUnit.resources
        elseif type(previousResources) == "table" and ResourceSync.ApplyResourceDeltasToResources then
            ResourceSync.ApplyResourceDeltasToResources(previousResources, normalizedResourceDeltas)
        end
    end

    -- Accept a valid client command even when it only affects the draft/cache;
    -- only a live EventUnit change is eligible for the authoritative broadcast.
    return true, eventUpdated, targetUnit, appliedDeltas
end

local function getUnitHealthValue(unit, eventState)
    if type(unit) ~= "table" then
        return nil
    end
    local healthRef = eventState and eventState.healthResourceRef or "health"
    for index = 1, #(unit.resources or {}) do
        local resource = unit.resources[index]
        if resource and resource.resourceRef == healthRef then
            return tonumber(resource.currentValue) or 0
        end
    end
    return nil
end

local function isBossEventUnit(unit)
    if type(unit) ~= "table" then
        return false
    end
    local eventUnitClass = Addon.Internal
        and Addon.Internal.Database
        and Addon.Internal.Database.Classes
        and Addon.Internal.Database.Classes.EventUnit
        or nil
    if eventUnitClass and type(eventUnitClass.IsBoss) == "function" then
        return eventUnitClass.IsBoss(unit) == true
    end
    return unit.boss == true
end

local function getUnitOwnerName(unit)
    return Common.NormalizeName(unit and (unit.ownerID or unit.controllerID or unit.name) or nil)
end

local function getEventHostName(eventState)
    return Common.NormalizeName(eventState and eventState.hostName)
end

local function validateResourceTarget(eventState, envelope, targetEventId)
    local numericTargetEventId = tonumber(targetEventId) or 0
    if type(eventState) ~= "table" or eventState.active ~= true or numericTargetEventId <= 0 then
        return nil, "invalid-target"
    end

    local targetUnit = findEventUnitById(eventState.units, numericTargetEventId)
    if type(targetUnit) ~= "table" then
        return nil, "unknown-target"
    end

    local originName = Common.NormalizeName(envelope and envelope.originName)
    local hostName = getEventHostName(eventState)
    local actorEventId = tonumber(envelope and envelope.actorEventId) or 0
    local actorUnit = actorEventId > 0 and findEventUnitById(eventState.units, actorEventId) or nil
    if actorEventId > 0 and not actorUnit then
        return nil, "unknown-actor"
    end

    if originName ~= hostName then
        local ownedUnit = actorUnit or (targetUnit.isPlayer == true and targetUnit or nil)
        if type(ownedUnit) ~= "table" or getUnitOwnerName(ownedUnit) ~= originName then
            return nil, "origin-does-not-own-actor"
        end
    end

    return targetUnit
end

local function normalizeResourceDeltas(resourceDeltas)
    if type(ResourceSync.CoalesceResourceDeltas) ~= "function" then
        return type(resourceDeltas) == "table" and resourceDeltas or {}
    end
    return ResourceSync.CoalesceResourceDeltas(resourceDeltas)
end

local function normalizeTargetedResourceDeltas(targetedResourceDeltas)
    if type(ResourceSync.CoalesceTargetedResourceDeltas) ~= "function" then
        return type(targetedResourceDeltas) == "table" and targetedResourceDeltas or {}
    end
    return ResourceSync.CoalesceTargetedResourceDeltas(targetedResourceDeltas)
end

local function updateTrackedClientResources(state, clientName, targetUnit)
    if type(state) ~= "table" or type(targetUnit) ~= "table" then
        return
    end
    local targetOwnerName = getUnitOwnerName(targetUnit)
    local cacheName = targetUnit.isPlayer == true and targetOwnerName or Common.NormalizeName(clientName)
    if cacheName == "" then
        return
    end
    local tracked = state.clientsByName and state.clientsByName[cacheName]
    if not tracked then
        addClient(state, cacheName)
        tracked = state.clientsByName and state.clientsByName[cacheName]
    end
    if tracked and type(targetUnit.resources) == "table" then
        tracked.resources = ResourceSync.CloneResources
            and ResourceSync.CloneResources(targetUnit.resources)
            or targetUnit.resources
    end
end

local function applyResourceReplaceToServerState(server, state, clientName, targetEventId, resources)
    local targetUnit = findEventUnitById(server.EventState and server.EventState.units, targetEventId)
    local draftUnit = findEventUnitById(server.EventDraftState and server.EventDraftState.units, targetEventId)
    local eventUpdated = false
    local draftUpdated = false
    if type(ResourceSync.ApplyResourcesToEventUnitByEventID) == "function" then
        draftUpdated = ResourceSync.ApplyResourcesToEventUnitByEventID(
            server.EventDraftState and server.EventDraftState.units,
            targetEventId,
            resources
        ) or false
        eventUpdated = ResourceSync.ApplyResourcesToEventUnitByEventID(
            server.EventState and server.EventState.units,
            targetEventId,
            resources
        ) or false
    end
    targetUnit = findEventUnitById(server.EventState and server.EventState.units, targetEventId) or targetUnit or draftUnit
    if targetUnit then
        updateTrackedClientResources(state, clientName, targetUnit)
    end
    return draftUpdated or eventUpdated, eventUpdated, targetUnit
end

local function applyResourceDeltasForTransaction(server, state, clientName, targetEventId, resourceDeltas)
    local eventState = server.EventState
    local targetUnit = findEventUnitById(eventState and eventState.units, targetEventId)
    local healthBefore = getUnitHealthValue(targetUnit, eventState)
    local changedByEventId = {}
    local applied, eventUpdated, updatedUnit, appliedDeltas = applyClientResourceDeltasToServerState(
        server,
        state,
        clientName,
        targetEventId,
        resourceDeltas
    )
    if not applied then
        return false, nil, changedByEventId
    end
    updatedUnit = updatedUnit or findEventUnitById(eventState and eventState.units, targetEventId)
    if eventUpdated and updatedUnit then
        changedByEventId[tonumber(updatedUnit.eventID) or 0] = updatedUnit
    end

    local healthAfter = getUnitHealthValue(updatedUnit, eventState)
    local result = {
        targetEventId = tonumber(targetEventId) or 0,
        resourceDeltas = appliedDeltas or resourceDeltas,
        actualDamage = healthBefore ~= nil and healthAfter ~= nil and math.max(0, healthBefore - healthAfter) or 0,
        actualHealing = healthBefore ~= nil and healthAfter ~= nil and math.max(0, healthAfter - healthBefore) or 0,
    }
    if healthBefore ~= nil and healthAfter ~= nil and healthBefore > 0 and healthAfter <= 0 then
        result.kill = {
            targetEventId = result.targetEventId,
            isBoss = isBossEventUnit(updatedUnit),
        }
    end
    return true, result, changedByEventId
end

local function buildAuthoritativeEntries(changedByEventId)
    local entries = {}
    for eventId, unit in pairs(changedByEventId or {}) do
        if type(unit) == "table" and tonumber(eventId) and tonumber(eventId) > 0 then
            entries[#entries + 1] = {
                operation = "upsert",
                eventID = tonumber(eventId),
                unit = unit,
            }
        end
    end
    table.sort(entries, function(left, right)
        return (tonumber(left.eventID) or 0) < (tonumber(right.eventID) or 0)
    end)
    return entries
end

local function commitResourceTransaction(server, changedByEventId)
    local entries = buildAuthoritativeEntries(changedByEventId)
    if #entries == 0 then
        return true, nil
    end
    if type(server.BroadcastEventDeltaBatch) ~= "function" then
        return false, "missing-authoritative-broadcaster"
    end
    if server:BroadcastEventDeltaBatch(entries, false) ~= true then
        return false, "authoritative-broadcast-failed"
    end
    return true, entries
end

Server.State = Server.State or nil

function Server:GetState()
    return self.State
end

function Server:IsActive()
    return self.State ~= nil and self.State.active == true
end

function Server:GetExpectedClientHashes()
    local expected = {
        datasetHash = normalizeHashValue(Registry.GenerateActivatedDatasetsHash and Registry:GenerateActivatedDatasetsHash() or nil),
        rulesetHash = normalizeHashValue(Registry.GenerateActiveRulesetHash and Registry:GenerateActiveRulesetHash() or nil),
    }
    if type(Debug.Internal) == "function" then
        Debug.Internal(
            "Compatibility refresh client=%s revision=%d datasetHash=%s rulesetHash=%s stage=server-expected-hashes reason=host-state.",
            tostring(Common.GetPlayerName and Common.GetPlayerName() or "unknown"),
            math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0)),
            tostring(expected.datasetHash or ""),
            tostring(expected.rulesetHash or "")
        )
    end
    return expected
end

function Server:GetClientHashMismatches(state)
    local activeState = state or self.State
    local mismatches = {}
    if not activeState or activeState.active ~= true then
        return mismatches
    end

    local expected = self:GetExpectedClientHashes()
    local clientOrder = activeState.clientOrder or {}
    local clientsByName = activeState.clientsByName or {}

    for index = 1, #clientOrder do
        local clientName = clientOrder[index]
        local clientState = clientsByName[clientName]
        if clientState and clientState.hashesReceived == true then
            local datasetHash = normalizeHashValue(clientState.datasetHash)
            local rulesetHash = normalizeHashValue(clientState.rulesetHash)
            local datasetMismatch = datasetHash ~= expected.datasetHash
            local rulesetMismatch = rulesetHash ~= expected.rulesetHash

            if datasetMismatch or rulesetMismatch then
                if type(Debug.Internal) == "function" then
                    Debug.Internal(
                        "Compatibility refresh client=%s revision=%d datasetHash=%s rulesetHash=%s stage=server-mismatch-evaluation reason=stored-vs-expected expectedDatasetHash=%s expectedRulesetHash=%s.",
                        tostring(clientName),
                        math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0)),
                        tostring(datasetHash or ""),
                        tostring(rulesetHash or ""),
                        tostring(expected.datasetHash or ""),
                        tostring(expected.rulesetHash or "")
                    )
                end
                mismatches[#mismatches + 1] = {
                    name = clientName,
                    datasetMismatch = datasetMismatch,
                    rulesetMismatch = rulesetMismatch,
                    datasetHash = datasetHash,
                    rulesetHash = rulesetHash,
                    expectedDatasetHash = expected.datasetHash,
                    expectedRulesetHash = expected.rulesetHash,
                }
            end
        elseif clientState then
            if type(Debug.Internal) == "function" then
                Debug.Internal(
                    "Compatibility refresh client=%s revision=%d datasetHash=%s rulesetHash=%s stage=server-mismatch-evaluation reason=hashes-pending expectedDatasetHash=%s expectedRulesetHash=%s.",
                    tostring(clientName),
                    math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0)),
                    tostring(clientState.datasetHash or ""),
                    tostring(clientState.rulesetHash or ""),
                    tostring(expected.datasetHash or ""),
                    tostring(expected.rulesetHash or "")
                )
            end
            mismatches[#mismatches + 1] = {
                name = clientName,
                hashesPending = true,
                datasetMismatch = false,
                rulesetMismatch = false,
                datasetHash = normalizeHashValue(clientState.datasetHash),
                rulesetHash = normalizeHashValue(clientState.rulesetHash),
                expectedDatasetHash = expected.datasetHash,
                expectedRulesetHash = expected.rulesetHash,
            }
        end
    end

    return mismatches
end

function Server:ClientHashesMatch(clientName, state)
    local activeState = state or self.State
    local normalizedClientName = Common.NormalizeName(clientName)
    if not activeState or activeState.active ~= true or normalizedClientName == "" then
        return false
    end

    local clientState = activeState.clientsByName and activeState.clientsByName[normalizedClientName] or nil
    if not clientState or clientState.hashesReceived ~= true then
        return false
    end

    local expected = self:GetExpectedClientHashes()
    return normalizeHashValue(clientState.datasetHash) == expected.datasetHash
        and normalizeHashValue(clientState.rulesetHash) == expected.rulesetHash
end

function Server:HasClientHashMismatch(state)
    return #(self:GetClientHashMismatches(state)) > 0
end

function Server:BuildClientHashMismatchWarning(state)
    local mismatches = self:GetClientHashMismatches(state)
    if #mismatches == 0 then
        return nil
    end

    local details = {}
    local pendingCount = 0
    for index = 1, #mismatches do
        local mismatch = mismatches[index]
        local labels = {}
        if mismatch.hashesPending then
            pendingCount = pendingCount + 1
            labels[#labels + 1] = "pending"
        elseif mismatch.datasetMismatch then
            labels[#labels + 1] = "dataset"
            if mismatch.rulesetMismatch then
                labels[#labels + 1] = "ruleset"
            end
        elseif mismatch.rulesetMismatch then
            labels[#labels + 1] = "ruleset"
        end

        details[#details + 1] = ("%s (%s)"):format(
            tostring(mismatch.name or "unknown"),
            table.concat(labels, " and ")
        )
    end

    if pendingCount > 0 then
        return ("Warning: Waiting for compatibility hashes from %s. Hold Shift while clicking Start Event on the Event Manager dashboard to override."):format(table.concat(details, ", "))
    end

    return ("Warning: Client hash mismatch detected for %s. Hold Shift while clicking Start Event on the Event Manager dashboard to override."):format(table.concat(details, ", "))
end

function Server:SendServerStartToClient(state, clientName)
    if not state or self.State ~= state then
        return false
    end

    local normalizedClientName = Common.NormalizeName(clientName)
    if normalizedClientName == "" then
        return false
    end

    return Comms:SendMessage("WHISPER", SERVER_START_OPCODE, {
        state.channelName,
    }, normalizedClientName, buildSendMetadata(SERVER_START_OPCODE))
end

function Server:HandleServerQuery(arguments, sender)
    local state = self.State
    if not state or state.active ~= true then
        return false
    end

    local clientName = Common.NormalizeName(sender)
    if clientName == "" then
        return false
    end

    return self:SendServerStartToClient(state, clientName)
end

function Server:HandleSkillRollBroadcast(arguments, sender, distribution, target, message)
    local state = self.State
    local sourceName = Common.NormalizeName(arguments and arguments[1] or nil)
    local senderName = Common.NormalizeName(sender)
    if type(state) ~= "table" or state.active ~= true
        or distribution ~= "CHANNEL"
        or tonumber(target) ~= tonumber(state.channelId)
        or senderName == "" or sourceName == "" or senderName ~= sourceName
        or not state.clientsByName or state.clientsByName[senderName] == nil
        or not SKILL_ROLL_RESULT_OPCODE
    then
        return false
    end

    return Comms:SendToChannel(state.channelId, SKILL_ROLL_RESULT_OPCODE, arguments, buildSendMetadata(SKILL_ROLL_RESULT_OPCODE))
end

function Server:HandleClientConnect(arguments, sender)
    local state = self.State
    if not state then
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if channelName ~= state.channelName then
        return false
    end

    local clientName = Common.NormalizeName(sender)
    if clientName == "" then
        return false
    end

    Debug.Internal("Server received CLIENT_CONNECT from %s.", tostring(clientName))
    addClient(state, clientName)
    local clientState = state.clientsByName and state.clientsByName[clientName] or nil
    if clientState then
        clientState.datasetHash = normalizeHashValue(arguments and arguments[3] or nil)
        clientState.rulesetHash = normalizeHashValue(arguments and arguments[4] or nil)
        clientState.hashesReceived = clientState.datasetHash ~= nil or clientState.rulesetHash ~= nil
    end

    local expected = self:GetExpectedClientHashes()
    if type(Debug.Internal) == "function" then
        Debug.Internal(
            "Compatibility refresh client=%s revision=%d datasetHash=%s rulesetHash=%s stage=server-replace reason=client-connect expectedDatasetHash=%s expectedRulesetHash=%s.",
            tostring(clientName),
            math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0)),
            tostring(clientState and clientState.datasetHash or ""),
            tostring(clientState and clientState.rulesetHash or ""),
            tostring(expected.datasetHash or ""),
            tostring(expected.rulesetHash or "")
        )
    end

    if self.ReconcileClientEventSession then
        self:ReconcileClientEventSession(clientName)
    end

    refreshEventManagePage()

    return true
end

function Server:HandleClientDisconnect(arguments, sender)
    local state = self.State
    if not state then
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if channelName ~= state.channelName then
        return false
    end

    local clientName = Common.NormalizeName(sender)
    if clientName == "" then
        return false
    end

    Debug.Internal("Server received CLIENT_DISCONNECT from %s.", tostring(clientName))
    local removed = removeClient(state, clientName)
    if removed then
        refreshEventManagePage()
    end
    return removed
end

function Server:HandleResource(arguments, sender)
    local state = self.State
    if not state or state.active ~= true then
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if channelName ~= state.channelName then
        return false
    end

    local clientName = Common.NormalizeName(sender)
    if clientName == "" or clientName ~= Common.NormalizeName(arguments and arguments[2]) then
        return false
    end

    addClient(state, clientName)
    local targetEventId = tonumber(arguments and arguments[4]) or 0

    -- Live EventUnits are transaction-owned. RESOURCE remains only for the
    -- session/profile bootstrap path; a targeted live replace is submitted as
    -- event-resource-replace by the client adapter.
    if targetEventId > 0 then
        return false
    end
    if self.EventState and math.max(0, math.floor(tonumber(self.EventState.liveUnitRevision) or 0)) > 0 then
        return false
    end

    local clientState = state.clientsByName and state.clientsByName[clientName] or nil
    if not clientState then
        return false
    end

    local resources = ResourceSync.NormalizeResources and ResourceSync.NormalizeResources(arguments and arguments[3] or "") or {}
    local hadCachedResources = type(clientState.resources) == "table" and #clientState.resources > 0
    local cachedChanged = not hadCachedResources
        or not (ResourceSync.ResourcesEqual and ResourceSync.ResourcesEqual(clientState.resources, resources))

    local draftUpdated = ResourceSync.ApplyResourcesToEventUnits
        and ResourceSync.ApplyResourcesToEventUnits(self.EventDraftState and self.EventDraftState.units or nil, clientName, resources)
        or false
    local eventUpdated = ResourceSync.ApplyResourcesToEventUnits
        and ResourceSync.ApplyResourcesToEventUnits(self.EventState and self.EventState.units or nil, clientName, resources)
        or false

    if cachedChanged then
        if targetEventId > 0 and ResourceSync.MergeResourcesByRef then
            clientState.resources = ResourceSync.MergeResourcesByRef(clientState.resources, resources)
        else
            clientState.resources = ResourceSync.CloneResources and ResourceSync.CloneResources(resources) or resources
        end
    end

    if not cachedChanged and not draftUpdated and not eventUpdated then
        return true
    end

    return true
end

function Server:IsHostClientReady(state)
    if not state or not Client or not Client.GetState then
        return false
    end

    local clientState = Client:GetState()
    if not clientState or clientState.channelName ~= state.channelName then
        return false
    end

    local hostName = Common.GetPlayerName()
    return clientState.channelId ~= nil
        and clientState.membersByName ~= nil
        and clientState.membersByName[hostName] ~= nil
end

function Server:BroadcastServerStart(state)
    if not state or self.State ~= state or state.broadcasted then
        return false
    end

    local distribution, target = buildServerRoute(state.distribution)
    state.broadcasted = Comms:SendMessage(distribution, SERVER_START_OPCODE, {
        state.channelName,
    }, target, buildSendMetadata(SERVER_START_OPCODE)) and true or false

    return state.broadcasted
end

function Server:FinalizeStartServer(state, attempt)
    if not state or self.State ~= state then
        return false
    end

    if not state.channelId then
        state.channelId = Comms:ResolveChannelId(state.channelName)
    end

    if state.channelId then
        return self:BroadcastServerStart(state)
    end

    if self:IsHostClientReady(state) then
        return self:BroadcastServerStart(state)
    end

    local currentAttempt = tonumber(attempt) or 1
    if currentAttempt >= MAX_START_ATTEMPTS then
        return self:BroadcastServerStart(state)
    end

    defer(function(targetState, nextAttempt)
        Server:FinalizeStartServer(targetState, nextAttempt)
    end, state, currentAttempt + 1)

    return false
end

function Server:StartServer()
    if not Addon.Client
        or type(Addon.Client.RequireSetupCompletion) ~= "function"
        or Addon.Client:RequireSetupCompletion("server-start") ~= true
    then
        return nil
    end

    if self:IsActive() then
        self:StopServer("replaced")
    end

    self.EventDraftState = nil

    local state = {
        active = true,
        distribution = Common.GetGroupType(),
        channelName = buildChannelName(),
        channelId = nil,
        startedAt = Common.GetNow(),
        clientsByName = {},
        clientOrder = {},
        broadcasted = false,
    }

    state.channelId = Comms:JoinChannel(state.channelName)
    self.State = state

    local hostName = Common.NormalizeName(Common.GetPlayerName())
    addClient(state, hostName, state.startedAt)
    local hostClientState = state.clientsByName and state.clientsByName[hostName] or nil
    local expectedHostHashes = self:GetExpectedClientHashes()
    if hostClientState then
        hostClientState.datasetHash = expectedHostHashes.datasetHash
        hostClientState.rulesetHash = expectedHostHashes.rulesetHash
        hostClientState.hashesReceived = true
    end
    if Client and Client.HandleServerStart then
        Client:HandleServerStart({
            state.channelName,
        }, Common.GetPlayerName())
    end

    self:FinalizeStartServer(state, 1)
    refreshEventManagePage()
    return state
end

function Server:StopServer(reason)
    local state = self.State
    if not state then
        return false
    end

    if self:IsEventActive() then
        self:EndEvent(reason or "server-stopped")
    end

    local distribution, target = buildServerRoute(Common.GetGroupType() or state.distribution)
    Comms:SendMessage(distribution, SERVER_STOP_OPCODE, {
        state.channelName,
    }, target, buildSendMetadata(SERVER_STOP_OPCODE))

    Comms:LeaveChannel(state.channelName)
    self.State = nil
    self.EventDraftState = nil
    refreshEventManagePage()
    return true
end

local function handleEventResourceTransaction(envelope, context, operation)
    local state = Server.State
    local eventState = context and context.eventState or Server.EventState
    local input = type(envelope and envelope.input) == "table" and envelope.input or {}
    local originName = Common.NormalizeName(envelope and envelope.originName)
    if type(state) ~= "table" or state.active ~= true
        or type(eventState) ~= "table" or eventState.active ~= true
        or tostring(envelope and envelope.eventId or "") ~= tostring(eventState.id or "")
        or originName == ""
    then
        return { state = "rejected", outcome = { reason = "inactive-event" } }
    end

    local changedByEventId = {}
    local resourceResults = {}
    local targetEventIds = {}
    local targetSeen = {}
    local targetDeltas = {}
    local targetOrder = {}

    if operation == "event-resource-replace" then
        local targetEventId = tonumber(input.targetEventId or envelope.targetEventIds and envelope.targetEventIds[1]) or 0
        local targetUnit, targetReason = validateResourceTarget(eventState, envelope, targetEventId)
        local resources = ResourceSync.NormalizeResources and ResourceSync.NormalizeResources(input.resources) or input.resources
        if not targetUnit then
            return { state = "rejected", outcome = { reason = targetReason or "invalid-target" } }
        end
        if type(resources) ~= "table" or #resources == 0 then
            return { state = "rejected", outcome = { reason = "empty-resources" } }
        end
        if type(Server.BroadcastEventDeltaBatch) ~= "function" then
            return { state = "rejected", outcome = { reason = "missing-authoritative-broadcaster" } }
        end

        local healthBefore = getUnitHealthValue(targetUnit, eventState)
        local accepted, eventUpdated, updatedUnit = applyResourceReplaceToServerState(
            Server,
            state,
            originName,
            targetEventId,
            resources
        )
        if not accepted then
            return { state = "rejected", outcome = { reason = "resource-replace-failed" } }
        end
        updatedUnit = updatedUnit or targetUnit
        if eventUpdated and updatedUnit then
            changedByEventId[targetEventId] = updatedUnit
        end
        local healthAfter = getUnitHealthValue(updatedUnit, eventState)
        local result = {
            targetEventId = targetEventId,
            replacement = true,
            actualDamage = healthBefore ~= nil and healthAfter ~= nil and math.max(0, healthBefore - healthAfter) or 0,
            actualHealing = healthBefore ~= nil and healthAfter ~= nil and math.max(0, healthAfter - healthBefore) or 0,
        }
        if healthBefore ~= nil and healthAfter ~= nil and healthBefore <= 0 and healthAfter > 0 then
            result.resurrect = true
        end
        resourceResults[1] = result
        targetEventIds[1] = targetEventId
    else
        if operation == "event-resource-delta" then
            local targetEventId = tonumber(input.targetEventId) or 0
            targetDeltas[targetEventId] = normalizeResourceDeltas(input.resourceDeltas)
            targetOrder[1] = targetEventId
            targetEventIds[1] = targetEventId
        else
            local normalized = normalizeTargetedResourceDeltas(input.targetedResourceDeltas)
            for index = 1, #normalized do
                local entry = normalized[index]
                local targetEventId = tonumber(entry and entry.targetEventId) or 0
                if targetEventId > 0 then
                    targetDeltas[targetEventId] = targetDeltas[targetEventId] or {}
                    targetDeltas[targetEventId][#targetDeltas[targetEventId] + 1] = {
                        resourceRef = entry.resourceRef,
                        delta = entry.delta,
                        maxValue = entry.maxValue,
                        currentValue = entry.currentValue,
                    }
                    if not targetSeen[targetEventId] then
                        targetSeen[targetEventId] = true
                        targetEventIds[#targetEventIds + 1] = targetEventId
                        targetOrder[#targetOrder + 1] = targetEventId
                    end
                end
            end
        end

        if #targetOrder == 0 then
            return { state = "rejected", outcome = { reason = "empty-resource-deltas" } }
        end
        for index = 1, #targetOrder do
            local targetEventId = targetOrder[index]
            local targetUnit, targetReason = validateResourceTarget(eventState, envelope, targetEventId)
            if not targetUnit then
                return { state = "rejected", outcome = { reason = targetReason or "invalid-target" } }
            end
            local deltas = normalizeResourceDeltas(targetDeltas[targetEventId])
            if #deltas == 0 then
                return { state = "rejected", outcome = { reason = "empty-resource-deltas" } }
            end
            local applied, result, changed = applyResourceDeltasForTransaction(
                Server,
                state,
                originName,
                targetEventId,
                deltas
            )
            if not applied then
                return { state = "rejected", outcome = { reason = "resource-delta-failed" } }
            end
            for eventId, unit in pairs(changed) do
                changedByEventId[eventId] = unit
            end
            resourceResults[#resourceResults + 1] = result
        end
    end

    local threatUpdates = type(input.threatUpdates) == "table" and input.threatUpdates or {}
    local threatChanged
    threatChanged, changedByEventId = applyThreatUpdatesToServerState(Server, threatUpdates, changedByEventId)
    local committed, entriesOrReason = commitResourceTransaction(Server, changedByEventId)
    if not committed then
        return { state = "rejected", outcome = { reason = entriesOrReason or "resource-commit-failed" } }
    end

    local currentRevision = math.max(0, math.floor(tonumber(eventState.liveUnitRevision) or 0))
    return {
        state = "committed",
        outcome = {
            operation = operation,
            actionOwnerName = originName,
            reason = tostring(input.reason or operation),
            targetEventIds = targetEventIds,
            resourceResults = resourceResults,
            threatChanged = threatChanged == true,
        },
        authoritativeDelta = entriesOrReason,
        newRevision = currentRevision,
    }
end

if EventTransactions and type(EventTransactions.Server) == "table"
    and type(EventTransactions.Server.Register) == "function"
then
    EventTransactions.Server:Register("event-resource-delta", function(envelope, context)
        return handleEventResourceTransaction(envelope, context, "event-resource-delta")
    end)
    EventTransactions.Server:Register("event-resource-batch", function(envelope, context)
        return handleEventResourceTransaction(envelope, context, "event-resource-batch")
    end)
    EventTransactions.Server:Register("event-resource-replace", function(envelope, context)
        return handleEventResourceTransaction(envelope, context, "event-resource-replace")
    end)
end
