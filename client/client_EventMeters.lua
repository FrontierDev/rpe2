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
    bucket.turns = type(bucket.turns) == "table" and bucket.turns or {}
    for index = 1, #METER_TYPES do
        local meterType = METER_TYPES[index]
        bucket.total[meterType] = type(bucket.total[meterType]) == "table" and bucket.total[meterType] or {}
    end
    return bucket
end

local function migrateLegacyBucket(bucket)
    if type(bucket) ~= "table" then return ensureMeterMaps({}) end
    if type(bucket.total) == "table" then return ensureMeterMaps(bucket) end
    return ensureMeterMaps({
        total = {
            damage = type(bucket.damage) == "table" and bucket.damage or {},
            healing = type(bucket.healing) == "table" and bucket.healing or {},
            threat = {},
        },
        turns = {},
        currentTurn = normalizePositiveInteger(bucket.currentTurn) or 1,
    })
end

local function ensureEventBucket(self, eventId)
    self.byEventId = self.byEventId or {}
    local bucket = migrateLegacyBucket(self.byEventId[eventId])
    self.byEventId[eventId] = bucket
    return bucket
end

local function ensureTurnBucket(bucket, turnNumber)
    local normalizedTurn = normalizePositiveInteger(turnNumber) or 1
    local turn = bucket.turns[normalizedTurn]
    if type(turn) ~= "table" then turn = {}; bucket.turns[normalizedTurn] = turn end
    for index = 1, #METER_TYPES do
        local meterType = METER_TYPES[index]
        turn[meterType] = type(turn[meterType]) == "table" and turn[meterType] or {}
    end
    bucket.currentTurn = normalizedTurn
    return turn
end

local function getRowsMap(bucket, meterType, scope, turnNumber)
    local source = bucket
    if scope == "turn" then source = bucket.turns[normalizePositiveInteger(turnNumber) or bucket.currentTurn or 1] end
    return type(source) == "table" and source[meterType] or nil
end

local function cloneRows(rows)
    local result = {}
    for _, row in pairs(rows or {}) do
        if type(row) == "table" and (tonumber(row.eventId) or 0) > 0 and (tonumber(row.amount) or 0) > 0 then result[#result + 1] = cloneRow(row) end
    end
    table.sort(result, function(left, right)
        if left.amount ~= right.amount then return left.amount > right.amount end
        return left.eventId < right.eventId
    end)
    return result
end

local function cloneThreatRows(threatRows, targetEventId)
    local result = {}
    local targets = {}
    if targetEventId then
        targets[tonumber(targetEventId)] = threatRows and threatRows[tonumber(targetEventId)] or nil
    else
        targets = threatRows or {}
    end
    for targetId, rows in pairs(targets) do
        local numericTargetId = normalizePositiveInteger(targetId)
        local cloned = cloneRows(rows)
        if numericTargetId and #cloned > 0 then result[#result + 1] = { targetEventId = numericTargetId, rows = cloned } end
    end
    table.sort(result, function(left, right) return left.targetEventId < right.targetEventId end)
    return result
end

local function getCurrentTurn(self, eventId, bucket, options)
    local requested = type(options) == "table" and options.turnNumber or nil
    if normalizePositiveInteger(requested) then return normalizePositiveInteger(requested) end
    local eventState = type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState
    if type(eventState) == "table" and normalizeEventId(eventState.id) == eventId then
        return normalizePositiveInteger(eventState.turnNumber) or bucket.currentTurn or 1
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
    local turnNumber = normalizePositiveInteger(eventState.turnNumber) or bucket.currentTurn or 1
    local turn = ensureTurnBucket(bucket, turnNumber)
    addRow(bucket.total[meterType], sourceUnit, sourceEventId, amount)
    addRow(turn[meterType], sourceUnit, sourceEventId, amount)
    return true
end

function EventMeters:RecordThreatUpdate(eventState, threatUpdate)
    if type(eventState) ~= "table" or eventState.active ~= true or type(threatUpdate) ~= "table" then return false end
    local eventId = normalizeEventId(eventState.id)
    local targetEventId = normalizePositiveInteger(threatUpdate.targetEventId)
    local sourceEventId = normalizePositiveInteger(threatUpdate.sourceEventId)
    local amount = normalizeNonNegativeNumber(threatUpdate.amount)
    local targetUnit = findEventUnit(eventState, targetEventId)
    local sourceUnit = findEventUnit(eventState, sourceEventId)
    if not eventId or not targetEventId or not sourceEventId or amount == nil or amount <= 0
        or type(targetUnit) ~= "table" or targetUnit.isPlayer == true
        or type(sourceUnit) ~= "table" or sourceUnit.isPlayer ~= true then return false end
    local bucket = ensureEventBucket(self, eventId)
    local turnNumber = normalizePositiveInteger(threatUpdate.turnNumber) or normalizePositiveInteger(eventState.turnNumber) or bucket.currentTurn or 1
    local turn = ensureTurnBucket(bucket, turnNumber)
    bucket.total.threat[targetEventId] = bucket.total.threat[targetEventId] or {}
    turn.threat[targetEventId] = turn.threat[targetEventId] or {}
    addRow(bucket.total.threat[targetEventId], sourceUnit, sourceEventId, amount)
    addRow(turn.threat[targetEventId], sourceUnit, sourceEventId, amount)
    return true
end

function EventMeters:GetRows(eventId, meterType, scope, options)
    local normalizedEventId = normalizeEventId(eventId)
    local normalizedMeterType = normalizeMeterType(meterType)
    if not normalizedEventId or not normalizedMeterType then return {} end
    if type(scope) == "table" then options = scope; scope = nil end
    scope = normalizeScope(scope)
    local bucket = type(self.byEventId) == "table" and self.byEventId[normalizedEventId] or nil
    if type(bucket) ~= "table" then return {} end
    bucket = migrateLegacyBucket(bucket)
    self.byEventId[normalizedEventId] = bucket
    local turnNumber = getCurrentTurn(self, normalizedEventId, bucket, options)
    local targetEventId = type(options) == "table" and normalizePositiveInteger(options.targetEventId) or nil
    local rows = getRowsMap(bucket, normalizedMeterType, scope, turnNumber)
    if normalizedMeterType == "threat" then return cloneRows(rows and rows[targetEventId] or nil) end
    return cloneRows(rows)
end

function EventMeters:GetSnapshot(eventId, options)
    local normalizedEventId = normalizeEventId(eventId)
    if not normalizedEventId then return nil end
    local bucket = ensureEventBucket(self, normalizedEventId)
    local currentTurn = getCurrentTurn(self, normalizedEventId, bucket, options)
    local currentTurnGroup = {
        damage = self:GetRows(normalizedEventId, "damage", "turn", { turnNumber = currentTurn }),
        healing = self:GetRows(normalizedEventId, "healing", "turn", { turnNumber = currentTurn }),
        threat = cloneThreatRows(bucket.turns[currentTurn] and bucket.turns[currentTurn].threat),
    }
    return {
        eventId = normalizedEventId,
        currentTurn = currentTurn,
        total = {
            damage = self:GetRows(normalizedEventId, "damage", "total"),
            healing = self:GetRows(normalizedEventId, "healing", "total"),
            threat = cloneThreatRows(bucket.total.threat),
        },
        turn = currentTurnGroup,
        turns = { [currentTurn] = currentTurnGroup },
        damage = self:GetRows(normalizedEventId, "damage", "total"),
        healing = self:GetRows(normalizedEventId, "healing", "total"),
        threat = cloneThreatRows(bucket.total.threat),
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

local function stageThreatRows(target, records, eventState)
    if records == nil then return true end
    if type(records) ~= "table" then return false end
    for index = 1, #records do
        local record = records[index]
        local targetEventId = normalizePositiveInteger(record and record.targetEventId)
        local rows = record and record.rows
        if not targetEventId or type(rows) ~= "table" then return false end
        local targetUnit = findEventUnit(eventState, targetEventId)
        if type(targetUnit) ~= "table" or targetUnit.isPlayer ~= true then
            target[targetEventId] = target[targetEventId] or {}
            if not stageRows(target[targetEventId], rows, eventState) then return false end
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
    local turn = type(snapshot.turn) == "table" and snapshot.turn or nil
    if not turn and type(snapshot.turns) == "table" then turn = snapshot.turns[currentTurn] end
    local stagedTotal = { damage = {}, healing = {}, threat = {} }
    local stagedTurn = { damage = {}, healing = {}, threat = {} }
    local eventState = type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState
    for _, meterType in ipairs({ "damage", "healing" }) do
        local rows = total[meterType]
        if rows == nil and meterType == "healing" then rows = total.heal end
        if not stageRows(stagedTotal[meterType], rows, eventState) then return false end
        if turn and not stageRows(stagedTurn[meterType], turn[meterType], eventState) then return false end
    end
    if not stageThreatRows(stagedTotal.threat, total.threat or snapshot.threat, eventState) then return false end
    if turn and not stageThreatRows(stagedTurn.threat, turn.threat, eventState) then return false end
    if replaceExisting == true then self:ResetEvent(normalizedEventId) end
    local bucket = ensureEventBucket(self, normalizedEventId)
    mergeMaps(bucket.total.damage, stagedTotal.damage, replaceExisting)
    mergeMaps(bucket.total.healing, stagedTotal.healing, replaceExisting)
    for targetEventId, rows in pairs(stagedTotal.threat) do
        bucket.total.threat[targetEventId] = bucket.total.threat[targetEventId] or {}
        mergeMaps(bucket.total.threat[targetEventId], rows, replaceExisting)
    end
    currentTurn = normalizePositiveInteger(snapshot.currentTurn) or bucket.currentTurn or 1
    if turn then
        local turnBucket = ensureTurnBucket(bucket, currentTurn)
        mergeMaps(turnBucket.damage, stagedTurn.damage, replaceExisting)
        mergeMaps(turnBucket.healing, stagedTurn.healing, replaceExisting)
        for targetEventId, rows in pairs(stagedTurn.threat) do
            turnBucket.threat[targetEventId] = turnBucket.threat[targetEventId] or {}
            mergeMaps(turnBucket.threat[targetEventId], rows, replaceExisting)
        end
    else
        bucket.currentTurn = currentTurn
    end
    return true
end

EventMeters.byEventId = EventMeters.byEventId or {}
Client.EventMeters = EventMeters

return true
