local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Server = Addon.Server
local Client = Addon.Client or {}
local EventUnit = Addon.Internal.Database.Classes.EventUnit
local Common = Addon.Utils and Addon.Utils.Common or {}

if type(EventUnit) ~= "table" or type(Server) ~= "table" then
    return
end

local function normalizeName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end
    return tostring(value or "")
end

local function normalizeEventId(value)
    local numericValue = tonumber(value)
    if numericValue == nil or numericValue <= 0 or numericValue ~= math.floor(numericValue) then
        return nil
    end
    return math.floor(numericValue)
end

local function findEventUnit(units, eventId)
    local normalizedEventId = normalizeEventId(eventId)
    if not normalizedEventId then
        return nil
    end

    for index = 1, #(units or {}) do
        local unit = units[index]
        if normalizeEventId(unit and unit.eventID) == normalizedEventId then
            return unit
        end
    end

    return nil
end

local function validateEventIdList(values, fieldName, requireExisting, units)
    if type(values) ~= "table" or #values == 0 then
        return nil, ("%s must contain at least one Event unit ID."):format(fieldName)
    end

    local normalized = {}
    local seen = {}
    for index = 1, #values do
        local eventId = normalizeEventId(values[index])
        if not eventId then
            return nil, ("%s contains an invalid Event unit ID."):format(fieldName)
        end
        if seen[eventId] then
            return nil, ("%s contains duplicate Event unit ID #%d."):format(fieldName, eventId)
        end
        seen[eventId] = true

        if requireExisting then
            local unit = findEventUnit(units, eventId)
            if not unit then
                return nil, ("Event unit #%d no longer exists."):format(eventId)
            end
            if unit.isPlayer == true then
                return nil, ("Event unit #%d is a player and cannot be renamed."):format(eventId)
            end
        end

        normalized[#normalized + 1] = eventId
    end

    table.sort(normalized)
    return normalized
end

local function contains(values, value)
    for index = 1, #(values or {}) do
        if values[index] == value then
            return true
        end
    end
    return false
end

local function refreshPresentation(server, reason)
    local eventManage = Addon.Server.UI and Addon.Server.UI.EventManage
    if type(eventManage) == "table" then
        if type(eventManage.InvalidateEditableSettingsState) == "function" then
            eventManage:InvalidateEditableSettingsState()
        end
        if type(eventManage.RefreshUnitsPage) == "function" then
            eventManage:RefreshUnitsPage()
        end
        if type(eventManage.RefreshActivePage) == "function" then
            eventManage:RefreshActivePage()
        end
    end

    if server.EventState and server.EventState.active == true
        and type(Client.QueueEventWidgetRefresh) == "function"
    then
        Client:QueueEventWidgetRefresh(reason or "event-unit-display-name")
    end
end

function Server:SetEventUnitDisplayNameOverrides(eventIds, displayName, options)
    options = type(options) == "table" and options or {}
    local eventState = type(self.GetEditableEventState) == "function" and self:GetEditableEventState() or nil
    if type(eventState) ~= "table" then
        return false, "event-inactive"
    end

    local localHostName = normalizeName(Common.GetPlayerName and Common.GetPlayerName() or "")
    local eventHostName = normalizeName(eventState.hostName)
    if localHostName == "" or (eventHostName ~= "" and localHostName ~= eventHostName) then
        return false, "local-event-host-required"
    end

    local units = eventState.units or {}
    local selectedIds, selectedError = validateEventIdList(eventIds, "eventIds", true, units)
    if not selectedIds then
        return false, selectedError
    end

    local normalizedName, nameError = EventUnit.NormalizeDisplayNameOverride(displayName)
    local resetting = options.reset == true
    if not resetting and not normalizedName then
        return false, nameError or "display-name-required"
    end

    local previousIds = {}
    if options.previousEventIds ~= nil then
        local previousError
        previousIds, previousError = validateEventIdList(options.previousEventIds, "previousEventIds", false, units)
        if not previousIds then
            return false, previousError
        end
    end

    local previousDisplayName = nil
    if options.previousDisplayName ~= nil then
        local rawPreviousDisplayName = tostring(options.previousDisplayName or "")
        if rawPreviousDisplayName:gsub("^%s+", ""):gsub("%s+$", "") ~= "" then
            local previousNameError
            previousDisplayName, previousNameError = EventUnit.NormalizeDisplayNameOverride(rawPreviousDisplayName)
            if not previousDisplayName then
                return false, previousNameError or "previous-display-name-invalid"
            end
        end
    end

    local changes = {}
    local changedIds = {}
    local function stage(unit, nextOverride)
        if not unit then
            return
        end
        local current = EventUnit.NormalizeDisplayNameOverride(unit.displayNameOverride)
        if current ~= nextOverride then
            changes[#changes + 1] = {
                operation = "upsert",
                eventID = unit.eventID,
                unit = unit,
                previousOverride = current,
                nextOverride = nextOverride,
            }
            changedIds[#changedIds + 1] = normalizeEventId(unit.eventID)
        end
    end

    -- Apply additions/reassignments first. This makes a selected NPC's new
    -- assignment authoritative even if it previously belonged to another row.
    for index = 1, #selectedIds do
        local unit = findEventUnit(units, selectedIds[index])
        stage(unit, resetting and nil or normalizedName)
    end

    -- Editing an existing row is a replace-group operation. Only clear an ID
    -- removed from that row when it still carries that row's old assignment;
    -- this protects a newer reassignment from a stale editor snapshot.
    for index = 1, #previousIds do
        local eventId = previousIds[index]
        if not contains(selectedIds, eventId) then
            local unit = findEventUnit(units, eventId)
            local current = EventUnit.NormalizeDisplayNameOverride(unit and unit.displayNameOverride)
            if unit and unit.isPlayer ~= true and (previousDisplayName == nil or current == previousDisplayName) then
                stage(unit, nil)
            end
        end
    end

    if #changes > 0 then
        for index = 1, #changes do
            changes[index].unit.displayNameOverride = changes[index].nextOverride
        end

        if eventState.active == true then
            if type(self.BroadcastEventDeltaBatch) == "function" then
                local entries = {}
                for index = 1, #changes do
                    entries[index] = changes[index]
                end
                local sent = self:BroadcastEventDeltaBatch(entries, false)
                if sent ~= true then
                    -- The local authoritative mutation remains valid; report
                    -- transport failure explicitly and roll back the local
                    -- mutation so the UI cannot treat an unacknowledged
                    -- update as saved.
                    for index = 1, #changes do
                        changes[index].unit.displayNameOverride = changes[index].previousOverride
                    end
                    return false, "event-unit-display-name-broadcast-failed"
                end
            else
                for index = 1, #changes do
                    changes[index].unit.displayNameOverride = changes[index].previousOverride
                end
                return false, "event-unit-display-name-broadcast-unavailable"
            end
            if type(self.CopyLiveEventToDraftState) == "function" then
                self:CopyLiveEventToDraftState()
            end
        end
    end

    for index = 1, #changes do
        changes[index].nextOverride = nil
        changes[index].previousOverride = nil
    end

    refreshPresentation(self, "event-unit-display-name")
    return true, changedIds
end
