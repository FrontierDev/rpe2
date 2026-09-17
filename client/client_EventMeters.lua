local _, Addon = ...

Addon.Client = Addon.Client or {}

local Client = Addon.Client
local EventMeters = Client.EventMeters or {}

local function normalizeEventId(value)
    local eventId = tostring(value or "")
    return eventId ~= "" and eventId or nil
end

local function normalizePositiveInteger(value)
    local number = math.floor(tonumber(value) or 0)
    return number > 0 and number or nil
end

local function normalizeNonNegativeNumber(value)
    local number = tonumber(value)
    if number == nil or number ~= number or number == math.huge or number == -math.huge or number < 0 then
        return nil
    end
    return number
end

local function normalizeMeterType(value)
    local meterType = string.lower(tostring(value or ""))
    if meterType == "heal" then
        meterType = "healing"
    end
    if meterType ~= "damage" and meterType ~= "healing" then
        return nil
    end
    return meterType
end

local function findEventUnit(eventState, eventId)
    if type(eventState) ~= "table" then
        return nil
    end

    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 then
        return nil
    end

    for index = 1, #((eventState and eventState.units) or {}) do
        local unit = eventState.units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit
        end
    end

    return nil
end

local function cloneRow(row)
    return {
        eventId = tonumber(row and row.eventId) or 0,
        name = tostring(row and row.name or "Unknown"),
        team = tonumber(row and row.team) or 0,
        amount = math.max(0, tonumber(row and row.amount) or 0),
    }
end

local function ensureEventBucket(self, eventId)
    self.byEventId = self.byEventId or {}
    local bucket = self.byEventId[eventId]
    if type(bucket) ~= "table" then
        bucket = {
            damage = {},
            healing = {},
        }
        self.byEventId[eventId] = bucket
    end
    bucket.damage = bucket.damage or {}
    bucket.healing = bucket.healing or {}
    return bucket
end

local function cloneRows(rows)
    local result = {}
    for _, row in pairs(rows or {}) do
        if type(row) == "table" and (tonumber(row.eventId) or 0) > 0 and (tonumber(row.amount) or 0) > 0 then
            result[#result + 1] = cloneRow(row)
        end
    end

    table.sort(result, function(left, right)
        if left.amount ~= right.amount then
            return left.amount > right.amount
        end
        return left.eventId < right.eventId
    end)
    return result
end

function EventMeters:ResetEvent(eventId)
    local normalizedEventId = normalizeEventId(eventId)
    if not normalizedEventId or type(self.byEventId) ~= "table" then
        return false
    end

    local existed = self.byEventId[normalizedEventId] ~= nil
    self.byEventId[normalizedEventId] = nil
    return existed
end

function EventMeters:ClearAll()
    self.byEventId = {}
    return true
end

function EventMeters:RecordCombatLogEntry(entry, eventState)
    if type(entry) ~= "table" or type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    local eventId = normalizeEventId(entry.eventId)
    if not eventId or eventId ~= normalizeEventId(eventState.id) then
        return false
    end

    local meterType = normalizeMeterType(entry.entryType)
    local casterEventId = normalizePositiveInteger(entry.casterEventId)
    local meterAmount = normalizePositiveInteger(entry.meterAmount)
    if not meterType or not casterEventId or not meterAmount then
        return false
    end

    local sourceUnit = findEventUnit(eventState, casterEventId)
    if type(sourceUnit) ~= "table" then
        return false
    end

    local bucket = ensureEventBucket(self, eventId)
    local rows = bucket[meterType]
    local row = rows[casterEventId]
    if type(row) ~= "table" then
        row = {
            eventId = casterEventId,
            name = "Unknown",
            team = 0,
            amount = 0,
        }
        rows[casterEventId] = row
    end

    local name = tostring(sourceUnit.name or "")
    if name ~= "" then
        row.name = name
    end
    local team = tonumber(sourceUnit.team)
    if team then
        row.team = math.floor(team)
    end
    row.amount = math.max(0, tonumber(row.amount) or 0) + meterAmount
    return true
end

function EventMeters:GetRows(eventId, meterType)
    local normalizedEventId = normalizeEventId(eventId)
    local normalizedMeterType = normalizeMeterType(meterType)
    if not normalizedEventId or not normalizedMeterType then
        return {}
    end

    local bucket = type(self.byEventId) == "table" and self.byEventId[normalizedEventId] or nil
    return cloneRows(type(bucket) == "table" and bucket[normalizedMeterType] or nil)
end

function EventMeters:GetSnapshot(eventId)
    local normalizedEventId = normalizeEventId(eventId)
    if not normalizedEventId then
        return nil
    end

    return {
        eventId = normalizedEventId,
        damage = self:GetRows(normalizedEventId, "damage"),
        healing = self:GetRows(normalizedEventId, "healing"),
    }
end

function EventMeters:InstallSnapshot(eventId, snapshot, replaceExisting)
    local normalizedEventId = normalizeEventId(eventId)
    if not normalizedEventId or type(snapshot) ~= "table" then
        return false
    end

    local staged = {
        damage = {},
        healing = {},
    }
    for _, meterType in ipairs({ "damage", "healing" }) do
        local rows = snapshot[meterType]
        if meterType == "healing" and type(rows) ~= "table" then
            rows = snapshot.heal
        end
        if rows ~= nil and type(rows) ~= "table" then
            return false
        end
        for index = 1, #(rows or {}) do
            local incoming = rows[index]
            local casterEventId = normalizePositiveInteger(incoming and incoming.eventId)
            local amount = normalizeNonNegativeNumber(incoming and incoming.amount)
            if type(incoming) ~= "table" or not casterEventId or amount == nil then
                return false
            end
            local team = incoming.team
            if team ~= nil and normalizeNonNegativeNumber(team) == nil then
                return false
            end
            staged[meterType][casterEventId] = {
                eventId = casterEventId,
                name = tostring(incoming.name or "Unknown"),
                team = math.floor(tonumber(team) or 0),
                amount = amount,
            }
        end
    end

    if replaceExisting == true then
        self:ResetEvent(normalizedEventId)
    end

    local bucket = ensureEventBucket(self, normalizedEventId)
    for _, meterType in ipairs({ "damage", "healing" }) do
        for casterEventId, row in pairs(staged[meterType]) do
            if replaceExisting ~= true and type(bucket[meterType][casterEventId]) == "table" then
                local existing = bucket[meterType][casterEventId]
                row.amount = math.max(tonumber(existing.amount) or 0, row.amount)
            end
            bucket[meterType][casterEventId] = row
        end
    end
    return true
end

EventMeters.byEventId = EventMeters.byEventId or {}
Client.EventMeters = EventMeters

return true
