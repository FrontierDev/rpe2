local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Utils = Addon.Utils or {}

local Server = Addon.Server
local Client = Addon.Client
local Common = Addon.Utils.Common or {}
local LootLogic = Addon.Internal.Loot or {}
local Comms = Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}
local Protocol = Comms.LootProtocol or {}

local Loot = Server.Loot or {}
Server.Loot = Loot

local MAX_IDENTIFIER_LENGTH = 192
local MAX_EXECUTIONS_PER_SESSION = 128
local MAX_RETAINED_SESSIONS = 5

Loot.ExecutionsByKey = type(Loot.ExecutionsByKey) == "table" and Loot.ExecutionsByKey or {}
Loot.ExecutionKeysBySession = type(Loot.ExecutionKeysBySession) == "table" and Loot.ExecutionKeysBySession or {}
Loot.SessionOrder = type(Loot.SessionOrder) == "table" and Loot.SessionOrder or {}
Loot.DeliveryIndex = type(Loot.DeliveryIndex) == "table" and Loot.DeliveryIndex or {}
Loot.NextGrantSequence = math.max(0, math.floor(tonumber(Loot.NextGrantSequence) or 0))
Loot.NextDeliverySequence = math.max(0, math.floor(tonumber(Loot.NextDeliverySequence) or 0))
Loot.MaxExecutionsPerSession = MAX_EXECUTIONS_PER_SESSION
Loot.MaxRetainedSessions = MAX_RETAINED_SESSIONS

local function deepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local copy = {}
    seen[value] = copy
    for key, nested in pairs(value) do
        copy[key] = deepCopy(nested, seen)
    end
    return copy
end

local function deepEqual(left, right)
    if left == right then
        return true
    end
    if type(left) ~= type(right) or type(left) ~= "table" then
        return false
    end
    for key, value in pairs(left) do
        if not deepEqual(value, right[key]) then
            return false
        end
    end
    for key in pairs(right) do
        if left[key] == nil then
            return false
        end
    end
    return true
end

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeName(value)
    local normalized = trim(value)
    if normalized == "" then
        return ""
    end
    if type(Common.NormalizeName) == "function" then
        normalized = trim(Common.NormalizeName(normalized))
    end
    return normalized
end

local function getNow()
    return type(Common.GetNow) == "function"
        and math.max(0, math.floor(tonumber(Common.GetNow()) or 0))
        or 0
end

local function positiveInteger(value)
    local numeric = tonumber(value)
    if numeric == nil
        or numeric ~= numeric
        or numeric == math.huge
        or numeric == -math.huge
        or numeric < 1
        or numeric ~= math.floor(numeric)
    then
        return nil
    end
    return math.floor(numeric)
end

local function nonNegativeInteger(value)
    local numeric = tonumber(value)
    if numeric == nil
        or numeric ~= numeric
        or numeric == math.huge
        or numeric == -math.huge
        or numeric < 0
        or numeric ~= math.floor(numeric)
    then
        return nil
    end
    return math.floor(numeric)
end

local function validIdentifier(value, maximumLength)
    local normalized = trim(value)
    if normalized == "" or #normalized > (maximumLength or MAX_IDENTIFIER_LENGTH) then
        return nil
    end
    if normalized:find("[%z\1-\31\127]") then
        return nil
    end
    return normalized
end

local function executionKey(eventSessionId, grantId)
    return tostring(eventSessionId or "") .. "\0" .. tostring(grantId or "")
end

local function collectOrderedNumericValues(values)
    local ordered = {}
    if type(values) ~= "table" then
        return ordered
    end
    for key, value in pairs(values) do
        if type(key) == "number" then
            ordered[#ordered + 1] = { index = key, value = value }
        end
    end
    table.sort(ordered, function(left, right)
        return left.index < right.index
    end)
    return ordered
end

local function resolvePlayerUnitName(unit)
    if type(unit) ~= "table" or unit.isPlayer ~= true then
        return ""
    end
    local candidates = { unit.ownerID, unit.controllerID, unit.name }
    for index = 1, #candidates do
        local normalized = normalizeName(candidates[index])
        if normalized ~= "" then
            return normalized
        end
    end
    return ""
end

local function copyConcreteReward(reward)
    return {
        type = tostring(reward and reward.type or ""),
        ref = tostring(reward and reward.ref or ""),
        amount = math.floor(tonumber(reward and reward.amount) or 0),
    }
end

local function touchSession(eventSessionId)
    local sessionId = tostring(eventSessionId or "")
    if sessionId == "" then
        return
    end
    for index = #Loot.SessionOrder, 1, -1 do
        if Loot.SessionOrder[index] == sessionId then
            table.remove(Loot.SessionOrder, index)
            break
        end
    end
    Loot.SessionOrder[#Loot.SessionOrder + 1] = sessionId
end

local function removeExecutionByKey(key)
    local execution = Loot.ExecutionsByKey[key]
    if type(execution) ~= "table" then
        return false
    end
    for deliveryId in pairs(execution.deliveries or {}) do
        Loot.DeliveryIndex[deliveryId] = nil
    end
    Loot.ExecutionsByKey[key] = nil

    local sessionId = tostring(execution.eventSessionId or "")
    local keys = Loot.ExecutionKeysBySession[sessionId]
    if type(keys) == "table" then
        for index = #keys, 1, -1 do
            if keys[index] == key then
                table.remove(keys, index)
                break
            end
        end
        if #keys == 0 then
            Loot.ExecutionKeysBySession[sessionId] = nil
        end
    end
    return true
end

local function removeSession(eventSessionId)
    local sessionId = tostring(eventSessionId or "")
    local keys = Loot.ExecutionKeysBySession[sessionId]
    if type(keys) == "table" then
        local copy = {}
        for index = 1, #keys do
            copy[index] = keys[index]
        end
        for index = 1, #copy do
            removeExecutionByKey(copy[index])
        end
    end
    Loot.ExecutionKeysBySession[sessionId] = nil
    for index = #Loot.SessionOrder, 1, -1 do
        if Loot.SessionOrder[index] == sessionId then
            table.remove(Loot.SessionOrder, index)
        end
    end
end

local function resolveEventAuthority(eventSessionId)
    if type(Client.ResolveLootEventAuthority) ~= "function" then
        return nil, "event-authority-unavailable"
    end
    local ok, authority, reason = pcall(Client.ResolveLootEventAuthority, Client, eventSessionId)
    if not ok or type(authority) ~= "table" then
        return nil, reason or "unknown-event-session"
    end
    local hostName = normalizeName(authority.hostName)
    if hostName == "" then
        return nil, "unknown-event-session"
    end
    return {
        eventSessionId = tostring(authority.eventSessionId or eventSessionId or ""),
        hostName = hostName,
        active = authority.active == true,
    }
end

local function localPlayerName()
    return normalizeName(type(Common.GetPlayerName) == "function" and Common.GetPlayerName() or "")
end

local function isServerActive()
    if type(Server.IsActive) == "function" then
        return Server:IsActive() == true
    end
    local state = type(Server.GetState) == "function" and Server:GetState() or Server.State
    return type(state) == "table" and state.active == true
end

local function validateRetainedExecutionAuthority(execution)
    if not isServerActive() then
        return nil, "server-inactive"
    end
    if type(execution) ~= "table" then
        return nil, "unknown-delivery"
    end
    local authority, reason = resolveEventAuthority(execution.eventSessionId)
    if not authority then
        return nil, reason or "unknown-event-session"
    end
    local localName = localPlayerName()
    if localName == "" or authority.hostName ~= localName or normalizeName(execution.hostName) ~= localName then
        return nil, "not-host"
    end
    return authority
end

function Loot:PruneExecutions()
    local removed = 0
    for index = #self.SessionOrder, 1, -1 do
        local sessionId = self.SessionOrder[index]
        local authority = resolveEventAuthority(sessionId)
        if not authority then
            local keys = self.ExecutionKeysBySession[sessionId]
            removed = removed + (type(keys) == "table" and #keys or 0)
            removeSession(sessionId)
        end
    end

    while #self.SessionOrder > MAX_RETAINED_SESSIONS do
        local oldestSession = self.SessionOrder[1]
        local keys = self.ExecutionKeysBySession[oldestSession]
        removed = removed + (type(keys) == "table" and #keys or 0)
        removeSession(oldestSession)
    end
    return removed
end

function Loot:GetEligiblePlayers(eventStateOverride)
    local eventState = eventStateOverride or (type(Server.GetEventState) == "function" and Server:GetEventState() or Server.EventState)
    if type(eventState) ~= "table" then
        return nil, "event-inactive"
    end

    local players = {}
    local seen = {}
    for index = 1, #(eventState.units or {}) do
        local identity = resolvePlayerUnitName(eventState.units[index])
        if identity ~= "" and not seen[identity] then
            seen[identity] = true
            players[#players + 1] = identity
        end
    end
    if #players == 0 then
        return nil, "empty-eligibility", {}
    end
    return players
end

function Loot:ValidateEligiblePlayers(eventState, requestedPlayers)
    local allPlayers, reason, detail = self:GetEligiblePlayers(eventState)
    if not allPlayers then
        return nil, reason, detail
    end
    if requestedPlayers == nil then
        return allPlayers
    end

    local allowed = {}
    for index = 1, #allPlayers do
        allowed[allPlayers[index]] = true
    end

    local normalized = {}
    local seen = {}
    local orderedRequested = collectOrderedNumericValues(requestedPlayers)
    for position = 1, #orderedRequested do
        local entry = orderedRequested[position]
        local playerName = normalizeName(entry.value)
        if playerName ~= "" and not seen[playerName] then
            if not allowed[playerName] then
                return nil, "ineligible-player", {
                    player = playerName,
                    playerIndex = entry.index,
                }
            end
            seen[playerName] = true
            normalized[#normalized + 1] = playerName
        end
    end
    if #normalized == 0 then
        return nil, "empty-eligibility", {}
    end
    return normalized
end

local function normalizeGrantContract(grant)
    if type(grant) ~= "table" then
        return nil, nil, "unsupported-source", { reason = "grant-not-table" }
    end

    local sourceType = string.lower(trim(grant.sourceType))
    local distribution = string.lower(trim(grant.distribution))
    if distribution ~= "group" and distribution ~= "personal" then
        return nil, nil, "unsupported-distribution", { distribution = grant.distribution }
    end

    if sourceType == "direct" then
        if type(grant.reward) ~= "table" then
            return nil, nil, "invalid-reward", { reason = "reward-not-table" }
        end
        local source = {
            type = "direct",
            reward = deepCopy(grant.reward),
        }
        local snapshot = {
            sourceType = "direct",
            reward = deepCopy(grant.reward),
            distribution = distribution,
        }
        return source, snapshot
    end

    if sourceType == "loot_table" then
        local lootRef = trim(grant.lootRef)
        if lootRef == "" then
            return nil, nil, "invalid-loot-table", { field = "lootRef" }
        end
        local source = {
            type = "table",
            lootRef = lootRef,
        }
        local snapshot = {
            sourceType = "loot_table",
            lootRef = lootRef,
            distribution = distribution,
        }
        return source, snapshot
    end

    return nil, nil, "unsupported-source", { sourceType = grant.sourceType }
end

local function buildRequestFingerprint(eventSessionId, hostName, sourceName, grantSnapshot, eligiblePlayers)
    local parts = {
        tostring(eventSessionId or ""),
        tostring(hostName or ""),
        tostring(sourceName or ""),
        tostring(grantSnapshot and grantSnapshot.sourceType or ""),
        tostring(grantSnapshot and grantSnapshot.distribution or ""),
        tostring(grantSnapshot and grantSnapshot.lootRef or ""),
    }
    local reward = grantSnapshot and grantSnapshot.reward or nil
    if type(reward) == "table" then
        parts[#parts + 1] = tostring(reward.type or "")
        parts[#parts + 1] = tostring(reward.ref or "")
        parts[#parts + 1] = tostring(reward.amount or "")
    end
    for index = 1, #(eligiblePlayers or {}) do
        parts[#parts + 1] = tostring(eligiblePlayers[index])
    end
    return table.concat(parts, string.char(31))
end

local function validateExecuteContext(context)
    if not isServerActive() then
        return nil, "server-inactive"
    end
    local eventState = type(Server.GetEventState) == "function" and Server:GetEventState() or Server.EventState
    if type(eventState) ~= "table" or eventState.active ~= true then
        return nil, "event-inactive"
    end
    if type(Server.IsEventUnitsReady) == "function" and Server:IsEventUnitsReady() ~= true then
        return nil, "event-not-ready"
    end

    local eventSessionId = validIdentifier(type(context) == "table" and context.eventSessionId or nil)
    if not eventSessionId or tostring(eventState.id or "") ~= eventSessionId then
        return nil, "event-state-mismatch"
    end

    local clientState = type(Client.GetState) == "function" and Client:GetState() or Client.State
    local clientEventState = type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState
    if type(clientState) ~= "table" or clientState.active ~= true then
        return nil, "client-inactive"
    end
    if type(clientEventState) ~= "table"
        or clientEventState.active ~= true
        or tostring(clientEventState.id or "") ~= eventSessionId
    then
        return nil, "event-state-mismatch"
    end
    if type(Client.IsLocalEventHost) ~= "function" or Client:IsLocalEventHost(clientEventState) ~= true then
        return nil, "not-host"
    end

    local authoritativeHost = normalizeName(eventState.hostName)
    local localName = localPlayerName()
    if authoritativeHost == "" or localName == "" or authoritativeHost ~= localName then
        return nil, "not-host"
    end
    local requestedHost = normalizeName(type(context) == "table" and context.hostName or nil)
    if requestedHost ~= "" and requestedHost ~= authoritativeHost then
        return nil, "host-mismatch"
    end

    local source = trim(type(context) == "table" and context.source or "")
    if source ~= "event-end" and source ~= "event-manager" then
        return nil, "invalid-source-context"
    end

    return {
        eventState = eventState,
        eventSessionId = eventSessionId,
        hostName = authoritativeHost,
        source = source,
        rng = context and context.rng or nil,
    }
end

function Loot:GenerateGrantId(eventSessionId, source)
    local sessionId = validIdentifier(eventSessionId)
    if not sessionId then
        return nil, "invalid-event-session-id"
    end
    local normalizedSource = trim(source)
    if normalizedSource == "" then
        normalizedSource = "grant"
    end
    normalizedSource = normalizedSource:gsub("[^%w_.-]", "-")
    self.NextGrantSequence = math.max(0, math.floor(tonumber(self.NextGrantSequence) or 0)) + 1
    local identifier = ("%s:loot:%s:%d:%d"):format(sessionId, normalizedSource, getNow(), self.NextGrantSequence)
    if #identifier > MAX_IDENTIFIER_LENGTH then
        identifier = ("loot:%s:%d:%d"):format(normalizedSource, getNow(), self.NextGrantSequence)
    end
    return identifier
end

local function generateDeliveryId(eventSessionId)
    Loot.NextDeliverySequence = math.max(0, math.floor(tonumber(Loot.NextDeliverySequence) or 0)) + 1
    local identifier = ("%s:delivery:%d:%d"):format(tostring(eventSessionId or "evt"), getNow(), Loot.NextDeliverySequence)
    if #identifier > MAX_IDENTIFIER_LENGTH then
        identifier = ("loot-delivery:%d:%d"):format(getNow(), Loot.NextDeliverySequence)
    end
    return identifier
end

local function freezeAssignments(assignments, eligiblePlayers)
    if type(assignments) ~= "table" then
        return nil, "invalid-assignment", { reason = "assignments-not-table" }
    end

    local eligible = {}
    for index = 1, #(eligiblePlayers or {}) do
        eligible[eligiblePlayers[index]] = true
    end

    local frozen = {}
    local byPlayer = {}
    for assignmentIndex = 1, #assignments do
        local assignment = assignments[assignmentIndex]
        local player = normalizeName(type(assignment) == "table" and assignment.player or nil)
        if player == "" or not eligible[player] then
            return nil, "invalid-assignment", {
                assignmentIndex = assignmentIndex,
                player = player,
            }
        end
        local rewards = type(assignment.rewards) == "table" and assignment.rewards or nil
        if not rewards or #rewards == 0 then
            return nil, "invalid-assignment", {
                assignmentIndex = assignmentIndex,
                player = player,
                reason = "empty-rewards",
            }
        end

        local bucket = byPlayer[player]
        if not bucket then
            bucket = { player = player, rewards = {} }
            byPlayer[player] = bucket
            frozen[#frozen + 1] = bucket
        end
        for rewardIndex = 1, #rewards do
            local concrete = nil
            local reason = nil
            local detail = nil
            if type(LootLogic.ValidateConcreteReward) == "function" then
                concrete, reason, detail = LootLogic.ValidateConcreteReward(rewards[rewardIndex])
            end
            if type(concrete) ~= "table" then
                return nil, reason or "invalid-assignment", {
                    assignmentIndex = assignmentIndex,
                    rewardIndex = rewardIndex,
                    detail = detail,
                }
            end
            bucket.rewards[#bucket.rewards + 1] = copyConcreteReward(concrete)
        end
    end

    if #frozen == 0 then
        return nil, "invalid-assignment", { reason = "no-assignments" }
    end

    for index = 1, #frozen do
        if type(LootLogic.MergeConcreteRewards) == "function" then
            local merged, reason, detail = LootLogic.MergeConcreteRewards(frozen[index].rewards)
            if not merged then
                return nil, reason or "invalid-assignment", detail
            end
            frozen[index].rewards = merged
        end
    end
    return frozen
end

local function indexExecution(execution)
    local key = executionKey(execution.eventSessionId, execution.grantId)
    Loot.ExecutionsByKey[key] = execution
    local sessionId = execution.eventSessionId
    Loot.ExecutionKeysBySession[sessionId] = type(Loot.ExecutionKeysBySession[sessionId]) == "table"
        and Loot.ExecutionKeysBySession[sessionId]
        or {}
    Loot.ExecutionKeysBySession[sessionId][#Loot.ExecutionKeysBySession[sessionId] + 1] = key
    touchSession(sessionId)
    for deliveryId in pairs(execution.deliveries or {}) do
        Loot.DeliveryIndex[deliveryId] = key
    end
    return key
end

local function updateExecutionStatus(execution)
    local count = 0
    local succeeded = 0
    local failed = 0
    local pending = 0
    for _, delivery in pairs(execution and execution.deliveries or {}) do
        count = count + 1
        if delivery.status == "success" then
            succeeded = succeeded + 1
        elseif delivery.status == "failed" then
            failed = failed + 1
        else
            pending = pending + 1
        end
    end

    if count == 0 then
        execution.status = "failed"
    elseif succeeded == count then
        execution.status = "success"
        execution.completedAt = getNow()
    elseif pending > 0 then
        execution.status = "pending"
        execution.completedAt = nil
    else
        execution.status = "failed"
        execution.completedAt = nil
    end
    execution.successCount = succeeded
    execution.failedCount = failed
    execution.pendingCount = pending
    return execution.status
end

local function buildDeliveryPayload(execution, delivery)
    return {
        protocolVersion = Protocol.Version or 1,
        deliveryId = delivery.deliveryId,
        eventSessionId = execution.eventSessionId,
        grantId = execution.grantId,
        recipientName = delivery.recipientName,
        rewards = deepCopy(delivery.rewards),
    }
end

local function sendDelivery(execution, delivery)
    local opcode = type(Operations.GetOpcode) == "function" and Operations:GetOpcode("LOOT_DELIVERY") or Protocol.DeliveryOpcode
    if not opcode
        or type(Protocol.BuildDeliveryArguments) ~= "function"
        or type(Comms.SendMessage) ~= "function"
    then
        delivery.status = "failed"
        delivery.failureReason = "delivery-api-unavailable"
        delivery.lastSendAttemptAt = getNow()
        delivery.sendAttempts = math.max(0, math.floor(tonumber(delivery.sendAttempts) or 0)) + 1
        updateExecutionStatus(execution)
        return false, delivery.failureReason
    end

    local payload = buildDeliveryPayload(execution, delivery)
    local arguments, reason = Protocol.BuildDeliveryArguments(payload)
    if type(arguments) ~= "table" then
        delivery.status = "failed"
        delivery.failureReason = reason or "invalid-payload"
        delivery.lastSendAttemptAt = getNow()
        delivery.sendAttempts = math.max(0, math.floor(tonumber(delivery.sendAttempts) or 0)) + 1
        updateExecutionStatus(execution)
        return false, delivery.failureReason
    end

    delivery.sendAttempts = math.max(0, math.floor(tonumber(delivery.sendAttempts) or 0)) + 1
    delivery.lastSendAttemptAt = getNow()
    delivery.sentAt = delivery.lastSendAttemptAt
    delivery.status = "pending"
    delivery.failureReason = nil
    updateExecutionStatus(execution)

    local sent = Comms:SendMessage("WHISPER", opcode, arguments, delivery.recipientName, {
        opcode = opcode,
        scope = "server",
    }) == true
    if not sent and delivery.status == "pending" then
        delivery.status = "failed"
        delivery.failureReason = "send-failed"
    end
    updateExecutionStatus(execution)
    return sent, sent and nil or delivery.failureReason
end

local function buildSummaryRewards(delivery)
    local response = type(delivery.response) == "table" and delivery.response or nil
    if response and response.success == true and type(response.rewards) == "table" then
        return deepCopy(response.rewards)
    end

    local rewards = {}
    for index = 1, #(delivery.rewards or {}) do
        local reward = delivery.rewards[index]
        rewards[#rewards + 1] = {
            type = reward.type,
            ref = reward.ref,
            requestedAmount = reward.amount,
            appliedAmount = nil,
            reason = delivery.failureReason,
        }
    end
    return rewards
end

local function buildExecutionSummary(execution, reused)
    if type(execution) ~= "table" then
        return nil
    end
    local deliveries = {}
    local orderedIds = type(execution.deliveryOrder) == "table" and execution.deliveryOrder or {}
    for index = 1, #orderedIds do
        local delivery = execution.deliveries[orderedIds[index]]
        if type(delivery) == "table" then
            deliveries[#deliveries + 1] = {
                deliveryId = delivery.deliveryId,
                recipientName = delivery.recipientName,
                status = delivery.status,
                reason = delivery.failureReason or (delivery.response and delivery.response.reason or nil),
                rewards = buildSummaryRewards(delivery),
                sentAt = delivery.sentAt,
                receivedAt = delivery.receivedAt,
                sendAttempts = delivery.sendAttempts or 0,
            }
        end
    end
    return {
        grantId = execution.grantId,
        eventSessionId = execution.eventSessionId,
        source = execution.source,
        status = execution.status,
        createdAt = execution.createdAt,
        completedAt = execution.completedAt,
        reused = reused == true,
        deliveries = deliveries,
    }
end

function Loot:GetGrantExecution(eventSessionId, grantId)
    local key = executionKey(eventSessionId, grantId)
    local execution = self.ExecutionsByKey[key]
    return type(execution) == "table" and deepCopy(execution) or nil
end

function Loot:GetGrantExecutionSummary(eventSessionId, grantId)
    return buildExecutionSummary(self.ExecutionsByKey[executionKey(eventSessionId, grantId)], false)
end

function Loot:GetDelivery(deliveryId)
    local key = self.DeliveryIndex[tostring(deliveryId or "")]
    local execution = key and self.ExecutionsByKey[key] or nil
    local delivery = execution and execution.deliveries and execution.deliveries[tostring(deliveryId or "")] or nil
    return type(delivery) == "table" and deepCopy(delivery) or nil
end

function Loot:ExecuteGrant(grant, eligiblePlayers, context)
    self:PruneExecutions()

    local authority, reason, detail = validateExecuteContext(context)
    if not authority then
        return nil, reason, detail
    end

    local players = nil
    players, reason, detail = self:ValidateEligiblePlayers(authority.eventState, eligiblePlayers)
    if not players then
        return nil, reason, detail
    end

    local source, grantSnapshot = nil, nil
    source, grantSnapshot, reason, detail = normalizeGrantContract(grant)
    if not source then
        return nil, reason, detail
    end

    local rawGrantId = type(context) == "table" and context.grantId or nil
    local grantId = validIdentifier(rawGrantId)
    if trim(rawGrantId) ~= "" and not grantId then
        return nil, "invalid-grant-id"
    end
    if not grantId then
        grantId, reason = self:GenerateGrantId(authority.eventSessionId, authority.source)
        if not grantId then
            return nil, reason or "invalid-grant-id"
        end
    end

    local key = executionKey(authority.eventSessionId, grantId)
    local requestFingerprint = buildRequestFingerprint(
        authority.eventSessionId,
        authority.hostName,
        authority.source,
        grantSnapshot,
        players
    )
    local existing = self.ExecutionsByKey[key]
    if type(existing) == "table" then
        if existing.requestFingerprint ~= requestFingerprint then
            return nil, "grant-conflict", {
                eventSessionId = authority.eventSessionId,
                grantId = grantId,
            }
        end
        touchSession(existing.eventSessionId)
        return buildExecutionSummary(existing, true)
    end

    local sessionKeys = self.ExecutionKeysBySession[authority.eventSessionId]
    if type(sessionKeys) == "table" and #sessionKeys >= MAX_EXECUTIONS_PER_SESSION then
        return nil, "execution-cap-reached", {
            eventSessionId = authority.eventSessionId,
            maximum = MAX_EXECUTIONS_PER_SESSION,
        }
    end

    if type(LootLogic.BuildAssignments) ~= "function" then
        return nil, "loot-resolver-unavailable"
    end
    local assignments = nil
    assignments, reason, detail = LootLogic.BuildAssignments(source, grantSnapshot.distribution, players, authority.rng)
    if not assignments then
        return nil, reason, detail
    end

    local frozenAssignments = nil
    frozenAssignments, reason, detail = freezeAssignments(assignments, players)
    if not frozenAssignments then
        return nil, reason, detail
    end

    local execution = {
        grantId = grantId,
        eventSessionId = authority.eventSessionId,
        hostName = authority.hostName,
        source = authority.source,
        grantSnapshot = deepCopy(grantSnapshot),
        eligiblePlayers = deepCopy(players),
        requestFingerprint = requestFingerprint,
        assignments = deepCopy(frozenAssignments),
        createdAt = getNow(),
        status = "pending",
        deliveries = {},
        deliveryOrder = {},
    }

    for index = 1, #frozenAssignments do
        local assignment = frozenAssignments[index]
        local deliveryId = generateDeliveryId(execution.eventSessionId)
        local delivery = {
            deliveryId = deliveryId,
            eventSessionId = execution.eventSessionId,
            grantId = execution.grantId,
            recipientName = assignment.player,
            rewards = deepCopy(assignment.rewards),
            status = "pending",
            response = nil,
            failureReason = nil,
            sentAt = nil,
            receivedAt = nil,
            sendAttempts = 0,
        }
        execution.deliveries[deliveryId] = delivery
        execution.deliveryOrder[#execution.deliveryOrder + 1] = deliveryId
    end

    indexExecution(execution)
    updateExecutionStatus(execution)

    for index = 1, #execution.deliveryOrder do
        local delivery = execution.deliveries[execution.deliveryOrder[index]]
        sendDelivery(execution, delivery)
    end
    return buildExecutionSummary(execution, false)
end

local function validateSuccessResponse(delivery, response)
    if type(response.rewards) ~= "table" or #response.rewards ~= #(delivery.rewards or {}) then
        return nil, "invalid-response", { reason = "reward-count" }
    end
    local normalized = {}
    for index = 1, #delivery.rewards do
        local expected = delivery.rewards[index]
        local actual = response.rewards[index]
        if type(actual) ~= "table"
            or string.lower(trim(actual.type)) ~= tostring(expected.type or "")
            or trim(actual.ref) ~= tostring(expected.ref or "")
        then
            return nil, "invalid-response", { rewardIndex = index, reason = "reward-identity" }
        end
        local requested = positiveInteger(actual.requestedAmount)
        local applied = nonNegativeInteger(actual.appliedAmount)
        if requested ~= expected.amount or applied == nil or applied > requested then
            return nil, "invalid-response", { rewardIndex = index, reason = "reward-amount" }
        end
        local responseReason = trim(actual.reason)
        if expected.type == "item" then
            if applied ~= requested or responseReason ~= "" then
                return nil, "invalid-response", { rewardIndex = index, reason = "item-result" }
            end
        elseif applied < requested then
            if responseReason ~= "currency-capped" then
                return nil, "invalid-response", { rewardIndex = index, reason = "currency-cap-reason" }
            end
        elseif responseReason ~= "" then
            return nil, "invalid-response", { rewardIndex = index, reason = "unexpected-reason" }
        end
        normalized[#normalized + 1] = {
            type = expected.type,
            ref = expected.ref,
            requestedAmount = requested,
            appliedAmount = applied,
            reason = responseReason ~= "" and responseReason or nil,
        }
    end
    return normalized
end

local function validateResponse(delivery, response)
    if tonumber(response.protocolVersion) ~= tonumber(Protocol.Version or 1) then
        return nil, "unsupported-protocol"
    end
    if tostring(response.deliveryId or "") ~= tostring(delivery.deliveryId or "") then
        return nil, "invalid-response", { reason = "delivery-id" }
    end
    if response.success == true then
        local rewards, reason, detail = validateSuccessResponse(delivery, response)
        if not rewards then
            return nil, reason, detail
        end
        return {
            protocolVersion = Protocol.Version or 1,
            deliveryId = delivery.deliveryId,
            success = true,
            rewards = rewards,
        }
    end

    local failureReason = trim(response.reason)
    if failureReason == "" or (type(response.rewards) == "table" and #response.rewards > 0) then
        return nil, "invalid-response", { reason = "failure-shape" }
    end
    return {
        protocolVersion = Protocol.Version or 1,
        deliveryId = delivery.deliveryId,
        success = false,
        reason = failureReason,
        rewards = {},
    }
end

function Loot:HandleDeliveryResponse(arguments, sender)
    self:PruneExecutions()
    if not isServerActive() then
        return false, "server-inactive"
    end
    if type(Protocol.ParseResponseArguments) ~= "function" then
        return false, "delivery-api-unavailable"
    end
    local response, parseReason, detail = Protocol.ParseResponseArguments(arguments)
    if not response then
        return false, parseReason or "invalid-response", detail
    end

    local deliveryId = tostring(response.deliveryId or "")
    local key = self.DeliveryIndex[deliveryId]
    local execution = key and self.ExecutionsByKey[key] or nil
    local delivery = execution and execution.deliveries and execution.deliveries[deliveryId] or nil
    if type(execution) ~= "table" or type(delivery) ~= "table" then
        return false, "unknown-delivery"
    end

    local authority, reason = validateRetainedExecutionAuthority(execution)
    if not authority then
        return false, reason
    end
    if tostring(execution.grantId or "") ~= tostring(delivery.grantId or "")
        or tostring(execution.eventSessionId or "") ~= tostring(delivery.eventSessionId or "")
    then
        return false, "delivery-context-mismatch"
    end
    if normalizeName(sender) ~= normalizeName(delivery.recipientName) then
        return false, "invalid-sender"
    end

    local normalizedResponse = nil
    normalizedResponse, reason, detail = validateResponse(delivery, response)
    if not normalizedResponse then
        return false, reason, detail
    end

    if delivery.status == "success" then
        if deepEqual(delivery.response, normalizedResponse) then
            return true, "duplicate-response", buildExecutionSummary(execution, true)
        end
        return false, "response-conflict"
    end
    if delivery.status == "failed" and deepEqual(delivery.response, normalizedResponse) then
        return true, "duplicate-response", buildExecutionSummary(execution, true)
    end

    delivery.response = deepCopy(normalizedResponse)
    delivery.receivedAt = getNow()
    if normalizedResponse.success == true then
        delivery.status = "success"
        delivery.failureReason = nil
    else
        delivery.status = "failed"
        delivery.failureReason = normalizedResponse.reason
    end
    updateExecutionStatus(execution)
    touchSession(execution.eventSessionId)
    return true, normalizedResponse.success == true and "success" or "failed", buildExecutionSummary(execution, false)
end

function Loot:RetryDelivery(deliveryId)
    self:PruneExecutions()
    if not isServerActive() then
        return nil, "server-inactive"
    end
    local normalizedId = validIdentifier(deliveryId)
    if not normalizedId then
        return nil, "invalid-delivery-id"
    end

    local key = self.DeliveryIndex[normalizedId]
    local execution = key and self.ExecutionsByKey[key] or nil
    local delivery = execution and execution.deliveries and execution.deliveries[normalizedId] or nil
    if type(execution) ~= "table" or type(delivery) ~= "table" then
        return nil, "unknown-delivery"
    end

    local authority, reason = validateRetainedExecutionAuthority(execution)
    if not authority then
        return nil, reason
    end
    if delivery.status == "success" then
        return buildExecutionSummary(execution, true), "already-successful"
    end
    sendDelivery(execution, delivery)
    touchSession(execution.eventSessionId)
    return buildExecutionSummary(execution, false)
end
