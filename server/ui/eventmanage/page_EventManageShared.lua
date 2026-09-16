local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}

local Server = Addon.Server
local ServerUI = Addon.Server.UI
local Debug = Addon.Debug or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local EventUnit = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.EventUnit or nil
local Event = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Event or nil
local UI = Addon.UI or {}

ServerUI.EventManage = ServerUI.EventManage or {}
local EventManage = ServerUI.EventManage

EventManage.Layout = EventManage.Layout or {
    WindowWidth = 520,
    WindowHeight = 318,
    PageContentWidth = 480,
    DashboardToolbarButtonWidth = 78,
    DashboardAdvanceButtonWidth = 104,
    DashboardStatusRowHeight = 156,
    DashboardStatusTextWidth = 220,
    DashboardHashTextWidth = 236,
    DashboardWarningHeight = 24,
    UnitsTablePanelHeight = 218,
    UnitsTableWidth = 468,
    UnitsVisibleRows = 8,
    SettingsWidth = 480,
    SettingsNameInputWidth = 180,
    SettingsSubtextInputWidth = 260,
}

local function coerceEventUnitBoolean(value, defaultValue)
    if EventUnit and EventUnit.CoerceBoolean then
        return EventUnit.CoerceBoolean(value, defaultValue)
    end

    if value == nil then
        return defaultValue == true
    end

    if value == true or value == false then
        return value
    end

    local numericValue = tonumber(value)
    if numericValue ~= nil then
        return numericValue ~= 0
    end

    if type(value) == "string" then
        local normalized = string.lower(value)
        if normalized == "true" or normalized == "yes" or normalized == "on" then
            return true
        end
        if normalized == "false" or normalized == "no" or normalized == "off" then
            return false
        end
    end

    return defaultValue == true
end

local function formatValue(value, emptyValue)
    if type(value) == "boolean" then
        return value and "Active" or "Inactive"
    end

    if value == nil or value == "" then
        return emptyValue or "-"
    end

    return tostring(value)
end

local function formatList(values)
    if not values or #values == 0 then
        return "-"
    end

    return table.concat(values, ", ")
end

local function buildSignature(...)
    local parts = {}

    for index = 1, select("#", ...) do
        local value = select(index, ...)
        parts[index] = tostring(value == nil and "" or value)
    end

    return table.concat(parts, "\31")
end

local function buildUnitRowsSignature(rows, totalCount, playerCount, npcCount, serverActive)
    local parts = {
        buildSignature(totalCount, playerCount, npcCount, serverActive == true and 1 or 0),
    }

    for index = 1, #(rows or {}) do
        local row = rows[index]
        parts[#parts + 1] = buildSignature(
            tonumber(row and row.raidMarker) or 0,
            tonumber(row and row.team) or 0,
            tonumber(row and row.eventID) or 0,
            tostring(row and row.name or ""),
            tostring(row and row.registryID or ""),
            row and row.isPlayer == true and 1 or 0,
            row and row.active == true and 1 or 0,
            row and row.hidden == true and 1 or 0,
            row and row.showInNpcMode == true and 1 or 0
        )
    end

    return table.concat(parts, "\30")
end

function EventManage:IsDashboardPageActive()
    local window = self.Window
    local activeTab = window and window.GetActiveTab and window:GetActiveTab() or nil
    return activeTab and activeTab.name == "page_Dashboard"
end

function EventManage:IsUnitsPageActive()
    local window = self.Window
    local activeTab = window and window.GetActiveTab and window:GetActiveTab() or nil
    return activeTab and activeTab.name == "page_Units"
end

function EventManage:IsSettingsPageActive()
    local window = self.Window
    local activeTab = window and window.GetActiveTab and window:GetActiveTab() or nil
    return activeTab and activeTab.name == "page_Settings"
end

function EventManage:RefreshActivePage()
    if not self.IsWindowVisible or not self:IsWindowVisible() then
        return false
    end

    if self:IsDashboardPageActive() then
        return self:RefreshDashboard()
    end
    if self:IsUnitsPageActive() then
        return self:RefreshUnitsPage()
    end
    if self:IsSettingsPageActive() and self.RefreshSettingsPage then
        return self:RefreshSettingsPage()
    end

    return false
end

function EventManage:BuildSessionSummary()
    local state = Server.GetState and Server:GetState() or nil
    if not state then
        return "Status: Inactive\nDistribution: -\nChannel: -\nChannel ID: -\nStarted At: -\nClients: -"
    end

    return table.concat({
        ("Status: %s"):format(formatValue(state.active)),
        ("Distribution: %s"):format(formatValue(state.distribution)),
        ("Channel: %s"):format(formatValue(state.channelName)),
        ("Channel ID: %s"):format(formatValue(state.channelId)),
        ("Started At: %s"):format(formatValue(state.startedAt)),
        ("Clients: %s"):format(formatList(state.clientOrder)),
    }, "\n")
end

function EventManage:BuildEventSummary()
    local state = Server.GetEventState and Server:GetEventState() or nil
    local editableState = Server.GetEditableEventState and Server:GetEditableEventState() or nil
    local modeState = editableState or state
    local eventMode = Event and Event.NormalizeEventMode and Event.NormalizeEventMode(modeState and modeState.eventMode) or "combat"
    local eventModeLabel = eventMode == "npc" and "NPC" or "Combat"
    if not state then
        return ("Status: Inactive  Mode: %s\nEvent ID: -\nName: -\nHost: -\nChannel: -\nStarted At: -\nTurn: -\nTick: -"):format(eventModeLabel)
    end

    local rosterReady = state.rosterReady == true
    local healthReady = state.resourcesReady == true

    return table.concat({
        ("Status: %s  Mode: %s"):format(formatValue(state.active), eventModeLabel),
        ("Event ID: %s"):format(formatValue(state.id)),
        ("Name: %s"):format(formatValue(state.name, "Unnamed")),
        ("Subtext: %s"):format(formatValue(state.subtext)),
        ("Host: %s"):format(formatValue(state.hostName)),
        ("Channel: %s"):format(formatValue(state.channelName)),
        ("Started At: %s"):format(formatValue(state.startedAt)),
        ("Roster Ready: %s"):format(formatValue(rosterReady)),
        ("Health Ready: %s"):format(formatValue(healthReady)),
        ("Ready: %s"):format(formatValue(state.unitsReady == true)),
        ("Turn: %s"):format(formatValue(state.turnNumber)),
        ("Tick: %s"):format(state.totalTicks and state.totalTicks > 0 and ("%s / %s"):format(formatValue(state.tickNumber, "0"), formatValue(state.totalTicks, "0")) or formatValue(state.tickNumber)),
    }, "\n")
end

function EventManage:BuildUnitRows()
    local eventState = Server.GetEditableEventState and Server:GetEditableEventState() or nil
    local units = eventState and eventState.units or {}
    local rows = {}

    for index = 1, #units do
        local unit = units[index]
        rows[#rows + 1] = {
            raidMarker = unit and unit.raidMarker or 0,
            team = unit and unit.team or 0,
            teamName = Event and Event.GetTeamName and Event.GetTeamName(eventState, unit and unit.team or 0) or ("Team %d"):format(tonumber(unit and unit.team) or 0),
            eventID = unit and unit.eventID or nil,
            boss = EventUnit and EventUnit.IsBoss and EventUnit.IsBoss(unit) or coerceEventUnitBoolean(unit and unit.boss, false),
            name = unit and unit.name or "",
            registryID = unit and unit.registryID or "",
            isPlayer = unit and unit.isPlayer == true or false,
            active = EventUnit and EventUnit.IsActive and EventUnit.IsActive(unit) or (unit and (unit.isPlayer == true or coerceEventUnitBoolean(unit.active, true)) or false),
            hidden = EventUnit and EventUnit.IsHidden and EventUnit.IsHidden(unit) or coerceEventUnitBoolean(unit and unit.hidden, false),
            showInNpcMode = EventUnit and EventUnit.IsShownInNpcMode and EventUnit.IsShownInNpcMode(unit) or coerceEventUnitBoolean(unit and unit.showInNpcMode, false),
            sourceUnit = unit,
        }
    end

    return rows
end

function EventManage:SummarizeUnits()
    local eventState = Server.GetEditableEventState and Server:GetEditableEventState() or nil
    local units = eventState and eventState.units or {}
    local totalCount = 0
    local playerCount = 0
    local npcCount = 0

    for index = 1, #units do
        local unit = units[index]
        totalCount = totalCount + 1

        if unit and unit.isPlayer == true then
            playerCount = playerCount + 1
        else
            npcCount = npcCount + 1
        end
    end

    return totalCount, playerCount, npcCount
end

function EventManage:BuildRaidMarkerMenuItems(selectedMarker)
    local items = {}

    for marker = 1, 8 do
        items[#items + 1] = {
            label = ("Raid Marker %d"):format(marker),
            value = marker,
            checked = (tonumber(selectedMarker) or 0) == marker,
        }
    end

    items[#items + 1] = {
        label = "Clear Raid Marker",
        value = 0,
        checked = (tonumber(selectedMarker) or 0) == 0,
    }

    return items
end

function EventManage:BuildTeamMenuItems(selectedTeam)
    local items = {}
    local currentTeam = tonumber(selectedTeam) or 1
    local eventState = Server.GetEditableEventState and Server:GetEditableEventState() or nil
    local teams = eventState and eventState.teams or nil

    for team = 1, #(teams or {}) do
        items[#items + 1] = {
            label = Event and Event.GetTeamName and Event.GetTeamName(eventState, team) or ("Team %d"):format(team),
            value = team,
            checked = currentTeam == team,
        }
    end

    if #items == 0 then
        items[1] = {
            label = "Team 1",
            value = 1,
            checked = currentTeam == 1,
        }
    end

    return items
end

function EventManage:BuildUnitTooltip(rowData)
    if not rowData then
        return nil
    end

    local unitName = rowData.name ~= nil and rowData.name ~= "" and tostring(rowData.name) or "Unnamed Unit"
    local registryID = rowData.registryID ~= nil and rowData.registryID ~= "" and tostring(rowData.registryID) or "-"
    local eventID = rowData.eventID ~= nil and tostring(rowData.eventID) or "-"
    local team = tonumber(rowData.team) or 0
    local teamName = tostring(rowData.teamName or "")
    local raidMarker = tonumber(rowData.raidMarker) or 0

    return {
        type = "custom",
        title = unitName,
        lines = {
            ("Event ID: %s"):format(eventID),
            ("Registry ID: %s"):format(registryID),
            ("Team: %s"):format(teamName ~= "" and ("%s (%d)"):format(teamName, team) or tostring(team)),
            ("Raid Marker: %s"):format(raidMarker > 0 and tostring(raidMarker) or "-"),
            ("Boss: %s"):format(rowData.boss == true and "Yes" or "No"),
            ("State: %s"):format(rowData.active == true and "Active" or "Inactive"),
            ("Visibility: %s"):format(rowData.hidden == true and "Hidden" or "Visible"),
            ("NPC Mode: %s"):format(rowData.isPlayer == true and "Not Applicable" or rowData.showInNpcMode == true and "Shown" or "Hidden"),
        },
    }
end

function EventManage:BuildUnitCellTooltip(_, rowData)
    return self:BuildUnitTooltip(rowData)
end

function EventManage:CanAdvanceEventStep()
    local client = Addon.Client
    if type(client) ~= "table"
        or type(client.GetEventState) ~= "function"
        or type(client.CanPerformEventAction) ~= "function"
        or type(client.IsLocalEventHost) ~= "function"
        or type(Server.AdvanceEventStep) ~= "function"
    then
        return false
    end

    if type(Server.IsActive) ~= "function" or Server:IsActive() ~= true then
        return false
    end
    if type(Server.IsEventUnitsReady) ~= "function" or Server:IsEventUnitsReady() ~= true then
        return false
    end

    local serverEventState = Server.GetEventState and Server:GetEventState() or Server.EventState
    local eventState = client:GetEventState()
    if type(serverEventState) ~= "table"
        or serverEventState.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or tostring(serverEventState.id or "") ~= tostring(eventState.id or "")
        or client:IsLocalEventHost(eventState) ~= true
    then
        return false
    end

    if Event and Event.NormalizeEventMode and Event.NormalizeEventMode(serverEventState.eventMode) == "npc" then
        return false
    end

    return client:CanPerformEventAction(eventState, "advance-event-step") == true
end

function EventManage:RefreshDashboard()
    local layout = self.Layout or {}
    local mismatches = Server.GetClientHashMismatches and Server:GetClientHashMismatches() or {}
    local hasClientHashMismatch = #mismatches > 0
    local datasetHash = Registry.GenerateActivatedDatasetsHash and Registry:GenerateActivatedDatasetsHash() or nil
    local rulesetHash = Registry.GenerateActiveRulesetHash and Registry:GenerateActiveRulesetHash() or nil
    local warningText = Server.BuildClientHashMismatchWarning and Server:BuildClientHashMismatchWarning() or nil
    if type(Debug.Internal) == "function" then
        Debug.Internal(
            "Compatibility refresh client=%s revision=%d datasetHash=%s rulesetHash=%s stage=dashboard-refresh reason=state-change mismatches=%d.",
            tostring(Addon.Utils and Addon.Utils.Common and Addon.Utils.Common.GetPlayerName and Addon.Utils.Common.GetPlayerName() or "unknown"),
            math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0)),
            tostring(datasetHash or ""),
            tostring(rulesetHash or ""),
            #mismatches
        )
    end
    local sessionSummary = self:BuildSessionSummary()
    local eventSummary = self:BuildEventSummary()
    local serverActive = Server.IsActive and Server:IsActive() or false
    local eventActive = Server.IsEventActive and Server:IsEventActive() or false
    local editableEventState = Server.GetEditableEventState and Server:GetEditableEventState() or nil
    local eventMode = Event and Event.NormalizeEventMode and Event.NormalizeEventMode(editableEventState and editableEventState.eventMode) or "combat"
    local eventUnitsReady = Server.IsEventUnitsReady and Server:IsEventUnitsReady() or false
    local canAdvanceEventStep = self:CanAdvanceEventStep()
    local signature = buildSignature(
        datasetHash,
        rulesetHash,
        warningText,
        sessionSummary,
        eventSummary,
        hasClientHashMismatch == true and 1 or 0,
        serverActive == true and 1 or 0,
        eventActive == true and 1 or 0,
        eventMode,
        eventUnitsReady == true and 1 or 0,
        canAdvanceEventStep == true and 1 or 0
    )

    if self.LastDashboardRefreshSignature == signature then
        return true
    end

    self.LastDashboardRefreshSignature = signature

    if self.DatasetHashText and self.DatasetHashText.SetText then
        self.DatasetHashText:SetText(("Dataset Hash: %s"):format(formatValue(datasetHash)))
    end

    if self.RulesetHashText and self.RulesetHashText.SetText then
        self.RulesetHashText:SetText(("Ruleset Hash: %s"):format(formatValue(rulesetHash)))
    end

    if self.HashWarningText and self.HashWarningText.SetText then
        self.HashWarningText:SetText(tostring(warningText or ""))
        if self.HashWarningText.SetHeight then
            self.HashWarningText:SetHeight(warningText and warningText ~= "" and (layout.DashboardWarningHeight or 24) or 0)
        end
    end

    if self.SessionStatusText and self.SessionStatusText.SetText then
        self.SessionStatusText:SetText(sessionSummary)
    end

    if self.EventStatusText and self.EventStatusText.SetText then
        self.EventStatusText:SetText(eventSummary)
    end

    if self.StartServerButton and self.StartServerButton.SetEnabled then
        self.StartServerButton:SetEnabled(not serverActive)
    end

    if self.StopServerButton and self.StopServerButton.SetEnabled then
        self.StopServerButton:SetEnabled(serverActive)
    end

    if self.StartEventButton and self.StartEventButton.SetEnabled then
        -- Keep the button clickable during a mismatch so its Shift-held
        -- dashboard override can deliberately start the event.
        self.StartEventButton:SetEnabled(serverActive and not eventActive)
    end

    if self.StopEventButton and self.StopEventButton.SetEnabled then
        self.StopEventButton:SetEnabled(eventActive)
    end

    if self.AdvanceEventStepButton and self.AdvanceEventStepButton.SetEnabled then
        self.AdvanceEventStepButton:SetEnabled(canAdvanceEventStep)
    end
    if self.AdvanceEventStepButton then
        if self.AdvanceEventStepButton.SetWidth then
            self.AdvanceEventStepButton:SetWidth(eventMode == "npc" and 0 or self.AdvanceEventStepButtonWidth or (layout.DashboardAdvanceButtonWidth or 104))
        end
        local frame = self.AdvanceEventStepButton.GetFrame and self.AdvanceEventStepButton:GetFrame() or nil
        if frame then
            if eventMode == "npc" then
                frame:Hide()
            else
                frame:Show()
            end
        end
        if self.DashboardToolbarLayout and self.DashboardToolbarLayout.RefreshLayout then
            self.DashboardToolbarLayout:RefreshLayout()
        end
    end

    return true
end

function EventManage:RefreshUnitsPage()
    local rows = self:BuildUnitRows()
    local totalCount, playerCount, npcCount = self:SummarizeUnits()
    local serverActive = Server.IsActive and Server:IsActive() or false
    local signature = buildUnitRowsSignature(rows, totalCount, playerCount, npcCount, serverActive)

    if self.LastUnitsPageRefreshSignature == signature then
        return true
    end

    self.LastUnitsPageRefreshSignature = signature

    if self.UnitsTable and self.UnitsTable.SetRows then
        self.UnitsTable:SetRows(rows)
    end
    if self.BindUnitsTableRowHandlers then
        self:BindUnitsTableRowHandlers()
    end

    if self.UnitsToolbarInfoText and self.UnitsToolbarInfoText.SetText then
        self.UnitsToolbarInfoText:SetText(("Total: %d  Players: %d  NPCs: %d"):format(totalCount, playerCount, npcCount))
    end

    if self.UnitsAddNpcButton and self.UnitsAddNpcButton.SetEnabled then
        self.UnitsAddNpcButton:SetEnabled(serverActive)
    end

    if self.UnitsClearNpcButton and self.UnitsClearNpcButton.SetEnabled then
        self.UnitsClearNpcButton:SetEnabled(serverActive and npcCount > 0)
    end

    return true
end

function EventManage:BuildActivityMenuItem(isActive, isPlayer)
    if isActive == true then
        return {
            label = "Set Inactive",
            value = 0,
            enabled = isPlayer ~= true,
        }
    end

    return {
        label = "Set Active",
        value = 1,
        enabled = true,
    }
end

function EventManage:BuildVisibilityMenuItem(isHidden)
    if isHidden == true then
        return {
            label = "Set Visible",
            value = 0,
        }
    end

    return {
        label = "Set Hidden",
        value = 1,
    }
end

function EventManage:BuildBossMenuItem(isBoss)
    if isBoss == true then
        return {
            label = "Unset Boss",
            value = 0,
        }
    end

    return {
        label = "Set Boss",
        value = 1,
    }
end

function EventManage:EnsureUnitsContextMenu()
    if self.UnitsContextMenu then
        return self.UnitsContextMenu
    end

    self.UnitsContextMenu = UI.ContextMenu:New({
        name = "RPEServerEventManageUnitsContextMenu",
        width = 140,
        panelWidth = 140,
        visibleRows = 9,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            local value = item and item.value or nil
            local assignmentType = item and item.assignmentType or nil
            local numericValue = tonumber(value)
            if assignmentType == nil or numericValue == nil then
                return
            end

            local targetEventId = self.ContextMenuUnitEventID
            if targetEventId == nil then
                return
            end

            if assignmentType == "raidMarker" and Server.SetEventUnitRaidMarker then
                Server:SetEventUnitRaidMarker(targetEventId, numericValue)
            elseif assignmentType == "team" and Server.SetEventUnitTeam then
                Server:SetEventUnitTeam(targetEventId, numericValue)
            elseif assignmentType == "active" and Server.SetEventUnitActive then
                Server:SetEventUnitActive(targetEventId, numericValue == 1)
            elseif assignmentType == "hidden" and Server.SetEventUnitHidden then
                Server:SetEventUnitHidden(targetEventId, numericValue == 1)
            elseif assignmentType == "boss" and Server.SetEventUnitBoss then
                Server:SetEventUnitBoss(targetEventId, numericValue == 1)
            elseif assignmentType == "showInNpcMode" and Server.SetEventUnitShowInNpcMode then
                Server:SetEventUnitShowInNpcMode(targetEventId, numericValue == 1)
            end

            self:RefreshUnitsPage()

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.UnitsContextMenu:SetParent(self.Window and self.Window:GetFrame() or UIParent)
    self.UnitsContextMenu:Create()
    return self.UnitsContextMenu
end

function EventManage:ShowUnitsContextMenu(row, rowData)
    if not rowData then
        return
    end

    local menu = self:EnsureUnitsContextMenu()
    self.ContextMenuUnitEventID = rowData.eventID

    local markerItems = self:BuildRaidMarkerMenuItems(rowData.raidMarker)
    for index = 1, #markerItems do
        markerItems[index].assignmentType = "raidMarker"
    end

    local teamItems = self:BuildTeamMenuItems(rowData.team)
    for index = 1, #teamItems do
        teamItems[index].assignmentType = "team"
    end

    local activityItem = self:BuildActivityMenuItem(rowData.active == true, rowData.isPlayer == true)
    activityItem.assignmentType = "active"

    local visibilityItem = self:BuildVisibilityMenuItem(rowData.hidden == true)
    visibilityItem.assignmentType = "hidden"

    local bossItem = self:BuildBossMenuItem(rowData.boss == true)
    bossItem.assignmentType = "boss"

    local items = {
        {
            label = "Marker",
            value = "marker",
            children = markerItems,
        },
        {
            label = "Team",
            value = "team",
            children = teamItems,
        },
        activityItem,
        visibilityItem,
        bossItem,
    }
    if rowData.isPlayer ~= true then
        items[#items + 1] = {
            label = rowData.showInNpcMode == true and "Hide from NPC Mode" or "Show in NPC Mode",
            value = rowData.showInNpcMode == true and 0 or 1,
            assignmentType = "showInNpcMode",
        }
    end

    menu:SetItems(items)
    menu:ShowAt(row and row.GetFrame and row:GetFrame() or nil)
end
