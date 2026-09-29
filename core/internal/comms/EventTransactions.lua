local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Client = Addon.Client or {}
Addon.Server = Addon.Server or {}

local Comms = Addon.Internal.Comms
local Operations = Comms.Operations or {}
local Common = Addon.Utils and Addon.Utils.Common or {}

local Transactions = Comms.EventTransactions or {}
Comms.EventTransactions = Transactions

Transactions.ProtocolVersion = 1
Transactions.MaxIdLength = 128
Transactions.MaxTerminalRecords = 2048
Transactions.TerminalRetentionSeconds = 30 * 60
Transactions.MaxDiagnostics = 256
Transactions.RetryDelaysMs = { 1500, 3000, 6000 }
Transactions.DefaultDeadlineMs = 15000

local TERMINAL_STATES = {
    committed = true,
    rejected = true,
    cancelled = true,
    ["timed-out"] = true,
}

local VALID_STATES = {
    created = true,
    ["awaiting-input"] = true,
    submitted = true,
    committed = true,
    rejected = true,
    cancelled = true,
    ["timed-out"] = true,
}

local TRANSITIONS = {
    created = { ["awaiting-input"] = true, submitted = true, cancelled = true },
    ["awaiting-input"] = { submitted = true, cancelled = true, ["timed-out"] = true },
    submitted = { committed = true, rejected = true, cancelled = true, ["timed-out"] = true },
}

local function now()
    if type(Common.GetNow) == "function" then
        return tonumber(Common.GetNow()) or 0
    end
    if type(GetTimePreciseSec) == "function" then
        return tonumber(GetTimePreciseSec()) or 0
    end
    return 0
end

local function normalizeName(name)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(name)
    end
    return tostring(name or "")
end

local function clone(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local copy = {}
    seen[value] = copy
    for key, child in pairs(value) do
        copy[clone(key, seen)] = clone(child, seen)
    end
    return copy
end

local function sortedKeys(value)
    local keys = {}
    for key in pairs(value) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(left, right)
        return tostring(left) < tostring(right)
    end)
    return keys
end

local function encodeString(value)
    local bytes = {}
    for index = 1, #value do
        bytes[#bytes + 1] = string.format("%02x", string.byte(value, index))
    end
    return table.concat(bytes)
end

local function decodeString(value)
    if #value % 2 ~= 0 then
        return nil
    end
    local bytes = {}
    for index = 1, #value, 2 do
        local byte = tonumber(string.sub(value, index, index + 1), 16)
        if not byte then
            return nil
        end
        bytes[#bytes + 1] = string.char(byte)
    end
    return table.concat(bytes)
end

-- A small deterministic codec keeps the transport envelope opaque while
-- allowing the normal multipart Comms layer to carry arbitrary input/output
-- tables. It intentionally supports only protocol data types.
local function encode(value, seen)
    local valueType = type(value)
    if value == nil then
        return "n"
    elseif valueType == "boolean" then
        return value and "b1" or "b0"
    elseif valueType == "number" then
        local numberText = tostring(value)
        return "d" .. tostring(#numberText) .. ":" .. numberText
    elseif valueType == "string" then
        local encoded = encodeString(value)
        return "s" .. tostring(#encoded) .. ":" .. encoded
    elseif valueType ~= "table" then
        error("transaction codec does not support " .. valueType, 3)
    end

    seen = seen or {}
    if seen[value] then
        error("transaction codec does not support cyclic tables", 3)
    end
    seen[value] = true
    local parts = { "t" }
    for _, key in ipairs(sortedKeys(value)) do
        parts[#parts + 1] = encode(key, seen)
        parts[#parts + 1] = encode(value[key], seen)
    end
    parts[#parts + 1] = "e"
    seen[value] = nil
    return table.concat(parts)
end

local function decode(text, position)
    position = position or 1
    local marker = string.sub(text, position, position)
    position = position + 1
    if marker == "n" then
        return nil, position
    elseif marker == "b" then
        local bit = string.sub(text, position, position)
        return bit == "1", position + 1
    elseif marker == "d" then
        local separator = string.find(text, ":", position, true)
        if not separator then
            return nil, nil
        end
        local length = tonumber(string.sub(text, position, separator - 1))
        if not length or length < 0 then
            return nil, nil
        end
        local startPosition = separator + 1
        local endPosition = startPosition + length
        return tonumber(string.sub(text, startPosition, endPosition - 1)), endPosition
    elseif marker == "s" then
        local separator = string.find(text, ":", position, true)
        if not separator then
            return nil, nil
        end
        local length = tonumber(string.sub(text, position, separator - 1))
        if not length or length < 0 then
            return nil, nil
        end
        local startPosition = separator + 1
        local endPosition = startPosition + length
        local value = decodeString(string.sub(text, startPosition, endPosition - 1))
        return value, value and endPosition or nil
    elseif marker == "t" then
        local value = {}
        while string.sub(text, position, position) ~= "e" do
            if position > #text then
                return nil, nil
            end
            local key, nextPosition = decode(text, position)
            if nextPosition == nil then
                return nil, nil
            end
            local child
            child, position = decode(text, nextPosition)
            if position == nil then
                return nil, nil
            end
            value[key] = child
        end
        return value, position + 1
    end
    return nil, nil
end

local function decodeEnvelope(payload)
    if type(payload) == "table" then
        return clone(payload)
    end
    if type(payload) ~= "string" then
        return nil
    end
    local value, position = decode(payload, 1)
    if value == nil or position ~= #payload + 1 then
        return nil
    end
    return value
end

local function copyTargets(targets)
    local result = {}
    local seen = {}
    for _, target in ipairs(type(targets) == "table" and targets or {}) do
        local normalized = tostring(target or "")
        if normalized ~= "" and not seen[normalized] then
            seen[normalized] = true
            result[#result + 1] = normalized
        end
    end
    table.sort(result)
    return result
end

local function normalizeEnvelope(input)
    local source = type(input) == "table" and input or {}
    local envelope = {
        protocolVersion = source.protocolVersion ~= nil and tonumber(source.protocolVersion) or nil,
        transactionId = tostring(source.transactionId or ""),
        eventId = tostring(source.eventId or ""),
        operation = tostring(source.operation or ""),
        originName = normalizeName(source.originName),
        actorEventId = source.actorEventId,
        targetEventIds = copyTargets(source.targetEventIds),
        turnNumber = source.turnNumber ~= nil and tonumber(source.turnNumber) or nil,
        tickNumber = source.tickNumber ~= nil and tonumber(source.tickNumber) or nil,
        baseRevision = source.baseRevision ~= nil and tonumber(source.baseRevision) or nil,
        input = clone(source.input),
        state = source.state,
        outcome = clone(source.outcome),
        newRevision = source.newRevision ~= nil and tonumber(source.newRevision) or nil,
        authoritativeDelta = clone(source.authoritativeDelta),
        deltaRef = source.deltaRef,
        presentationKey = source.presentationKey,
        inputRecipient = normalizeName(source.inputRecipient),
        requestDigest = source.requestDigest,
        createdAt = source.createdAt,
        submittedAt = source.submittedAt,
        terminalAt = source.terminalAt,
        stepSensitive = source.stepSensitive == true,
        deadlineMs = source.deadlineMs,
    }
    return envelope
end

local function digestFor(envelope)
    return encode({
        protocolVersion = envelope.protocolVersion,
        transactionId = envelope.transactionId,
        eventId = envelope.eventId,
        operation = envelope.operation,
        originName = envelope.originName,
        actorEventId = envelope.actorEventId,
        targetEventIds = envelope.targetEventIds,
        inputRecipient = envelope.inputRecipient,
        turnNumber = envelope.turnNumber,
        tickNumber = envelope.tickNumber,
        baseRevision = envelope.baseRevision,
        input = envelope.input,
    })
end

local function identityDigestFor(envelope)
    return encode({
        protocolVersion = envelope.protocolVersion,
        transactionId = envelope.transactionId,
        eventId = envelope.eventId,
        operation = envelope.operation,
        originName = envelope.originName,
        actorEventId = envelope.actorEventId,
        targetEventIds = envelope.targetEventIds,
        inputRecipient = envelope.inputRecipient,
        turnNumber = envelope.turnNumber,
        tickNumber = envelope.tickNumber,
        baseRevision = envelope.baseRevision,
        stepSensitive = envelope.stepSensitive,
    })
end

local function transition(record, nextState, reason)
    local current = record.state
    if current == nextState then
        return true
    end
    if TERMINAL_STATES[current] or not (TRANSITIONS[current] and TRANSITIONS[current][nextState]) then
        return false
    end
    record.state = nextState
    record.lastTransitionReason = reason
    return true
end

local function eventIdOf(eventState)
    return type(eventState) == "table" and tostring(eventState.id or "") or ""
end

local function currentClientEvent()
    local client = Addon.Client
    if type(client.GetEventState) == "function" then
        return client:GetEventState()
    end
    return client.EventState
end

local function currentServerEvent()
    local server = Addon.Server
    if type(server.GetEventState) == "function" then
        return server:GetEventState()
    end
    return server.EventState
end

local function currentHostName(eventState)
    if type(eventState) == "table" and eventState.hostName then
        return normalizeName(eventState.hostName)
    end
    local state = Addon.Client and Addon.Client.State
    return normalizeName(type(state) == "table" and state.hostName or nil)
end

local function channelIdFor(eventState)
    if type(eventState) ~= "table" then
        return nil
    end
    return eventState.channelId or eventState.channelName
end

local function operationCode(key)
    return Operations:GetOpcode(key)
end

local function sendPayload(key, payload, distribution, target, metadata)
    local opcode = operationCode(key)
    if not opcode or type(Comms.SendMessage) ~= "function" then
        return false
    end
    local encoded = encode(payload)
    return Comms:SendMessage(distribution, opcode, { encoded }, target, metadata) == true
end

local function sendToChannel(key, payload, channelId, metadata)
    local opcode = operationCode(key)
    if not opcode or type(Comms.SendToChannel) ~= "function" then
        return false
    end
    return Comms:SendToChannel(channelId, opcode, { encode(payload) }, metadata) == true
end

local function recordDiagnostic(service, eventId, entry)
    service.diagnostics = service.diagnostics or {}
    local record = clone(entry or {})
    record.at = record.at or now()
    record.eventId = eventId or record.eventId
    service.diagnostics[#service.diagnostics + 1] = record
    while #service.diagnostics > Transactions.MaxDiagnostics do
        table.remove(service.diagnostics, 1)
    end
    local diagnostics = Comms.Diagnostics
    if type(diagnostics) == "table" and type(diagnostics.RecordTransaction) == "function" then
        diagnostics:RecordTransaction(record)
    end
end

local function addBounded(cache, order, key, value, maximum)
    if cache[key] == nil then
        order[#order + 1] = key
    end
    cache[key] = value
    while #order > maximum do
        local oldest = table.remove(order, 1)
        cache[oldest] = nil
    end
end

local function makeTransactionId(service, originName)
    service.counter = (service.counter or 0) + 1
    local clock = math.floor((now() or 0) * 1000)
    local suffix = math.random(1000, 9999)
    return table.concat({ service.sessionNonce, normalizeName(originName), service.counter, clock, suffix }, ":")
end

local ClientService = {}
ClientService.__index = ClientService

function ClientService.new()
    local service = setmetatable({
        pendingByEventId = {},
        terminalByEventId = {},
        presentationByEventId = {},
        diagnostics = {},
        counter = 0,
        sessionNonce = tostring(math.random(100000, 999999)),
        currentEventId = nil,
    }, ClientService)
    service.PendingTransactions = service.pendingByEventId
    service.TerminalTransactions = service.terminalByEventId
    service.PresentationLedger = service.presentationByEventId
    return service
end

function ClientService:_pending(eventId)
    self.pendingByEventId[eventId] = self.pendingByEventId[eventId] or {}
    return self.pendingByEventId[eventId]
end

function ClientService:_terminal(eventId)
    self.terminalByEventId[eventId] = self.terminalByEventId[eventId] or {}
    return self.terminalByEventId[eventId]
end

function ClientService:_presentation(eventId)
    self.presentationByEventId[eventId] = self.presentationByEventId[eventId] or {}
    return self.presentationByEventId[eventId]
end

function ClientService:StartEvent(eventId)
    local normalized = tostring(eventId or "")
    if self.currentEventId and self.currentEventId ~= normalized then
        self:EndEvent(self.currentEventId, "event-replaced")
    end
    self.currentEventId = normalized ~= "" and normalized or nil
    return self.currentEventId
end

function ClientService:Create(options)
    options = type(options) == "table" and options or {}
    local eventState = currentClientEvent()
    local eventId = tostring(options.eventId or eventIdOf(eventState))
    local originName = normalizeName(options.originName or (Common.GetPlayerName and Common.GetPlayerName()))
    if eventId == "" or originName == "" then
        return nil, "missing-event-or-origin"
    end
    self:StartEvent(eventId)
    local envelope = normalizeEnvelope({
        protocolVersion = Transactions.ProtocolVersion,
        transactionId = options.transactionId or makeTransactionId(self, originName),
        eventId = eventId,
        operation = options.operation,
        originName = originName,
        actorEventId = options.actorEventId,
        targetEventIds = options.targetEventIds,
        turnNumber = options.turnNumber or (eventState and eventState.turnNumber),
        tickNumber = options.tickNumber or (eventState and eventState.tickNumber),
        baseRevision = options.baseRevision or (eventState and eventState.liveUnitRevision),
        input = options.input ~= nil and options.input or {},
        stepSensitive = options.stepSensitive == true,
        deadlineMs = options.deadlineMs or Transactions.DefaultDeadlineMs,
        createdAt = now(),
    })
    local pending = self:_pending(eventId)
    if pending[envelope.transactionId] then
        return nil, "duplicate-local-transaction-id"
    end
    local record = {
        envelope = envelope,
        id = envelope.transactionId,
        eventId = eventId,
        state = "created",
        createdAt = envelope.createdAt,
        attempts = 0,
        nextRetryAt = nil,
        deadlineAt = envelope.createdAt + (tonumber(envelope.deadlineMs) or Transactions.DefaultDeadlineMs) / 1000,
        lastSendFailure = nil,
        statusRequested = false,
        terminal = nil,
        presentationSettled = false,
        options = options,
    }
    pending[record.id] = record
    recordDiagnostic(self, eventId, { transactionId = record.id, operation = envelope.operation, state = "created" })
    return record
end

function ClientService:AwaitInput(transactionId)
    local record = self:GetPending(transactionId)
    if not record or not transition(record, "awaiting-input", "awaiting-input") then
        return false
    end
    recordDiagnostic(self, record.eventId, { transactionId = record.id, state = record.state })
    return true
end

function ClientService:_send(record, isRetry, messageKey)
    local eventState = currentClientEvent()
    if tostring(eventIdOf(eventState)) ~= tostring(record.eventId) or eventState.active == false then
        recordDiagnostic(self, record.eventId, { transactionId = record.id, state = "stale-event", reason = "retry-blocked" })
        return false
    end
    local hostName = currentHostName(eventState)
    local key = messageKey or record.messageKey or "EVENT_TX_REQUEST"
    local metadata = {
        opcode = operationCode(key),
        scope = "transaction",
        transactionId = record.id,
        onFailed = function(_, failure)
            record.lastSendFailure = tostring(failure or "send-failed")
            recordDiagnostic(self, record.eventId, {
                transactionId = record.id,
                state = record.state,
                lastSendFailure = record.lastSendFailure,
            })
        end,
    }
    local server = Addon.Server and Addon.Server.EventTransactions or nil
    local localName = normalizeName(Common.GetPlayerName and Common.GetPlayerName())
    local sent
    if server and type(server.IsAuthoritative) == "function" and server:IsAuthoritative()
        and localName == normalizeName(hostName)
    then
        if key == "EVENT_TX_INPUT" and type(server.ReceiveInput) == "function" then
            sent = server:ReceiveInput(record.envelope, localName)
        else
            sent = server:ReceiveRequest(record.envelope, localName)
        end
    else
        sent = sendPayload(key, record.envelope, "WHISPER", hostName, metadata)
    end
    record.attempts = record.attempts + 1
    record.lastSendAt = now()
    record.lastRetry = isRetry == true
    recordDiagnostic(self, record.eventId, {
        transactionId = record.id,
        state = record.state,
        attempts = record.attempts,
        transport = sent and "accepted" or "failed",
    })
    return sent
end

function ClientService:_scheduleRetry(record)
    if record.retryTimer or TERMINAL_STATES[record.state] then
        return
    end
    local delay = Transactions.RetryDelaysMs[record.attempts] or nil
    if not delay then
        delay = math.max(0, (record.deadlineAt - now()) * 1000)
    end
    record.nextRetryAt = now() + delay / 1000
    if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
        record.retryTimer = C_Timer.After(delay / 1000, function()
            record.retryTimer = nil
            self:ProcessRetry(record.eventId, record.id)
        end)
    end
end

function ClientService:Submit(recordOrId, input)
    local record = type(recordOrId) == "table" and recordOrId or self:GetPending(recordOrId)
    if not record or TERMINAL_STATES[record.state] then
        return false, "not-pending"
    end
    if input ~= nil then
        record.envelope.input = clone(input)
    end
    if not transition(record, "submitted", "submit") then
        return false, "invalid-transition"
    end
    record.envelope.submittedAt = now()
    record.messageKey = "EVENT_TX_REQUEST"
    self:_send(record, false)
    self:_scheduleRetry(record)
    return true
end

function ClientService:SubmitInput(recordOrId, input)
    local record = type(recordOrId) == "table" and recordOrId or self:GetPending(recordOrId)
    if not record or TERMINAL_STATES[record.state] then
        return false, "not-pending"
    end
    record.envelope.input = clone(input ~= nil and input or {})
    if not transition(record, "submitted", "submit-input") then
        return false, "invalid-transition"
    end
    record.envelope.submittedAt = now()
    record.messageKey = "EVENT_TX_INPUT"
    self:_send(record, false, record.messageKey)
    self:_scheduleRetry(record)
    return true
end

function ClientService:ProcessRetry(eventId, transactionId)
    local pending = self.pendingByEventId[tostring(eventId or "")] or {}
    local record = pending[tostring(transactionId or "")]
    if not record or TERMINAL_STATES[record.state] then
        return false
    end
    local current = now()
    if current >= record.deadlineAt then
        if not record.statusRequested then
            record.statusRequested = true
            sendPayload("EVENT_TX_STATUS_REQUEST", record.envelope, "WHISPER", currentHostName(currentClientEvent()), {
                opcode = operationCode("EVENT_TX_STATUS_REQUEST"),
                scope = "transaction",
                transactionId = record.id,
            })
            recordDiagnostic(self, record.eventId, { transactionId = record.id, state = "status-requested" })
            self:_scheduleRetry(record)
        else
            record.transportStalled = true
            record.nextRetryAt = nil
            recordDiagnostic(self, record.eventId, { transactionId = record.id, state = "transport-stalled", timeout = true })
        end
        return true
    end
    if record.attempts >= #Transactions.RetryDelaysMs + 1 then
        self:_scheduleRetry(record)
        return true
    end
    self:_send(record, true)
    self:_scheduleRetry(record)
    return true
end

function ClientService:GetPending(transactionId, eventId)
    if eventId then
        return (self.pendingByEventId[tostring(eventId)] or {})[tostring(transactionId)]
    end
    for _, pending in pairs(self.pendingByEventId) do
        if pending[tostring(transactionId)] then
            return pending[tostring(transactionId)]
        end
    end
    return nil
end

function ClientService:_settle(record, envelope)
    local eventId = record.eventId
    local terminal = self:_terminal(eventId)
    self._terminalOrder = self._terminalOrder or {}
    self._terminalOrder[eventId] = self._terminalOrder[eventId] or {}
    addBounded(terminal, self._terminalOrder[eventId], record.id, clone(envelope), Transactions.MaxTerminalRecords)
    local presentation = self:_presentation(eventId)
    local key = tostring(envelope.presentationKey or (eventId .. ":" .. record.id))
    local duplicatePresentation = presentation[key] == true
    if not duplicatePresentation then
        presentation[key] = true
    end
    record.presentationSettled = true
    record.terminal = clone(envelope)
    record.state = envelope.state
    local pending = self.pendingByEventId[eventId] or {}
    pending[record.id] = nil
    if record.retryTimer and type(record.retryTimer.Cancel) == "function" then
        record.retryTimer:Cancel()
    end
    record.retryTimer = nil
    recordDiagnostic(self, eventId, {
        transactionId = record.id,
        state = envelope.state,
        outcome = clone(envelope.outcome),
        duplicatePresentation = duplicatePresentation,
    })
    if not duplicatePresentation and type(record.options.onTerminal) == "function" then
        record.options.onTerminal(clone(envelope), record)
    end
end

function ClientService:ReceiveRequest(payload, sender)
    local envelope = normalizeEnvelope(decodeEnvelope(payload) or payload)
    local eventState = currentClientEvent()
    local eventId = tostring(envelope.eventId or "")
    local localName = normalizeName(Common.GetPlayerName and Common.GetPlayerName())
    if envelope.protocolVersion ~= Transactions.ProtocolVersion
        or envelope.state ~= "awaiting-input"
        or eventId == ""
        or eventId ~= eventIdOf(eventState)
        or normalizeName(sender) ~= currentHostName(eventState)
        or envelope.inputRecipient ~= localName
    then
        recordDiagnostic(self, eventId, {
            transactionId = envelope.transactionId,
            state = "invalid-awaiting-input-request",
            sender = sender,
        })
        return false
    end

    local pending = self:_pending(eventId)
    local existing = pending[envelope.transactionId]
    if existing then
        if existing.envelope and identityDigestFor(existing.envelope) ~= identityDigestFor(envelope) then
            recordDiagnostic(self, eventId, {
                transactionId = envelope.transactionId,
                state = "transaction-id-conflict",
            })
            return false
        end
        return true
    end

    local record = {
        envelope = envelope,
        id = envelope.transactionId,
        eventId = eventId,
        state = "created",
        createdAt = envelope.createdAt or now(),
        attempts = 0,
        nextRetryAt = nil,
        deadlineAt = (tonumber(envelope.createdAt) or now())
            + (tonumber(envelope.deadlineMs) or Transactions.DefaultDeadlineMs) / 1000,
        lastSendFailure = nil,
        statusRequested = false,
        terminal = nil,
        presentationSettled = false,
        messageKey = "EVENT_TX_INPUT",
        serverCreated = true,
        options = { serverCreated = true },
    }
    pending[record.id] = record
    transition(record, "awaiting-input", "server-awaiting-input")
    recordDiagnostic(self, eventId, {
        transactionId = record.id,
        operation = envelope.operation,
        state = record.state,
        serverCreated = true,
    })
    return true
end

function ClientService:ReceiveTerminal(payload, sender)
    local envelope = decodeEnvelope(payload)
    if not envelope or envelope.protocolVersion ~= Transactions.ProtocolVersion
        or not TERMINAL_STATES[envelope.state]
    then
        return false
    end
    local eventState = currentClientEvent()
    local eventId = tostring(envelope.eventId or "")
    if eventId == "" or eventId ~= eventIdOf(eventState) then
        recordDiagnostic(self, eventId, { transactionId = envelope.transactionId, state = "stale-event", sender = sender })
        return false
    end
    local expectedHost = currentHostName(eventState)
    if normalizeName(sender) ~= normalizeName(expectedHost) then
        recordDiagnostic(self, eventId, { transactionId = envelope.transactionId, state = "invalid-terminal-sender", sender = sender })
        return false
    end
    local record = self:GetPending(envelope.transactionId, eventId)
    local terminal = self:_terminal(eventId)
    if not record then
        if terminal[envelope.transactionId] then
            recordDiagnostic(self, eventId, { transactionId = envelope.transactionId, state = envelope.state, duplicate = true })
            return true
        end
        self._terminalOrder = self._terminalOrder or {}
        self._terminalOrder[eventId] = self._terminalOrder[eventId] or {}
        addBounded(terminal, self._terminalOrder[eventId], envelope.transactionId,
            clone(envelope), Transactions.MaxTerminalRecords)
        recordDiagnostic(self, eventId, {
            transactionId = envelope.transactionId,
            state = envelope.state,
            projectionOnly = true,
        })
        return true
    end
    if record.envelope.requestDigest and envelope.requestDigest
        and record.envelope.requestDigest ~= envelope.requestDigest
    then
        recordDiagnostic(self, eventId, { transactionId = record.id, state = "digest-conflict" })
        return false
    end
    self:_settle(record, envelope)
    return true
end

function ClientService:ReceiveStatus(payload, sender)
    local envelope = decodeEnvelope(payload)
    if not envelope then
        return false
    end
    local eventState = currentClientEvent()
    if envelope.protocolVersion ~= Transactions.ProtocolVersion
        or tostring(envelope.eventId or "") ~= eventIdOf(eventState)
        or normalizeName(sender) ~= currentHostName(eventState)
    then
        recordDiagnostic(self, envelope.eventId, {
            transactionId = envelope.transactionId,
            state = "stale-or-invalid-status",
            sender = sender,
        })
        return false
    end
    if envelope.state == "unknown" then
        local record = self:GetPending(envelope.transactionId, envelope.eventId)
        if record then
            record.transportStalled = true
        end
        recordDiagnostic(self, envelope.eventId, { transactionId = envelope.transactionId, state = "unknown" })
        return true
    end
    return self:ReceiveTerminal(envelope, sender)
end

function ClientService:Replay(transactionId, eventId)
    local id = tostring(transactionId or "")
    local selectedEvent = tostring(eventId or self.currentEventId or "")
    local envelope = (self:_terminal(selectedEvent)[id])
    if not envelope then
        local record = self:GetPending(id, selectedEvent)
        envelope = record and record.envelope or nil
    end
    if not envelope then
        return false
    end
    return sendPayload("EVENT_TX_REQUEST", envelope, "WHISPER", currentHostName(currentClientEvent()), {
        opcode = operationCode("EVENT_TX_REQUEST"), scope = "transaction", transactionId = id,
    })
end

function ClientService:ReplayInput(transactionId, eventId)
    local id = tostring(transactionId or "")
    local selectedEvent = tostring(eventId or self.currentEventId or "")
    local envelope = self:_terminal(selectedEvent)[id]
    if not envelope then
        local record = self:GetPending(id, selectedEvent)
        envelope = record and record.envelope or nil
    end
    if not envelope then
        return false
    end
    return sendPayload("EVENT_TX_INPUT", envelope, "WHISPER", currentHostName(currentClientEvent()), {
        opcode = operationCode("EVENT_TX_INPUT"), scope = "transaction", transactionId = id,
    })
end

function ClientService:Cancel(transactionId, reason)
    local record = self:GetPending(transactionId)
    if not record then
        return false
    end
    if record.serverCreated and record.state == "awaiting-input" then
        return sendPayload("EVENT_TX_CANCEL", record.envelope, "WHISPER", currentHostName(currentClientEvent()), {
            opcode = operationCode("EVENT_TX_CANCEL"), scope = "transaction", transactionId = record.id,
        })
    end
    if record.state == "created" or record.state == "awaiting-input" then
        local envelope = clone(record.envelope)
        envelope.state = "cancelled"
        envelope.outcome = { reason = tostring(reason or "cancelled") }
        self:_settle(record, envelope)
        return true
    end
    return sendPayload("EVENT_TX_CANCEL", record.envelope, "WHISPER", currentHostName(currentClientEvent()), {
        opcode = operationCode("EVENT_TX_CANCEL"), scope = "transaction", transactionId = record.id,
    })
end

function ClientService:EndEvent(eventId, reason)
    local normalized = tostring(eventId or "")
    local pending = self.pendingByEventId[normalized] or {}
    local records = {}
    for _, record in pairs(pending) do
        records[#records + 1] = record
    end
    for _, record in ipairs(records) do
        if record.retryTimer and type(record.retryTimer.Cancel) == "function" then
            record.retryTimer:Cancel()
        end
        record.retryTimer = nil
        local terminal = clone(record.envelope)
        terminal.state = "cancelled"
        terminal.outcome = { reason = tostring(reason or "event-ended") }
        terminal.terminalAt = now()
        self:_settle(record, terminal)
    end
    self.pendingByEventId[normalized] = nil
    self.terminalByEventId[normalized] = nil
    self.presentationByEventId[normalized] = nil
    if self.currentEventId == normalized then
        self.currentEventId = nil
    end
end

function ClientService:GetDiagnostics()
    return self.diagnostics
end

function ClientService:GetDiagnosticsSnapshot()
    local pendingCount = 0
    local terminalCount = 0
    for _, pending in pairs(self.pendingByEventId) do
        for _ in pairs(pending) do
            pendingCount = pendingCount + 1
        end
    end
    for _, terminal in pairs(self.terminalByEventId) do
        for _ in pairs(terminal) do
            terminalCount = terminalCount + 1
        end
    end
    return {
        pendingCount = pendingCount,
        terminalCount = terminalCount,
        currentEventId = self.currentEventId,
        diagnostics = self.diagnostics,
    }
end

local ServerService = {}
ServerService.__index = ServerService

function ServerService.new()
    local service = setmetatable({
        currentEventId = nil,
        terminalOrderByEvent = {},
        handlers = {},
        recordsByEvent = {},
        terminalOrder = {},
        diagnostics = {},
        enabled = false,
        counter = 0,
        sessionNonce = tostring(math.random(100000, 999999)),
        MaxTerminalRecords = nil,
    }, ServerService)
    service.ProcessedTransactions = service.recordsByEvent
    service.TerminalTransactions = service.recordsByEvent
    return service
end

function ServerService:IsAuthoritative()
    local eventState = currentServerEvent()
    return self.enabled == true and type(eventState) == "table" and eventState.active == true
end

function ServerService:StartEvent(eventId)
    local normalized = tostring(eventId or "")
    if self.currentEventId and self.currentEventId ~= normalized then
        self:EndEvent(self.currentEventId, "event-replaced")
    end
    self.currentEventId = normalized ~= "" and normalized or nil
    self.enabled = self.currentEventId ~= nil
    if self.currentEventId then
        self.recordsByEvent[self.currentEventId] = self.recordsByEvent[self.currentEventId] or {}
        self.terminalOrderByEvent[self.currentEventId] = self.terminalOrderByEvent[self.currentEventId] or {}
    end
    return self.currentEventId
end

function ServerService:Register(operation, handler)
    if type(operation) ~= "string" or operation == "" or type(handler) ~= "function" then
        return false
    end
    self.handlers[operation] = handler
    return true
end

function ServerService:BeginAwaitingInput(options)
    options = type(options) == "table" and options or {}
    local eventState = currentServerEvent()
    local eventId = tostring(options.eventId or eventIdOf(eventState))
    local inputRecipient = normalizeName(options.inputRecipient or options.defenderName
        or options.targetName or options.recipient or options.awaitingInputFor)
    local originName = normalizeName(options.originName or inputRecipient)
    if not self:IsAuthoritative() or eventId == "" or eventId ~= eventIdOf(eventState) then
        return nil, "stale-event"
    end
    if originName == "" or inputRecipient == "" or tostring(options.operation or "") == "" then
        return nil, "missing-awaiting-input-fields"
    end

    local envelope = normalizeEnvelope({
        protocolVersion = Transactions.ProtocolVersion,
        transactionId = options.transactionId or makeTransactionId(self, originName),
        eventId = eventId,
        operation = options.operation,
        originName = originName,
        actorEventId = options.actorEventId,
        targetEventIds = options.targetEventIds,
        turnNumber = options.turnNumber or eventState.turnNumber,
        tickNumber = options.tickNumber or eventState.tickNumber,
        baseRevision = options.baseRevision or eventState.liveUnitRevision,
        input = options.input ~= nil and options.input or {},
        inputRecipient = inputRecipient,
        state = "awaiting-input",
        deadlineMs = options.deadlineMs or Transactions.DefaultDeadlineMs,
        createdAt = now(),
        stepSensitive = options.stepSensitive == true,
    })
    if envelope.transactionId == "" or #envelope.transactionId > Transactions.MaxIdLength then
        return nil, "invalid-transaction-id"
    end

    local records = self:_records(eventId)
    if records[envelope.transactionId] then
        return nil, "duplicate-transaction-id"
    end
    local record = {
        id = envelope.transactionId,
        eventId = eventId,
        envelope = envelope,
        identityDigest = identityDigestFor(envelope),
        requestDigest = identityDigestFor(envelope),
        state = "created",
        createdAt = envelope.createdAt,
        submittedAt = envelope.createdAt,
        serverCreated = true,
        inputRecipient = inputRecipient,
    }
    records[record.id] = record
    transition(record, "awaiting-input", "server-awaiting-input")
    self:_scheduleTimeout(record)
    recordDiagnostic(self, eventId, {
        transactionId = record.id,
        operation = envelope.operation,
        state = record.state,
        serverCreated = true,
    })
    sendPayload("EVENT_TX_REQUEST", envelope, "WHISPER", inputRecipient, {
        opcode = operationCode("EVENT_TX_REQUEST"),
        scope = "transaction",
        transactionId = record.id,
        eventId = eventId,
    })
    return record
end

ServerService.Create = ServerService.BeginAwaitingInput
ServerService.CreateAwaitingInput = ServerService.BeginAwaitingInput

function ServerService:_records(eventId)
    self.recordsByEvent[eventId] = self.recordsByEvent[eventId] or {}
    return self.recordsByEvent[eventId]
end

function ServerService:_terminalEnvelope(envelope, state, outcome, record)
    local result = normalizeEnvelope(envelope)
    result.state = state
    result.outcome = clone(outcome or {})
    result.requestDigest = record and record.requestDigest or envelope.requestDigest
    result.createdAt = record and record.createdAt or envelope.createdAt
    result.submittedAt = record and record.submittedAt or now()
    result.terminalAt = now()
    result.presentationKey = result.presentationKey or (result.eventId .. ":" .. result.transactionId)
    if record then
        result.newRevision = record.newRevision
        result.authoritativeDelta = clone(record.authoritativeDelta)
        result.deltaRef = record.deltaRef
    end
    return result
end

function ServerService:_publish(envelope, recipient)
    local eventState = currentServerEvent()
    local keyByState = {
        committed = "EVENT_TX_COMMIT",
        rejected = "EVENT_TX_REJECT",
        cancelled = "EVENT_TX_CANCELLED",
        ["timed-out"] = "EVENT_TX_TIMED_OUT",
    }
    local key = keyByState[envelope.state]
    if not key then
        return false
    end
    local metadata = {
        opcode = operationCode(key),
        scope = "transaction",
        transactionId = envelope.transactionId,
        eventId = envelope.eventId,
    }
    if envelope.state == "committed" or envelope.state == "cancelled" then
        return sendToChannel(key, envelope, channelIdFor(eventState), metadata)
    end
    return sendPayload(key, envelope, "WHISPER", recipient or envelope.originName, metadata)
end

function ServerService:_terminalize(record, state, outcome, result)
    if not transition(record, state, outcome and outcome.reason or state) then
        return false
    end
    record.outcome = clone(outcome or {})
    record.newRevision = result and result.newRevision or nil
    record.authoritativeDelta = result and clone(result.authoritativeDelta) or nil
    record.deltaRef = result and result.deltaRef or nil
    record.terminalAt = now()
    if record.timeoutTimer and type(record.timeoutTimer.Cancel) == "function" then
        record.timeoutTimer:Cancel()
    end
    record.timeoutTimer = nil
    local terminal = self:_terminalEnvelope(record.envelope, state, record.outcome, record)
    record.terminal = terminal
    local records = self.recordsByEvent[record.eventId]
    local order = self.terminalOrderByEvent[record.eventId] or {}
    self.terminalOrderByEvent[record.eventId] = order
    if not record.terminalTracked then
        order[#order + 1] = record.id
        record.terminalTracked = true
    end
    local maximum = math.max(1, tonumber(self.MaxTerminalRecords or Transactions.MaxTerminalRecords) or Transactions.MaxTerminalRecords)
    while #order > maximum do
        local oldest = table.remove(order, 1)
        if oldest ~= record.id then
            records[oldest] = nil
        end
    end
    recordDiagnostic(self, record.eventId, {
        transactionId = record.id,
        operation = record.envelope.operation,
        state = state,
        reason = record.outcome.reason,
    })
    self:_publish(terminal, record.serverCreated and record.inputRecipient or record.envelope.originName)
    return true
end

function ServerService:_scheduleTimeout(record)
    local deadlineMs = tonumber(record.envelope.deadlineMs) or Transactions.DefaultDeadlineMs
    record.deadlineAt = record.submittedAt + deadlineMs / 1000
    if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
        record.timeoutTimer = C_Timer.After(deadlineMs / 1000, function()
            self:ProcessTimeouts()
        end)
    end
end

function ServerService:ProcessTimeouts()
    local timedOut = 0
    local current = now()
    for _, records in pairs(self.recordsByEvent) do
        for _, record in pairs(records) do
            if (record.state == "submitted" or record.state == "awaiting-input")
                and record.deadlineAt and current >= record.deadlineAt
            then
                if self:_terminalize(record, "timed-out", { reason = "server-deadline" }) then
                    timedOut = timedOut + 1
                end
            end
        end
    end
    return timedOut
end

function ServerService:_reject(envelope, reason, sender)
    local normalized = normalizeEnvelope(envelope)
    normalized.state = "rejected"
    normalized.outcome = { reason = tostring(reason or "rejected") }
    normalized.terminalAt = now()
    normalized.presentationKey = normalized.eventId .. ":" .. normalized.transactionId
    recordDiagnostic(self, normalized.eventId, {
        transactionId = normalized.transactionId,
        state = "rejected",
        reason = normalized.outcome.reason,
    })
    self:_publish(normalized, sender or normalized.originName)
    return false, normalized.outcome.reason
end

function ServerService:_resolve(record)
    local handler = self.handlers[record.envelope.operation]
    if type(handler) ~= "function" then
        self:_terminalize(record, "rejected", { reason = "unknown-operation" })
        return false, "unknown-operation"
    end
    local ok, result = pcall(handler, clone(record.envelope), {
        server = self,
        record = record,
        eventState = currentServerEvent(),
    })
    if not ok then
        self:_terminalize(record, "rejected", { reason = "handler-error", detail = tostring(result) })
        return false, "handler-error"
    end
    if type(result) ~= "table" or not TERMINAL_STATES[result.state] then
        self:_terminalize(record, "rejected", { reason = "invalid-handler-result" })
        return false, "invalid-handler-result"
    end
    self:_terminalize(record, result.state,
        result.outcome or result.reason and { reason = result.reason } or {}, result)
    return result.state == "committed", result.state
end

function ServerService:_validateServerCreated(envelope, record, sender)
    if envelope.protocolVersion ~= Transactions.ProtocolVersion then
        return false, "unsupported-protocol-version"
    end
    if envelope.transactionId == "" or #envelope.transactionId > Transactions.MaxIdLength then
        return false, "invalid-transaction-id"
    end
    if envelope.eventId == "" or envelope.eventId ~= eventIdOf(currentServerEvent())
        or not self:IsAuthoritative()
    then
        return false, "stale-event"
    end
    if normalizeName(sender) ~= normalizeName(record.inputRecipient) then
        return false, "invalid-input-recipient"
    end
    if identityDigestFor(envelope) ~= record.identityDigest then
        return false, "transaction-id-conflict"
    end
    if envelope.stepSensitive then
        local eventState = currentServerEvent()
        if envelope.turnNumber ~= tonumber(eventState.turnNumber)
            or envelope.tickNumber ~= tonumber(eventState.tickNumber)
        then
            return false, "stale-step"
        end
    end
    return true
end

function ServerService:_validate(envelope, sender)
    if envelope.protocolVersion ~= Transactions.ProtocolVersion then
        return false, "unsupported-protocol-version"
    end
    if envelope.transactionId == "" or #envelope.transactionId > Transactions.MaxIdLength then
        return false, "invalid-transaction-id"
    end
    if envelope.eventId == "" then
        return false, "missing-event-id"
    end
    if envelope.operation == "" then
        return false, "missing-operation"
    end
    if envelope.input == nil then
        return false, "missing-input"
    end
    if envelope.originName == "" or normalizeName(sender) ~= envelope.originName then
        return false, "invalid-origin"
    end
    local sessionState = Addon.Server and Addon.Server.State
    if type(sessionState) == "table" and type(sessionState.clientsByName) == "table"
        and not sessionState.clientsByName[envelope.originName]
    then
        return false, "unknown-origin"
    end
    if envelope.stepSensitive and (envelope.turnNumber == nil or envelope.tickNumber == nil) then
        return false, "missing-step-scope"
    end
    local eventState = currentServerEvent()
    if not self:IsAuthoritative() or envelope.eventId ~= eventIdOf(eventState) then
        return false, "stale-event"
    end
    if envelope.stepSensitive then
        if envelope.turnNumber ~= tonumber(eventState.turnNumber)
            or envelope.tickNumber ~= tonumber(eventState.tickNumber)
        then
            return false, "stale-step"
        end
    end
    return true
end

function ServerService:ReceiveRequest(payload, sender)
    self:Prune()
    local envelope = normalizeEnvelope(decodeEnvelope(payload) or payload)
    local valid, reason = self:_validate(envelope, sender)
    if not valid then
        return self:_reject(envelope, reason, sender)
    end
    local records = self:_records(envelope.eventId)
    local existing = records[envelope.transactionId]
    local digest = digestFor(envelope)
    if existing then
        if existing.requestDigest ~= digest then
            return self:_reject(envelope, "transaction-id-conflict", sender)
        end
        if existing.terminal then
            self:_publish(existing.terminal, sender)
            recordDiagnostic(self, envelope.eventId, {
                transactionId = envelope.transactionId,
                state = existing.state,
                duplicate = true,
                replay = true,
            })
            return true
        end
        recordDiagnostic(self, envelope.eventId, {
            transactionId = envelope.transactionId,
            state = "submitted",
            duplicate = true,
        })
        return true
    end

    envelope.requestDigest = nil
    local record = {
        id = envelope.transactionId,
        eventId = envelope.eventId,
        envelope = envelope,
        requestDigest = digest,
        state = "submitted",
        createdAt = envelope.createdAt or now(),
        submittedAt = now(),
    }
    records[record.id] = record
    self:_scheduleTimeout(record)
    recordDiagnostic(self, record.eventId, {
        transactionId = record.id,
        operation = envelope.operation,
        state = "submitted",
    })

    return self:_resolve(record)
end

function ServerService:ReceiveInput(payload, sender)
    self:Prune()
    local envelope = normalizeEnvelope(decodeEnvelope(payload) or payload)
    local records = self.recordsByEvent[envelope.eventId] or {}
    local record = records[envelope.transactionId]
    if not record or not record.serverCreated then
        return self:ReceiveRequest(envelope, sender)
    end

    local valid, reason = self:_validateServerCreated(envelope, record, sender)
    if not valid then
        return self:_reject(envelope, reason, sender)
    end
    if record.terminal then
        self:_publish(record.terminal, sender)
        recordDiagnostic(self, envelope.eventId, {
            transactionId = envelope.transactionId,
            state = record.state,
            duplicate = true,
            replay = true,
        })
        return true
    end

    local inputDigest = encode(envelope.input)
    if record.state == "submitted" then
        if record.inputDigest == inputDigest then
            return true
        end
        return self:_reject(envelope, "transaction-input-conflict", sender)
    end
    if record.state ~= "awaiting-input" then
        return self:_reject(envelope, "invalid-input-state", sender)
    end

    record.envelope.input = clone(envelope.input)
    record.envelope.submittedAt = now()
    record.envelope.state = "submitted"
    record.inputDigest = inputDigest
    record.submittedAt = now()
    transition(record, "submitted", "client-input")
    recordDiagnostic(self, record.eventId, {
        transactionId = record.id,
        operation = record.envelope.operation,
        state = record.state,
        inputRecipient = sender,
    })
    return self:_resolve(record)
end

function ServerService:ReceiveCancel(payload, sender)
    local envelope = normalizeEnvelope(decodeEnvelope(payload) or payload)
    local records = self.recordsByEvent[envelope.eventId] or {}
    local existing = records[envelope.transactionId]
    if existing and existing.serverCreated then
        local valid, reason = self:_validateServerCreated(envelope, existing, sender)
        if not valid then
            return self:_reject(envelope, reason, sender)
        end
        if existing.terminal then
            self:_publish(existing.terminal, sender)
            return true
        end
        if existing.state == "awaiting-input" or existing.state == "submitted" then
            self:_terminalize(existing, "cancelled", { reason = "client-cancelled" })
            return true
        end
        return self:_reject(envelope, "invalid-cancel-state", sender)
    end
    local valid, reason = self:_validate(envelope, sender)
    if not valid then
        return self:_reject(envelope, reason, sender)
    end
    records = self:_records(envelope.eventId)
    local record = records[envelope.transactionId]
    if record and record.terminal then
        self:_publish(record.terminal, sender)
        return true
    end
    if record then
        self:_terminalize(record, "cancelled", { reason = "client-cancelled" })
        return true
    end
    return self:_reject(envelope, "unknown-transaction", sender)
end

function ServerService:ReceiveStatus(payload, sender)
    local envelope = normalizeEnvelope(decodeEnvelope(payload) or payload)
    local records = self.recordsByEvent[envelope.eventId] or {}
    local record = records[envelope.transactionId]
    if record and record.terminal then
        local metadata = {
            opcode = operationCode("EVENT_TX_STATUS"),
            scope = "transaction",
            transactionId = envelope.transactionId,
        }
        return sendPayload("EVENT_TX_STATUS", record.terminal, "WHISPER", sender, metadata)
    end
    local unknown = normalizeEnvelope(envelope)
    unknown.state = "unknown"
    unknown.outcome = { reason = "unknown-transaction" }
    return sendPayload("EVENT_TX_STATUS", unknown, "WHISPER", sender, {
        opcode = operationCode("EVENT_TX_STATUS"), scope = "transaction", transactionId = envelope.transactionId,
    })
end

function ServerService:EndEvent(eventId, reason)
    local normalized = tostring(eventId or "")
    local records = self.recordsByEvent[normalized] or {}
    for _, record in pairs(records) do
        if not TERMINAL_STATES[record.state] then
            self:_terminalize(record, "cancelled", { reason = tostring(reason or "event-ended") })
        end
    end
    self.recordsByEvent[normalized] = nil
    self.terminalOrderByEvent[normalized] = nil
    if self.currentEventId == normalized then
        self.currentEventId = nil
        self.enabled = false
    end
end

function ServerService:Prune()
    local current = now()
    for eventId, records in pairs(self.recordsByEvent) do
        for transactionId, record in pairs(records) do
            if record.terminal and record.terminalAt
                and current - tonumber(record.terminalAt) > Transactions.TerminalRetentionSeconds
            then
                records[transactionId] = nil
            end
        end
        if next(records) == nil and eventId ~= self.currentEventId then
            self.recordsByEvent[eventId] = nil
        end
    end
end

function ServerService:GetDiagnostics()
    return self.diagnostics
end

function ServerService:GetDiagnosticsSnapshot()
    local processedCount = 0
    local terminalCount = 0
    for _, records in pairs(self.recordsByEvent) do
        for _, record in pairs(records) do
            processedCount = processedCount + 1
            if record.terminal then
                terminalCount = terminalCount + 1
            end
        end
    end
    return {
        processedCount = processedCount,
        terminalCount = terminalCount,
        currentEventId = self.currentEventId,
        diagnostics = self.diagnostics,
    }
end

local function operationHandler(kind, receiver)
    return function(arguments, sender)
        local payload = arguments and arguments[1]
        return receiver(payload, sender, kind)
    end
end

local function allocateOperations()
    local keys = {
        "EVENT_TX_REQUEST",
        "EVENT_TX_INPUT",
        "EVENT_TX_CANCEL",
        "EVENT_TX_COMMIT",
        "EVENT_TX_REJECT",
        "EVENT_TX_CANCELLED",
        "EVENT_TX_TIMED_OUT",
        "EVENT_TX_STATUS_REQUEST",
        "EVENT_TX_STATUS",
    }
    for _, key in ipairs(keys) do
        local operationKey = key
        if not Operations:GetOpcode(operationKey) then
            Operations:Allocate(operationKey, function(arguments, sender)
                local payload = arguments and arguments[1]
                local server = Addon.Server and Addon.Server.EventTransactions
                local client = Addon.Client and Addon.Client.EventTransactions
                if operationKey == "EVENT_TX_REQUEST" then
                    if server and server:IsAuthoritative() then
                        return server:ReceiveRequest(payload, sender)
                    end
                    if client and type(client.ReceiveRequest) == "function" then
                        return client:ReceiveRequest(payload, sender)
                    end
                    return false
                elseif operationKey == "EVENT_TX_INPUT" then
                    if server and server:IsAuthoritative() then
                        if type(server.ReceiveInput) == "function" then
                            return server:ReceiveInput(payload, sender)
                        end
                        return server:ReceiveRequest(payload, sender)
                    end
                    return false
                elseif operationKey == "EVENT_TX_CANCEL" then
                    if server and server:IsAuthoritative() then
                        return server:ReceiveCancel(payload, sender)
                    end
                    return false
                elseif operationKey == "EVENT_TX_STATUS_REQUEST" then
                    if server and server:IsAuthoritative() then
                        return server:ReceiveStatus(payload, sender)
                    end
                    return false
                elseif operationKey == "EVENT_TX_STATUS" then
                    return client and client:ReceiveStatus(payload, sender) or false
                end
                return client and client:ReceiveTerminal(payload, sender) or false
            end, operationKey)
        end
        Transactions.Opcodes = Transactions.Opcodes or {}
        Transactions.Opcodes[operationKey] = Operations:GetOpcode(operationKey)
    end
end

allocateOperations()

Transactions.Encode = encode
Transactions.Decode = decodeEnvelope
Transactions.NormalizeEnvelope = normalizeEnvelope
Transactions.Digest = digestFor
Transactions.IdentityDigest = identityDigestFor
Transactions.IsTerminal = function(state) return TERMINAL_STATES[state] == true end
Transactions.Transition = transition
Transactions.ClientService = ClientService
Transactions.ServerService = ServerService

Addon.Client.EventTransactions = ClientService.new()
Addon.Server.EventTransactions = ServerService.new()
Transactions.Client = Addon.Client.EventTransactions
Transactions.Server = Addon.Server.EventTransactions

return Transactions
