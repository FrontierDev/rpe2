local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
local Client = Addon.Client
local Event = Addon.Internal.Database and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event or nil

local SpeechCues = Client.AutopilotSpeechCues or {}
Client.AutopilotSpeechCues = SpeechCues

local MAX_TEXT_LENGTH = 500

local function state(override)
    if type(override) == "table" then return override end
    if type(Client.GetEventState) == "function" then return Client:GetEventState() end
    return Client.EventState
end

local function eventId(value)
    local id = tonumber(value)
    if id == nil or id <= 0 or id ~= id or id == math.huge or id == -math.huge or id ~= math.floor(id) then return 0 end
    return id
end

local function normalizeText(value)
    if type(value) ~= "string" then return nil end
    local text = value:gsub("\r\n?", "\n"):gsub("[%z\1-\8\11\12\14-\31\127]", "")
    text = text:match("^%s*(.-)%s*$") or ""
    if text == "" then return nil, "speech-empty" end
    if #text > MAX_TEXT_LENGTH then return nil, "speech-too-long" end
    return text
end

local function isHostAutopilot(eventState)
    local autopilotMode = tostring(eventState and eventState.turnMode or "manual") == "autopilot"
    if type(Event) == "table" and type(Event.NormalizeTurnMode) == "function" then
        autopilotMode = Event.NormalizeTurnMode(eventState and eventState.turnMode) == "autopilot"
    end
    return type(eventState) == "table" and eventState.active == true and eventState.ending ~= true
        and autopilotMode
        and type(Client.IsLocalEventHost) == "function" and Client:IsLocalEventHost(eventState) == true
end

local function currentPlan(eventState)
    if not isHostAutopilot(eventState) then return nil, "not-host-autopilot" end
    if type(Client.GetAutopilotPendingPlan) ~= "function" then return nil, "pending-plan-unavailable" end
    local plan, reason = Client:GetAutopilotPendingPlan(eventState)
    if type(plan) ~= "table" then return nil, reason or "pending-plan-unavailable" end
    if tostring(plan.status or "") == "stale" then return nil, "pending-plan-stale" end
    if tostring(plan.eventId or "") ~= tostring(eventState.id or "")
        or tonumber(plan.turnNumber) ~= tonumber(eventState.turnNumber)
        or tonumber(plan.tickNumber) ~= tonumber(eventState.tickNumber)
    then
        local authorization = Client.AutopilotAuthorization
        if type(authorization) == "table" and type(authorization.MarkPlanStale) == "function" then
            authorization.MarkPlanStale(plan, "event-context-changed")
        end
        return nil, "pending-plan-stale"
    end
    return plan
end

local function getAction(plan, actionId)
    actionId = tostring(actionId or "")
    if actionId == "" or type(plan) ~= "table" or type(plan.actionsById) ~= "table" then return nil end
    local action = plan.actionsById[actionId]
    if type(action) ~= "table" or tostring(action.actionId or "") ~= actionId then return nil end
    if action.actionType ~= "spell" and action.actionType ~= "movement" then return nil end
    return action
end

local function editable(action)
    return type(action) == "table" and (action.status == "pending" or action.status == "blocked")
end

local function findUnit(eventState, id)
    id = eventId(id)
    if id <= 0 then return nil end
    for index = 1, #((eventState and eventState.units) or {}) do
        local unit = eventState.units[index]
        if eventId(unit and unit.eventID) == id then return unit end
    end
end

local function unitIsActive(unit)
    if type(unit) ~= "table" then return false end
    if type(Event) == "table" and type(Event.IsUnitActive) == "function" then
        return Event.IsUnitActive(unit) == true
    end
    return unit.active ~= false
end

local function validSpeaker(eventState, id)
    id = eventId(id)
    local unit = findUnit(eventState, id)
    if id <= 0 or type(unit) ~= "table" or unit.isPlayer == true or not unitIsActive(unit) then return nil end
    return unit
end

local function speakerIds(action)
    local ids, seen = {}, {}
    local function add(value)
        local id = eventId(value)
        if id > 0 and not seen[id] then seen[id] = true; ids[#ids + 1] = id end
    end
    if action.actionType == "spell" then
        add(action.casterEventId)
    elseif action.actionType == "movement" then
        for _, value in ipairs(action.expectedMemberEventIds or {}) do add(value) end
    end
    return ids
end

local function speakersFor(action, eventState)
    local result = {}
    for _, id in ipairs(speakerIds(action)) do
        local unit = validSpeaker(eventState, id)
        if unit then
            result[#result + 1] = {
                eventId = id,
                name = tostring(unit.name or ("Unit " .. tostring(id))),
                raidMarker = tonumber(unit.raidMarker) or 0,
            }
        end
    end
    return result
end

local function ensureCueState(plan)
    plan.speechCuesByActionId = type(plan.speechCuesByActionId) == "table" and plan.speechCuesByActionId or {}
    plan.nextSpeechCueSerial = math.max(0, math.floor(tonumber(plan.nextSpeechCueSerial) or 0))
    return plan.speechCuesByActionId
end

local function getList(plan, actionId, create)
    local root = create and ensureCueState(plan) or (type(plan.speechCuesByActionId) == "table" and plan.speechCuesByActionId or nil)
    if not root then return nil end
    local key = tostring(actionId or "")
    local list = root[key]
    if type(list) ~= "table" and create then list = {}; root[key] = list end
    return list
end

local function reindex(list)
    for index = 1, #(list or {}) do list[index].order = index end
end

local function cueIndex(list, cueId)
    cueId = tostring(cueId or "")
    for index = 1, #(list or {}) do
        if tostring(list[index] and list[index].id or "") == cueId then return index, list[index] end
    end
end

local function setError(plan, reason)
    if type(plan) == "table" then plan.speechCueLastError = reason and tostring(reason) or nil end
end

local function refresh()
    if type(Client.QueueAutopilotDMHelperRefresh) == "function" then Client:QueueAutopilotDMHelperRefresh() end
end

local function exactCurrentPlan(action, plan, eventState)
    if not isHostAutopilot(eventState) or type(Client.GetAutopilotPendingPlan) ~= "function" then return false end
    local activePlan = Client:GetAutopilotPendingPlan(eventState)
    return activePlan == plan and tostring(plan.status or "") ~= "stale"
        and getAction(plan, action and action.actionId) == action
end

function SpeechCues.GetValidSpeakers(actionId, eventStateOverride)
    local eventState = state(eventStateOverride)
    local plan, reason = currentPlan(eventState)
    if not plan then return {}, nil, reason end
    local action = getAction(plan, actionId)
    if not action then return {}, plan, "pending-action-unavailable" end
    return speakersFor(action, eventState), plan, nil, action
end

function SpeechCues.GetActionCues(actionId, eventStateOverride)
    local eventState = state(eventStateOverride)
    local plan, reason = currentPlan(eventState)
    if not plan then return {}, nil, reason end
    local action = getAction(plan, actionId)
    if not action then return {}, plan, "pending-action-unavailable" end
    local result = {}
    for _, cue in ipairs(getList(plan, actionId, false) or {}) do
        result[#result + 1] = {
            id = tostring(cue.id or ""), actionId = tostring(cue.actionId or actionId),
            speakerEventId = eventId(cue.speakerEventId), text = tostring(cue.text or ""),
            order = math.max(1, math.floor(tonumber(cue.order) or #result + 1)),
            sent = cue.sent == true, dispatchAttempted = cue.dispatchAttempted == true,
            lastError = cue.lastError,
        }
    end
    table.sort(result, function(left, right)
        if left.order == right.order then return left.id < right.id end
        return left.order < right.order
    end)
    return result, plan, nil, action
end

function SpeechCues.AddCue(actionId, speakerEventId, text, eventStateOverride)
    local eventState = state(eventStateOverride)
    local plan, reason = currentPlan(eventState)
    if not plan then return false, nil, reason end
    local action = getAction(plan, actionId)
    if not action then return false, nil, "pending-action-unavailable" end
    if not editable(action) then return false, nil, "action-already-resolved" end
    local speaker = validSpeaker(eventState, speakerEventId)
    local canSpeak = false
    for _, candidate in ipairs(speakersFor(action, eventState)) do
        if candidate.eventId == eventId(speakerEventId) then canSpeak = true; break end
    end
    if not speaker or not canSpeak then return false, nil, "speaker-unavailable" end
    local normalized, textReason = normalizeText(text)
    if not normalized then return false, nil, textReason end

    ensureCueState(plan)
    plan.nextSpeechCueSerial = plan.nextSpeechCueSerial + 1
    local list = getList(plan, actionId, true)
    local cue = {
        id = ("%s:speech:%d"):format(tostring(plan.planId or "plan"), plan.nextSpeechCueSerial),
        actionId = tostring(actionId), speakerEventId = eventId(speakerEventId), text = normalized,
        order = #list + 1, sent = false, dispatchAttempted = false,
    }
    list[#list + 1] = cue
    setError(plan)
    refresh()
    return true, cue
end

function SpeechCues.EditCue(actionId, cueId, speakerEventId, text, eventStateOverride)
    local eventState = state(eventStateOverride)
    local plan, reason = currentPlan(eventState)
    if not plan then return false, nil, reason end
    local action = getAction(plan, actionId)
    if not action then return false, nil, "pending-action-unavailable" end
    if not editable(action) then return false, nil, "action-already-resolved" end
    local list = getList(plan, actionId, false)
    local _, cue = cueIndex(list, cueId)
    if type(cue) ~= "table" then return false, nil, "speech-cue-unavailable" end
    if cue.sent == true or cue.dispatchAttempted == true then return false, nil, "speech-cue-already-sent" end
    local valid = false
    for _, candidate in ipairs(speakersFor(action, eventState)) do
        if candidate.eventId == eventId(speakerEventId) then valid = true; break end
    end
    if not valid then return false, nil, "speaker-unavailable" end
    local normalized, textReason = normalizeText(text)
    if not normalized then return false, nil, textReason end
    cue.speakerEventId, cue.text = eventId(speakerEventId), normalized
    cue.lastError = nil
    setError(plan)
    refresh()
    return true, cue
end

function SpeechCues.RemoveCue(actionId, cueId, eventStateOverride)
    local plan, reason = currentPlan(state(eventStateOverride))
    if not plan then return false, reason end
    local action = getAction(plan, actionId)
    if not action then return false, "pending-action-unavailable" end
    if not editable(action) then return false, "action-already-resolved" end
    local list = getList(plan, actionId, false)
    local index, cue = cueIndex(list, cueId)
    if not cue then return false, "speech-cue-unavailable" end
    if cue.sent == true or cue.dispatchAttempted == true then return false, "speech-cue-already-sent" end
    table.remove(list, index)
    reindex(list)
    if #list == 0 then plan.speechCuesByActionId[tostring(actionId)] = nil end
    setError(plan)
    refresh()
    return true
end

function SpeechCues.MoveCue(actionId, cueId, direction, eventStateOverride)
    local plan, reason = currentPlan(state(eventStateOverride))
    if not plan then return false, reason end
    local action = getAction(plan, actionId)
    if not action then return false, "pending-action-unavailable" end
    if not editable(action) then return false, "action-already-resolved" end
    local list = getList(plan, actionId, false)
    local index, cue = cueIndex(list, cueId)
    if not cue then return false, "speech-cue-unavailable" end
    if cue.sent == true or cue.dispatchAttempted == true then return false, "speech-cue-already-sent" end
    local target = index + (tonumber(direction) or 0)
    if target < 1 or target > #list then return false, "speech-cue-order-boundary" end
    list[index], list[target] = list[target], list[index]
    reindex(list)
    refresh()
    return true
end

function SpeechCues.ClearPlan(plan)
    if type(plan) ~= "table" then return false end
    plan.speechCuesByActionId, plan.nextSpeechCueSerial, plan.speechCueLastError = nil, nil, nil
    return true
end

function Client:ClearAutopilotSpeechCuesForPlan(plan)
    return SpeechCues.ClearPlan(plan)
end

local function emitForAction(action, plan, eventState)
    if not exactCurrentPlan(action, plan, eventState) then return false end
    local expectedStatus = action.actionType == "spell" and "authorized" or "confirmed"
    if action.status ~= expectedStatus then return false end
    local source = getList(plan, action.actionId, false) or {}
    local list = {}
    for index = 1, #source do list[index] = source[index] end
    table.sort(list, function(left, right)
        local leftOrder, rightOrder = tonumber(left and left.order) or 0, tonumber(right and right.order) or 0
        if leftOrder == rightOrder then return tostring(left and left.id or "") < tostring(right and right.id or "") end
        return leftOrder < rightOrder
    end)
    local attemptedAny = false
    for _, cue in ipairs(list) do
        if cue.sent ~= true and cue.dispatchAttempted ~= true then
            cue.dispatchAttempted = true
            attemptedAny = true
            if not validSpeaker(eventState, cue.speakerEventId) then
                cue.lastError = "speaker-unavailable"
                setError(plan, cue.lastError)
            elseif type(Client.EmitNPCSpeech) ~= "function" then
                cue.lastError = "npc-speech-api-unavailable"
                setError(plan, cue.lastError)
            else
                local ok, emitted = pcall(Client.EmitNPCSpeech, Client, cue.speakerEventId, cue.text, {
                    source = "autopilot-speech-cue",
                })
                if ok and emitted == true then
                    cue.sent, cue.lastError = true, nil
                    setError(plan)
                else
                    cue.lastError = ok and "speech-emission-failed" or tostring(emitted or "speech-emission-failed")
                    setError(plan, cue.lastError)
                end
            end
        end
    end
    if attemptedAny then refresh() end
    return attemptedAny
end

if type(Client.RegisterAutopilotActionCueHandler) == "function" then
    Client:RegisterAutopilotActionCueHandler("npc-speech", {
        spellAuthorized = emitForAction,
        movementConfirmed = emitForAction,
    })
end

local baseRows = Client.GetAutopilotPendingActionRows
if type(baseRows) == "function" then
    function Client:GetAutopilotPendingActionRows(eventStateOverride)
        local rows, plan = baseRows(self, eventStateOverride)
        if type(plan) == "table" and type(plan.speechCuesByActionId) == "table" then
            for _, row in ipairs(rows or {}) do
                local actionId = tostring(row and row.actionId or "")
                local cues = getList(plan, actionId, false) or {}
                if #cues > 0 and type(row) == "table" then
                    row.hasSpeechCue = true
                    row.speechCueCount = #cues
                end
            end
        end
        return rows, plan
    end
end

return SpeechCues
