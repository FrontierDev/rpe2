local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Utils = Addon.Utils or {}

local Common = Addon.Utils.Common or {}
local ThreatUpdates = Addon.Internal.Comms.ThreatUpdates or {}
Addon.Internal.Comms.ThreatUpdates = ThreatUpdates

-- These separators are deliberately distinct from Serialization.ArgumentSeparator
-- (char(31)). Threat updates are nested inside serialized comms arguments.
ThreatUpdates.RecordSeparator = string.char(30)
ThreatUpdates.FieldSeparator = string.char(29)

local function splitPreservingEmpty(text, separator)
    if type(Common.SplitPreservingEmpty) == "function" then
        return Common.SplitPreservingEmpty(text, separator)
    end

    local values = {}
    local startIndex = 1
    while true do
        local separatorIndex = string.find(text, separator, startIndex, true)
        if not separatorIndex then
            values[#values + 1] = string.sub(text, startIndex)
            return values
        end
        values[#values + 1] = string.sub(text, startIndex, separatorIndex - 1)
        startIndex = separatorIndex + #separator
    end
end

local function normalizePositiveInteger(value)
    local number = tonumber(value)
    if number == nil or number ~= math.floor(number) then
        return nil
    end
    number = math.floor(number)
    return number > 0 and number or nil
end

local function normalizePositiveNumber(value)
    local number = tonumber(value)
    if number == nil or number ~= number or number == math.huge or number == -math.huge or number <= 0 then
        return nil
    end
    return number
end

local function normalizeUpdate(update)
    if type(update) ~= "table" then
        return nil, "record is not a table"
    end

    local targetEventId = normalizePositiveInteger(update.targetEventId)
    local sourceEventId = normalizePositiveInteger(update.sourceEventId)
    local amount = normalizePositiveNumber(update.amount)
    local turnValue = update.turnNumber
    local turnNumber = nil
    if turnValue ~= nil and turnValue ~= "" then
        turnNumber = normalizePositiveInteger(turnValue)
    end
    if not targetEventId then return nil, "target event id is invalid" end
    if not sourceEventId then return nil, "source event id is invalid" end
    if not amount then return nil, "amount is invalid" end
    if turnValue ~= nil and turnValue ~= "" and not turnNumber then return nil, "turn number is invalid" end

    return {
        targetEventId = targetEventId,
        sourceEventId = sourceEventId,
        amount = amount,
        turnNumber = turnNumber,
    }
end

function ThreatUpdates:Serialize(updates)
    if type(updates) ~= "table" then
        return nil, "updates must be a table"
    end

    local records = {}
    for index = 1, #updates do
        local update, reason = normalizeUpdate(updates[index])
        if not update then
            return nil, ("record %d: %s"):format(index, reason)
        end
        records[#records + 1] = table.concat({
            tostring(update.targetEventId),
            tostring(update.sourceEventId),
            tostring(update.amount),
            tostring(update.turnNumber or 0),
        }, self.FieldSeparator)
    end
    return table.concat(records, self.RecordSeparator)
end

function ThreatUpdates:Deserialize(payload)
    if type(payload) ~= "string" then
        return nil, "payload must be a string"
    end
    if payload == "" then
        return {}
    end

    local updates = {}
    local records = splitPreservingEmpty(payload, self.RecordSeparator)
    for index = 1, #records do
        local fields = splitPreservingEmpty(records[index], self.FieldSeparator)
        if #fields ~= 4 then
            return nil, ("record %d has %d fields; expected 4"):format(index, #fields)
        end
        local update, reason = normalizeUpdate({
            targetEventId = fields[1],
            sourceEventId = fields[2],
            amount = fields[3],
            turnNumber = fields[4] == "0" and nil or fields[4],
        })
        if not update then
            return nil, ("record %d: %s"):format(index, reason)
        end
        updates[#updates + 1] = update
    end
    return updates
end

return true
