local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Utils = Addon.Utils or {}
Addon.Internal = Addon.Internal or {}

local Server = Addon.Server
local Client = Addon.Client
local Common = Addon.Utils.Common
local Comms = Addon.Internal.Comms
local Operations = Comms.Operations
local Registry = Addon.Internal.Registry or {}
local ResourceSync = Comms.ResourceSync or {}
local Debug = Addon.Debug or {}

local function getTasks()
    return Addon.Internal and Addon.Internal.Tasks or nil
end

local SERVER_START_OPCODE = Operations:GetOpcode("SERVER_START")
local SERVER_STOP_OPCODE = Operations:GetOpcode("SERVER_STOP")
local SERVER_QUERY_OPCODE = Operations:GetOpcode("SERVER_QUERY")
local RESOURCE_DELTA_OPCODE = Operations:GetOpcode("RESOURCE_DELTA")
local SKILL_ROLL_RESULT_OPCODE = Operations:GetOpcode("SKILL_ROLL_RESULT")
local MAX_START_ATTEMPTS = 5
local START_RETRY_DELAY = 1.5
local THREAT_UPDATE_RECORD_SEPARATOR = string.char(30)
local THREAT_UPDATE_FIELD_SEPARATOR = string.char(31)

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

local function normalizeThreatUpdates(text)
    local normalized = {}
    if type(text) ~= "string" or text == "" then
        return normalized
    end

    local records = Common.SplitPreservingEmpty and Common.SplitPreservingEmpty(text, THREAT_UPDATE_RECORD_SEPARATOR) or {}
    for index = 1, #records do
        local values = Common.SplitPreservingEmpty and Common.SplitPreservingEmpty(records[index], THREAT_UPDATE_FIELD_SEPARATOR) or {}
        local targetEventId = math.floor(tonumber(values[1]) or 0)
        local sourceEventId = math.floor(tonumber(values[2]) or 0)
        local amount = math.max(0, tonumber(values[3]) or 0)
        if targetEventId > 0 and sourceEventId > 0 and amount > 0 then
            normalized[#normalized + 1] = {
                targetEventId = targetEventId,
                sourceEventId = sourceEventId,
                amount = amount,
            }
        end
    end

    return normalized
end

local function applyThreatUpdatesToUnits(units, threatUpdates, changedByEventId)
    local changed = false
    for index = 1, #(threatUpdates or {}) do
        local update = threatUpdates[index]
        local unit = findEventUnitById(units, update and update.targetEventId)
        if unit and unit.isPlayer ~= true then
            unit.threatTable = type(unit.threatTable) == "table" and unit.threatTable or {}
            local sourceEventId = math.floor(tonumber(update.sourceEventId) or 0)
            local amount = math.max(0, tonumber(update.amount) or 0)
            if sourceEventId > 0 and amount > 0 then
                unit.threatTable[sourceEventId] = (tonumber(unit.threatTable[sourceEventId]) or 0) + amount
                changedByEventId[tonumber(unit.eventID) or 0] = unit
                changed = true
            end
        end
    end

    return changed
end

local function applyThreatUpdatesToServerState(server, threatUpdates)
    local normalizedThreatUpdates = type(threatUpdates) == "table" and threatUpdates or {}
    if #normalizedThreatUpdates == 0 then
        return false
    end

    local changedByEventId = {}
    local eventChanged = applyThreatUpdatesToUnits(server.EventState and server.EventState.units, normalizedThreatUpdates, changedByEventId)
    local draftChanged = applyThreatUpdatesToUnits(server.EventDraftState and server.EventDraftState.units, normalizedThreatUpdates, {})
    if not eventChanged and not draftChanged then
        return false
    end

    if eventChanged and type(server.BroadcastEventDeltaBatch) == "function" then
        local entries = {}
        for _, unit in pairs(changedByEventId) do
            entries[#entries + 1] = {
                operation = "upsert",
                eventID = tonumber(unit and unit.eventID) or 0,
                unit = unit,
            }
        end
        if #entries > 0 then
            server:BroadcastEventDeltaBatch(entries, false)
        end
    end
    refreshEventManagePage()
    return true
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
    local targetUnit = nil
    local targetUnitIsPlayer = false
    local targetOwnerName = ""
    if ResourceSync.ApplyResourceDeltasToEventUnitByEventID then
        draftUpdated = select(1, ResourceSync.ApplyResourceDeltasToEventUnitByEventID(
            server.EventDraftState and server.EventDraftState.units or nil,
            numericTargetEventId,
            normalizedResourceDeltas
        )) or false
        eventUpdated, targetUnit = ResourceSync.ApplyResourceDeltasToEventUnitByEventID(
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

    return true
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
        return ("Warning: Waiting for compatibility hashes from %s. Event start is locked."):format(table.concat(details, ", "))
    end

    return ("Warning: Client hash mismatch detected for %s. Event start is locked."):format(table.concat(details, ", "))
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

    local clientName = Common.NormalizeName(arguments and arguments[2] or sender)
    if clientName == "" then
        return false
    end

    addClient(state, clientName)
    local targetEventId = tonumber(arguments and arguments[4]) or 0

    local clientState = state.clientsByName and state.clientsByName[clientName] or nil
    if not clientState then
        return false
    end

    local resources = ResourceSync.NormalizeResources and ResourceSync.NormalizeResources(arguments and arguments[3] or "") or {}
    local hadCachedResources = type(clientState.resources) == "table" and #clientState.resources > 0
    local cachedChanged = not hadCachedResources
        or not (ResourceSync.ResourcesEqual and ResourceSync.ResourcesEqual(clientState.resources, resources))

    local draftUpdated = false
    local eventUpdated = false
    local targetUnitIsPlayer = false
    if targetEventId > 0 and ResourceSync.ApplyResourcesToEventUnitByEventID then
        draftUpdated = ResourceSync.ApplyResourcesToEventUnitByEventID(self.EventDraftState and self.EventDraftState.units or nil, targetEventId, resources) or false
        eventUpdated = ResourceSync.ApplyResourcesToEventUnitByEventID(self.EventState and self.EventState.units or nil, targetEventId, resources) or false

        local searchState = eventUpdated and self.EventState or (draftUpdated and self.EventDraftState or nil)
        for index = 1, #(((searchState and searchState.units) or {})) do
            local unit = searchState.units[index]
            if unit and tonumber(unit.eventID) == targetEventId then
                targetUnitIsPlayer = unit.isPlayer == true
                break
            end
        end
    else
        draftUpdated = ResourceSync.ApplyResourcesToEventUnits
            and ResourceSync.ApplyResourcesToEventUnits(self.EventDraftState and self.EventDraftState.units or nil, clientName, resources)
            or false
        eventUpdated = ResourceSync.ApplyResourcesToEventUnits
            and ResourceSync.ApplyResourcesToEventUnits(self.EventState and self.EventState.units or nil, clientName, resources)
            or false
        targetUnitIsPlayer = true
    end

    if cachedChanged and (targetEventId <= 0 or targetUnitIsPlayer == true) then
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

function Server:HandleResourceDelta(arguments, sender)
    local state = self.State
    if not state or state.active ~= true then
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if channelName ~= state.channelName then
        return false
    end

    local clientName = Common.NormalizeName(arguments and arguments[2] or sender)
    if clientName == "" then
        return false
    end

    addClient(state, clientName)
    local targetEventId = tonumber(arguments and arguments[4]) or 0

    local resourceDeltas = ResourceSync.NormalizeResourceDeltas and ResourceSync.NormalizeResourceDeltas(arguments and arguments[3] or "") or {}
    if type(resourceDeltas) ~= "table" or #resourceDeltas == 0 then
        return false
    end

    local handled = applyClientResourceDeltasToServerState(self, state, clientName, targetEventId, resourceDeltas)
    local threatUpdates = normalizeThreatUpdates(arguments and arguments[5] or "")
    if #threatUpdates > 0 then
        applyThreatUpdatesToServerState(self, threatUpdates)
    end
    return handled
end

function Server:HandleResourceDeltaBatch(arguments, sender)
    local state = self.State
    if not state or state.active ~= true then
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if channelName ~= state.channelName then
        return false
    end

    local clientName = Common.NormalizeName(arguments and arguments[2] or sender)
    if clientName == "" then
        return false
    end

    addClient(state, clientName)

    local targetedResourceDeltas = ResourceSync.CoalesceTargetedResourceDeltas
        and ResourceSync.CoalesceTargetedResourceDeltas(arguments and arguments[3] or "")
        or {}
    if type(targetedResourceDeltas) ~= "table" or #targetedResourceDeltas == 0 then
        return false
    end
    local deltaOrder = {}
    local deltasByTargetEventId = {}
    for index = 1, #targetedResourceDeltas do
        local entry = targetedResourceDeltas[index]
        local targetEventId = tonumber(entry and entry.targetEventId) or 0
        if targetEventId > 0 then
            if not deltasByTargetEventId[targetEventId] then
                deltasByTargetEventId[targetEventId] = {}
                deltaOrder[#deltaOrder + 1] = targetEventId
            end

            local deltas = deltasByTargetEventId[targetEventId]
            deltas[#deltas + 1] = {
                resourceRef = entry.resourceRef,
                delta = entry.delta,
                maxValue = entry.maxValue,
                currentValue = entry.currentValue,
            }
        end
    end

    if #deltaOrder == 0 then
        return false
    end

    local handled = false
    for index = 1, #deltaOrder do
        handled = applyClientResourceDeltasToServerState(
            self,
            state,
            clientName,
            deltaOrder[index],
            deltasByTargetEventId[deltaOrder[index]]
        ) or handled
    end

    local threatUpdates = normalizeThreatUpdates(arguments and arguments[4] or "")
    if #threatUpdates > 0 then
        applyThreatUpdatesToServerState(self, threatUpdates)
    end

    return handled
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
