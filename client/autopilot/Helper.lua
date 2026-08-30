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
        ["awaiting-authorization"] = "Awaiting Authorization",
        ["suspended-instance"] = "Suspended (Instance)",
        ["suspended-position"] = "Suspended (Position)",
        ["cancelled-stale"] = "Cancelled (Stale)",
    }
    return labels[value] or (value ~= "" and value or "Ready")
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
    if type(runtime) ~= "table" then
        text = "Autopilot: Initializing"
    elseif runtime.status ~= "ready" then
        text = "Autopilot unavailable: " .. tostring(runtime.unavailableReason or "position unavailable")
    elseif type(pending) == "table" and tostring(pending.status or "") ~= "stale" then
        local actionCount = #(pending.spellActionIds or {}) + #(pending.movementActionIds or {})
        if actionCount > 0 then
            text = "Autopilot: Ready — pending authorization"
        end
    end
    return {
        kind = "status",
        text = text,
        status = status,
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
        local text = ("Marker %d: Position not set"):format(marker)
        if available then
            text = ("Marker %d: (%.1f, %.1f)"):format(marker, tonumber(position.x), tonumber(position.y))
        end
        rows[#rows + 1] = {
            kind = "marker-position",
            actionType = "marker-position",
            actionId = "marker-position:" .. tostring(marker),
            actorKey = actorKey,
            raidMarker = marker,
            text = text,
            status = available and "ready" or "position-unset",
            canSetPosition = type(runtime) == "table" and runtime.status == "ready",
        }
    end
    return rows
end

local function buildMovementRow(_, action)
    local marker = math.max(0, math.floor(tonumber(action and action.raidMarker) or 0))
    local proposed = type(action) == "table" and action.proposedPosition or nil
    local destination = "the proposed location"
    if type(proposed) == "table" and tonumber(proposed.x) and tonumber(proposed.y) then
        destination = ("(%.1f, %.1f)"):format(tonumber(proposed.x), tonumber(proposed.y))
    end
    local status = tostring(action and action.status or "pending")
    local text
    if status == "blocked" then
        text = ("Marker %d movement blocked: %s"):format(marker, tostring(action.reason or "movement invalid"))
    elseif status == "confirmed" then
        text = ("Marker %d moved to %s."):format(marker, destination)
    elseif status == "skipped" then
        text = ("Marker %d movement skipped."):format(marker)
    elseif status == "stale" then
        text = ("Marker %d movement is stale: %s"):format(marker, tostring(action.reason or "state changed"))
    else
        text = ("Move marker %d to %s."):format(marker, destination)
    end
    return {
        kind = "movement",
        actionType = "movement",
        actionId = action.actionId,
        text = text,
        status = status,
        canConfirm = status == "pending",
        canSkip = status == "pending",
    }
end

local function buildSpellRow(eventState, action)
    local caster = unitName(eventState, action and action.casterEventId)
    local spell = spellName(action and action.spellRef)
    local targets = targetNames(eventState, action and action.targetEventIds)
    local status = tostring(action and action.status or "pending")
    local text = ("[%s] casts %s at %s. [%s]"):format(caster, spell, targets, statusLabel(status))
    if (status == "blocked" or status == "stale" or status == "failed")
        and tostring(action.reason or "") ~= ""
    then
        text = text .. " " .. tostring(action.reason)
    end
    return {
        kind = "spell",
        actionType = "spell",
        actionId = action.actionId,
        casterEventId = action.casterEventId,
        text = text,
        status = status,
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
        entries[#entries + 1] = {
            kind = "warning",
            text = tostring(warning and (warning.text or warning.reason) or "Autopilot warning"),
            status = "warning",
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
        entries[#entries + 1] = {
            kind = "no-action",
            text = ("[%s] has no viable action: %s"):format(
                unitName(eventState, noAction and noAction.casterEventId),
                tostring(noAction and noAction.reason or "no useful action")
            ),
            status = "no-action",
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