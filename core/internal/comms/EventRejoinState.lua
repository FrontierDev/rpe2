local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Internal.Comms.EventRejoinState = Addon.Internal.Comms.EventRejoinState or {}

local Comms = Addon.Internal.Comms
local EventRejoinState = Comms.EventRejoinState
local Operations = Comms.Operations or {}

EventRejoinState.ProtocolVersion = 4
EventRejoinState.Opcode = 31

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

local function normalizePositiveInteger(value)
    local numeric = tonumber(value)
    if numeric == nil then
        return nil
    end
    if numeric ~= math.floor(numeric) then
        return nil
    end
    numeric = math.floor(numeric)
    return numeric > 0 and numeric or nil
end

local function normalizeNonNegativeNumber(value)
    local numeric = tonumber(value)
    if numeric == nil or numeric ~= numeric or numeric == math.huge or numeric == -math.huge or numeric < 0 then
        return nil
    end
    return numeric
end

local function encodeFields(values)
    local parts = {}
    for index = 1, #(values or {}) do
        local text = values[index] == nil and "" or tostring(values[index])
        parts[#parts + 1] = tostring(#text)
        parts[#parts + 1] = ":"
        parts[#parts + 1] = text
    end
    return table.concat(parts)
end

local function decodeFields(payload)
    local text = type(payload) == "string" and payload or ""
    local fields = {}
    local position = 1
    while position <= #text do
        local colon = string.find(text, ":", position, true)
        if not colon then
            return nil, "missing-length-separator"
        end
        local lengthText = string.sub(text, position, colon - 1)
        if lengthText == "" or not string.match(lengthText, "^%d+$") then
            return nil, "invalid-field-length"
        end
        local fieldLength = tonumber(lengthText)
        local fieldStart = colon + 1
        local fieldEnd = fieldStart + fieldLength - 1
        if fieldEnd > #text then
            return nil, "truncated-field"
        end
        fields[#fields + 1] = fieldLength == 0 and "" or string.sub(text, fieldStart, fieldEnd)
        position = fieldEnd + 1
    end
    return fields, nil
end

local function toHex(text)
    return (string.gsub(tostring(text or ""), ".", function(character)
        return string.format("%02X", string.byte(character))
    end))
end

local function fromHex(text)
    local encoded = tostring(text or "")
    if (#encoded % 2) ~= 0 or not string.match(encoded, "^[0-9A-Fa-f]*$") then
        return nil
    end
    return (string.gsub(encoded, "(%x%x)", function(pair)
        return string.char(tonumber(pair, 16))
    end))
end

local function serializeNumberList(values)
    local normalized = {}
    for index = 1, #(values or {}) do
        local numeric = math.floor(tonumber(values[index]) or 0)
        if numeric > 0 then
            normalized[#normalized + 1] = tostring(numeric)
        end
    end
    return table.concat(normalized, ",")
end

local function deserializeNumberList(text)
    local values = {}
    local source = tostring(text or "")
    if source == "" then
        return values
    end
    for token in string.gmatch(source, "[^,]+") do
        local numeric = math.floor(tonumber(token) or 0)
        if numeric > 0 then
            values[#values + 1] = numeric
        end
    end
    return values
end

local function serializeScalarNumberList(values)
    local normalized = {}
    for index = 1, #(values or {}) do
        local numeric = tonumber(values[index])
        normalized[#normalized + 1] = numeric ~= nil and tostring(numeric) or ""
    end
    return table.concat(normalized, ",")
end

local function deserializeScalarNumberList(text)
    local values = {}
    local source = tostring(text or "")
    if source == "" then
        return values
    end
    local startIndex = 1
    while true do
        local separatorIndex = string.find(source, ",", startIndex, true)
        local token = separatorIndex and string.sub(source, startIndex, separatorIndex - 1) or string.sub(source, startIndex)
        values[#values + 1] = token ~= "" and tonumber(token) or nil
        if not separatorIndex then
            break
        end
        startIndex = separatorIndex + 1
    end
    return values
end

local function serializeAuraRuntimeStates(effectState)
    local records = {}
    for effectIndex, state in pairs(type(effectState) == "table" and effectState or {}) do
        if type(state) == "table" and state.kind == "absorb" then
            local maximum = math.max(0, tonumber(state.maximum) or 0)
            local remaining = math.max(0, math.min(maximum, tonumber(state.remaining) or 0))
            records[#records + 1] = encodeFields({
                math.floor(tonumber(effectIndex) or 0),
                maximum,
                remaining,
                math.max(0, math.floor(tonumber(state.revision) or 0)),
            })
        end
    end
    table.sort(records)
    return encodeFields({ tostring(#records), encodeFields(records) })
end

local function deserializeAuraRuntimeStates(payload)
    local fields = decodeFields(payload)
    if type(fields) ~= "table" or #fields ~= 2 then
        return {}
    end
    local count = normalizeNonNegativeInteger(fields[1]) or 0
    local states = {}
    local records = decodeFields(fields[2]) or {}
    for index = 1, count do
        local record = decodeFields(records[index])
        if type(record) ~= "table" or #record < 1 then
            break
        end
        local effectIndex = math.floor(tonumber(record[1]) or 0)
        if effectIndex > 0 then
            local maximum = math.max(0, tonumber(record[2]) or 0)
            states[effectIndex] = {
                kind = "absorb",
                maximum = maximum,
                remaining = math.max(0, math.min(maximum, tonumber(record[3]) or 0)),
                revision = math.max(0, math.floor(tonumber(record[4]) or 0)),
            }
        end
    end
    return states
end

local function serializeTargetSelections(targetSelections, targetSelectionOrder)
    local keys = {}
    local seen = {}
    for index = 1, #(targetSelectionOrder or {}) do
        local key = tostring(targetSelectionOrder[index] or "")
        if key ~= "" and not seen[key] then
            seen[key] = true
            keys[#keys + 1] = key
        end
    end
    for key in pairs(type(targetSelections) == "table" and targetSelections or {}) do
        local normalized = tostring(key or "")
        if normalized ~= "" and not seen[normalized] then
            seen[normalized] = true
            keys[#keys + 1] = normalized
        end
    end
    if #(targetSelectionOrder or {}) == 0 then
        table.sort(keys)
    end

    local fields = { tostring(#keys) }
    for index = 1, #keys do
        local key = keys[index]
        local selection = type(targetSelections) == "table" and targetSelections[key] or nil
        fields[#fields + 1] = encodeFields({
            key,
            serializeNumberList(type(selection) == "table" and selection.targetEventIds or nil),
            math.floor(tonumber(type(selection) == "table" and selection.focusedTargetEventId or 0) or 0),
        })
    end
    return encodeFields(fields)
end

local function deserializeTargetSelections(payload)
    local fields = decodeFields(payload)
    if type(fields) ~= "table" or #fields == 0 then
        return {}, {}
    end
    local count = normalizeNonNegativeInteger(fields[1]) or 0
    if #fields ~= count + 1 then
        return {}, {}
    end
    local selections = {}
    local order = {}
    for index = 1, count do
        local record = decodeFields(fields[index + 1])
        if type(record) == "table" and #record == 3 and record[1] ~= "" then
            local key = record[1]
            selections[key] = {
                groupKey = key,
                targetEventIds = deserializeNumberList(record[2]),
                focusedTargetEventId = math.floor(tonumber(record[3]) or 0),
            }
            order[#order + 1] = key
        end
    end
    return selections, order
end

local function serializeAuraRecord(entry)
    return encodeFields({
        math.floor(tonumber(entry and entry.casterEventId) or 0),
        math.floor(tonumber(entry and entry.targetEventId) or 0),
        tostring(entry and entry.auraRef or ""),
        math.max(1, math.floor(tonumber(entry and entry.stacks) or 1)),
        math.max(1, math.floor(tonumber(entry and entry.turnsRemaining) or 1)),
        tonumber(entry and entry.powerLevel) or 0,
        serializeAuraRuntimeStates(entry and entry.effectState),
    })
end

local function deserializeAuraRecord(payload)
    local fields = decodeFields(payload)
    if type(fields) ~= "table" or (#fields ~= 6 and #fields ~= 7) then
        return nil
    end
    local casterEventId = math.floor(tonumber(fields[1]) or 0)
    local targetEventId = math.floor(tonumber(fields[2]) or 0)
    local auraRef = tostring(fields[3] or "")
    if casterEventId <= 0 or targetEventId <= 0 or auraRef == "" then
        return nil
    end
    return {
        casterEventId = casterEventId,
        targetEventId = targetEventId,
        auraRef = auraRef,
        stacks = math.max(1, math.floor(tonumber(fields[4]) or 1)),
        turnsRemaining = math.max(1, math.floor(tonumber(fields[5]) or 1)),
        powerLevel = tonumber(fields[6]) or 0,
        effectState = #fields >= 7 and deserializeAuraRuntimeStates(fields[7]) or {},
    }
end

local function serializeCastRecord(entry)
    return encodeFields({
        math.floor(tonumber(entry and entry.casterEventId) or 0),
        tostring(entry and entry.spellRef or ""),
        tostring(entry and entry.authorityType or ""),
        math.max(0, math.floor(tonumber(entry and entry.turnsTotal) or 0)),
        math.max(1, math.floor(tonumber(entry and entry.startedOnTurnNumber) or 1)),
        math.max(1, math.floor(tonumber(entry and entry.completeOnTurnNumber) or 1)),
        math.max(0, math.floor(tonumber(entry and entry.turnsElapsed) or 0)),
        math.max(1, math.floor(tonumber(entry and entry.lastAdvancedTurnNumber) or 1)),
        serializeTargetSelections(entry and entry.targetSelections, entry and entry.targetSelectionOrder),
        serializeNumberList(entry and entry.targetEventIds),
        math.floor(tonumber(entry and entry.focusedTargetEventId) or 0),
        serializeScalarNumberList(entry and entry.resolvedStartCostAmounts),
    })
end

local function deserializeCastRecord(payload)
    local fields = decodeFields(payload)
    if type(fields) ~= "table" or #fields ~= 12 then
        return nil
    end
    local casterEventId = math.floor(tonumber(fields[1]) or 0)
    local spellRef = tostring(fields[2] or "")
    local authorityType = tostring(fields[3] or "")
    local turnsTotal = math.max(0, math.floor(tonumber(fields[4]) or 0))
    if casterEventId <= 0 or spellRef == "" or turnsTotal <= 0 then
        return nil
    end
    local targetSelections, targetSelectionOrder = deserializeTargetSelections(fields[9])
    return {
        casterEventId = casterEventId,
        spellRef = spellRef,
        authorityType = authorityType,
        turnsTotal = turnsTotal,
        startedOnTurnNumber = math.max(1, math.floor(tonumber(fields[5]) or 1)),
        completeOnTurnNumber = math.max(1, math.floor(tonumber(fields[6]) or 1)),
        turnsElapsed = math.max(0, math.floor(tonumber(fields[7]) or 0)),
        lastAdvancedTurnNumber = math.max(1, math.floor(tonumber(fields[8]) or 1)),
        targetSelections = targetSelections,
        targetSelectionOrder = targetSelectionOrder,
        targetEventIds = deserializeNumberList(fields[10]),
        focusedTargetEventId = math.floor(tonumber(fields[11]) or 0),
        resolvedStartCostAmounts = deserializeScalarNumberList(fields[12]),
    }
end

local function serializeRecordList(records, serializer)
    local fields = { tostring(#(records or {})) }
    for index = 1, #(records or {}) do
        fields[#fields + 1] = serializer(records[index])
    end
    return encodeFields(fields)
end

local function deserializeRecordList(payload, deserializer)
    local fields = decodeFields(payload)
    if type(fields) ~= "table" or #fields == 0 then
        return nil
    end
    local count = normalizeNonNegativeInteger(fields[1])
    if count == nil or #fields ~= count + 1 then
        return nil
    end
    local records = {}
    for index = 1, count do
        local record = deserializer(fields[index + 1])
        if not record then
            return nil
        end
        records[#records + 1] = record
    end
    return records
end

local function serializeMeterRecord(entry)
    return encodeFields({
        math.floor(tonumber(entry and entry.eventId) or 0),
        tonumber(entry and entry.amount) or -1,
        tostring(entry and entry.name or ""),
        entry and entry.team ~= nil and tostring(entry.team) or "",
    })
end

local function deserializeMeterRecord(payload)
    local fields = decodeFields(payload)
    if type(fields) ~= "table" or #fields ~= 4 then
        return nil
    end

    local eventId = normalizePositiveInteger(fields[1])
    local amount = normalizeNonNegativeNumber(fields[2])
    if not eventId or amount == nil then
        return nil
    end

    local name = tostring(fields[3] or "")
    local team = nil
    if tostring(fields[4] or "") ~= "" then
        team = normalizeNonNegativeNumber(fields[4])
        if team == nil then
            return nil
        end
    end

    return {
        eventId = eventId,
        amount = amount,
        name = name ~= "" and name or nil,
        team = team,
    }
end

local function serializeThreatMeterRecords(records)
    local normalized = {}
    for index = 1, #(records or {}) do
        local record = records[index]
        local targetEventId = normalizePositiveInteger(record and record.targetEventId)
        if targetEventId and type(record) == "table" and type(record.rows) == "table" then
            normalized[#normalized + 1] = encodeFields({
                targetEventId,
                serializeRecordList(record.rows, serializeMeterRecord),
            })
        end
    end
    return serializeRecordList(normalized, function(value) return value end)
end

local function deserializeThreatMeterRecords(payload)
    local encoded = deserializeRecordList(payload, function(value) return value end)
    if type(encoded) ~= "table" then
        return nil
    end
    local records = {}
    for index = 1, #encoded do
        local fields = decodeFields(encoded[index])
        if type(fields) ~= "table" or #fields ~= 2 then
            return nil
        end
        local targetEventId = normalizePositiveInteger(fields[1])
        local rows = deserializeRecordList(fields[2], deserializeMeterRecord)
        if not targetEventId or type(rows) ~= "table" then
            return nil
        end
        records[#records + 1] = { targetEventId = targetEventId, rows = rows }
    end
    return records
end

local function serializeMeterGroup(group)
    group = type(group) == "table" and group or {}
    return encodeFields({
        serializeRecordList(group.damage or {}, serializeMeterRecord),
        serializeRecordList(group.healing or {}, serializeMeterRecord),
        serializeThreatMeterRecords(group.threat or {}),
    })
end

local function deserializeMeterGroup(payload)
    local fields = decodeFields(payload)
    if type(fields) ~= "table" or #fields ~= 3 then
        return nil
    end
    local damage = deserializeRecordList(fields[1], deserializeMeterRecord)
    local healing = deserializeRecordList(fields[2], deserializeMeterRecord)
    local threat = deserializeThreatMeterRecords(fields[3])
    if type(damage) ~= "table" or type(healing) ~= "table" or type(threat) ~= "table" then
        return nil
    end
    return { damage = damage, healing = healing, threat = threat }
end

local function serializeMeterSnapshot(snapshot)
    snapshot = type(snapshot) == "table" and snapshot or {}
    return encodeFields({
        normalizePositiveInteger(snapshot.currentTurn) or 1,
        serializeMeterGroup(snapshot.total or snapshot),
    })
end

local function deserializeMeterSnapshot(payload)
    local fields = decodeFields(payload)
    if type(fields) ~= "table" then
        return nil
    end
    -- Protocol 3 snapshots contained only total damage and healing.
    if #fields == 2 then
        local currentTurn = normalizePositiveInteger(fields[1])
        if currentTurn then
            local total = deserializeMeterGroup(fields[2])
            if type(total) ~= "table" then return nil end
            return {
                currentTurn = currentTurn,
                total = total,
                damage = total.damage,
                healing = total.healing,
                threat = total.threat,
            }
        end

        local damage = deserializeRecordList(fields[1], deserializeMeterRecord)
        local healing = deserializeRecordList(fields[2], deserializeMeterRecord)
        if type(damage) ~= "table" or type(healing) ~= "table" then return nil end
        return { currentTurn = 1, total = { damage = damage, healing = healing, threat = {} }, turn = {}, damage = damage, healing = healing }
    end
    if #fields ~= 3 then return nil end
    local currentTurn = normalizePositiveInteger(fields[1])
    local total = deserializeMeterGroup(fields[2])
    local turn = deserializeMeterGroup(fields[3])
    if not currentTurn or type(total) ~= "table" or type(turn) ~= "table" then return nil end
    return {
        currentTurn = currentTurn,
        total = total,
        damage = total.damage,
        healing = total.healing,
        threat = total.threat,
    }
end

function EventRejoinState.SerializeSnapshot(snapshot)
    local body = encodeFields({
        EventRejoinState.ProtocolVersion,
        serializeRecordList(type(snapshot) == "table" and snapshot.auras or {}, serializeAuraRecord),
        serializeRecordList(type(snapshot) == "table" and snapshot.casts or {}, serializeCastRecord),
        serializeMeterSnapshot(type(snapshot) == "table" and snapshot.meters or nil),
    })
    return toHex(body)
end

function EventRejoinState.DeserializeSnapshot(payload)
    local body = fromHex(payload)
    if body == nil then
        return nil, "invalid-hex"
    end
    local fields, reason = decodeFields(body)
    if type(fields) ~= "table" then
        return nil, reason or "invalid-snapshot"
    end
    local protocolVersion = tonumber(fields[1])
    if protocolVersion ~= 1 and protocolVersion ~= 2 and protocolVersion ~= 3 and protocolVersion ~= EventRejoinState.ProtocolVersion then
        return nil, "unsupported-version"
    end
    local expectedFieldCount = protocolVersion >= 3 and 4 or 3
    if #fields ~= expectedFieldCount then
        return nil, "unsupported-version"
    end
    local auras = deserializeRecordList(fields[2], deserializeAuraRecord)
    local casts = deserializeRecordList(fields[3], deserializeCastRecord)
    if type(auras) ~= "table" or type(casts) ~= "table" then
        return nil, "invalid-record-list"
    end
    local meters = {
        damage = {},
        healing = {},
    }
    if protocolVersion >= 3 then
        meters = deserializeMeterSnapshot(fields[4])
        if type(meters) ~= "table" then
            return nil, "invalid-meter-snapshot"
        end
    end

    return {
        protocolVersion = EventRejoinState.ProtocolVersion,
        auras = auras,
        casts = casts,
        meters = meters,
    }, nil
end

local existing = type(Operations.Get) == "function" and Operations:Get(EventRejoinState.Opcode) or nil
if existing and tostring(existing.key or "") ~= "EVENT_REJOIN_STATE" then
    error("EVENT_REJOIN_STATE opcode collision at 31.")
end

local definition = {
    opcode = EventRejoinState.Opcode,
    key = "EVENT_REJOIN_STATE",
    name = "event-rejoin-state",
    ["function"] = function(arguments, sender, distribution, target, message)
        local client = Addon.Client
        if not client or type(client.HandleEventRejoinState) ~= "function" then
            return false
        end
        return client:HandleEventRejoinState(arguments, sender, distribution, target, message)
    end,
}

Operations.Opcodes = Operations.Opcodes or {}
Operations.Registry = Operations.Registry or {}
Operations.KeyIndex = Operations.KeyIndex or {}
Operations.Opcodes[EventRejoinState.Opcode] = definition
Operations.Registry[EventRejoinState.Opcode] = definition
Operations.KeyIndex.EVENT_REJOIN_STATE = EventRejoinState.Opcode
