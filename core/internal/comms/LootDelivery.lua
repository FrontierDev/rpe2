local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Internal.Comms.LootProtocol = Addon.Internal.Comms.LootProtocol or {}

local Comms = Addon.Internal.Comms
local Operations = Comms.Operations or {}
local Protocol = Comms.LootProtocol
local Common = Addon.Utils and Addon.Utils.Common or {}

Protocol.Version = 1
Protocol.DeliveryOpcode = 29
Protocol.ResponseOpcode = 30
Protocol.FieldSeparator = string.char(29)
Protocol.RecordSeparator = string.char(30)

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function splitPreservingEmpty(value, separator)
    if type(Common.SplitPreservingEmpty) == "function" then
        return Common.SplitPreservingEmpty(value, separator)
    end

    local result = {}
    local text = tostring(value or "")
    local startIndex = 1
    while true do
        local separatorIndex = string.find(text, separator, startIndex, true)
        if not separatorIndex then
            result[#result + 1] = string.sub(text, startIndex)
            break
        end
        result[#result + 1] = string.sub(text, startIndex, separatorIndex - 1)
        startIndex = separatorIndex + #separator
    end
    return result
end

local function encodeField(value)
    local text = tostring(value or "")
    local parts = {}
    for index = 1, #text do
        local byte = string.byte(text, index)
        local character = string.char(byte)
        if (byte >= 48 and byte <= 57)
            or (byte >= 65 and byte <= 90)
            or (byte >= 97 and byte <= 122)
            or character == "."
            or character == "_"
            or character == ":"
            or character == "-"
        then
            parts[#parts + 1] = character
        else
            parts[#parts + 1] = ("%%%02X"):format(byte)
        end
    end
    return table.concat(parts)
end

local function decodeField(value)
    local text = tostring(value or "")
    local parts = {}
    local index = 1
    while index <= #text do
        local character = string.sub(text, index, index)
        if character ~= "%" then
            parts[#parts + 1] = character
            index = index + 1
        else
            local hex = string.sub(text, index + 1, index + 2)
            if #hex ~= 2 or not hex:match("^%x%x$") then
                return nil, "invalid-payload"
            end
            parts[#parts + 1] = string.char(tonumber(hex, 16))
            index = index + 3
        end
    end
    return table.concat(parts)
end

Protocol.EncodeField = encodeField
Protocol.DecodeField = decodeField

local function serializeRows(rows, fieldNames)
    if type(rows) ~= "table" then
        return ""
    end

    local records = {}
    for index = 1, #rows do
        local row = rows[index]
        if type(row) ~= "table" then
            return nil, "invalid-payload", { rowIndex = index }
        end
        local fields = {}
        for fieldIndex = 1, #fieldNames do
            fields[fieldIndex] = encodeField(row[fieldNames[fieldIndex]])
        end
        records[#records + 1] = table.concat(fields, Protocol.FieldSeparator)
    end
    return table.concat(records, Protocol.RecordSeparator)
end

local function deserializeRows(text, fieldNames)
    local source = tostring(text or "")
    if source == "" then
        return {}
    end

    local records = splitPreservingEmpty(source, Protocol.RecordSeparator)
    local rows = {}
    for index = 1, #records do
        local fields = splitPreservingEmpty(records[index], Protocol.FieldSeparator)
        if #fields ~= #fieldNames then
            return nil, "invalid-payload", {
                rowIndex = index,
                reason = "field-count",
            }
        end
        local row = {}
        for fieldIndex = 1, #fieldNames do
            local decoded, reason = decodeField(fields[fieldIndex])
            if decoded == nil then
                return nil, reason or "invalid-payload", {
                    rowIndex = index,
                    field = fieldNames[fieldIndex],
                }
            end
            row[fieldNames[fieldIndex]] = decoded
        end
        rows[#rows + 1] = row
    end
    return rows
end

local DELIVERY_REWARD_FIELDS = { "type", "ref", "amount" }
local RESPONSE_REWARD_FIELDS = { "type", "ref", "requestedAmount", "appliedAmount", "reason" }

function Protocol.SerializeRewards(rewards)
    return serializeRows(rewards, DELIVERY_REWARD_FIELDS)
end

function Protocol.DeserializeRewards(text)
    return deserializeRows(text, DELIVERY_REWARD_FIELDS)
end

function Protocol.SerializeResultRewards(rewards)
    return serializeRows(rewards, RESPONSE_REWARD_FIELDS)
end

function Protocol.DeserializeResultRewards(text)
    return deserializeRows(text, RESPONSE_REWARD_FIELDS)
end

function Protocol.BuildDeliveryArguments(payload)
    local values = type(payload) == "table" and payload or {}
    local rewardsText, reason, detail = Protocol.SerializeRewards(values.rewards or {})
    if rewardsText == nil then
        return nil, reason, detail
    end

    return {
        tostring(values.protocolVersion or Protocol.Version),
        encodeField(values.deliveryId),
        encodeField(values.eventSessionId),
        encodeField(values.grantId),
        encodeField(values.recipientName),
        rewardsText,
    }
end

function Protocol.ParseDeliveryArguments(arguments)
    if type(arguments) ~= "table" or #arguments < 6 then
        return nil, "invalid-payload", { reason = "argument-count" }
    end

    local deliveryId, deliveryReason = decodeField(arguments[2])
    local eventSessionId, eventReason = decodeField(arguments[3])
    local grantId, grantReason = decodeField(arguments[4])
    local recipientName, recipientReason = decodeField(arguments[5])
    if deliveryId == nil or eventSessionId == nil or grantId == nil or recipientName == nil then
        return nil, deliveryReason or eventReason or grantReason or recipientReason or "invalid-payload"
    end

    local rewards, reason, detail = Protocol.DeserializeRewards(arguments[6])
    if not rewards then
        return nil, reason, detail
    end

    return {
        protocolVersion = tonumber(arguments[1]),
        deliveryId = deliveryId,
        eventSessionId = eventSessionId,
        grantId = grantId,
        recipientName = recipientName,
        rewards = rewards,
    }
end

function Protocol.BuildResponseArguments(response)
    local values = type(response) == "table" and response or {}
    local rewardsText, reason, detail = Protocol.SerializeResultRewards(values.rewards or {})
    if rewardsText == nil then
        return nil, reason, detail
    end

    return {
        tostring(values.protocolVersion or Protocol.Version),
        encodeField(values.deliveryId),
        values.success == true and "1" or "0",
        encodeField(values.reason),
        rewardsText,
    }
end

function Protocol.ParseResponseArguments(arguments)
    if type(arguments) ~= "table" or #arguments < 5 then
        return nil, "invalid-payload", { reason = "argument-count" }
    end

    local deliveryId, deliveryReason = decodeField(arguments[2])
    local responseReason, reasonReason = decodeField(arguments[4])
    if deliveryId == nil or responseReason == nil then
        return nil, deliveryReason or reasonReason or "invalid-payload"
    end

    local rewards, reason, detail = Protocol.DeserializeResultRewards(arguments[5])
    if not rewards then
        return nil, reason, detail
    end

    return {
        protocolVersion = tonumber(arguments[1]),
        deliveryId = deliveryId,
        success = tostring(arguments[3] or "") == "1",
        reason = responseReason ~= "" and responseReason or nil,
        rewards = rewards,
    }
end

function Protocol.BuildDeliveryFingerprint(payload)
    local arguments, reason, detail = Protocol.BuildDeliveryArguments(payload)
    if not arguments then
        return nil, reason, detail
    end
    return table.concat(arguments, string.char(31))
end

local function installOperation(opcode, key, name, handler)
    Operations.Opcodes = type(Operations.Opcodes) == "table" and Operations.Opcodes or {}
    Operations.KeyIndex = type(Operations.KeyIndex) == "table" and Operations.KeyIndex or {}
    Operations.Registry = type(Operations.Registry) == "table" and Operations.Registry or {}

    local existingKeyOpcode = type(Operations.GetOpcode) == "function" and Operations:GetOpcode(key) or Operations.KeyIndex[key]
    if existingKeyOpcode ~= nil and tonumber(existingKeyOpcode) ~= tonumber(opcode) then
        error(("Loot operation key collision: %s is already opcode %s."):format(key, tostring(existingKeyOpcode)), 2)
    end

    local existingDefinition = Operations.Opcodes[opcode] or (type(Operations.Get) == "function" and Operations:Get(opcode) or nil)
    local existingKey = type(existingDefinition) == "table" and string.upper(tostring(existingDefinition.key or "")) or ""
    if existingKey ~= "" and existingKey ~= key then
        error(("Loot opcode collision: %d is already registered as %s."):format(opcode, existingKey), 2)
    end

    local definition = {
        key = key,
        name = name,
        ["function"] = handler,
    }
    Operations.Opcodes[opcode] = definition
    Operations.KeyIndex[key] = opcode

    if type(Operations.Register) == "function" then
        local operation = Operations:Register(opcode, handler, name)
        if type(operation) == "table" then
            operation.key = key
        end
    else
        definition.opcode = opcode
        Operations.Registry[opcode] = definition
    end

    return opcode
end

installOperation(Protocol.DeliveryOpcode, "LOOT_DELIVERY", "loot-delivery", function(arguments, sender, distribution, target, message)
    local client = Addon.Client
    if type(client) ~= "table" or type(client.HandleLootDelivery) ~= "function" then
        return false
    end
    return client:HandleLootDelivery(arguments, sender, distribution, target, message)
end)

installOperation(Protocol.ResponseOpcode, "LOOT_DELIVERY_RESPONSE", "loot-delivery-response", function(arguments, sender, distribution, target, message)
    local server = Addon.Server
    local loot = type(server) == "table" and server.Loot or nil
    if type(loot) == "table" and type(loot.HandleDeliveryResponse) == "function" then
        return loot:HandleDeliveryResponse(arguments, sender, distribution, target, message)
    end
    if type(server) == "table" and type(server.HandleLootDeliveryResponse) == "function" then
        return server:HandleLootDeliveryResponse(arguments, sender, distribution, target, message)
    end
    return false
end)
