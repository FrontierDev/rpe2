local _, Addon = ...

Addon.Client = Addon.Client or {}

local Client = Addon.Client
local EventMeters = Client.EventMeters or {}
local METER_TYPES = { "damage", "healing", "threat" }

local function normalizeEventId(value)
    local eventId = tostring(value or "")
    return eventId ~= "" and eventId or nil
end

local function normalizePositiveInteger(value)
    local number = tonumber(value)
    if number == nil or number ~= math.floor(number) then
        return nil
    end
    number = math.floor(number)
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
    if meterType == "heal" then meterType = "healing" end
    for index = 1, #METER_TYPES do
        if meterType == METER_TYPES[index] then return meterType end
    end
    return nil
end

local function normalizeScope(value)
    local scope = string.lower(tostring(value or "total"))
    if scope == "turn" or scope == "per-turn" or scope == "per turn" then return "turn" end
    return "total"
end

local function findEventUnit(eventState, eventId)
    if type(eventState) ~= "table" then return nil end
    local numericEventId = normalizePositiveInteger(eventId)
    if not numericEventId then return nil end
    for index = 1, #((eventState and eventState.units) or {}) do
        local unit = eventState.units[index]
        if tonumber(unit and unit.eventID) == numericEventId then return unit end
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

local function ensureMeterMaps(bucket)
    bucket.total = type(bucket.total) == "table" and bucket.total or {}
    for _, meterType in ipairs({ "damage", "healing" }) do
        bucket.total[meterType] = type(bucket.total[meterType]) == "table" and bucket.total[meterType] or {}
    end
    -- Older clients kept redundant per-turn ledgers. Totals are now authoritative.
    bucket.total.threat = nil
    bucket.turns = nil
    bucket.currentTurn = normalizePositiveInteger(bucket.currentTurn) or 1
    return bucket
end

local function migrateLegacyBucket(bucket)
    if type(bucket) ~= "table" then return ensureMeterMaps({}) end
    if type(bucket.total) == "table" then return ensureMeterMaps(bucket) end
    return ensureMeterMaps({
        total = {
            damage = type(bucket.damage) == "table" and bucket.damage or {},
            healing = type(bucket.healing) == "table" and bucket.healing or {},
        },
        currentTurn = normalizePositiveInteger(bucket.currentTurn) or 1,
    })
end

local function ensureEventBucket(self, eventId)
    self.byEventId = self.byEventId or {}
    local bucket = migrateLegacyBucket(self.byEventId[eventId])
    self.byEventId[eventId] = bucket
    return bucket
end

local function getRowsMap(bucket, meterType)
    local total = type(bucket) == "table" and bucket.total or nil
    return type(total) == "table" and total[meterType] or nil
end

local function cloneRows(rows, divisor)
    local result = {}
    divisor = math.max(1, tonumber(divisor) or 1)
    for _, row in pairs(rows or {}) do
        if type(row) == "table" and (tonumber(row.eventId) or 0) > 0 and (tonumber(row.amount) or 0) > 0 then result[#result + 1] = cloneRow(row) end
    end
    if divisor ~= 1 then
        for index = 1, #result do
            result[index].amount = result[index].amount / divisor
        end
    end
    table.sort(result, function(left, right)
        if left.amount ~= right.amount then return left.amount > right.amount end
        return left.eventId < right.eventId
    end)
    return result
end

local function buildThreatRows(eventState, targetEventId)
    local targetUnit = findEventUnit(eventState, targetEventId)
    if type(targetUnit) ~= "table" or targetUnit.isPlayer == true then
        return {}
    end

    local rows = {}
    for sourceEventId, amount in pairs(type(targetUnit.threatTable) == "table" and targetUnit.threatTable or {}) do
        local numericSourceEventId = normalizePositiveInteger(sourceEventId)
        local numericAmount = normalizeNonNegativeNumber(amount)
        local sourceUnit = findEventUnit(eventState, numericSourceEventId)
        if numericSourceEventId and numericAmount and numericAmount > 0
            and type(sourceUnit) == "table" and sourceUnit.isPlayer == true
        then
            rows[numericSourceEventId] = {
                eventId = numericSourceEventId,
                name = tostring(sourceUnit.name or "Unknown"),
                team = tonumber(sourceUnit.team) or 0,
                amount = numericAmount,
            }
        end
    end
    return cloneRows(rows)
end

local function getTurnCount(self, eventId, bucket, options)
    local requested = type(options) == "table"
        and (options.turnCount or options.turnNumber or options.currentTurn)
        or nil
    if normalizePositiveInteger(requested) then return normalizePositiveInteger(requested) end
    local eventState = type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState
    if type(eventState) == "table" and normalizeEventId(eventState.id) == eventId then
        return normalizePositiveInteger(eventState.turnNumber)
            or normalizePositiveInteger(eventState.turnCount)
            or bucket.currentTurn
            or 1
    end
    return bucket.currentTurn or 1
end

local function addRow(rows, sourceUnit, sourceEventId, amount)
    local row = rows[sourceEventId]
    if type(row) ~= "table" then row = { eventId = sourceEventId, name = "Unknown", team = 0, amount = 0 }; rows[sourceEventId] = row end
    local name = tostring(sourceUnit and sourceUnit.name or "")
    if name ~= "" then row.name = name end
    local team = tonumber(sourceUnit and sourceUnit.team)
    if team then row.team = math.floor(team) end
    row.amount = math.max(0, tonumber(row.amount) or 0) + amount
end

function EventMeters:ResetEvent(eventId)
    local normalizedEventId = normalizeEventId(eventId)
    if not normalizedEventId or type(self.byEventId) ~= "table" then return false end
    local existed = self.byEventId[normalizedEventId] ~= nil
    self.byEventId[normalizedEventId] = nil
    return existed
end

function EventMeters:ClearAll()
    self.byEventId = {}
    return true
end

function EventMeters:RecordCombatLogEntry(entry, eventState)
    if type(entry) ~= "table" or type(eventState) ~= "table" or eventState.active ~= true then return false end
    local eventId = normalizeEventId(entry.eventId)
    if not eventId or eventId ~= normalizeEventId(eventState.id) then return false end
    local meterType = normalizeMeterType(entry.entryType)
    local sourceEventId = normalizePositiveInteger(entry.casterEventId)
    local amount = normalizePositiveInteger(entry.meterAmount)
    local sourceUnit = findEventUnit(eventState, sourceEventId)
    if meterType == "threat" or not meterType or not sourceEventId or not amount or type(sourceUnit) ~= "table" or sourceUnit.isPlayer ~= true then return false end
    local bucket = ensureEventBucket(self, eventId)
    addRow(bucket.total[meterType], sourceUnit, sourceEventId, amount)
    bucket.currentTurn = normalizePositiveInteger(eventState.turnNumber) or bucket.currentTurn or 1
    return true
end

function EventMeters:GetRows(eventId, meterType, scope, options)
    local normalizedEventId = normalizeEventId(eventId)
    local normalizedMeterType = normalizeMeterType(meterType)
    if not normalizedEventId or not normalizedMeterType then return {} end
    if type(scope) == "table" then options = scope; scope = nil end
    scope = normalizeScope(scope)
    if normalizedMeterType == "threat" then
        local eventState = type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState
        local targetEventId = type(options) == "table" and normalizePositiveInteger(options.targetEventId) or nil
        if type(eventState) ~= "table" or normalizeEventId(eventState.id) ~= normalizedEventId or not targetEventId then
            return {}
        end
        return buildThreatRows(eventState, targetEventId)
    end
    local bucket = type(self.byEventId) == "table" and self.byEventId[normalizedEventId] or nil
    if type(bucket) ~= "table" then return {} end
    bucket = migrateLegacyBucket(bucket)
    self.byEventId[normalizedEventId] = bucket
    local turnCount = getTurnCount(self, normalizedEventId, bucket, options)
    local rows = getRowsMap(bucket, normalizedMeterType)
    return cloneRows(rows, scope == "turn" and turnCount or 1)
end

function EventMeters:GetThreatRows(eventState, targetEventId)
    return buildThreatRows(eventState, targetEventId)
end

function EventMeters:GetSnapshot(eventId, options)
    local normalizedEventId = normalizeEventId(eventId)
    if not normalizedEventId then return nil end
    local bucket = ensureEventBucket(self, normalizedEventId)
    local currentTurn = getTurnCount(self, normalizedEventId, bucket, options)
    return {
        eventId = normalizedEventId,
        currentTurn = currentTurn,
        total = {
            damage = self:GetRows(normalizedEventId, "damage", "total"),
            healing = self:GetRows(normalizedEventId, "healing", "total"),
        },
        damage = self:GetRows(normalizedEventId, "damage", "total"),
        healing = self:GetRows(normalizedEventId, "healing", "total"),
    }
end

local function stageRows(target, rows, eventState)
    if rows == nil then return true end
    if type(rows) ~= "table" then return false end
    for index = 1, #rows do
        local incoming = rows[index]
        local sourceEventId = normalizePositiveInteger(incoming and incoming.eventId)
        local amount = normalizeNonNegativeNumber(incoming and incoming.amount)
        if type(incoming) ~= "table" or not sourceEventId or amount == nil then return false end
        if incoming.team ~= nil and normalizeNonNegativeNumber(incoming.team) == nil then return false end
        local sourceUnit = findEventUnit(eventState, sourceEventId)
        if type(sourceUnit) ~= "table" or sourceUnit.isPlayer == true then
            target[sourceEventId] = { eventId = sourceEventId, name = tostring(incoming.name or "Unknown"), team = math.floor(tonumber(incoming.team) or 0), amount = amount }
        end
    end
    return true
end

local function mergeMaps(destination, staged, replaceExisting)
    for sourceEventId, row in pairs(staged or {}) do
        if replaceExisting ~= true and type(destination[sourceEventId]) == "table" then row.amount = math.max(tonumber(destination[sourceEventId].amount) or 0, row.amount) end
        destination[sourceEventId] = row
    end
end

function EventMeters:InstallSnapshot(eventId, snapshot, replaceExisting)
    local normalizedEventId = normalizeEventId(eventId)
    if not normalizedEventId or type(snapshot) ~= "table" then return false end
    local total = type(snapshot.total) == "table" and snapshot.total or snapshot
    local currentTurn = normalizePositiveInteger(snapshot.currentTurn) or 1
    local stagedTotal = { damage = {}, healing = {} }
    local eventState = type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState
    for _, meterType in ipairs({ "damage", "healing" }) do
        local rows = total[meterType]
        if rows == nil and meterType == "healing" then rows = total.heal end
        if not stageRows(stagedTotal[meterType], rows, eventState) then return false end
    end
    if replaceExisting == true then self:ResetEvent(normalizedEventId) end
    local bucket = ensureEventBucket(self, normalizedEventId)
    mergeMaps(bucket.total.damage, stagedTotal.damage, replaceExisting)
    mergeMaps(bucket.total.healing, stagedTotal.healing, replaceExisting)
    currentTurn = normalizePositiveInteger(snapshot.currentTurn) or bucket.currentTurn or 1
    bucket.currentTurn = currentTurn
    return true
end

EventMeters.byEventId = EventMeters.byEventId or {}
Client.EventMeters = EventMeters

return true
