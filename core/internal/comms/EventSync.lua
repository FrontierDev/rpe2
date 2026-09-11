local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Internal.Comms.EventSync = Addon.Internal.Comms.EventSync or {}
Addon.Utils = Addon.Utils or {}

local Comms = Addon.Internal.Comms
local EventSync = Comms.EventSync
local Operations = Comms.Operations or {}

EventSync.ProtocolVersion = 2

local function normalizeNonNegativeInteger(value)
    local numeric = tonumber(value)
    if numeric == nil then
        return nil
    end
    numeric = math.floor(numeric)
    if numeric < 0 then
        return nil
    end
    return numeric
end

function EventSync.NormalizeRevision(value)
    return normalizeNonNegativeInteger(value)
end

function EventSync.NormalizeProtocolVersion(value)
    return normalizeNonNegativeInteger(value)
end

function EventSync.IsProtocolCompatible(value)
    return EventSync.NormalizeProtocolVersion(value) == EventSync.ProtocolVersion
end

-- EventSync payloads may embed existing RPE serializers, many of which use
-- control characters as separators.  Length-prefixed fields therefore form
-- the only framing layer used by this protocol.
function EventSync.EncodeFields(values)
    local encoded = {}
    for index = 1, #(values or {}) do
        local value = values[index]
        local text = value == nil and "" or tostring(value)
        encoded[#encoded + 1] = tostring(#text)
        encoded[#encoded + 1] = ":"
        encoded[#encoded + 1] = text
    end
    return table.concat(encoded)
end

function EventSync.DecodeFields(payload)
    local text = type(payload) == "string" and payload or ""
    local fields = {}
    local position = 1
    local textLength = #text

    while position <= textLength do
        local colon = string.find(text, ":", position, true)
        if not colon then
            return nil, "missing-length-separator"
        end

        local lengthText = string.sub(text, position, colon - 1)
        if lengthText == "" or not string.match(lengthText, "^%d+$") then
            return nil, "invalid-field-length"
        end

        local fieldLength = tonumber(lengthText)
        if fieldLength == nil or fieldLength < 0 then
            return nil, "invalid-field-length"
        end

        local fieldStart = colon + 1
        local fieldEnd = fieldStart + fieldLength - 1
        if fieldEnd > textLength then
            return nil, "truncated-field"
        end

        if fieldLength == 0 then
            fields[#fields + 1] = ""
        else
            fields[#fields + 1] = string.sub(text, fieldStart, fieldEnd)
        end
        position = fieldEnd + 1
    end

    return fields, nil
end

local function normalizeOperation(operation)
    if type(operation) ~= "table" then
        return nil
    end

    local opcode = math.floor(tonumber(operation.opcode) or 0)
    if opcode <= 0 then
        return nil
    end

    return {
        opcode = opcode,
        sender = tostring(operation.sender or ""),
        payload = tostring(operation.payload or ""),
    }
end

function EventSync.SerializeOperation(operation)
    local normalized = normalizeOperation(operation)
    if not normalized then
        return nil
    end

    return EventSync.EncodeFields({
        normalized.opcode,
        normalized.sender,
        normalized.payload,
    })
end

function EventSync.DeserializeOperation(payload)
    local fields, reason = EventSync.DecodeFields(payload)
    if not fields then
        return nil, reason
    end
    if #fields ~= 3 then
        return nil, "invalid-operation-field-count"
    end

    local operation = normalizeOperation({
        opcode = fields[1],
        sender = fields[2],
        payload = fields[3],
    })
    if not operation then
        return nil, "invalid-operation"
    end
    return operation, nil
end

function EventSync.NormalizeOperations(operations)
    local normalized = {}
    for index = 1, #(operations or {}) do
        local operation = normalizeOperation(operations[index])
        if not operation then
            return nil, "invalid-operation:" .. tostring(index)
        end
        normalized[#normalized + 1] = operation
    end
    return normalized, nil
end

function EventSync.SerializeOperationList(operations)
    local normalized, reason = EventSync.NormalizeOperations(operations)
    if not normalized then
        return nil, reason
    end

    local fields = { tostring(#normalized) }
    for index = 1, #normalized do
        local encoded = EventSync.SerializeOperation(normalized[index])
        if not encoded then
            return nil, "operation-serialize-failed:" .. tostring(index)
        end
        fields[#fields + 1] = encoded
    end
    return EventSync.EncodeFields(fields), nil
end

function EventSync.DeserializeOperationList(payload)
    local fields, reason = EventSync.DecodeFields(payload)
    if not fields then
        return nil, reason
    end
    if #fields == 0 then
        return nil, "missing-operation-count"
    end

    local operationCount = normalizeNonNegativeInteger(fields[1])
    if operationCount == nil or #fields ~= operationCount + 1 then
        return nil, "invalid-operation-count"
    end

    local operations = {}
    for index = 1, operationCount do
        local operation, operationReason = EventSync.DeserializeOperation(fields[index + 1])
        if not operation then
            return nil, operationReason or ("invalid-operation:" .. tostring(index))
        end
        operations[#operations + 1] = operation
    end
    return operations, nil
end

function EventSync.SerializeMutationRequest(request)
    if type(request) ~= "table" then
        return nil
    end

    local protocolVersion = EventSync.NormalizeProtocolVersion(request.protocolVersion or EventSync.ProtocolVersion)
    local eventId = tostring(request.eventId or "")
    local channelName = tostring(request.channelName or "")
    local opcode = math.floor(tonumber(request.opcode) or 0)
    if protocolVersion == nil or eventId == "" or channelName == "" or opcode <= 0 then
        return nil
    end

    return EventSync.EncodeFields({
        protocolVersion,
        channelName,
        eventId,
        opcode,
        tostring(request.payload or ""),
    })
end

function EventSync.DeserializeMutationRequest(payload)
    local fields, reason = EventSync.DecodeFields(payload)
    if not fields then
        return nil, reason
    end
    if #fields ~= 5 then
        return nil, "invalid-mutation-request-field-count"
    end

    local protocolVersion = EventSync.NormalizeProtocolVersion(fields[1])
    local opcode = math.floor(tonumber(fields[4]) or 0)
    if protocolVersion == nil or fields[2] == "" or fields[3] == "" or opcode <= 0 then
        return nil, "invalid-mutation-request"
    end

    return {
        protocolVersion = protocolVersion,
        channelName = fields[2],
        eventId = fields[3],
        opcode = opcode,
        payload = fields[5],
    }, nil
end

function EventSync.SerializeMutationCommit(commit)
    if type(commit) ~= "table" then
        return nil
    end

    local protocolVersion = EventSync.NormalizeProtocolVersion(commit.protocolVersion or EventSync.ProtocolVersion)
    local revision = EventSync.NormalizeRevision(commit.revision)
    local channelName = tostring(commit.channelName or "")
    local eventId = tostring(commit.eventId or "")
    local operationsPayload = EventSync.SerializeOperationList(commit.operations or {})
    if protocolVersion == nil or revision == nil or channelName == "" or eventId == "" or not operationsPayload then
        return nil
    end

    return EventSync.EncodeFields({
        protocolVersion,
        channelName,
        eventId,
        revision,
        operationsPayload,
    })
end

function EventSync.DeserializeMutationCommit(payload)
    local fields, reason = EventSync.DecodeFields(payload)
    if not fields then
        return nil, reason
    end
    if #fields ~= 5 then
        return nil, "invalid-mutation-commit-field-count"
    end

    local protocolVersion = EventSync.NormalizeProtocolVersion(fields[1])
    local revision = EventSync.NormalizeRevision(fields[4])
    local operations, operationReason = EventSync.DeserializeOperationList(fields[5])
    if protocolVersion == nil or revision == nil or fields[2] == "" or fields[3] == "" or not operations then
        return nil, operationReason or "invalid-mutation-commit"
    end

    return {
        protocolVersion = protocolVersion,
        channelName = fields[2],
        eventId = fields[3],
        revision = revision,
        operations = operations,
    }, nil
end

function EventSync.SerializeSyncRequest(request)
    if type(request) ~= "table" then
        return nil
    end
    local protocolVersion = EventSync.NormalizeProtocolVersion(request.protocolVersion or EventSync.ProtocolVersion)
    local revision = EventSync.NormalizeRevision(request.appliedRevision or 0)
    local channelName = tostring(request.channelName or "")
    if protocolVersion == nil or revision == nil or channelName == "" then
        return nil
    end
    return EventSync.EncodeFields({
        protocolVersion,
        channelName,
        tostring(request.eventId or ""),
        revision,
        tostring(request.reason or "repair"),
    })
end

function EventSync.DeserializeSyncRequest(payload)
    local fields, reason = EventSync.DecodeFields(payload)
    if not fields then
        return nil, reason
    end
    if #fields ~= 5 then
        return nil, "invalid-sync-request-field-count"
    end
    local protocolVersion = EventSync.NormalizeProtocolVersion(fields[1])
    local revision = EventSync.NormalizeRevision(fields[4])
    if protocolVersion == nil or revision == nil or fields[2] == "" then
        return nil, "invalid-sync-request"
    end
    return {
        protocolVersion = protocolVersion,
        channelName = fields[2],
        eventId = fields[3],
        appliedRevision = revision,
        reason = fields[5],
    }, nil
end

function EventSync.SerializeSyncAck(ack)
    if type(ack) ~= "table" then
        return nil
    end
    local protocolVersion = EventSync.NormalizeProtocolVersion(ack.protocolVersion or EventSync.ProtocolVersion)
    local revision = EventSync.NormalizeRevision(ack.appliedRevision or 0)
    local channelName = tostring(ack.channelName or "")
    local eventId = tostring(ack.eventId or "")
    if protocolVersion == nil or revision == nil or channelName == "" or eventId == "" then
        return nil
    end
    return EventSync.EncodeFields({ protocolVersion, channelName, eventId, revision })
end

function EventSync.DeserializeSyncAck(payload)
    local fields, reason = EventSync.DecodeFields(payload)
    if not fields then
        return nil, reason
    end
    if #fields ~= 4 then
        return nil, "invalid-sync-ack-field-count"
    end
    local protocolVersion = EventSync.NormalizeProtocolVersion(fields[1])
    local revision = EventSync.NormalizeRevision(fields[4])
    if protocolVersion == nil or revision == nil or fields[2] == "" or fields[3] == "" then
        return nil, "invalid-sync-ack"
    end
    return {
        protocolVersion = protocolVersion,
        channelName = fields[2],
        eventId = fields[3],
        appliedRevision = revision,
    }, nil
end

function EventSync.SerializeNamedSections(sections)
    local names = {}
    for name in pairs(type(sections) == "table" and sections or {}) do
        names[#names + 1] = tostring(name)
    end
    table.sort(names)

    local fields = { tostring(#names) }
    for index = 1, #names do
        local name = names[index]
        fields[#fields + 1] = name
        fields[#fields + 1] = tostring(sections[name] or "")
    end
    return EventSync.EncodeFields(fields)
end

function EventSync.DeserializeNamedSections(payload)
    local fields, reason = EventSync.DecodeFields(payload)
    if not fields then
        return nil, reason
    end
    if #fields == 0 then
        return nil, "missing-section-count"
    end

    local count = normalizeNonNegativeInteger(fields[1])
    if count == nil or #fields ~= 1 + (count * 2) then
        return nil, "invalid-section-count"
    end

    local sections = {}
    for index = 1, count do
        local name = fields[(index * 2)]
        local value = fields[(index * 2) + 1]
        if name == "" or sections[name] ~= nil then
            return nil, "invalid-section-name"
        end
        sections[name] = value
    end
    return sections, nil
end

-- Generic snapshot envelope primitives are registered in #234 so #236 can add
-- hydration without changing the framing contract.
function EventSync.SerializeSnapshotEnvelope(snapshot)
    if type(snapshot) ~= "table" then
        return nil
    end
    local protocolVersion = EventSync.NormalizeProtocolVersion(snapshot.protocolVersion or EventSync.ProtocolVersion)
    local revision = EventSync.NormalizeRevision(snapshot.revision or 0)
    local channelName = tostring(snapshot.channelName or "")
    local eventId = tostring(snapshot.eventId or "")
    if protocolVersion == nil or revision == nil or channelName == "" or eventId == "" then
        return nil
    end
    return EventSync.EncodeFields({
        protocolVersion,
        channelName,
        eventId,
        revision,
        EventSync.SerializeNamedSections(snapshot.sections or {}),
    })
end

function EventSync.DeserializeSnapshotEnvelope(payload)
    local fields, reason = EventSync.DecodeFields(payload)
    if not fields then
        return nil, reason
    end
    if #fields ~= 5 then
        return nil, "invalid-snapshot-field-count"
    end
    local protocolVersion = EventSync.NormalizeProtocolVersion(fields[1])
    local revision = EventSync.NormalizeRevision(fields[4])
    local sections, sectionReason = EventSync.DeserializeNamedSections(fields[5])
    if protocolVersion == nil or revision == nil or fields[2] == "" or fields[3] == "" or not sections then
        return nil, sectionReason or "invalid-snapshot"
    end
    return {
        protocolVersion = protocolVersion,
        channelName = fields[2],
        eventId = fields[3],
        revision = revision,
        sections = sections,
    }, nil
end

local function rawPayload(arguments, message)
    if type(message) == "table" and type(message.argumentsText) == "string" then
        return message.argumentsText
    end
    if type(arguments) == "table" then
        return tostring(arguments[1] or "")
    end
    return tostring(arguments or "")
end

local function dispatchTo(targetName, methodName, arguments, sender, distribution, target, message)
    local receiver = Addon[targetName]
    local method = type(receiver) == "table" and receiver[methodName] or nil
    if type(method) ~= "function" then
        return false
    end
    return method(receiver, rawPayload(arguments, message), sender, distribution, target, message)
end

local function installOperation(opcode, key, name, handler)
    Operations.Opcodes = Operations.Opcodes or {}
    Operations.Registry = Operations.Registry or {}
    Operations.KeyIndex = Operations.KeyIndex or {}

    local existing = Operations.Opcodes[opcode]
    if type(existing) == "table" and tostring(existing.key or "") ~= key then
        error(("EventSync opcode %d is already assigned to %s."):format(opcode, tostring(existing.key or "unknown")))
    end

    local definition = existing or {}
    definition.opcode = opcode
    definition.key = key
    definition.name = name
    definition["function"] = handler
    Operations.Opcodes[opcode] = definition
    Operations.Registry[opcode] = definition
    Operations.KeyIndex[string.upper(key)] = opcode
end

installOperation(35, "EVENT_SYNC_REQUEST", "event-sync-request", function(arguments, sender, distribution, target, message)
    return dispatchTo("Server", "HandleEventSyncRequest", arguments, sender, distribution, target, message)
end)
installOperation(36, "EVENT_SYNC_SNAPSHOT", "event-sync-snapshot", function(arguments, sender, distribution, target, message)
    return dispatchTo("Client", "HandleEventSyncSnapshot", arguments, sender, distribution, target, message)
end)
installOperation(37, "EVENT_SYNC_ACK", "event-sync-ack", function(arguments, sender, distribution, target, message)
    return dispatchTo("Server", "HandleEventSyncAck", arguments, sender, distribution, target, message)
end)
installOperation(38, "EVENT_MUTATION_REQUEST", "event-mutation-request", function(arguments, sender, distribution, target, message)
    return dispatchTo("Server", "HandleEventMutationRequest", arguments, sender, distribution, target, message)
end)
installOperation(39, "EVENT_MUTATION_COMMIT", "event-mutation-commit", function(arguments, sender, distribution, target, message)
    return dispatchTo("Client", "HandleCommittedEventMutation", arguments, sender, distribution, target, message)
end)
