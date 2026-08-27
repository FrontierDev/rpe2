local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}

local Server = Addon.Server
local ServerUI = Addon.Server.UI
local UI = Addon.UI or {}
local C = UI.Constants or {}

ServerUI.EventManage = ServerUI.EventManage or {}
local EventManage = ServerUI.EventManage

function EventManage:BuildDashboardPage(page)
    if self.DashboardRootLayout then
        return self.DashboardRootLayout
    end

    local layout = self.Layout or {}
    local toolbarButtonWidth = layout.DashboardToolbarButtonWidth or 78
    local advanceButtonWidth = layout.DashboardAdvanceButtonWidth or 104
    local contentWidth = layout.PageContentWidth or 480
    local statusRowHeight = layout.DashboardStatusRowHeight or 188
    local statusTextWidth = layout.DashboardStatusTextWidth or 220
    local hashTextWidth = layout.DashboardHashTextWidth or 236

    self.DashboardRootLayout = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEServerEventManagepage_DashboardRootLayout", {
        spacing = 10,
        paddingLeft = 0,
        paddingTop = 0,
        fitChildrenWidth = true,
    })
    self.DashboardRootLayout:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    self.DashboardRootLayout:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)
    self.DashboardRootLayout:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)
    self.DashboardRootLayout:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)

    local toolbar = UI.CreateLayout(UI.HorizontalLayoutGroup, self.DashboardRootLayout:GetFrame(), "RPEServerEventManageDashboardToolbar", {
        spacing = 8,
        autoSize = true,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })

    self.StartServerButton = UI.CreateButton(toolbar:GetFrame(), "RPEServerEventManageStartServerButton", "Start Server", toolbarButtonWidth, function()
        if Server.StartServer then
            Server:StartServer()
            EventManage:RefreshDashboard()
        end
    end)
    toolbar:AddChild(self.StartServerButton)

    self.StopServerButton = UI.CreateButton(toolbar:GetFrame(), "RPEServerEventManageStopServerButton", "Stop Server", toolbarButtonWidth, function()
        if Server.StopServer then
            Server:StopServer("ui")
            EventManage:RefreshDashboard()
        end
    end)
    toolbar:AddChild(self.StopServerButton)

    self.StartEventButton = UI.CreateButton(toolbar:GetFrame(), "RPEServerEventManageStartEventButton", "Start Event", toolbarButtonWidth, function()
        if Server.StartEvent then
            Server:StartEvent({})
            EventManage:RefreshDashboard()
        end
    end)
    toolbar:AddChild(self.StartEventButton)

    self.StopEventButton = UI.CreateButton(toolbar:GetFrame(), "RPEServerEventManageStopEventButton", "Stop Event", toolbarButtonWidth, function()
        if Server.EndEvent then
            Server:EndEvent("ui")
            EventManage:RefreshDashboard()
        end
    end)
    toolbar:AddChild(self.StopEventButton)

    self.AdvanceEventStepButton = UI.CreateButton(toolbar:GetFrame(), "RPEServerEventManageAdvanceEventStepButton", "Next Tick / Turn", advanceButtonWidth, function()
        if Server.AdvanceEventStep and EventManage:CanAdvanceEventStep() == true then
            Server:AdvanceEventStep()
            EventManage:RefreshDashboard()
        end
    end)
    self.AdvanceEventStepButton:SetScript("OnEnter", function()
        local client = Addon.Client
        if client and client.ShowPendingTurnChangesTooltip then
            client:ShowPendingTurnChangesTooltip(self.AdvanceEventStepButton)
        end
    end)
    self.AdvanceEventStepButton:SetScript("OnLeave", function()
        local client = Addon.Client
        if client and client.HidePendingTurnChangesTooltip then
            client:HidePendingTurnChangesTooltip()
        end
    end)
    self.AdvanceEventStepButton:SetScript("OnHide", function()
        local client = Addon.Client
        if client and client.HidePendingTurnChangesTooltip then
            client:HidePendingTurnChangesTooltip()
        end
    end)
    toolbar:AddChild(self.AdvanceEventStepButton)

    self.DashboardRootLayout:AddChild(toolbar)

    local statusRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.DashboardRootLayout:GetFrame(), "RPEServerEventManageDashboardStatusRow", {
        width = contentWidth,
        height = statusRowHeight,
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })

    local function createStatusPanel(key, title)
        local panel = UI.CreatePanel(statusRow:GetFrame(), "RPEServerEventManage" .. key .. "Panel", {
            width = "50%-4",
            height = statusRowHeight,
            contentInset = 2,
        })

        local layout = UI.CreateLayout(UI.VerticalLayoutGroup, panel:GetContentFrame(), "RPEServerEventManage" .. key .. "Layout", {
            spacing = 4,
            paddingLeft = 6,
            paddingRight = 6,
            paddingTop = 6,
            paddingBottom = 6,
            fitChildrenWidth = true,
            fitChildrenHeight = true,
        })
        layout:SetPoint("TOPLEFT", panel:GetContentFrame(), "TOPLEFT", 0, 0)
        layout:SetPoint("TOPRIGHT", panel:GetContentFrame(), "TOPRIGHT", 0, 0)
        layout:SetPoint("BOTTOMLEFT", panel:GetContentFrame(), "BOTTOMLEFT", 0, 0)
        layout:SetPoint("BOTTOMRIGHT", panel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)

        local header = UI.CreateText(layout:GetFrame(), "RPEServerEventManage" .. key .. "Header", title, {
            fontFile = (C.FontFiles and C.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
            fontSize = (C.FontSizes and C.FontSizes.Heading2) or 10,
            textColor = UI.ResolveColor(nil, "warning"),
            width = statusTextWidth,
            height = 14,
        })
        layout:AddChild(header)

        local body = UI.CreateText(layout:GetFrame(), "RPEServerEventManage" .. key .. "Body", "-", {
            fontFile = (C.FontFiles and C.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
            fontSize = (C.FontSizes and C.FontSizes.Body) or 8,
            textColor = UI.ResolveColor(nil, "text.primary"),
            width = statusTextWidth,
            height = statusRowHeight - 38,
            wordWrap = true,
            justifyH = "LEFT",
            justifyV = "TOP",
        })
        layout:AddChild(body)
        statusRow:AddChild(panel)

        return body
    end

    self.SessionStatusText = createStatusPanel("Session", "Session Status")
    self.EventStatusText = createStatusPanel("Event", "Event Status")
    self.DashboardRootLayout:AddChild(statusRow)

    local hashRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.DashboardRootLayout:GetFrame(), "RPEServerEventManageDashboardHashRow", {
        width = contentWidth,
        height = 28,
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })

    self.DatasetHashText = UI.CreateText(hashRow:GetFrame(), "RPEServerEventManageDashboardDatasetHashText", "Dataset Hash: -", {
        fontFile = (C.FontFiles and C.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = 7,
        textColor = UI.ResolveColor(nil, "text.primary"),
        width = hashTextWidth,
        height = 28,
        justifyH = "LEFT",
        justifyV = "TOP",
        wordWrap = true,
    })
    hashRow:AddChild(self.DatasetHashText)

    self.RulesetHashText = UI.CreateText(hashRow:GetFrame(), "RPEServerEventManageDashboardRulesetHashText", "Ruleset Hash: -", {
        fontFile = (C.FontFiles and C.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = 7,
        textColor = UI.ResolveColor(nil, "text.primary"),
        width = hashTextWidth,
        height = 28,
        justifyH = "LEFT",
        justifyV = "TOP",
        wordWrap = true,
    })
    hashRow:AddChild(self.RulesetHashText)

    self.DashboardRootLayout:AddChild(hashRow)

    self.HashWarningText = UI.CreateText(self.DashboardRootLayout:GetFrame(), "RPEServerEventManageDashboardHashWarningText", "", {
        fontFile = (C.FontFiles and C.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = 8,
        textColor = UI.ResolveColor(nil, "warning"),
        width = contentWidth,
        height = 0,
        justifyH = "LEFT",
        justifyV = "TOP",
        wordWrap = true,
    })
    self.DashboardRootLayout:AddChild(self.HashWarningText)
    self:RefreshDashboard()
    return self.DashboardRootLayout
end
