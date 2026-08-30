local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Registry = Addon.Internal.Registry or {}
local Event = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil
local Spatial = Client.AutopilotSpatial or {}

Client.AutopilotHelper = Client.AutopilotHelper or {}
local Helper = Client.AutopilotHelper

local REASON_TEXT = {
    ["step-advanced"] = "This action belongs to the previous event step.",
    ["event-changed"] = "The active event changed after this action was planned.",
    ["turn-changed"] = "The active turn changed after this action was planned.",
    ["tick-changed"] = "The active turn step changed after this action was planned.",
    ["actor-changed"] = "The active NPC actor changed after this action was planned.",
    ["schedule-changed"] = "The event turn schedule changed after this action was planned.",
    ["snapshot-stale"] = "State changed while this plan was being built; the plan must be replaced.",
    ["cohort-immobilized"] = "This marker cannot move because at least one active NPC in the cohort currently has 0 movement allowance.",
    ["movement-allowance-reduced"] = "The marker's current movement allowance is lower than the distance in the planned move.",
    ["movement-range-unconfigured"] = "The ruleset has no Movement Range Stat configured.",
    ["movement-range-stat-missing"] = "The configured Movement Range Stat is not present on this NPC.",
    ["movement-allowance-api-unavailable"] = "The movement allowance resolver is unavailable.",
    ["movement-allowance-unavailable"] = "The NPC's effective movement allowance could not be resolved.",
    ["movement-pending"] = "This action requires the marker's planned movement to be confirmed first.",
    ["movement-missing"] = "This action depends on a movement proposal that is no longer available.",
    ["movement-skipped"] = "The required marker movement was skipped by the DM.",
    ["movement-solve-unavailable"] = "The shared-marker movement solver is unavailable.",
    ["movement-solve-failed"] = "The shared-marker movement solver could not produce a valid result.",
    ["movement-commit-api-unavailable"] = "The marker position update API is unavailable.",
    ["movement-commit-failed"] = "The planned marker position could not be committed.",
    ["cohort-changed"] = "The active members sharing this raid marker changed after the movement was planned.",
    ["marked-cohort-required"] = "This movement action no longer identifies a valid marked NPC cohort.",
    ["position-unavailable"] = "The required virtual/world position is not available.",
    ["position-unset"] = "The marker's virtual position has not been initialized.",
    ["marker-position-unavailable"] = "The marker's current virtual position is not available.",
    ["proposed-position-unavailable"] = "The planned destination is no longer available.",
    ["distance-api-unavailable"] = "The distance calculation API is unavailable.",
    ["distance-unavailable"] = "The distance to the planned destination could not be calculated.",
    ["no-useful-action"] = "No useful legal action was found for this NPC.",
    ["dm-rejected"] = "This action was rejected by the DM.",
    ["dm-skipped"] = "This movement was skipped by the DM.",
    ["dm-replan"] = "The DM requested a replacement plan.",
    ["replaced-plan"] = "This plan was replaced by a newer plan.",
}

local function normalizeEventId(value)
    local eventId = math.floor(tonumber(value) or 0)
    return eventId > 0 and eventId or 0
end

local function normalizeTurnMode(value)
    if type(Event) == "table" and type(Event.NormalizeTurnMode) == "function" then
        return Event.NormalizeTurnMode(value)
    end
    return tostring(value or "") == "autopilot" and "autopilot" or "manual"
end

local function findUnit(eventState, eventId)
    local wanted = normalizeEventId(eventId)
    if wanted <= 0 then
        return nil
    end
    for index = 1, #((eventState and eventState.units) or {}) do
        local unit = eventState.units[index]
        if normalizeEventId(unit and unit.eventID) == wanted then
            return unit
        end
    end
    return nil
end

local function unitName(eventState, eventId)
    local unit = findUnit(eventState, eventId)
    if type(unit) == "table" and tostring(unit.name or "") ~= "" then
        return tostring(unit.name)
    end
    local numeric = normalizeEventId(eventId)
    return numeric > 0 and ("Unit %d"):format(numeric) or "Unknown"
end

local function spellName(spellRef)
    local ref = tostring(spellRef or "")
    if ref == "" then
        return "Unknown Spell"
    end
    if type(Registry.ResolveSpellReference) == "function" then
        local _, spell = Registry:ResolveSpellReference(ref)
        if type(spell) == "table" and tostring(spell.name or "") ~= "" then
            return tostring(spell.name)
        end
    end
    return ref
end

local function targetNames(eventState, targetEventIds)
    local names = {}
    for index = 1, #(targetEventIds or {}) do
        names[#names + 1] = unitName(eventState, targetEventIds[index])
    end
    return #names > 0 and table.concat(names, ", ") or "no target"
end

local function statusLabel(status)
    local value = tostring(status or "")
    local labels = {
        pending = "Pending",
        authorized = "Authorized",
        executing = "Executing",
        completed = "Completed",
        rejected = "Rejected",
        blocked = "Blocked",
        stale = "Stale",
        failed = "Failed",
        confirmed = "Confirmed",
        skipped = "Skipped",
        planning = "Planning",
        ready = "Ready",
        warning = "Warning",
        ["no-action"] = "No Action",
        ["position-unset"] = "Position Not Set",
        ["awaiting-authorization"] = "Awaiting Authorization",
        ["suspended-instance"] = "Suspended (Instance)",
        ["suspended-position"] = "Suspended (Position)",
        ["cancelled-stale"] = "Cancelled (Stale)",
    }
    return labels[value] or (value ~= "" and value or "Ready")
end

function Helper.GetReasonText(reason)
    local code = tostring(reason or "")
    if code == "" then
        return nil
    end
    return REASON_TEXT[code] or code
end

function Helper.GetStatusLabel(status)
    return statusLabel(status)
end

local function appendDetail(lines, label, value)
    if value == nil then
        return
    end
    local text = tostring(value)
    if text == "" then
        return
    end
    lines[#lines + 1] = tostring(label) .. ": " .. text
end

local function appendReason(lines, reason)
    local code = tostring(reason or "")
    if code == "" then
        return nil, nil
    end
    local reasonText = Helper.GetReasonText(code)
    appendDetail(lines, "Reason", reasonText)
    if reasonText ~= code then
        appendDetail(lines, "Reason code", code)
    end
    return code, reasonText
end

local function positionText(position)
    if type(position) ~= "table" or tonumber(position.x) == nil or tonumber(position.y) == nil then
        return nil
    end
    return ("(%.1f, %.1f)"):format(tonumber(position.x), tonumber(position.y))
end

local function joinNamesForEventIds(eventState, eventIds)
    local names = {}
    for index = 1, #(eventIds or {}) do
        names[#names + 1] = unitName(eventState, eventIds[index])
    end
    return #names > 0 and table.concat(names, ", ") or nil
end

local function appendMovementMemberDiagnostics(lines, eventState, movementByMemberEventId)
    if type(movementByMemberEventId) ~= "table" then
        return
    end

    local eventIds = {}
    for eventId in pairs(movementByMemberEventId) do
        local normalized = normalizeEventId(eventId)
        if normalized > 0 then
            eventIds[#eventIds + 1] = normalized
        end
    end
    table.sort(eventIds)

    for index = 1, #eventIds do
        local eventId = eventIds[index]
        local details = movementByMemberEventId[eventId] or movementByMemberEventId[tostring(eventId)]
        if type(details) == "table" then
            local parts = {}
            if details.baseValue ~= nil then
                parts[#parts + 1] = "base=" .. tostring(details.baseValue)
            end
            if details.movementRangeOverride ~= nil then
                parts[#parts + 1] = "override=" .. tostring(details.movementRangeOverride)
            end
            if details.effectiveValue ~= nil then
                parts[#parts + 1] = "effective=" .. tostring(details.effectiveValue)
            end
            if tostring(details.statRef or "") ~= "" then
                parts[#parts + 1] = "stat=" .. tostring(details.statRef)
            end
            if tostring(details.reason or "") ~= "" then
                parts[#parts + 1] = "reason=" .. tostring(Helper.GetReasonText(details.reason))
            end
            if #parts > 0 then
                lines[#lines + 1] = ("Movement — %s: %s"):format(unitName(eventState, eventId), table.concat(parts, ", "))
            end
        end
    end
end

local function getRuntime(eventState)
    local eventId = tostring(type(eventState) == "table" and eventState.id or "")
    if eventId == "" or type(Client.AutopilotRuntimeByEventId) ~= "table" then
        return nil
    end
    return Client.AutopilotRuntimeByEventId[eventId]
end

local function isHostAutopilotEvent(eventState)
    return type(eventState) == "table"
        and eventState.active == true
        and normalizeTurnMode(eventState.turnMode) == "autopilot"
        and type(Client.IsLocalEventHost) == "function"
        and Client:IsLocalEventHost(eventState) == true
end

local function buildStatusRow(eventState, runtime, pending)
    local status = type(runtime) == "table" and tostring(runtime.plannerStatus or "ready") or "planning"
    local text = "Autopilot: " .. statusLabel(status)
    local reason = nil
    if type(runtime) ~= "table" then
        text = "Autopilot: Initializing"
    elseif runtime.status ~= "ready" then
        reason = tostring(runtime.unavailableReason or "position-unavailable")
        text = "Autopilot unavailable: " .. tostring(Helper.GetReasonText(reason) or reason)
    elseif type(pending) == "table" and tostring(pending.status or "") ~= "stale" then
        local actionCount = #(pending.spellActionIds or {}) + #(pending.movementActionIds or {})
        if actionCount > 0 then
            status = "awaiting-authorization"
            text = "Autopilot: Ready — pending authorization"
        end
    end

    local lines = {}
    appendDetail(lines, "Status", statusLabel(status))
    local reasonCode, reasonText = appendReason(lines, reason)
    return {
        kind = "status",
        entryId = "autopilot-status:" .. tostring(eventState and eventState.id or ""),
        summary = "Autopilot — " .. statusLabel(status),
        details = #lines > 0 and table.concat(lines, "\n") or text,
        text = text,
        status = status,
        reasonCode = reasonCode,
        reasonText = reasonText,
        eventId = tostring(eventState and eventState.id or ""),
    }
end

local function buildMarkerPositionRows(eventState, runtime)
    if type(Spatial.BuildNpcActorKeySet) ~= "function" then
        return {}
    end

    local actorKeys = Spatial.BuildNpcActorKeySet(eventState) or {}
    local actorKeyByMarker = {}
    local markers = {}
    for actorKey in pairs(actorKeys) do
        local marker = tonumber(string.match(tostring(actorKey or ""), "^marker:(%d+)$"))
        if marker and marker > 0 and actorKeyByMarker[marker] == nil then
            actorKeyByMarker[marker] = actorKey
            markers[#markers + 1] = marker
        end
    end
    table.sort(markers)

    local rows = {}
    for index = 1, #markers do
        local marker = markers[index]
        local actorKey = actorKeyByMarker[marker]
        local position = type(runtime) == "table"
            and type(runtime.positionByActorKey) == "table"
            and runtime.positionByActorKey[actorKey]
            or nil
        local available = type(Spatial.IsPositionAvailable) == "function"
            and Spatial.IsPositionAvailable(position) == true
        local status = available and "ready" or "position-unset"
        local text = ("Marker %d: Position not set"):format(marker)
        if available then
            text = ("Marker %d: %s"):format(marker, positionText(position))
        end

        local lines = {}
        appendDetail(lines, "Marker", marker)
        appendDetail(lines, "Actor", actorKey)
        appendDetail(lines, "Status", available and "Position set" or "Position not set")
        appendDetail(lines, "Position", positionText(position))
        local reasonCode, reasonText = nil, nil
        if not available then
            reasonCode, reasonText = appendReason(lines, position and position.reason or "position-unset")
        end

        rows[#rows + 1] = {
            kind = "marker-position",
            entryId = "autopilot-marker:" .. tostring(marker),
            actionType = "marker-position",
            actionId = "marker-position:" .. tostring(marker),
            actorKey = actorKey,
            raidMarker = marker,
            summary = ("Marker %d — %s"):format(marker, available and "Position set" or "Position not set"),
            details = table.concat(lines, "\n"),
            text = text,
            status = status,
            reasonCode = reasonCode,
            reasonText = reasonText,
            canSetPosition = type(runtime) == "table" and runtime.status == "ready",
        }
    end
    return rows
end

local function buildMovementRow(eventState, action)
    local marker = math.max(0, math.floor(tonumber(action and action.raidMarker) or 0))
    local proposed = type(action) == "table" and action.proposedPosition or nil
    local destination = positionText(proposed) or "the proposed location"
    local status = tostring(action and action.status or "pending")
    local reason = tostring(action and action.reason or "")
    local text
    if status == "blocked" then
        text = ("Marker %d movement blocked: %s"):format(marker, reason ~= "" and reason or "movement invalid")
    elseif status == "confirmed" then
        text = ("Marker %d moved to %s."):format(marker, destination)
    elseif status == "skipped" then
        text = ("Marker %d movement skipped."):format(marker)
    elseif status == "stale" then
        text = ("Marker %d movement is stale: %s"):format(marker, reason ~= "" and reason or "state changed")
    else
        text = ("Move marker %d to %s."):format(marker, destination)
    end

    local lines = {}
    appendDetail(lines, "Marker", marker)
    appendDetail(lines, "Actor", action and action.actorKey)
    appendDetail(lines, "Action", "Move shared marker cohort")
    appendDetail(lines, "Status", statusLabel(status))
    appendDetail(lines, "Planned movement allowance", action and action.movementAllowance ~= nil and (tostring(action.movementAllowance) .. " yd") or nil)
    appendDetail(lines, "Planned movement distance", action and action.movementDistance ~= nil and (tostring(action.movementDistance) .. " yd") or nil)
    appendDetail(lines, "Current movement allowance", action and action.currentMovementAllowance ~= nil and (tostring(action.currentMovementAllowance) .. " yd") or nil)
    appendDetail(lines, "Current movement distance", action and action.currentMovementDistance ~= nil and (tostring(action.currentMovementDistance) .. " yd") or nil)
    appendDetail(lines, "Proposed position", positionText(proposed))
    appendDetail(lines, "Limiting NPCs", joinNamesForEventIds(eventState, action and action.limitingMemberEventIds))
    local reasonCode, reasonText = appendReason(lines, reason)
    appendMovementMemberDiagnostics(lines, eventState, action and (action.currentMovementByMemberEventId or action.movementByMemberEventId))

    return {
        kind = "movement",
        entryId = "autopilot-action:" .. tostring(action and action.actionId or ""),
        actionType = "movement",
        actionId = action.actionId,
        actorKey = action.actorKey,
        raidMarker = marker,
        summary = ("Move Marker %d — %s"):format(marker, statusLabel(status)),
        details = table.concat(lines, "\n"),
        text = text,
        status = status,
        reasonCode = reasonCode,
        reasonText = reasonText,
        canConfirm = status == "pending",
        canSkip = status == "pending",
    }
end

local function buildSpellRow(eventState, action)
    local caster = unitName(eventState, action and action.casterEventId)
    local spell = spellName(action and action.spellRef)
    local targets = targetNames(eventState, action and action.targetEventIds)
    local status = tostring(action and action.status or "pending")
    local reason = tostring(action and action.reason or "")
    local text = ("[%s] casts %s at %s. [%s]"):format(caster, spell, targets, statusLabel(status))
    if (status == "blocked" or status == "stale" or status == "failed") and reason ~= "" then
        text = text .. " " .. reason
    end

    local lines = {}
    appendDetail(lines, "NPC", caster)
    appendDetail(lines, "Actor", action and action.actorKey)
    appendDetail(lines, "Action", "Cast " .. spell)
    appendDetail(lines, "Targets", targets)
    appendDetail(lines, "Status", statusLabel(status))
    local reasonCode, reasonText = appendReason(lines, reason)

    return {
        kind = "spell",
        entryId = "autopilot-action:" .. tostring(action and action.actionId or ""),
        actionType = "spell",
        actionId = action.actionId,
        actorKey = action.actorKey,
        casterEventId = action.casterEventId,
        summary = ("NPC: %s — %s"):format(caster, statusLabel(status)),
        details = table.concat(lines, "\n"),
        text = text,
        status = status,
        reasonCode = reasonCode,
        reasonText = reasonText,
        canAuthorize = status == "pending",
        canReject = status == "pending" or status == "blocked",
    }
end

function Helper.BuildEntries(eventState)
    if not isHostAutopilotEvent(eventState) then
        return {}
    end

    local entries = {}
    local runtime = getRuntime(eventState)
    local pending = type(Client.GetAutopilotPendingPlan) == "function"
        and select(1, Client:GetAutopilotPendingPlan(eventState))
        or nil

    entries[#entries + 1] = buildStatusRow(eventState, runtime, pending)
    local markerRows = buildMarkerPositionRows(eventState, runtime)
    for index = 1, #markerRows do
        entries[#entries + 1] = markerRows[index]
    end
    if type(pending) ~= "table" then
        return entries
    end

    for index = 1, #(pending.movementActionIds or {}) do
        local action = pending.actionsById and pending.actionsById[pending.movementActionIds[index]] or nil
        if type(action) == "table" then
            entries[#entries + 1] = buildMovementRow(eventState, action)
        end
    end
    for index = 1, #(pending.warnings or {}) do
        local warning = pending.warnings[index]
        local reason = tostring(warning and warning.reason or "")
        local fullText = tostring(warning and (warning.text or warning.reason) or "Autopilot warning")
        local lines = { fullText }
        local reasonCode, reasonText = appendReason(lines, reason)
        entries[#entries + 1] = {
            kind = "warning",
            entryId = ("autopilot-warning:%s:%d"):format(tostring(pending.planId or ""), index),
            summary = "Autopilot warning — Warning",
            details = table.concat(lines, "\n"),
            text = fullText,
            status = "warning",
            reasonCode = reasonCode,
            reasonText = reasonText,
        }
    end
    for index = 1, #(pending.spellActionIds or {}) do
        local action = pending.actionsById and pending.actionsById[pending.spellActionIds[index]] or nil
        if type(action) == "table" then
            entries[#entries + 1] = buildSpellRow(eventState, action)
        end
    end
    for index = 1, #(pending.noActions or {}) do
        local noAction = pending.noActions[index]
        local caster = unitName(eventState, noAction and noAction.casterEventId)
        local reason = tostring(noAction and noAction.reason or "no-useful-action")
        local text = ("[%s] has no viable action: %s"):format(caster, reason)
        local lines = {}
        appendDetail(lines, "NPC", caster)
        appendDetail(lines, "Status", "No Action")
        local reasonCode, reasonText = appendReason(lines, reason)
        entries[#entries + 1] = {
            kind = "no-action",
            entryId = ("autopilot-no-action:%s:%d"):format(tostring(pending.planId or ""), index),
            casterEventId = noAction and noAction.casterEventId,
            summary = ("NPC: %s — No Action"):format(caster),
            details = table.concat(lines, "\n"),
            text = text,
            status = "no-action",
            reasonCode = reasonCode,
            reasonText = reasonText,
        }
    end
    return entries
end

function Client:QueueAutopilotDMHelperRefresh()
    local widgetNamespace = self.UI and self.UI.EventWidget or nil
    local widget = type(widgetNamespace) == "table"
        and type(widgetNamespace.Get) == "function"
        and widgetNamespace:Get()
        or widgetNamespace
    if type(widget) ~= "table"
        or tostring(widget.combatLogHistoryMode or "") ~= "dm-helper"
        or type(widget.IsCombatLogHistoryPanelShown) ~= "function"
        or widget:IsCombatLogHistoryPanelShown() ~= true
        or type(widget.RefreshCombatLogHistoryPanel) ~= "function"
    then
        return false
    end
    widget:RefreshCombatLogHistoryPanel()
    return true
end

if type(Client.RegisterDMHelperProvider) == "function" then
    Client:RegisterDMHelperProvider("autopilot", function(_, eventState)
        return Helper.BuildEntries(eventState)
    end)
end

return Helper
