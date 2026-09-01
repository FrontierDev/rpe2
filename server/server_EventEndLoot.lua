local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Server = Addon.Server
local Event = Addon.Internal.Database.Classes.Event
local Debug = Addon.Debug or {}
local Common = Addon.Utils and Addon.Utils.Common or {}

Server.Loot = Server.Loot or {}
local Loot = Server.Loot

if type(Server) ~= "table" or type(Event) ~= "table" or Server._eventEndLootIntegrationInstalled == true then
    return
end

local MAX_IDENTIFIER_LENGTH = 192
local DEFAULT_MAX_RETAINED_END_RESULTS = 5

Loot.EventEndResultsBySession = type(Loot.EventEndResultsBySession) == "table" and Loot.EventEndResultsBySession or {}
Loot.EventEndResultOrder = type(Loot.EventEndResultOrder) == "table" and Loot.EventEndResultOrder or {}
Loot.LastEventEndSessionId = tostring(Loot.LastEventEndSessionId or "")

local function deepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy
    for key, nestedValue in pairs(value) do
        copy[key] = deepCopy(nestedValue, seen)
    end
    return copy
end

local function cloneGrants(values)
    if type(Event.CloneEndLootGrants) == "function" then
        return Event.CloneEndLootGrants(values)
    end

    local cloned = {}
    for index = 1, #(type(values) == "table" and values or {}) do
        local source = values[index]
        if type(source) == "table" then
            local copy = {
                sourceType = source.sourceType,
                distribution = source.distribution,
                lootRef = source.lootRef,
            }
            if type(source.reward) == "table" then
                copy.reward = {
                    type = source.reward.type,
                    ref = source.reward.ref,
                    amount = source.reward.amount,
                }
            end
            cloned[#cloned + 1] = copy
        end
    end
    return cloned
end

local function deriveLegacy(values)
    if type(Event.BuildEndLootGrantsFromLegacyRefs) == "function" then
        return Event.BuildEndLootGrantsFromLegacyRefs(values)
    end
    return {}
end

local function chooseStartGrants(server, data)
    local values = type(data) == "table" and data or {}
    if values.endLootGrants ~= nil then
        return cloneGrants(values.endLootGrants)
    end
    if values.lootRefs ~= nil then
        return deriveLegacy(values.lootRefs)
    end

    local draft = server.EventDraftState
    if type(draft) == "table" then
        if draft.endLootGrants ~= nil then
            return cloneGrants(draft.endLootGrants)
        end
        return deriveLegacy(draft.lootRefs)
    end
    return {}
end

local function applyGrants(eventState, grants)
    if type(eventState) ~= "table" then
        return false
    end
    if type(eventState.Merge) == "function" then
        eventState:Merge({ endLootGrants = cloneGrants(grants) })
    else
        eventState.endLootGrants = cloneGrants(grants)
        if type(Event.BuildLegacyLootRefsFromEndLootGrants) == "function" then
            eventState.lootRefs = Event.BuildLegacyLootRefsFromEndLootGrants(eventState.endLootGrants)
        end
    end
    return true
end

local function getNow()
    if type(Common.GetNow) == "function" then
        return math.max(0, math.floor(tonumber(Common.GetNow()) or 0))
    end
    return 0
end

local function buildStableEndGrantId(eventSessionId, grantIndex)
    local normalizedIndex = math.max(1, math.floor(tonumber(grantIndex) or 1))
    local sessionId = tostring(eventSessionId or "")
    local identifier = ("%s:end-loot:%d"):format(sessionId, normalizedIndex)
    if #identifier <= MAX_IDENTIFIER_LENGTH then
        return identifier
    end

    -- ExecuteGrant is keyed by both eventSessionId and grantId, so this shorter
    -- deterministic fallback remains unique within the immutable Event session.
    return ("end-loot:%d"):format(normalizedIndex)
end

local function buildEndSnapshot(eventState)
    if type(eventState) ~= "table" then
        return nil
    end

    local grants = nil
    if eventState.endLootGrants ~= nil then
        grants = cloneGrants(eventState.endLootGrants)
    else
        grants = deriveLegacy(eventState.lootRefs)
    end

    return {
        eventSessionId = tostring(eventState.id or ""),
        hostName = tostring(eventState.hostName or ""),
        units = deepCopy(type(eventState.units) == "table" and eventState.units or {}),
        endLootGrants = grants,
        snapshotAt = getNow(),
    }
end

local function firstExecutionFailureReason(summary)
    for index = 1, #(type(summary) == "table" and summary.deliveries or {}) do
        local reason = tostring(summary.deliveries[index] and summary.deliveries[index].reason or "")
        if reason ~= "" then
            return reason
        end
    end
    return nil
end

local function updateBatchStatus(batch)
    local successful = 0
    local pending = 0
    local failed = 0

    for index = 1, #(type(batch) == "table" and batch.grants or {}) do
        local status = tostring(batch.grants[index] and batch.grants[index].status or "failed")
        if status == "success" then
            successful = successful + 1
        elseif status == "pending" then
            pending = pending + 1
        else
            failed = failed + 1
        end
    end

    batch.successCount = successful
    batch.pendingCount = pending
    batch.failedCount = failed
    batch.grantCount = #(batch.grants or {})

    if batch.grantCount == 0 then
        batch.status = "none"
    elseif failed > 0 and (successful > 0 or pending > 0) then
        batch.status = "partial"
    elseif pending > 0 then
        batch.status = "pending"
    elseif failed > 0 then
        batch.status = "failed"
    else
        batch.status = "success"
    end
    return batch.status
end

local function touchEndResultSession(loot, eventSessionId)
    local sessionId = tostring(eventSessionId or "")
    if sessionId == "" then
        return false
    end

    for index = #loot.EventEndResultOrder, 1, -1 do
        if loot.EventEndResultOrder[index] == sessionId then
            table.remove(loot.EventEndResultOrder, index)
            break
        end
    end
    loot.EventEndResultOrder[#loot.EventEndResultOrder + 1] = sessionId
    loot.LastEventEndSessionId = sessionId

    local maximum = math.max(1, math.floor(tonumber(loot.MaxRetainedSessions) or DEFAULT_MAX_RETAINED_END_RESULTS))
    while #loot.EventEndResultOrder > maximum do
        local oldest = table.remove(loot.EventEndResultOrder, 1)
        loot.EventEndResultsBySession[oldest] = nil
    end
    return true
end

local function rememberEndResult(loot, batch)
    local sessionId = tostring(type(batch) == "table" and batch.eventSessionId or "")
    if sessionId == "" then
        return false
    end

    loot.EventEndResultsBySession[sessionId] = deepCopy(batch)
    touchEndResultSession(loot, sessionId)
    return true
end

function Loot:GetEventEndResult(eventSessionId)
    local sessionId = tostring(eventSessionId or self.LastEventEndSessionId or "")
    local stored = self.EventEndResultsBySession[sessionId]
    if type(stored) ~= "table" then
        return nil
    end

    local result = deepCopy(stored)
    for index = 1, #(result.grants or {}) do
        local grantResult = result.grants[index]
        if type(grantResult) == "table"
            and tostring(grantResult.grantId or "") ~= ""
            and type(self.GetGrantExecutionSummary) == "function"
        then
            local summary = self:GetGrantExecutionSummary(sessionId, grantResult.grantId)
            if type(summary) == "table" then
                grantResult.execution = summary
                grantResult.status = tostring(summary.status or grantResult.status or "pending")
                grantResult.reason = firstExecutionFailureReason(summary)
                grantResult.detail = nil
            end
        end
    end
    updateBatchStatus(result)
    return result
end

function Server:SyncEndLootGrantsToDraft(eventStateOverride)
    local liveState = eventStateOverride or self.EventState
    local draftState = self.EventDraftState
    if type(liveState) ~= "table" or type(draftState) ~= "table" then
        return false
    end
    return applyGrants(draftState, liveState.endLootGrants)
end

function Server:ExecuteEventEndLoot(eventStateOverride)
    local eventState = eventStateOverride or self.EventState
    if type(eventState) ~= "table"
        or eventState ~= self.EventState
        or eventState.active ~= true
    then
        return nil, "event-inactive"
    end

    local snapshot = buildEndSnapshot(eventState)
    if type(snapshot) ~= "table" then
        return nil, "event-snapshot-failed"
    end

    local grants = snapshot.endLootGrants or {}
    if #grants == 0 then
        return {
            eventSessionId = snapshot.eventSessionId,
            hostName = snapshot.hostName,
            source = "event-end",
            snapshotAt = snapshot.snapshotAt,
            eligiblePlayers = {},
            grants = {},
            grantCount = 0,
            successCount = 0,
            pendingCount = 0,
            failedCount = 0,
            status = "none",
        }
    end

    local loot = self.Loot
    local batch = {
        eventSessionId = snapshot.eventSessionId,
        hostName = snapshot.hostName,
        source = "event-end",
        snapshotAt = snapshot.snapshotAt,
        eligiblePlayers = {},
        grants = {},
    }

    local eligiblePlayers = nil
    local eligibilityReason = nil
    local eligibilityDetail = nil
    if type(loot) == "table" and type(loot.GetEligiblePlayers) == "function" then
        eligiblePlayers, eligibilityReason, eligibilityDetail = loot:GetEligiblePlayers({
            units = snapshot.units,
        })
    else
        eligibilityReason = "loot-eligibility-api-unavailable"
    end
    batch.eligiblePlayers = deepCopy(eligiblePlayers or {})
    batch.eligibilityReason = eligibilityReason
    batch.eligibilityDetail = deepCopy(eligibilityDetail)

    for index = 1, #grants do
        local grant = grants[index]
        local grantId = buildStableEndGrantId(snapshot.eventSessionId, index)
        local grantResult = {
            index = index,
            grantId = grantId,
            grant = deepCopy(grant),
            status = "failed",
            reason = nil,
            detail = nil,
            execution = nil,
        }

        if type(loot) ~= "table" or type(loot.ExecuteGrant) ~= "function" then
            grantResult.reason = "loot-coordinator-unavailable"
        elseif eligibilityReason ~= nil and eligibilityReason ~= "empty-eligibility" then
            grantResult.reason = eligibilityReason
            grantResult.detail = deepCopy(eligibilityDetail)
        else
            local requestedPlayers = eligiblePlayers or {}
            local callOk, summary, reason, detail = pcall(loot.ExecuteGrant, loot, grant, requestedPlayers, {
                eventSessionId = snapshot.eventSessionId,
                grantId = grantId,
                hostName = snapshot.hostName,
                source = "event-end",
            })
            if not callOk then
                grantResult.reason = "loot-execution-error"
                grantResult.detail = { message = tostring(summary) }
            elseif type(summary) ~= "table" then
                grantResult.reason = reason or eligibilityReason or "loot-execution-failed"
                grantResult.detail = deepCopy(detail or eligibilityDetail)
            else
                grantResult.execution = deepCopy(summary)
                grantResult.status = tostring(summary.status or "pending")
                grantResult.reason = firstExecutionFailureReason(summary)
            end
        end

        batch.grants[#batch.grants + 1] = grantResult
    end

    updateBatchStatus(batch)
    rememberEndResult(loot, batch)
    return deepCopy(batch)
end

local baseCopyLiveEventToDraftState = Server.CopyLiveEventToDraftState
if type(baseCopyLiveEventToDraftState) == "function" then
    function Server:CopyLiveEventToDraftState(...)
        local result = baseCopyLiveEventToDraftState(self, ...)
        if result == true then
            self:SyncEndLootGrantsToDraft(self.EventState)
        end
        return result
    end
end

local baseStartEvent = Server.StartEvent
if type(baseStartEvent) == "function" then
    function Server:StartEvent(data, ...)
        local grants = chooseStartGrants(self, data)
        local previousContext = nil
        if type(Event.PushEndLootConstructionContext) == "function" then
            previousContext = Event.PushEndLootConstructionContext(grants)
        end

        local results = { pcall(baseStartEvent, self, data, ...) }
        local resultCount = #results

        if type(Event.PopEndLootConstructionContext) == "function" then
            Event.PopEndLootConstructionContext(previousContext)
        end

        if results[1] ~= true then
            error(results[2], 0)
        end

        local eventState = results[2]
        if type(eventState) == "table" then
            applyGrants(eventState, grants)
            if type(self.EventDraftState) == "table" then
                applyGrants(self.EventDraftState, grants)
            end
        end

        return unpack(results, 2, resultCount)
    end
end

local baseEndEvent = Server.EndEvent
if type(baseEndEvent) == "function" then
    function Server:EndEvent(reason, ...)
        local eventState = self.EventState
        if type(eventState) == "table" and eventState.active == true then
            local ok, resultOrError = pcall(self.ExecuteEventEndLoot, self, eventState)
            if not ok and type(Debug.Error) == "function" then
                Debug.Error("Event-end Loot integration failed for %s: %s", tostring(eventState.id or ""), tostring(resultOrError))
            end
        end

        return baseEndEvent(self, reason, ...)
    end
end

Server._eventEndLootIntegrationInstalled = true
