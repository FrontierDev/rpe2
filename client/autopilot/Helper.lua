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
local Combat = Client.Combat or {}

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

local function pack(...)
    return { n = select("#", ...), ... }
end

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

local function isUnitActive(unit)
    if type(unit) ~= "table" then
        return false
    end
    if type(Event) == "table" and type(Event.IsUnitActive) == "function" then
        return Event.IsUnitActive(unit) == true
    end
    return unit.active ~= false
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

function Helper.GetMarkerStates(eventState)
    if not isHostAutopilotEvent(eventState) then
        return {}
    end

    local states = {}
    local runtime = getRuntime(eventState)
    local usage = {}

    for index = 1, #((eventState and eventState.units) or {}) do
        local unit = eventState.units[index]
        local marker = math.max(0, math.floor(tonumber(unit and unit.raidMarker) or 0))
        if type(unit) == "table"
            and unit.isPlayer ~= true
            and isUnitActive(unit)
            and marker >= 1
            and marker <= 8
        then
            usage[marker] = (usage[marker] or 0) + 1
        end
    end

    for marker = 1, 8 do
        local used = (usage[marker] or 0) > 0
        local actorKey = used and ("marker:" .. tostring(marker)) or nil
        local position = used
            and type(runtime) == "table"
            and type(runtime.positionByActorKey) == "table"
            and runtime.positionByActorKey[actorKey]
            or nil
        local positionAvailable = used
            and type(Spatial.IsPositionAvailable) == "function"
            and Spatial.IsPositionAvailable(position) == true
            or false
        local lines = {}
        local reasonCode, reasonText = nil, nil
        appendDetail(lines, "Marker", marker)
        appendDetail(lines, "Active NPCs", usage[marker] or 0)
        if used then
            appendDetail(lines, "Actor", actorKey)
            appendDetail(lines, "Status", positionAvailable and "Position set" or "Position not set")
            appendDetail(lines, "Position", positionText(position))
            if not positionAvailable then
                reasonCode, reasonText = appendReason(lines, position and position.reason or "position-unset")
            end
        else
            lines[#lines + 1] = "No active NPCs currently use this raid marker."
        end

        states[#states + 1] = {
            kind = "marker-position",
            entryId = "autopilot-marker:" .. tostring(marker),
            actionType = "marker-position",
            actionId = "marker-position:" .. tostring(marker),
            raidMarker = marker,
            actorKey = actorKey,
            used = used,
            unitCount = usage[marker] or 0,
            position = position,
            positionAvailable = positionAvailable,
            canSetPosition = used and type(runtime) == "table" and runtime.status == "ready",
            summary = ("Marker %d — %s"):format(
                marker,
                used and (positionAvailable and "Position set" or "Position not set") or "Unused"
            ),
            text = ("Marker %d: %s"):format(
                marker,
                used and (positionAvailable and tostring(positionText(position) or "Position set") or "Position not set") or "Unused"
            ),
            details = table.concat(lines, "\n"),
            status = used and (positionAvailable and "ready" or "position-unset") or "unused",
            reasonCode = reasonCode,
            reasonText = reasonText,
        }
    end

    return states
end

local function buildMovementRow(eventState, action)
    local marker = math.max(0, math.floor(tonumber(action and action.raidMarker) or 0))
    local proposed = type(action) == "table" and action.proposedPosition or nil
    local destinationNames = targetNames(eventState, action and action.objectiveTargetEventIds)
    local status = tostring(action and action.status or "pending")
    local reason = tostring(action and action.reason or "")
    local displayText = ("Move marker %d near %s"):format(marker, destinationNames)
    if destinationNames == "no target" then
        displayText = ("Move marker %d to the proposed position"):format(marker)
    end

    local lines = {}
    appendDetail(lines, "Marker", marker)
    appendDetail(lines, "Actor", action and action.actorKey)
    appendDetail(lines, "Action", "Move shared marker cohort")
    appendDetail(lines, "Status", statusLabel(status))
    appendDetail(lines, "Near", destinationNames ~= "no target" and destinationNames or nil)
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
        actionId = action and action.actionId or nil,
        actorKey = action and action.actorKey or nil,
        raidMarker = marker,
        summary = displayText,
        displayText = displayText,
        objectiveText = destinationNames,
        text = displayText,
        details = table.concat(lines, "\n"),
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
    local displayText = ("%s casts %s at %s"):format(caster, spell, targets)

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
        actionId = action and action.actionId or nil,
        actorKey = action and action.actorKey or nil,
        casterEventId = action and action.casterEventId or nil,
        spellRef = action and action.spellRef or nil,
        targetEventIds = action and action.targetEventIds or nil,
        summary = displayText,
        displayText = displayText,
        text = displayText,
        details = table.concat(lines, "\n"),
        status = status,
        reasonCode = reasonCode,
        reasonText = reasonText,
        canAuthorize = status == "pending",
        canReject = status == "pending" or status == "blocked",
    }
end

function Helper.GetPendingActionRows(eventState)
    if not isHostAutopilotEvent(eventState) then
        return {}, nil
    end

    local pending = type(Client.GetAutopilotPendingPlan) == "function"
        and select(1, Client:GetAutopilotPendingPlan(eventState))
        or nil
    if type(pending) ~= "table" or tostring(pending.status or "") == "stale" then
        return {}, pending
    end

    local rows = {}
    for index = 1, #(pending.movementActionIds or {}) do
        local action = type(pending.actionsById) == "table"
            and pending.actionsById[pending.movementActionIds[index]]
            or nil
        if type(action) == "table" and tostring(action.status or "") ~= "stale" then
            rows[#rows + 1] = buildMovementRow(eventState, action)
        end
    end
    for index = 1, #(pending.spellActionIds or {}) do
        local action = type(pending.actionsById) == "table"
            and pending.actionsById[pending.spellActionIds[index]]
            or nil
        if type(action) == "table" and tostring(action.status or "") ~= "stale" then
            rows[#rows + 1] = buildSpellRow(eventState, action)
        end
    end
    return rows, pending
end

local function getOutcomeBucket(eventState, create)
    if not isHostAutopilotEvent(eventState) then
        return nil
    end
    local eventId = tostring(eventState.id or "")
    local turnNumber = math.max(0, math.floor(tonumber(eventState.turnNumber) or 0))
    if eventId == "" or turnNumber <= 0 then
        return nil
    end

    Client.AutopilotTurnOutcomesByEventId = type(Client.AutopilotTurnOutcomesByEventId) == "table"
        and Client.AutopilotTurnOutcomesByEventId
        or {}
    local bucket = Client.AutopilotTurnOutcomesByEventId[eventId]
    if type(bucket) ~= "table" or tonumber(bucket.turnNumber) ~= turnNumber then
        if create ~= true then
            return nil
        end
        bucket = {
            eventId = eventId,
            turnNumber = turnNumber,
            order = {},
            byKey = {},
        }
        Client.AutopilotTurnOutcomesByEventId[eventId] = bucket
    end
    return bucket
end

local function outcomeKey(entry)
    local checkId = tostring(type(entry) == "table" and entry.checkId or "")
    if checkId ~= "" then
        return checkId
    end
    return table.concat({
        tostring(type(entry) == "table" and entry.eventId or ""),
        tostring(type(entry) == "table" and entry.turnNumber or ""),
        tostring(type(entry) == "table" and entry.attackerEventId or ""),
        tostring(type(entry) == "table" and entry.defenderEventId or ""),
        tostring(type(entry) == "table" and entry.spellRef or ""),
        tostring(type(entry) == "table" and entry.componentKey or ""),
    }, ":")
end

local function isKillDamageResult(damageResult)
    if type(damageResult) ~= "table" then
        return false
    end
    for index = 1, #(damageResult.resourceDeltas or {}) do
        local delta = damageResult.resourceDeltas[index]
        if type(delta) == "table"
            and tostring(delta.resourceRef or "") == tostring(damageResult.healthResourceRef or "")
            and tonumber(delta.currentValue) ~= nil
            and tonumber(delta.currentValue) <= 0
        then
            return true
        end
    end
    local resourceEntry = damageResult.resourceEntry
    return type(resourceEntry) == "table"
        and tonumber(resourceEntry.currentValue) ~= nil
        and tonumber(resourceEntry.currentValue) <= 0
end

local function queueOutcomeRefresh()
    if type(Client.QueueAutopilotDMHelperRefresh) == "function" then
        Client:QueueAutopilotDMHelperRefresh()
    end
end

function Helper.RecordHitCheckOutcome(entry, landed)
    local eventState = type(entry) == "table" and entry.eventState or nil
    local bucket = getOutcomeBucket(eventState, true)
    if type(bucket) ~= "table" then
        return nil
    end

    local key = outcomeKey(entry)
    local outcome = bucket.byKey[key]
    if type(outcome) ~= "table" then
        outcome = {
            kind = "outcome",
            entryId = ("autopilot-outcome:%s:%d:%s"):format(bucket.eventId, bucket.turnNumber, key),
            key = key,
            sourceEventId = normalizeEventId(entry and entry.attackerEventId),
            targetEventId = normalizeEventId(entry and entry.defenderEventId),
            sourceName = unitName(eventState, entry and entry.attackerEventId),
            targetName = unitName(eventState, entry and entry.defenderEventId),
            spellRef = tostring(entry and entry.spellRef or ""),
            componentKey = tostring(entry and entry.componentKey or ""),
            attackType = tostring(entry and entry.attackType or ""),
            landed = landed == true,
            defended = landed ~= true,
            critical = false,
            killed = false,
        }
        bucket.byKey[key] = outcome
        bucket.order[#bucket.order + 1] = key
    else
        outcome.landed = landed == true
        outcome.defended = landed ~= true
    end

    queueOutcomeRefresh()
    return outcome
end

function Helper.UpdateDamageOutcome(entry, damageResult)
    local eventState = type(entry) == "table" and entry.eventState or nil
    local bucket = getOutcomeBucket(eventState, true)
    if type(bucket) ~= "table" then
        return nil
    end

    local key = outcomeKey(entry)
    local outcome = bucket.byKey[key]
    if type(outcome) ~= "table" then
        outcome = Helper.RecordHitCheckOutcome(entry, true)
        bucket = getOutcomeBucket(eventState, false)
        outcome = type(bucket) == "table" and bucket.byKey[key] or outcome
    end
    if type(outcome) ~= "table" then
        return nil
    end

    local changed = false
    if type(damageResult) == "table" and damageResult.wasCritical == true and outcome.critical ~= true then
        outcome.critical = true
        changed = true
    end
    if isKillDamageResult(damageResult) and outcome.killed ~= true then
        outcome.killed = true
        changed = true
    end
    if changed then
        queueOutcomeRefresh()
    end
    return outcome
end

function Helper.GetTurnOutcomes(eventState)
    local bucket = getOutcomeBucket(eventState, false)
    if type(bucket) ~= "table" then
        return {}
    end

    local rows = {}
    for index = 1, #(bucket.order or {}) do
        local outcome = bucket.byKey[bucket.order[index]]
        if type(outcome) == "table" then
            local labels = {}
            if outcome.defended == true then
                labels[#labels + 1] = "Defended"
            else
                labels[#labels + 1] = "Hit"
            end
            if outcome.critical == true then
                labels[#labels + 1] = "Critical"
            end
            if outcome.killed == true then
                labels[#labels + 1] = "Killed"
            end
            local actionName = tostring(outcome.spellRef or "") ~= "" and spellName(outcome.spellRef) or nil
            if not actionName or actionName == "" then
                local attackType = string.lower(tostring(outcome.attackType or ""))
                if attackType == "melee" then
                    actionName = "Melee attack"
                elseif attackType == "ranged" then
                    actionName = "Ranged attack"
                elseif attackType == "spell" then
                    actionName = "Spell attack"
                else
                    actionName = "Attack"
                end
            end
            local summary = ("%s -> %s — %s — %s"):format(
                tostring(outcome.sourceName or "Unknown"),
                tostring(outcome.targetName or "Unknown"),
                actionName,
                table.concat(labels, " · ")
            )
            local lines = {
                ("Source: %s"):format(tostring(outcome.sourceName or "Unknown")),
                ("Target: %s"):format(tostring(outcome.targetName or "Unknown")),
                ("Action: %s"):format(actionName),
                ("Outcome: %s"):format(table.concat(labels, " · ")),
            }
            rows[#rows + 1] = {
                kind = "outcome",
                entryId = outcome.entryId,
                sourceEventId = outcome.sourceEventId,
                targetEventId = outcome.targetEventId,
                spellRef = outcome.spellRef,
                summary = summary,
                displayText = summary,
                details = table.concat(lines, "\n"),
                landed = outcome.landed == true,
                defended = outcome.defended == true,
                critical = outcome.critical == true,
                killed = outcome.killed == true,
            }
        end
    end
    return rows
end

function Helper.BuildOverviewDetails(eventState)
    if not isHostAutopilotEvent(eventState) then
        return "Autopilot DM Helper is unavailable for this event."
    end

    local lines = {}
    local runtime = getRuntime(eventState)
    local pending = type(Client.GetAutopilotPendingPlan) == "function"
        and select(1, Client:GetAutopilotPendingPlan(eventState))
        or nil
    local statusRow = buildStatusRow(eventState, runtime, pending)
    lines[#lines + 1] = tostring(statusRow.summary or "Autopilot")

    if type(pending) == "table" and tostring(pending.status or "") ~= "stale" then
        for index = 1, #(pending.warnings or {}) do
            local warning = pending.warnings[index]
            local text = tostring(warning and (warning.text or warning.reason) or "Autopilot warning")
            lines[#lines + 1] = "Warning: " .. text
            local reason = tostring(warning and warning.reason or "")
            if reason ~= "" then
                lines[#lines + 1] = "Reason: " .. tostring(Helper.GetReasonText(reason) or reason)
            end
        end
        for index = 1, #(pending.noActions or {}) do
            local noAction = pending.noActions[index]
            local caster = unitName(eventState, noAction and noAction.casterEventId)
            local reason = tostring(noAction and noAction.reason or "no-useful-action")
            lines[#lines + 1] = ("%s: No Action — %s"):format(caster, tostring(Helper.GetReasonText(reason) or reason))
        end
    end

    if #lines == 1 then
        lines[#lines + 1] = "Select a raid marker, pending action, or turn outcome for full details."
    end
    return table.concat(lines, "\n")
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
    local markers = Helper.GetMarkerStates(eventState)
    for index = 1, #markers do
        if markers[index] and markers[index].used == true then
            entries[#entries + 1] = markers[index]
        end
    end
    if type(pending) ~= "table" then
        return entries
    end

    for index = 1, #(pending.movementActionIds or {}) do
        local action = type(pending.actionsById) == "table"
            and pending.actionsById[pending.movementActionIds[index]]
            or nil
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
        local action = type(pending.actionsById) == "table"
            and pending.actionsById[pending.spellActionIds[index]]
            or nil
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

function Client:GetAutopilotMarkerStates(eventStateOverride)
    local eventState = type(eventStateOverride) == "table"
        and eventStateOverride
        or (type(self.GetEventState) == "function" and self:GetEventState() or self.EventState)
    return Helper.GetMarkerStates(eventState)
end

function Client:GetAutopilotPendingActionRows(eventStateOverride)
    local eventState = type(eventStateOverride) == "table"
        and eventStateOverride
        or (type(self.GetEventState) == "function" and self:GetEventState() or self.EventState)
    return Helper.GetPendingActionRows(eventState)
end

function Client:GetAutopilotTurnOutcomes(eventStateOverride)
    local eventState = type(eventStateOverride) == "table"
        and eventStateOverride
        or (type(self.GetEventState) == "function" and self:GetEventState() or self.EventState)
    return Helper.GetTurnOutcomes(eventState)
end

function Client:GetAutopilotDMHelperOverview(eventStateOverride)
    local eventState = type(eventStateOverride) == "table"
        and eventStateOverride
        or (type(self.GetEventState) == "function" and self:GetEventState() or self.EventState)
    return Helper.BuildOverviewDetails(eventState)
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

local function installOutcomeHooks()
    if Helper._outcomeHooksInstalled == true then
        return true
    end

    local baseCompleteHitCheck = Combat.CompleteHitCheck
    if type(baseCompleteHitCheck) == "function" then
        function Combat:CompleteHitCheck(entry, resultToken, reason, ...)
            local results = pack(baseCompleteHitCheck(self, entry, resultToken, reason, ...))
            if results[1] == true then
                local result = results[2]
                local landed = type(result) == "table" and result.landed == true
                    or tostring(resultToken or "") == "pass"
                Helper.RecordHitCheckOutcome(entry, landed)
            end
            return unpack(results, 1, results.n)
        end
    end

    local baseFinalizeLocalDamageResult = Combat.FinalizeLocalDamageResult
    if type(baseFinalizeLocalDamageResult) == "function" then
        function Combat:FinalizeLocalDamageResult(entry, damageResult, ...)
            local results = pack(baseFinalizeLocalDamageResult(self, entry, damageResult, ...))
            Helper.UpdateDamageOutcome(entry, damageResult)
            return unpack(results, 1, results.n)
        end
    end

    local baseHandleDamageHitCheckResponse = Combat.HandleDamageHitCheckResponse
    if type(baseHandleDamageHitCheckResponse) == "function" then
        function Combat:HandleDamageHitCheckResponse(client, arguments, sender, ...)
            local checkId = tostring(arguments and arguments[1] or "")
            local entry = checkId ~= ""
                and type(client) == "table"
                and type(client.GetPendingCombatHitCheck) == "function"
                and client:GetPendingCombatHitCheck(checkId)
                or nil
            local results = pack(baseHandleDamageHitCheckResponse(self, client, arguments, sender, ...))
            if results[1] == true and type(entry) == "table" and type(entry.lastDamageResult) == "table" then
                Helper.UpdateDamageOutcome(entry, entry.lastDamageResult)
            end
            return unpack(results, 1, results.n)
        end
    end

    Helper._outcomeHooksInstalled = true
    return true
end

if type(Client.RegisterDMHelperProvider) == "function" then
    Client:RegisterDMHelperProvider("autopilot", function(_, eventState)
        return Helper.BuildEntries(eventState)
    end)
end

installOutcomeHooks()
return Helper