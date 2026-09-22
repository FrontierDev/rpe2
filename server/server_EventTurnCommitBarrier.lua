local _, Addon = ...

Addon.Server = Addon.Server or {}

local Server = Addon.Server
local Client = Addon.Client or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local Comms = Addon.Internal and Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}
local Tasks = Addon.Internal and Addon.Internal.Tasks or {}
local OPCODE = type(Operations.GetOpcode) == "function" and Operations:GetOpcode("EVENT_TURN_COMMIT_BARRIER") or nil
local BARRIER_TIMEOUT_MS = 5000

local function normalizeName(name)
    return type(Common.NormalizeName) == "function" and Common.NormalizeName(name) or tostring(name or "")
end

local function nowMilliseconds()
    if type(GetTimePreciseSec) == "function" then return (tonumber(GetTimePreciseSec()) or 0) * 1000 end
    if type(GetTime) == "function" then return (tonumber(GetTime()) or 0) * 1000 end
    return (tonumber(Common.GetNow and Common.GetNow() or 0) or 0) * 1000
end

local function barrierResolved(barrier)
    if barrier.localCommitCompleted ~= true then return false end
    for name in pairs(barrier.expected or {}) do
        if not barrier.acknowledgements[name] then return false end
    end
    return true
end

function Server:RecordEventTurnCommitBarrierAcknowledgement(requestId, sender, status)
    local commit = self.PendingEventAdvanceCommit
    local barrier = type(commit) == "table" and commit.barrier or nil
    local name = normalizeName(sender)
    if type(barrier) ~= "table" or tostring(barrier.requestId) ~= tostring(requestId) or not barrier.expected[name] then return false end
    if barrier.acknowledgements[name] then return true end
    barrier.acknowledgements[name] = tostring(status or "failed")
    return true
end

function Server:HandleEventTurnCommitBarrierAcknowledgement(arguments, sender)
    local eventState = self.GetEventState and self:GetEventState() or nil
    local commit = self.PendingEventAdvanceCommit
    local barrier = type(commit) == "table" and commit.barrier or nil
    if type(eventState) ~= "table" or type(barrier) ~= "table" or type(arguments) ~= "table"
        or tostring(arguments[2] or "") ~= tostring(eventState.id or "")
        or tonumber(arguments[3]) ~= tonumber(barrier.sourceTurnNumber)
        or tonumber(arguments[4]) ~= tonumber(barrier.sourceTickNumber)
        or tostring(arguments[5] or "") ~= tostring(barrier.requestId)
    then return false end
    return self:RecordEventTurnCommitBarrierAcknowledgement(barrier.requestId, sender, arguments[7])
end

function Server:BeginEventTurnCommitBarrier(eventState, clientEventState, sourceTurnNumber, sourceTickNumber)
    local sessionState = self.GetState and self:GetState() or nil
    if type(sessionState) ~= "table" or not OPCODE or type(Tasks.EnqueueSliceable) ~= "function" then return false end

    self.EventAdvanceRequestGeneration = math.max(0, math.floor(tonumber(self.EventAdvanceRequestGeneration) or 0)) + 1
    local requestId = ("%s:%d:%d:%d"):format(tostring(eventState.id), sourceTurnNumber, sourceTickNumber, self.EventAdvanceRequestGeneration)
    local expected = {}
    for index = 1, #(sessionState.clientOrder or {}) do
        local name = normalizeName(sessionState.clientOrder[index])
        if name ~= "" then expected[name] = true end
    end
    local hostName = normalizeName(eventState.hostName)
    if hostName == "" and type(Common.GetPlayerName) == "function" then hostName = normalizeName(Common.GetPlayerName()) end
    if hostName ~= "" then expected[hostName] = true end

    local barrier = {
        requestId = requestId, sourceTurnNumber = sourceTurnNumber, sourceTickNumber = sourceTickNumber,
        expected = expected, acknowledgements = {}, startedAtMs = nowMilliseconds(), timeoutAtMs = nowMilliseconds() + BARRIER_TIMEOUT_MS,
    }
    Client.ForcedTurnCommitBarriers = Client.ForcedTurnCommitBarriers or {}
    local localBarrierRecord = { status = "pending" }
    Client.ForcedTurnCommitBarriers[requestId] = localBarrierRecord
    local commit = Client:BeginPendingTurnCommit(Client.GetState and Client:GetState() or nil, clientEventState, {
        hostAdvancementRequested = true,
        onFinished = function(_, completed)
            localBarrierRecord.status = completed == true and "complete" or "failed"
            barrier.localCommitCompleted = true
            self:RecordEventTurnCommitBarrierAcknowledgement(requestId, hostName, localBarrierRecord.status)
        end,
    })
    if type(commit) ~= "table" then return false end
    commit.serverRequestGeneration = self.EventAdvanceRequestGeneration
    commit.barrier = barrier
    self.PendingEventAdvanceCommit = commit

    local channelId = sessionState.channelId
    if (channelId == nil or channelId == "") and type(Comms.ResolveChannelId) == "function" then channelId = Comms:ResolveChannelId(sessionState.channelName) end
    if channelId then
        Comms:SendToChannel(channelId, OPCODE, { sessionState.channelName, eventState.id, sourceTurnNumber, sourceTickNumber, requestId, "request" }, { opcode = OPCODE, scope = "server" })
    end

    barrier.job = Tasks:EnqueueSliceable({
        label = "event-turn-commit-barrier", scope = "event-turn-barrier:" .. tostring(eventState.id), state = { server = self, commit = commit },
        step = function(work)
            local activeBarrier = work.commit and work.commit.barrier or nil
            if self.PendingEventAdvanceCommit ~= work.commit then return true end
            if barrierResolved(activeBarrier) then return true end
            if nowMilliseconds() >= activeBarrier.timeoutAtMs then
                activeBarrier.timedOut = true
                activeBarrier.failures = {}
                for name in pairs(activeBarrier.expected) do
                    if not activeBarrier.acknowledgements[name] then activeBarrier.failures[#activeBarrier.failures + 1] = name end
                end
                if Addon.Debug and type(Addon.Debug.Warn) == "function" then Addon.Debug.Warn("Event turn commit barrier timed out: %s", table.concat(activeBarrier.failures, ", ")) end
                return true
            end
            return false
        end,
        onComplete = function(work)
            if self.PendingEventAdvanceCommit == work.commit then self:_AdvanceEventStepAfterCommit(work.commit, true) end
        end,
    })
    return barrier.job ~= nil
end
