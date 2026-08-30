local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Registry = Addon.Internal.Registry or {}

Client.AutopilotHelper = Client.AutopilotHelper or {}
local Helper = Client.AutopilotHelper

Client.DMHelperProviders = Client.DMHelperProviders or {}
Client.DMHelperProviderOrder = Client.DMHelperProviderOrder or {}

local function normalizeEventId(value)
    local eventId = math.floor(tonumber(value) or 0)
    return eventId > 0 and eventId or 0
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

local function isHost(eventState)
    return type(eventState) == "table"
        and eventState.active == true
        and type(Client.IsLocalEventHost) == "function"
        and Client:IsLocalEventHost(eventState) == true
end

local function buildStatusRow(eventState, runtime, pending)
    local status = type(runtime) == "table" and tostring(runtime.plannerStatus or "ready") or "ready"
    local text = "Autopilot: " .. statusLabel(status)
    if type(runtime) == "table" and runtime.status ~= "ready" then
        text = "Autopilot unavailable: " .. tostring(runtime.unavailableReason or "position unavailable")
    elseif type(pending) == "table" and tostring(pending.status or "") ~= "stale" then
        if type(pending.spellActionIds) == "table" or type(pending.movementActionIds) == "table" then
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

local function buildMovementRow(eventState, action)
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
    if status == "blocked" and tostring(action.reason or "") ~= "" then
        text = text .. " " .. tostring(action.reason)
    elseif status == "stale" and tostring(action.reason or "") ~= "" then
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
    if not isHost(eventState) then
        return {}
    end
    local entries = {}
    local runtime = getRuntime(eventState)
    local pending = type(Client.GetAutopilotPendingPlan) == "function"
        and select(1, Client:GetAutopilotPendingPlan(eventState))
        or nil

    entries[#entries + 1] = buildStatusRow(eventState, runtime, pending)
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

function Client:RegisterDMHelperProvider(key, provider)
    local normalizedKey = tostring(key or "")
    if normalizedKey == "" or type(provider) ~= "function" then
        return false
    end
    if self.DMHelperProviders[normalizedKey] == nil then
        self.DMHelperProviderOrder[#self.DMHelperProviderOrder + 1] = normalizedKey
    end
    self.DMHelperProviders[normalizedKey] = provider
    return true
end

local baseGetDMHelperEntries = Client.GetDMHelperEntries
function Client:GetDMHelperEntries(eventStateOverride)
    local eventState = type(eventStateOverride) == "table"
        and eventStateOverride
        or (type(self.GetEventState) == "function" and self:GetEventState() or self.EventState)
    if not isHost(eventState) then
        return {}
    end

    local entries = {}
    if type(baseGetDMHelperEntries) == "function" then
        local baseEntries = baseGetDMHelperEntries(self, eventState)
        for index = 1, #(baseEntries or {}) do
            entries[#entries + 1] = baseEntries[index]
        end
    end
    for index = 1, #(self.DMHelperProviderOrder or {}) do
        local provider = self.DMHelperProviders[self.DMHelperProviderOrder[index]]
        if type(provider) == "function" then
            local provided = provider(self, eventState)
            for entryIndex = 1, #(provided or {}) do
                entries[#entries + 1] = provided[entryIndex]
            end
        end
    end
    return entries
end

function Client:QueueAutopilotDMHelperRefresh()
    local widget = self.UI and self.UI.EventWidget or nil
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

Client:RegisterDMHelperProvider("autopilot", function(_, eventState)
    return Helper.BuildEntries(eventState)
end)

return Helper
