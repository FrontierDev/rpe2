local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Server = Addon.Server
local Event = Addon.Internal and Addon.Internal.Database
    and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Event or nil

Client.AutopilotEmoteCues = Client.AutopilotEmoteCues or {}
local Cues = Client.AutopilotEmoteCues

local CHAT_LIMIT = 255
local MARKERS = {
    [1] = "{star}", [2] = "{circle}", [3] = "{diamond}", [4] = "{triangle}",
    [5] = "{moon}", [6] = "{square}", [7] = "{cross}", [8] = "{skull}",
}

local function pack(...) return { n = select("#", ...), ... } end
local function eventId(value)
    local id = math.floor(tonumber(value) or 0)
    return id > 0 and id or 0
end
local function markerId(value)
    local marker = math.floor(tonumber(value) or 0)
    return marker >= 1 and marker <= 8 and marker or 0
end
local function turnMode(value)
    if type(Event) == "table" and type(Event.NormalizeTurnMode) == "function" then
        return Event.NormalizeTurnMode(value)
    end
    return tostring(value or "") == "autopilot" and "autopilot" or "manual"
end
local function activeUnit(unit)
    if type(unit) ~= "table" then return false end
    if type(Event) == "table" and type(Event.IsUnitActive) == "function" then
        return Event.IsUnitActive(unit) == true
    end
    return unit.active ~= false
end
local function state(override)
    if type(override) == "table" then return override end
    if type(Server.EventState) == "table" then return Server.EventState end
    if type(Client.GetEventState) == "function" then return Client:GetEventState() end
    return Client.EventState
end
local function isHostAutopilot(eventState)
    return type(eventState) == "table" and eventState.active == true
        and turnMode(eventState.turnMode) == "autopilot"
        and type(Client.IsLocalEventHost) == "function"
        and Client:IsLocalEventHost(eventState) == true
end
local function unit(eventState, id)
    id = eventId(id)
    for index = 1, #((eventState and eventState.units) or {}) do
        local candidate = eventState.units[index]
        if eventId(candidate and candidate.eventID) == id then return candidate end
    end
end
local function unitName(eventState, id)
    local found = unit(eventState, id)
    if type(found) == "table" and tostring(found.name or "") ~= "" then return tostring(found.name) end
    id = eventId(id)
    return id > 0 and ("Unit %d"):format(id) or "Unknown"
end
local function refresh()
    if type(Client.QueueAutopilotDMHelperRefresh) == "function" then Client:QueueAutopilotDMHelperRefresh() end
end
local function currentPlan(eventState)
    if type(Client.GetAutopilotPendingPlan) ~= "function" then return nil, "pending-plan-unavailable" end
    local plan, reason = Client:GetAutopilotPendingPlan(eventState)
    if type(plan) ~= "table" then return nil, reason or "pending-plan-unavailable" end
    if tostring(plan.status or "") == "stale" then return nil, "pending-plan-stale" end
    return plan
end
local function ensure(plan)
    if type(plan) ~= "table" then return nil end
    plan.emoteCuesById = type(plan.emoteCuesById) == "table" and plan.emoteCuesById or {}
    plan.emoteCueIdByUnitId = type(plan.emoteCueIdByUnitId) == "table" and plan.emoteCueIdByUnitId or {}
    plan.nextEmoteCueSerial = math.max(0, math.floor(tonumber(plan.nextEmoteCueSerial) or 0))
    return plan
end
local function body(value)
    return tostring(value or ""):gsub("\r\n", "\n"):gsub("\r", "\n"):gsub("^%s+", ""):gsub("%s+$", "")
end
local function oneLine(value) return body(value):gsub("%s*\n+%s*", " ") end
local function addId(list, seen, value)
    local id = eventId(value)
    if id > 0 and not seen[id] then seen[id] = true; list[#list + 1] = id end
end
local function sourceIds(action)
    local ids, seen = {}, {}
    if type(action) ~= "table" then return ids end
    if action.actionType == "spell" then
        addId(ids, seen, action.casterEventId)
    elseif action.actionType == "movement" then
        for _, id in ipairs(action.expectedMemberEventIds or {}) do addId(ids, seen, id) end
    end
    return ids
end
local function currentAction(action, triggerActionId)
    if type(action) ~= "table" then return false end
    if tostring(triggerActionId or "") ~= "" and tostring(action.actionId or "") == tostring(triggerActionId) then return true end
    local status = tostring(action.status or "")
    if action.actionType == "spell" then
        return status == "pending" or status == "blocked" or status == "authorized" or status == "executing"
    end
    return action.actionType == "movement" and (status == "pending" or status == "blocked")
end
local function participatingIds(plan, eventState)
    local ids, seen = {}, {}
    for _, actionId in ipairs(type(plan) == "table" and plan.orderedActionIds or {}) do
        local action = type(plan.actionsById) == "table" and plan.actionsById[tostring(actionId)] or nil
        if currentAction(action) then
            for _, id in ipairs(sourceIds(action)) do
                local found = unit(eventState, id)
                if type(found) == "table" and found.isPlayer ~= true and activeUnit(found) then addId(ids, seen, id) end
            end
        end
    end
    return ids
end
local function normalizedSelection(plan, eventState, values)
    local selected, ordered = {}, {}
    for _, value in ipairs(values or {}) do local id = eventId(value); if id > 0 then selected[id] = true end end
    for _, id in ipairs(participatingIds(plan, eventState)) do if selected[id] then ordered[#ordered + 1] = id end end
    return ordered
end
local function cueForUnit(plan, id, includeSent)
    if not ensure(plan) then return nil end
    id = eventId(id)
    local cueId = tostring(plan.emoteCueIdByUnitId[id] or "")
    local cue = cueId ~= "" and plan.emoteCuesById[cueId] or nil
    if type(cue) ~= "table" or (cue.sent == true and includeSent ~= true) then return nil end
    return cue
end
local function deleteIfEmpty(plan, cueId)
    local cue = plan.emoteCuesById[cueId]
    if type(cue) == "table" and next(cue.unitIds or {}) == nil then plan.emoteCuesById[cueId] = nil end
end
local function detach(plan, id, exceptCueId)
    id = eventId(id)
    local cueId = tostring(plan.emoteCueIdByUnitId[id] or "")
    if id <= 0 or cueId == "" or cueId == tostring(exceptCueId or "") then return false end
    local cue = plan.emoteCuesById[cueId]
    if type(cue) == "table" then
        cue.unitIds[id] = nil
        local order = {}
        for _, memberId in ipairs(cue.orderedUnitIds or {}) do if eventId(memberId) ~= id then order[#order + 1] = eventId(memberId) end end
        cue.orderedUnitIds = order
    end
    plan.emoteCueIdByUnitId[id] = nil
    deleteIfEmpty(plan, cueId)
    return true
end
local function setError(plan, reason) if type(plan) == "table" then plan.emoteCueLastError = reason and tostring(reason) or nil end end

function Cues.GetParticipatingUnits(eventStateOverride)
    local eventState = state(eventStateOverride)
    if not isHostAutopilot(eventState) then return {}, nil, "not-host-autopilot" end
    local plan, reason = currentPlan(eventState)
    if not plan then return {}, nil, reason end
    ensure(plan)
    local rows = {}
    for _, id in ipairs(participatingIds(plan, eventState)) do
        local found, cue = unit(eventState, id), cueForUnit(plan, id, false)
        rows[#rows + 1] = { eventId = id, name = unitName(eventState, id), raidMarker = markerId(found and found.raidMarker), hasCue = cue ~= nil, cueId = cue and cue.id or nil }
    end
    return rows, plan
end

function Cues.GetSharedCue(unitIds, eventStateOverride)
    local eventState = state(eventStateOverride)
    local plan = select(1, currentPlan(eventState))
    if not plan then return nil end
    local ordered, shared = normalizedSelection(plan, eventState, unitIds), nil
    if #ordered == 0 then return nil end
    for _, id in ipairs(ordered) do
        local cue = cueForUnit(plan, id, false)
        if not cue then return nil end
        if shared and shared.id ~= cue.id then return nil end
        shared = cue
    end
    return shared
end

function Cues.AssignCue(unitIds, text, editingCueId, eventStateOverride)
    local eventState = state(eventStateOverride)
    if not isHostAutopilot(eventState) then return false, nil, "not-host-autopilot" end
    local plan, reason = currentPlan(eventState)
    if not plan then return false, nil, reason end
    ensure(plan)
    local ordered = normalizedSelection(plan, eventState, unitIds)
    if #ordered == 0 then return false, nil, "no-units-selected" end
    text = body(text)
    if text == "" then return false, nil, "emote-empty" end

    local cueId = tostring(editingCueId or "")
    local cue = cueId ~= "" and plan.emoteCuesById[cueId] or nil
    if type(cue) ~= "table" or cue.sent == true then
        plan.nextEmoteCueSerial = plan.nextEmoteCueSerial + 1
        cueId = ("%s:emote:%d"):format(tostring(plan.planId or "plan"), plan.nextEmoteCueSerial)
        cue = { id = cueId, body = text, unitIds = {}, orderedUnitIds = {}, sent = false }
        plan.emoteCuesById[cueId] = cue
    else
        for oldId in pairs(cue.unitIds or {}) do plan.emoteCueIdByUnitId[eventId(oldId)] = nil end
        cue.body, cue.unitIds, cue.orderedUnitIds, cue.sent, cue.lastError = text, {}, {}, false, nil
    end
    for _, id in ipairs(ordered) do
        detach(plan, id, cueId)
        cue.unitIds[id], cue.orderedUnitIds[#cue.orderedUnitIds + 1], plan.emoteCueIdByUnitId[id] = true, id, cueId
    end
    setError(plan)
    refresh()
    return true, cue
end

function Cues.ClearCueForUnits(unitIds, eventStateOverride)
    local eventState = state(eventStateOverride)
    if not isHostAutopilot(eventState) then return false, "not-host-autopilot" end
    local plan, reason = currentPlan(eventState)
    if not plan then return false, reason end
    ensure(plan)
    local changed = false
    for _, id in ipairs(unitIds or {}) do changed = detach(plan, id) or changed end
    setError(plan)
    if changed then refresh() end
    return true
end

local function sourceSegment(cue, eventState)
    local groups, order, seen = {}, {}, {}
    for _, id in ipairs(cue and cue.orderedUnitIds or {}) do
        id = eventId(id)
        if id > 0 and not seen[id] then
            seen[id] = true
            local found = unit(eventState, id)
            local marker = markerId(found and found.raidMarker)
            if not groups[marker] then groups[marker], order[#order + 1] = {}, marker end
            groups[marker][#groups[marker] + 1] = id
        end
    end
    local parts = {}
    for _, marker in ipairs(order) do
        local ids = table.concat(groups[marker], ", ")
        parts[#parts + 1] = MARKERS[marker] and (MARKERS[marker] .. " (" .. ids .. ")") or ("(" .. ids .. ")")
    end
    return table.concat(parts, " ")
end
local function targetSegment(plan, cue, eventState, triggerActionId)
    local targets, seen = {}, {}
    for _, actionId in ipairs(type(plan) == "table" and plan.orderedActionIds or {}) do
        local action = type(plan.actionsById) == "table" and plan.actionsById[tostring(actionId)] or nil
        if currentAction(action, triggerActionId) then
            local belongs = false
            for _, id in ipairs(sourceIds(action)) do if cue.unitIds[eventId(id)] then belongs = true; break end end
            if belongs then
                local values = action.actionType == "movement" and action.objectiveTargetEventIds or action.targetEventIds
                for _, id in ipairs(values or {}) do addId(targets, seen, id) end
            end
        end
    end
    local labels = {}
    for _, id in ipairs(targets) do labels[#labels + 1] = "[" .. unitName(eventState, id) .. "]" end
    return #labels > 0 and ("@" .. table.concat(labels, ", ")) or ""
end
local function compose(targets, sources, text)
    local parts = {}
    if targets ~= "" then parts[#parts + 1] = targets end
    if sources ~= "" then parts[#parts + 1] = sources end
    text = oneLine(text); if text ~= "" then parts[#parts + 1] = text end
    return table.concat(parts, " ")
end

function Cues.ComposeCueMessage(cue, plan, eventStateOverride, triggerActionId)
    local eventState = state(eventStateOverride)
    if type(cue) ~= "table" or type(plan) ~= "table" then return nil, "emote-cue-unavailable" end
    local text = oneLine(cue.body)
    if text == "" then return nil, "emote-empty" end
    local message = compose(targetSegment(plan, cue, eventState, triggerActionId), sourceSegment(cue, eventState), text)
    return #message <= CHAT_LIMIT and message or nil, #message <= CHAT_LIMIT and nil or "message-too-long"
end

local function chatType()
    if type(IsInRaid) == "function" and IsInRaid() == true then return "RAID" end
    if type(IsInGroup) == "function" and IsInGroup() == true then return "PARTY" end
    if type(GetNumGroupMembers) == "function" and (tonumber(GetNumGroupMembers()) or 0) > 0 then return "PARTY" end
end
local function send(message)
    if tostring(message or "") == "" then return false, "emote-empty" end
    if #message > CHAT_LIMIT then return false, "message-too-long" end
    local channel = chatType()
    if not channel then return false, "not-in-group" end
    if type(SendChatMessage) ~= "function" then return false, "chat-api-unavailable" end
    local ok, reason = pcall(SendChatMessage, message, channel)
    return ok and true or false, ok and channel or tostring(reason or "chat-send-failed")
end

function Cues.SendCue(cue, plan, eventStateOverride, triggerActionId)
    local eventState = state(eventStateOverride)
    if not isHostAutopilot(eventState) then return false, "not-host-autopilot" end
    if type(cue) ~= "table" then return false, "emote-cue-unavailable" end
    if cue.sent == true then return true, "already-sent" end
    local message, reason = Cues.ComposeCueMessage(cue, plan, eventState, triggerActionId)
    if not message then cue.lastError = reason; setError(plan, reason); refresh(); return false, reason end
    local ok, channel = send(message)
    if not ok then cue.lastError = channel; setError(plan, channel); refresh(); return false, channel end
    cue.sent, cue.lastError, cue.lastMessage, cue.chatType = true, nil, message, channel
    setError(plan); refresh()
    return true, message
end

function Cues.TrySendForUnits(unitIds, planOverride, eventStateOverride, triggerActionId)
    local eventState = state(eventStateOverride)
    if not isHostAutopilot(eventState) then return false, "not-host-autopilot" end
    local plan = type(planOverride) == "table" and planOverride or select(1, currentPlan(eventState))
    if not plan then return false, "pending-plan-unavailable" end
    ensure(plan)
    local cueIds, seen, any, lastReason = {}, {}, false, nil
    for _, id in ipairs(unitIds or {}) do
        local cue = cueForUnit(plan, id, false)
        if cue and not seen[cue.id] then seen[cue.id] = true; cueIds[#cueIds + 1] = cue.id end
    end
    if #cueIds == 0 then return false, "emote-cue-unavailable" end
    for _, cueId in ipairs(cueIds) do
        local ok, reason = Cues.SendCue(plan.emoteCuesById[cueId], plan, eventState, triggerActionId)
        any = ok or any; if not ok then lastReason = reason end
    end
    return any, lastReason
end

function Cues.ComposeOutcomeMessage(outcome, text, eventStateOverride)
    local eventState = state(eventStateOverride)
    if not isHostAutopilot(eventState) then return nil, "not-host-autopilot" end
    if type(outcome) ~= "table" or tostring(outcome.kind or "") ~= "outcome" then return nil, "outcome-unavailable" end
    text = oneLine(text); if text == "" then return nil, "emote-empty" end
    local sourceId = eventId(outcome.sourceEventId)
    local sourceUnit = unit(eventState, sourceId)
    local source = sourceId > 0 and ("(" .. sourceId .. ")") or ""
    local marker = markerId(sourceUnit and sourceUnit.raidMarker)
    if source ~= "" and MARKERS[marker] then source = MARKERS[marker] .. " " .. source end
    local targetId = eventId(outcome.targetEventId)
    local target = targetId > 0 and ("@[" .. unitName(eventState, targetId) .. "]") or ""
    local message = compose(target, source, text)
    return #message <= CHAT_LIMIT and message or nil, #message <= CHAT_LIMIT and nil or "message-too-long"
end

function Cues.SendOutcomeEmote(outcome, text, eventStateOverride)
    local message, reason = Cues.ComposeOutcomeMessage(outcome, text, eventStateOverride)
    if not message then return false, reason end
    local ok, channel = send(message)
    return ok and true or false, ok and message or channel, ok and channel or nil
end

function Cues.GetLastError(eventStateOverride)
    local plan = select(1, currentPlan(state(eventStateOverride)))
    return type(plan) == "table" and plan.emoteCueLastError or nil
end

-- Decorate structured action rows without changing action ownership or parsing display text.
local baseRows = Client.GetAutopilotPendingActionRows
if type(baseRows) == "function" then
    function Client:GetAutopilotPendingActionRows(eventStateOverride)
        local rows, plan = baseRows(self, eventStateOverride)
        if type(plan) == "table" then
            ensure(plan)
            for _, row in ipairs(rows or {}) do
                local action = type(plan.actionsById) == "table" and plan.actionsById[tostring(row and row.actionId or "")] or nil
                local hasCue, cueId = false, nil
                for _, id in ipairs(sourceIds(action)) do
                    local cue = cueForUnit(plan, id, false)
                    if cue then hasCue, cueId = true, cueId or cue.id end
                end
                if type(row) == "table" then
                    row.hasEmoteCue, row.emoteCueId = hasCue, cueId
                    if hasCue then row.displayText = "[Emote] " .. tostring(row.displayText or row.summary or "") end
                end
            end
        end
        return rows, plan
    end
end

-- Authorization has already succeeded when this hook is entered; publish immediately before execution.
local baseAuthorized = Client.OnAutopilotPendingActionAuthorized
if type(baseAuthorized) == "function" then
    function Client:OnAutopilotPendingActionAuthorized(action, plan, eventState, ...)
        if type(action) == "table" and action.actionType == "spell" and action.status == "authorized" then
            Cues.TrySendForUnits({ action.casterEventId }, plan, eventState, action.actionId)
        end
        return baseAuthorized(self, action, plan, eventState, ...)
    end
end

-- Movement narration fires only after the canonical movement confirmation succeeds.
local baseConfirmMovement = Client.ConfirmAutopilotPendingMovement
if type(baseConfirmMovement) == "function" then
    function Client:ConfirmAutopilotPendingMovement(actionId, eventStateOverride, ...)
        local results = pack(baseConfirmMovement(self, actionId, eventStateOverride, ...))
        if results[1] == true and type(results[2]) == "table" then
            local eventState = state(eventStateOverride)
            Cues.TrySendForUnits(results[2].expectedMemberEventIds or {}, select(1, currentPlan(eventState)), eventState, results[2].actionId)
        end
        return unpack(results, 1, results.n)
    end
end

return Cues
