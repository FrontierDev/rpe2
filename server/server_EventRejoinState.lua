local _, Addon = ...

Addon.Server = Addon.Server or {}

local Server = Addon.Server
local Client = Addon.Client or {}
local Comms = Addon.Internal and Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}
local EventRejoinState = Comms.EventRejoinState or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local Debug = Addon.Debug or {}

local EVENT_REJOIN_STATE_OPCODE = type(Operations.GetOpcode) == "function"
    and Operations:GetOpcode("EVENT_REJOIN_STATE")
    or nil

local function normalizeName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end
    return tostring(value or "")
end

local function hasPlayerEventUnit(eventState, clientName)
    local normalizedClientName = normalizeName(clientName)
    if normalizedClientName == "" then
        return false
    end
    for index = 1, #((eventState and eventState.units) or {}) do
        local unit = eventState.units[index]
        if type(unit) == "table" and unit.isPlayer == true then
            local candidate = normalizeName(unit.ownerID or unit.controllerID or unit.name)
            if candidate == normalizedClientName then
                return true
            end
        end
    end
    return false
end

local function buildAuraSnapshot(eventId)
    local records = {}
    local bucket = type(Client.ActiveAurasByEventId) == "table" and Client.ActiveAurasByEventId[eventId] or nil
    local byKey = type(bucket) == "table" and bucket.byKey or nil
    for _, entry in pairs(type(byKey) == "table" and byKey or {}) do
        if type(entry) == "table"
            and tonumber(entry.casterEventId)
            and tonumber(entry.targetEventId)
            and tostring(entry.auraRef or "") ~= ""
            and (tonumber(entry.stacks) or 0) > 0
            and (tonumber(entry.turnsRemaining) or 0) > 0
        then
            records[#records + 1] = entry
        end
    end
    table.sort(records, function(left, right)
        local leftTarget = tonumber(left.targetEventId) or 0
        local rightTarget = tonumber(right.targetEventId) or 0
        if leftTarget ~= rightTarget then
            return leftTarget < rightTarget
        end
        local leftCaster = tonumber(left.casterEventId) or 0
        local rightCaster = tonumber(right.casterEventId) or 0
        if leftCaster ~= rightCaster then
            return leftCaster < rightCaster
        end
        return tostring(left.auraRef or "") < tostring(right.auraRef or "")
    end)
    return records
end

local function buildCastSnapshot(eventId)
    local records = {}
    local bucket = type(Client.ActiveSpellcastsByEventId) == "table" and Client.ActiveSpellcastsByEventId[eventId] or nil
    for _, entry in pairs(type(bucket) == "table" and bucket or {}) do
        if type(entry) == "table"
            and tonumber(entry.casterEventId)
            and tostring(entry.spellRef or "") ~= ""
            and (tonumber(entry.turnsTotal) or 0) > 0
        then
            records[#records + 1] = entry
        end
    end
    table.sort(records, function(left, right)
        return (tonumber(left.casterEventId) or 0) < (tonumber(right.casterEventId) or 0)
    end)
    return records
end

function Server:SendEventRejoinState(clientName, options)
    local eventState = self.EventState
    local normalizedClientName = normalizeName(clientName)
    if type(eventState) ~= "table"
        or eventState.active ~= true
        or normalizedClientName == ""
        or EVENT_REJOIN_STATE_OPCODE == nil
        or type(EventRejoinState.SerializeSnapshot) ~= "function"
        or type(Comms.SendMessage) ~= "function"
    then
        return false
    end

    local eventId = tostring(eventState.id or "")
    local channelName = tostring(eventState.channelName or "")
    if eventId == "" or channelName == "" then
        return false
    end

    local auraRecords = buildAuraSnapshot(eventId)
    local castRecords = buildCastSnapshot(eventId)
    local payload = EventRejoinState.SerializeSnapshot({
        auras = auraRecords,
        casts = castRecords,
    })
    if type(payload) ~= "string" or payload == "" then
        return false
    end

    local mode = type(options) == "table" and options.replaceExisting == true and "replace" or "merge"
    local sent = Comms:SendMessage(
        "WHISPER",
        EVENT_REJOIN_STATE_OPCODE,
        {
            channelName,
            eventId,
            payload,
            mode,
        },
        normalizedClientName,
        {
            opcode = EVENT_REJOIN_STATE_OPCODE,
            scope = "server",
        }
    ) == true

    if type(Debug.Internal) == "function" then
        Debug.Internal(
            "Event rejoin state queued: client=%s event=%s mode=%s auras=%d casts=%d queued=%s.",
            normalizedClientName,
            eventId,
            mode,
            #auraRecords,
            #castRecords,
            tostring(sent)
        )
    end
    return sent
end

if Server.EventRejoinStateReconcileWrapped ~= true and type(Server.ReconcileClientEventSession) == "function" then
    Server.EventRejoinStateReconcileWrapped = true
    local nativeReconcileClientEventSession = Server.ReconcileClientEventSession
    function Server:ReconcileClientEventSession(clientName)
        local eventStateBefore = self.EventState
        local returningPlayer = type(eventStateBefore) == "table"
            and eventStateBefore.active == true
            and hasPlayerEventUnit(eventStateBefore, clientName)
        local reconciled = nativeReconcileClientEventSession(self, clientName)
        local eventState = self.EventState
        if reconciled == true and type(eventState) == "table" and eventState.active == true then
            self:SendEventRejoinState(clientName, {
                replaceExisting = returningPlayer == true,
            })
        end
        return reconciled
    end
end
