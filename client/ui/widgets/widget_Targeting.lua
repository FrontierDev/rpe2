local addonName, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI
local UI = Addon.UI or {}
local Image = UI.Image
local EventClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Event or nil

local WINDOW_WIDTH = 292
local WINDOW_HEIGHT = 314
local WINDOW_TOP_OFFSET = -170
local SPELL_ICON_SIZE = 20
local GROUP_PANEL_HEIGHT = 48
local GROUP_BUTTON_HEIGHT = 20
local GROUP_BUTTON_COLUMNS = 2
local GROUP_BUTTON_SPACING = 4
local MAIN_PORTRAIT_SIZE = 28
local RECENT_PORTRAIT_SIZE = 24
local PORTRAIT_OVERLAY_TOP_PADDING = 7
local MAIN_PORTRAIT_SLOT_HEIGHT = MAIN_PORTRAIT_SIZE + PORTRAIT_OVERLAY_TOP_PADDING
local RECENT_PORTRAIT_SLOT_HEIGHT = RECENT_PORTRAIT_SIZE + PORTRAIT_OVERLAY_TOP_PADDING
local GRID_COLUMNS = 3
local GRID_SPACING = 4
local GRID_SCROLLBAR_WIDTH = 10
local GRID_SCROLLBAR_GAP = 4
local GRID_PANEL_WIDTH = 116
local GRID_VIEWPORT_WIDTH = (MAIN_PORTRAIT_SIZE * GRID_COLUMNS) + (GRID_SPACING * (GRID_COLUMNS - 1))
local GRID_VIEWPORT_HEIGHT = (MAIN_PORTRAIT_SLOT_HEIGHT * 3) + (GRID_SPACING * 2)
local GRID_VISIBLE_ROWS = 3
local GRID_VISIBLE_SLOT_COUNT = GRID_COLUMNS * GRID_VISIBLE_ROWS
local PORTRAITS_PANEL_HEIGHT = 150
local BODY_HEIGHT = 150
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local POSITIVE_HIT_COLOR = { r = 0.35, g = 0.82, b = 0.46, a = 1 }
local NEGATIVE_HIT_COLOR = { r = 0.92, g = 0.36, b = 0.33, a = 1 }
local PORTRAIT_REFRESH_BATCH_SIZE = 3

local function buildInlineIconLabel(iconPath, label)
    local text = tostring(label or "")
    local icon = tostring(iconPath or "")
    if icon ~= "" then
        return ("|T%s:12:12:0:0|t %s"):format(icon, text)
    end

    return text
end

ClientUI.TargetingWidget = ClientUI.TargetingWidget or {}
local TargetingWidget = ClientUI.TargetingWidget
TargetingWidget.__index = TargetingWidget

local function getTeamBorderColor(eventState, eventUnit)
    local color = EventClass and EventClass.GetTeamColor and EventClass.GetTeamColor(eventState, tonumber(eventUnit and eventUnit.team) or 0) or nil
    if type(color) ~= "table" then
        return UI.ResolveColor(nil, "panel.border")
    end

    return {
        r = tonumber(color.r) or 0.18,
        g = tonumber(color.g) or 0.2,
        b = tonumber(color.b) or 0.24,
        a = tonumber(color.a) or 1,
    }
end

local function createInstance()
    return setmetatable({
        window = nil,
        rootLayout = nil,
        headerRow = nil,
        headerIcon = nil,
        headerText = nil,
        headerSelectionText = nil,
        groupPanel = nil,
        groupLabel = nil,
        groupLayout = nil,
        groupButtons = {},
        bodyRow = nil,
        portraitsPanel = nil,
        recentLabel = nil,
        recentRow = nil,
        recentPortraits = {},
        gridHeaderRow = nil,
        gridHeaderText = nil,
        gridPanel = nil,
        gridScrollFrame = nil,
        gridScrollChild = nil,
        gridScrollBar = nil,
        gridScrollBarTrack = nil,
        gridLayout = nil,
        mainPortraits = {},
        detailPanel = nil,
        detailContentLayout = nil,
        detailEyebrowText = nil,
        detailNameText = nil,
        detailTeamText = nil,
        detailTypeSizeText = nil,
        detailHealthText = nil,
        detailSummaryText = nil,
        footerInfoPanel = nil,
        footerInfoLayout = nil,
        footerStatText = nil,
        footerHitText = nil,
        footerCritText = nil,
        footerActionsPanel = nil,
        footerActionsRow = nil,
        castButton = nil,
        cancelButton = nil,
        gridScrollOffset = 0,
        gridVisibleStartIndex = 1,
        portraitRefreshToken = 0,
        pendingPortraitRefreshPlan = nil,
        lastRefreshReason = nil,
        lastDisplayState = nil,
    }, TargetingWidget)
end

local function getGridScrollStep()
    return MAIN_PORTRAIT_SLOT_HEIGHT + GRID_SPACING
end

local function getVisibleCandidateSlice(displayState, startIndex)
    local visibleRows = {}
    local candidates = type(displayState) == "table" and displayState.candidates or nil
    local baseIndex = math.max(1, math.floor(tonumber(startIndex) or 1))
    for slotIndex = 1, GRID_VISIBLE_SLOT_COUNT do
        visibleRows[slotIndex] = candidates and candidates[baseIndex + slotIndex - 1] or nil
    end

    return visibleRows
end

local function enqueuePortraitRefreshWork(fn)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, fn)
        return true
    end

    fn()
    return true
end

function TargetingWidget:Get()
    if not self.Instance then
        self.Instance = createInstance()
    end

    return self.Instance
end

function TargetingWidget:Build()
    if self.window then
        return self.window
    end

    self.window = UI.Window:New({
        name = "RPEClientTargetingWidgetWindow",
        width = WINDOW_WIDTH,
        height = WINDOW_HEIGHT,
        point = "TOP",
        relativeTo = UIParent,
        relativePoint = "TOP",
        frameStrata = "DIALOG",
        frameLevel = 80,
        movable = false,
        hidden = true,
        contentInsetLeft = 10,
        contentInsetRight = 10,
        contentInsetTop = 28,
        contentInsetBottom = 6,
        onClose = function()
            if Client.CancelSpellTargeting then
                Client:CancelSpellTargeting("cancelled")
            end
        end,
    })
    self.window:SetTitle("Targeting")
    self.window:Create()

    local frame = self.window:GetFrame()
    frame:ClearAllPoints()
    frame:SetPoint("TOP", UIParent, "TOP", 0, WINDOW_TOP_OFFSET)

    local contentFrame = self.window:GetContentFrame()
    self.rootLayout = UI.CreateLayout(UI.VerticalLayoutGroup, contentFrame, "RPEClientTargetingWidgetRootLayout", {
        width = WINDOW_WIDTH - 20,
        height = WINDOW_HEIGHT - 38,
        spacing = 3,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.rootLayout, contentFrame, 0, 0, 0, 0)

    self.headerRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.rootLayout:GetFrame(), "RPEClientTargetingWidgetHeaderRow", {
        width = WINDOW_WIDTH - 20,
        height = 20,
        spacing = 6,
        fitChildrenWidth = false,
        fitChildrenHeight = true,
    })
    self.rootLayout:AddChild(self.headerRow)

    self.headerIcon = Image:New({
        name = "RPEClientTargetingWidgetHeaderIcon",
        width = SPELL_ICON_SIZE,
        height = SPELL_ICON_SIZE,
        texture = DEFAULT_ICON,
        border = false,
    })
    self.headerIcon:SetParent(self.headerRow:GetFrame())
    self.headerIcon:Create()
    self.headerRow:AddChild(self.headerIcon)

    self.headerText = UI.CreateText(self.headerRow:GetFrame(), "RPEClientTargetingWidgetHeaderText", "Spell", {
        width = 120,
        height = 20,
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        fontSize = 10,
        fontFlags = "OUTLINE",
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.headerRow:AddChild(self.headerText)

    self.headerSelectionText = UI.CreateText(self.headerRow:GetFrame(), "RPEClientTargetingWidgetHeaderSelectionText", "Selected 0/1", {
        width = 110,
        height = 20,
        justifyH = "RIGHT",
        justifyV = "MIDDLE",
        fontSize = 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.headerRow:AddChild(self.headerSelectionText)

    self.groupPanel = UI.CreatePanel(self.rootLayout:GetFrame(), "RPEClientTargetingWidgetGroupPanel", {
        width = WINDOW_WIDTH - 20,
        height = GROUP_PANEL_HEIGHT,
        contentInset = 4,
    })
    self.rootLayout:AddChild(self.groupPanel)

    self.groupLabel = UI.CreateText(self.groupPanel:GetContentFrame(), "RPEClientTargetingWidgetGroupLabel", "Target Groups", {
        width = WINDOW_WIDTH - 28,
        height = 12,
        justifyH = "LEFT",
        fontSize = 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.groupLabel:GetFrame():SetPoint("TOPLEFT", self.groupPanel:GetContentFrame(), "TOPLEFT", 0, 0)

    self.groupLayout = UI.CreateLayout(UI.GridLayoutGroup, self.groupPanel:GetContentFrame(), "RPEClientTargetingWidgetGroupLayout", {
        width = WINDOW_WIDTH - 28,
        height = GROUP_BUTTON_HEIGHT,
        columns = GROUP_BUTTON_COLUMNS,
        cellWidth = math.floor(((WINDOW_WIDTH - 28) - GROUP_BUTTON_SPACING) / GROUP_BUTTON_COLUMNS),
        cellHeight = GROUP_BUTTON_HEIGHT,
        spacing = GROUP_BUTTON_SPACING,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
        autoSize = false,
    })
    self.groupLayout:GetFrame():SetPoint("TOPLEFT", self.groupLabel:GetFrame(), "BOTTOMLEFT", 0, -4)

    self.bodyRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.rootLayout:GetFrame(), "RPEClientTargetingWidgetBodyRow", {
        width = WINDOW_WIDTH - 20,
        height = BODY_HEIGHT,
        spacing = 8,
        fitChildrenWidth = false,
        fitChildrenHeight = true,
        expandHeight = true,
    })
    self.rootLayout:AddChild(self.bodyRow)

    self.portraitsPanel = UI.CreatePanel(self.bodyRow:GetFrame(), "RPEClientTargetingWidgetPortraitsPanel", {
        width = 128,
        height = PORTRAITS_PANEL_HEIGHT,
        contentInset = 6,
    })
    self.bodyRow:AddChild(self.portraitsPanel)

    self.recentLabel = UI.CreateText(self.portraitsPanel:GetContentFrame(), "RPEClientTargetingWidgetRecentLabel", "Recent", {
        width = 116,
        height = 12,
        justifyH = "LEFT",
        fontSize = 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.recentLabel:GetFrame():SetPoint("TOPLEFT", self.portraitsPanel:GetContentFrame(), "TOPLEFT", 0, 0)

    self.recentRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.portraitsPanel:GetContentFrame(), "RPEClientTargetingWidgetRecentRow", {
        width = 116,
        height = RECENT_PORTRAIT_SLOT_HEIGHT,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = true,
    })
    self.recentRow:GetFrame():SetPoint("TOPLEFT", self.recentLabel:GetFrame(), "BOTTOMLEFT", 0, -4)

    self.gridHeaderRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.portraitsPanel:GetContentFrame(), "RPEClientTargetingWidgetGridHeaderRow", {
        width = 116,
        height = 14,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = true,
    })
    self.gridHeaderRow:GetFrame():SetPoint("TOPLEFT", self.recentRow:GetFrame(), "BOTTOMLEFT", 0, -8)

    self.gridHeaderText = UI.CreateText(self.gridHeaderRow:GetFrame(), "RPEClientTargetingWidgetGridHeaderText", "Targets", {
        width = 116,
        height = 14,
        justifyH = "LEFT",
        fontSize = 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.gridHeaderRow:AddChild(self.gridHeaderText)

    self.gridPanel = UI.CreatePanel(self.portraitsPanel:GetContentFrame(), "RPEClientTargetingWidgetGridPanel", {
        width = GRID_PANEL_WIDTH,
        height = GRID_VIEWPORT_HEIGHT,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
    })
    self.gridPanel:GetFrame():SetPoint("TOPLEFT", self.gridHeaderRow:GetFrame(), "BOTTOMLEFT", 0, -4)

    self.gridScrollFrame = CreateFrame("ScrollFrame", "RPEClientTargetingWidgetGridScrollFrame", self.gridPanel:GetContentFrame())
    self.gridScrollFrame:SetPoint("TOPLEFT", self.gridPanel:GetContentFrame(), "TOPLEFT", 0, 0)
    self.gridScrollFrame:SetPoint("BOTTOMLEFT", self.gridPanel:GetContentFrame(), "BOTTOMLEFT", 0, 0)
    self.gridScrollFrame:SetWidth(GRID_VIEWPORT_WIDTH)
    self.gridScrollFrame:EnableMouseWheel(true)
    if self.gridScrollFrame.SetClipsChildren then
        self.gridScrollFrame:SetClipsChildren(true)
    end

    self.gridScrollChild = CreateFrame("Frame", "RPEClientTargetingWidgetGridScrollChild", self.gridScrollFrame)
    self.gridScrollChild:SetPoint("TOPLEFT", self.gridScrollFrame, "TOPLEFT", 0, 0)
    self.gridScrollChild:SetSize(GRID_VIEWPORT_WIDTH, GRID_VIEWPORT_HEIGHT)
    self.gridScrollFrame:SetScrollChild(self.gridScrollChild)
    self.gridScrollFrame:SetScript("OnMouseWheel", function(frame, delta)
        local step = getGridScrollStep()
        local current = tonumber(self.gridScrollOffset) or 0
        local maxScroll = math.max(0, (self.gridScrollChild and self.gridScrollChild.GetHeight and self.gridScrollChild:GetHeight() or GRID_VIEWPORT_HEIGHT) - GRID_VIEWPORT_HEIGHT)
        local nextScroll = math.max(0, math.min(current - ((tonumber(delta) or 0) * step), maxScroll))
        if frame.SetVerticalScroll then
            frame:SetVerticalScroll(0)
        end
        self:SetGridScrollOffset(nextScroll)
    end)

    self.gridScrollBar = CreateFrame("Slider", "RPEClientTargetingWidgetGridScrollBar", self.gridPanel:GetContentFrame())
    self.gridScrollBar:SetPoint("TOPLEFT", self.gridScrollFrame, "TOPRIGHT", GRID_SCROLLBAR_GAP, 0)
    self.gridScrollBar:SetPoint("BOTTOMLEFT", self.gridScrollFrame, "BOTTOMRIGHT", GRID_SCROLLBAR_GAP, 0)
    self.gridScrollBar:SetOrientation("VERTICAL")
    self.gridScrollBar:SetMinMaxValues(0, 0)
    self.gridScrollBar:SetValueStep(MAIN_PORTRAIT_SLOT_HEIGHT + GRID_SPACING)
    if self.gridScrollBar.SetObeyStepOnDrag then
        self.gridScrollBar:SetObeyStepOnDrag(false)
    end
    self.gridScrollBar:SetWidth(GRID_SCROLLBAR_WIDTH)

    self.gridScrollBarTrack = self.gridScrollBarTrack or self.gridScrollBar:CreateTexture(nil, "BACKGROUND")
    self.gridScrollBarTrack:SetAllPoints(self.gridScrollBar)
    do
        local trackColor = UI.ResolveColor(nil, "scrollbar.track")
        self.gridScrollBarTrack:SetColorTexture(trackColor.r or 0.08, trackColor.g or 0.09, trackColor.b or 0.11, trackColor.a or 0.95)
    end

    self.gridScrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    do
        local thumb = self.gridScrollBar.GetThumbTexture and self.gridScrollBar:GetThumbTexture() or nil
        if thumb and thumb.SetVertexColor then
            local thumbColor = UI.ResolveColor(nil, "scrollbar.thumb")
            thumb:SetVertexColor(thumbColor.r or 0.42, thumbColor.g or 0.46, thumbColor.b or 0.52, thumbColor.a or 1)
        end
    end
    self.gridScrollBar:SetValue(0)
    self.gridScrollBar:SetScript("OnValueChanged", function(_, value)
        self:SetGridScrollOffset(value or 0)
    end)

    self.gridLayout = UI.CreateLayout(UI.GridLayoutGroup, self.gridScrollChild, "RPEClientTargetingWidgetGridLayout", {
        width = GRID_VIEWPORT_WIDTH,
        height = GRID_VIEWPORT_HEIGHT,
        columns = GRID_COLUMNS,
        cellWidth = MAIN_PORTRAIT_SIZE,
        cellHeight = MAIN_PORTRAIT_SLOT_HEIGHT,
        spacing = GRID_SPACING,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
        autoSize = false,
    })
    self.gridLayout:GetFrame():SetPoint("TOPLEFT", self.gridScrollChild, "TOPLEFT", 0, 0)

    self.detailPanel = UI.CreatePanel(self.bodyRow:GetFrame(), "RPEClientTargetingWidgetDetailPanel", {
        width = 136,
        height = BODY_HEIGHT,
        contentInset = 6,
    })
    self.bodyRow:AddChild(self.detailPanel)

    self.detailContentLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.detailPanel:GetContentFrame(), "RPEClientTargetingWidgetDetailContentLayout", {
        width = 124,
        height = BODY_HEIGHT - 12,
        spacing = 3,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(self.detailContentLayout, self.detailPanel:GetContentFrame(), 0, 0, 0, 0)

    self.detailEyebrowText = UI.CreateText(self.detailContentLayout:GetFrame(), "RPEClientTargetingWidgetDetailEyebrowText", "Selected Target", {
        width = 124,
        height = 12,
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        fontSize = 7,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.detailContentLayout:AddChild(self.detailEyebrowText)

    self.detailNameText = UI.CreateText(self.detailContentLayout:GetFrame(), "RPEClientTargetingWidgetDetailNameText", "No target selected", {
        width = 124,
        height = 18,
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        fontSize = 10,
        fontFlags = "OUTLINE",
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.detailContentLayout:AddChild(self.detailNameText)

    self.detailTeamText = UI.CreateText(self.detailContentLayout:GetFrame(), "RPEClientTargetingWidgetDetailTeamText", "", {
        width = 124,
        height = 14,
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        fontSize = 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.detailContentLayout:AddChild(self.detailTeamText)

    self.detailTypeSizeText = UI.CreateText(self.detailContentLayout:GetFrame(), "RPEClientTargetingWidgetDetailTypeSizeText", "", {
        width = 124,
        height = 14,
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        fontSize = 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.detailContentLayout:AddChild(self.detailTypeSizeText)

    self.detailHealthText = UI.CreateText(self.detailContentLayout:GetFrame(), "RPEClientTargetingWidgetDetailHealthText", "HP: -", {
        width = 124,
        height = 14,
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        fontSize = 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.detailContentLayout:AddChild(self.detailHealthText)

    self.detailSummaryText = UI.CreateText(self.detailContentLayout:GetFrame(), "RPEClientTargetingWidgetDetailSummaryText", "", {
        width = 124,
        height = 58,
        justifyH = "CENTER",
        justifyV = "TOP",
        fontSize = 8,
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.detailContentLayout:AddChild(self.detailSummaryText)

    self.footerInfoPanel = UI.CreatePanel(self.rootLayout:GetFrame(), "RPEClientTargetingWidgetFooterInfoPanel", {
        width = WINDOW_WIDTH - 20,
        height = 36,
        contentInset = 2,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
    })
    self.rootLayout:AddChild(self.footerInfoPanel)

    self.footerInfoLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.footerInfoPanel:GetContentFrame(), "RPEClientTargetingWidgetFooterInfoLayout", {
        width = WINDOW_WIDTH - 24,
        height = 32,
        spacing = 1,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(self.footerInfoLayout, self.footerInfoPanel:GetContentFrame(), 0, 0, 0, 0)

    self.footerStatText = UI.CreateText(self.footerInfoLayout:GetFrame(), "RPEClientTargetingWidgetFooterStatText", "", {
        width = WINDOW_WIDTH - 28,
        height = 12,
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        fontSize = 7,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.footerInfoLayout:AddChild(self.footerStatText)

    self.footerHitText = UI.CreateText(self.footerInfoLayout:GetFrame(), "RPEClientTargetingWidgetFooterHitText", "", {
        width = WINDOW_WIDTH - 28,
        height = 14,
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        fontSize = 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.footerInfoLayout:AddChild(self.footerHitText)

    self.footerCritText = UI.CreateText(self.footerInfoLayout:GetFrame(), "RPEClientTargetingWidgetFooterCritText", "", {
        width = WINDOW_WIDTH - 28,
        height = 14,
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        fontSize = 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.footerInfoLayout:AddChild(self.footerCritText)

    self.footerActionsPanel = UI.CreatePanel(self.rootLayout:GetFrame(), "RPEClientTargetingWidgetFooterActionsPanel", {
        width = WINDOW_WIDTH - 20,
        height = 24,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
    })
    self.rootLayout:AddChild(self.footerActionsPanel)

    self.footerActionsRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.footerActionsPanel:GetContentFrame(), "RPEClientTargetingWidgetFooterActionsRow", {
        width = 146,
        height = 18,
        spacing = 6,
        fitChildrenWidth = false,
        fitChildrenHeight = true,
    })
    self.footerActionsRow:GetFrame():SetPoint("BOTTOM", self.footerActionsPanel:GetContentFrame(), "BOTTOM", 0, 0)

    self.castButton = UI.CreateButton(self.footerActionsRow:GetFrame(), "RPEClientTargetingWidgetCastButton", "Cast", 68, function()
        if Client.ConfirmPendingSpellTargeting then
            Client:ConfirmPendingSpellTargeting()
        end
    end, {
        height = 18,
        fontSize = 8,
    })
    self.footerActionsRow:AddChild(self.castButton)

    self.cancelButton = UI.CreateButton(self.footerActionsRow:GetFrame(), "RPEClientTargetingWidgetCancelButton", "Cancel", 72, function()
        if Client.CancelSpellTargeting then
            Client:CancelSpellTargeting("cancelled")
        end
    end, {
        height = 18,
        fontSize = 8,
    })
    self.footerActionsRow:AddChild(self.cancelButton)

    return self.window
end

function TargetingWidget:GetGridVisibleStartIndex(displayState)
    local candidateCount = #(displayState and displayState.candidates or {})
    if candidateCount <= GRID_VISIBLE_SLOT_COUNT then
        return 1
    end

    local step = getGridScrollStep()
    local offset = math.max(0, tonumber(self.gridScrollOffset) or 0)
    local topRow = math.floor((offset / step) + 0.0001)
    local startIndex = (topRow * GRID_COLUMNS) + 1
    local lastStartIndex = math.max(1, candidateCount - GRID_VISIBLE_SLOT_COUNT + 1)
    return math.max(1, math.min(startIndex, lastStartIndex))
end

function TargetingWidget:SetGridScrollOffset(offset)
    local displayState = self.lastDisplayState
    local candidateCount = #(displayState and displayState.candidates or {})
    local totalRows = math.max(1, math.ceil(candidateCount / GRID_COLUMNS))
    local contentHeight = math.max(GRID_VIEWPORT_HEIGHT, (totalRows * MAIN_PORTRAIT_SLOT_HEIGHT) + ((totalRows - 1) * GRID_SPACING))
    local maxScroll = math.max(0, contentHeight - GRID_VIEWPORT_HEIGHT)
    local clampedOffset = math.max(0, math.min(tonumber(offset) or 0, maxScroll))

    self.gridScrollOffset = clampedOffset

    if self.gridScrollFrame and self.gridScrollFrame.SetVerticalScroll then
        self.gridScrollFrame:SetVerticalScroll(0)
    end

    if self.gridScrollBar then
        local currentValue = self.gridScrollBar.GetValue and self.gridScrollBar:GetValue() or 0
        if math.abs((tonumber(currentValue) or 0) - clampedOffset) > 0.001 then
            self.gridScrollBar:SetValue(clampedOffset)
        end
    end

    if not displayState then
        self.gridVisibleStartIndex = 1
        return clampedOffset
    end

    local nextStartIndex = self:GetGridVisibleStartIndex(displayState)
    if nextStartIndex ~= self.gridVisibleStartIndex then
        self.gridVisibleStartIndex = nextStartIndex
        self:RefreshVisibleCandidatePortraits(displayState, Client.GetEventState and Client:GetEventState() or nil)
    end

    return clampedOffset
end

function TargetingWidget:Show()
    self:Build()
    self.window:Show()
    return true
end

function TargetingWidget:Hide()
    if self.window then
        self.window:Hide()
    end
    return true
end

function TargetingWidget:EnsureGroupButton(index)
    self:Build()
    local slot = self.groupButtons[index]
    if slot then
        return slot
    end

    local button = UI.CreateButton(self.groupLayout:GetFrame(), ("RPEClientTargetingWidgetGroupButton%d"):format(index), "", 120, function()
        if slot and slot.groupKey and Client.SetPendingSpellTargetGroup then
            Client:SetPendingSpellTargetGroup(slot.groupKey)
        end
    end, {
        height = GROUP_BUTTON_HEIGHT,
        fontSize = 7,
    })
    self.groupLayout:AddChild(button)

    slot = {
        button = button,
        groupKey = nil,
    }
    self.groupButtons[index] = slot
    return slot
end

function TargetingWidget:EnsurePortraitSlot(collection, parentLayout, index, size, isRecent)
    self:Build()
    local slot = collection[index]
    if slot then
        return slot
    end

    slot = {
        portrait = nil,
        frame = nil,
        eventID = nil,
        isRecent = isRecent == true,
    }

    local portrait = UI.UnitPortrait:New({
        name = ("RPEClientTargetingWidget%sPortrait%d"):format(slot.isRecent and "Recent" or "Main", index),
        width = size,
        height = size,
        portraitWidth = size,
        portraitHeight = size,
        overlayTopPadding = PORTRAIT_OVERLAY_TOP_PADDING,
        progressHeight = 0,
        progressSpacing = 0,
        portraitBorderColor = UI.ResolveColor(nil, "panel.border"),
    })
    portrait:SetParent(parentLayout:GetFrame())
    portrait:Create()
    parentLayout:AddChild(portrait)

    local progressFrame = portrait.progressBar and portrait.progressBar.GetFrame and portrait.progressBar:GetFrame() or nil
    if progressFrame and progressFrame.Hide then
        progressFrame:Hide()
    end

    local function handleClick(_, button)
        if button ~= "LeftButton" or not slot.eventID then
            return
        end

        if Client.TogglePendingSpellTarget then
            Client:TogglePendingSpellTarget(slot.eventID)
        end
    end

    local frame = portrait:GetFrame()
    if frame and frame.EnableMouse then
        frame:EnableMouse(true)
        frame:SetScript("OnMouseUp", handleClick)
    end

    local portraitPanelFrame = portrait.portraitPanel and portrait.portraitPanel.GetFrame and portrait.portraitPanel:GetFrame() or nil
    if portraitPanelFrame and portraitPanelFrame.EnableMouse then
        portraitPanelFrame:EnableMouse(true)
        portraitPanelFrame:SetScript("OnMouseUp", handleClick)
    end

    local portraitImageFrame = portrait.portraitImage and portrait.portraitImage.GetFrame and portrait.portraitImage:GetFrame() or nil
    if portraitImageFrame and portraitImageFrame.EnableMouse then
        portraitImageFrame:EnableMouse(false)
    end

    if portrait.model and portrait.model.EnableMouse then
        portrait.model:EnableMouse(false)
    end

    slot.portrait = portrait
    slot.frame = frame
    collection[index] = slot
    return slot
end

function TargetingWidget:EnsureRecentPortrait(index)
    return self:EnsurePortraitSlot(self.recentPortraits, self.recentRow, index, RECENT_PORTRAIT_SIZE, true)
end

function TargetingWidget:EnsureMainPortrait(index)
    return self:EnsurePortraitSlot(self.mainPortraits, self.gridLayout, index, MAIN_PORTRAIT_SIZE, false)
end

function TargetingWidget:RefreshVisibleCandidatePortraits(displayState, eventState)
    local visibleRows = getVisibleCandidateSlice(displayState, self.gridVisibleStartIndex)
    for index = 1, GRID_VISIBLE_SLOT_COUNT do
        local slot = self:EnsureMainPortrait(index)
        self:ApplyPortraitRow(slot, visibleRows[index], eventState)
    end
end

function TargetingWidget:RefreshVisibleCandidateSelectionState(displayState, eventState)
    local visibleRows = getVisibleCandidateSlice(displayState, self.gridVisibleStartIndex)
    for index = 1, GRID_VISIBLE_SLOT_COUNT do
        local slot = self:EnsureMainPortrait(index)
        self:ApplyPortraitSelectionState(slot, visibleRows[index], eventState)
    end
end

function TargetingWidget:CancelPendingPortraitRefresh()
    self.portraitRefreshToken = math.max(0, math.floor(tonumber(self.portraitRefreshToken) or 0)) + 1
    self.pendingPortraitRefreshPlan = nil
    return self.portraitRefreshToken
end

function TargetingWidget:BuildPortraitRefreshPlan(displayState, eventState)
    local visibleRows = getVisibleCandidateSlice(displayState, self.gridVisibleStartIndex)
    return {
        token = self.portraitRefreshToken,
        eventState = eventState,
        recentCandidates = displayState.recentCandidates or {},
        visibleRows = visibleRows,
        nextRecentIndex = 1,
        nextVisibleIndex = 1,
    }
end

function TargetingWidget:DrainPortraitRefreshPlan(token)
    local plan = self.pendingPortraitRefreshPlan
    if type(plan) ~= "table" or tonumber(plan.token) ~= tonumber(token) then
        return false
    end

    local processed = 0
    while processed < PORTRAIT_REFRESH_BATCH_SIZE and plan.nextRecentIndex <= 3 do
        local slot = self:EnsureRecentPortrait(plan.nextRecentIndex)
        self:ApplyPortraitRow(slot, plan.recentCandidates[plan.nextRecentIndex], plan.eventState)
        plan.nextRecentIndex = plan.nextRecentIndex + 1
        processed = processed + 1
    end

    while processed < PORTRAIT_REFRESH_BATCH_SIZE and plan.nextVisibleIndex <= GRID_VISIBLE_SLOT_COUNT do
        local slot = self:EnsureMainPortrait(plan.nextVisibleIndex)
        self:ApplyPortraitRow(slot, plan.visibleRows[plan.nextVisibleIndex], plan.eventState)
        plan.nextVisibleIndex = plan.nextVisibleIndex + 1
        processed = processed + 1
    end

    local morePending = plan.nextRecentIndex <= 3 or plan.nextVisibleIndex <= GRID_VISIBLE_SLOT_COUNT
    if morePending then
        enqueuePortraitRefreshWork(function()
            self:DrainPortraitRefreshPlan(token)
        end)
        return true
    end

    self.pendingPortraitRefreshPlan = nil
    return true
end

function TargetingWidget:QueuePortraitRefresh(displayState, eventState)
    local token = self:CancelPendingPortraitRefresh()
    local plan = self:BuildPortraitRefreshPlan(displayState, eventState)
    plan.token = token
    self.pendingPortraitRefreshPlan = plan
    return self:DrainPortraitRefreshPlan(token)
end

function TargetingWidget:ApplyPortraitRow(slot, row, eventState)
    if not slot then
        return
    end

    if not row then
        slot.eventID = nil
        if slot.portrait and slot.portrait.SetRaidMarker then
            slot.portrait:SetRaidMarker(0)
        end
        if slot.portrait and slot.portrait.SetTooltip then
            slot.portrait:SetTooltip(nil)
            if slot.portrait.portraitPanel and slot.portrait.portraitPanel.SetTooltip then
                slot.portrait.portraitPanel:SetTooltip(nil)
            end
        end
        if slot.frame then
            slot.frame:Hide()
        end
        return
    end

    slot.eventID = row.eventID
    slot.portrait:SetUnit(row.unit)
    if slot.portrait and slot.portrait.SetRaidMarker then
        slot.portrait:SetRaidMarker(row.unit and row.unit.raidMarker or 0)
    end

    local teamColor = getTeamBorderColor(eventState, row.unit)
    if row.selected then
        slot.portrait:SetBorderColor(0.94, 0.78, 0.22, 1)
        slot.frame:SetAlpha(1)
    else
        slot.portrait:SetBorderColor(teamColor.r, teamColor.g, teamColor.b, teamColor.a)
        slot.frame:SetAlpha(row.enabled == false and 0.35 or 0.92)
    end

    local enabled = row.enabled ~= false
    slot.frame:EnableMouse(enabled)
    if slot.portrait and slot.portrait.portraitPanel and slot.portrait.portraitPanel.GetFrame then
        local portraitPanelFrame = slot.portrait.portraitPanel:GetFrame()
        if portraitPanelFrame and portraitPanelFrame.EnableMouse then
            portraitPanelFrame:EnableMouse(enabled)
        end
    end
    slot.frame:Show()
end

local function isSelectionOnlyRefreshCompatible(previousDisplayState, nextDisplayState)
    if type(previousDisplayState) ~= "table" or type(nextDisplayState) ~= "table" then
        return false
    end
    if tostring(previousDisplayState.activeGroupKey or "") ~= tostring(nextDisplayState.activeGroupKey or "") then
        return false
    end
    if #(previousDisplayState.groups or {}) ~= #(nextDisplayState.groups or {}) then
        return false
    end
    if #(previousDisplayState.candidates or {}) ~= #(nextDisplayState.candidates or {}) then
        return false
    end
    if #(previousDisplayState.recentCandidates or {}) ~= #(nextDisplayState.recentCandidates or {}) then
        return false
    end

    for index = 1, #(nextDisplayState.candidates or {}) do
        if tonumber(previousDisplayState.candidates[index] and previousDisplayState.candidates[index].eventID) ~= tonumber(nextDisplayState.candidates[index] and nextDisplayState.candidates[index].eventID) then
            return false
        end
    end
    for index = 1, #(nextDisplayState.recentCandidates or {}) do
        if tonumber(previousDisplayState.recentCandidates[index] and previousDisplayState.recentCandidates[index].eventID) ~= tonumber(nextDisplayState.recentCandidates[index] and nextDisplayState.recentCandidates[index].eventID) then
            return false
        end
    end

    return true
end

function TargetingWidget:ApplyPortraitSelectionState(slot, row, eventState)
    if not slot then
        return false
    end

    if not row then
        if slot.frame then
            slot.frame:Hide()
        end
        slot.eventID = nil
        return true
    end

    if tonumber(slot.eventID) ~= tonumber(row.eventID) then
        self:ApplyPortraitRow(slot, row, eventState)
        return true
    end

    local teamColor = getTeamBorderColor(eventState, row.unit)
    if row.selected then
        slot.portrait:SetBorderColor(0.94, 0.78, 0.22, 1)
        slot.frame:SetAlpha(1)
    else
        slot.portrait:SetBorderColor(teamColor.r, teamColor.g, teamColor.b, teamColor.a)
        slot.frame:SetAlpha(row.enabled == false and 0.35 or 0.92)
    end

    local enabled = row.enabled ~= false
    if slot.frame and slot.frame.EnableMouse then
        slot.frame:EnableMouse(enabled)
        slot.frame:Show()
    end
    if slot.portrait and slot.portrait.SetRaidMarker then
        slot.portrait:SetRaidMarker(row.unit and row.unit.raidMarker or 0)
    end
    if slot.portrait and slot.portrait.portraitPanel and slot.portrait.portraitPanel.GetFrame then
        local portraitPanelFrame = slot.portrait.portraitPanel:GetFrame()
        if portraitPanelFrame and portraitPanelFrame.EnableMouse then
            portraitPanelFrame:EnableMouse(enabled)
        end
    end

    return true
end

function TargetingWidget:RefreshSelectionState(reason, displayState)
    self.lastRefreshReason = reason
    self:CancelPendingPortraitRefresh()
    self:Build()
    self:Show()

    if self.headerSelectionText then
        self.headerSelectionText:SetText(tostring(displayState.selectionText or "Selected 0/0"))
    end
    if self.gridHeaderText then
        self.gridHeaderText:SetText(tostring(displayState.activeGroupLabel or "Targets"))
    end
    if self.detailEyebrowText then
        self.detailEyebrowText:SetText(tostring(displayState.selectedUnitRoleText or "Selected Target"))
    end
    if self.detailNameText then
        self.detailNameText:SetText(tostring(displayState.selectedUnitName or "No target selected"))
        local nameColor = type(displayState.selectedUnitNameColor) == "table" and displayState.selectedUnitNameColor or UI.ResolveColor(nil, "text.primary")
        self.detailNameText:SetTextColor(
            tonumber(nameColor.r) or 1,
            tonumber(nameColor.g) or 1,
            tonumber(nameColor.b) or 1,
            tonumber(nameColor.a) or 1
        )
    end
    if self.detailTeamText then
        self.detailTeamText:SetText(tostring(displayState.selectedUnitTeamText or ""))
    end
    if self.detailTypeSizeText then
        self.detailTypeSizeText:SetText(tostring(displayState.selectedUnitTypeSizeText or ""))
    end
    if self.detailHealthText then
        self.detailHealthText:SetText(tostring(displayState.selectedUnitHealthText or "HP: -"))
    end
    if self.detailSummaryText then
        self.detailSummaryText:SetText(tostring(displayState.selectedUnitSummaryText or ""))
    end
    if self.footerStatText then
        self.footerStatText:SetText(buildInlineIconLabel(displayState.selectedUnitHitStatIcon, displayState.selectedUnitHitStatName or ""))
    end
    if self.footerHitText then
        self.footerHitText:SetText(tostring(displayState.selectedUnitHitText or ""))
        local hitValue = tonumber(displayState.selectedUnitHitValue)
        local hitColor = UI.ResolveColor(nil, "text.secondary")
        if hitValue and hitValue > 0 then
            hitColor = POSITIVE_HIT_COLOR
        elseif hitValue and hitValue < 0 then
            hitColor = NEGATIVE_HIT_COLOR
        end
        self.footerHitText:SetTextColor(
            tonumber(hitColor.r) or 1,
            tonumber(hitColor.g) or 1,
            tonumber(hitColor.b) or 1,
            tonumber(hitColor.a) or 1
        )
    end
    if self.footerCritText then
        self.footerCritText:SetText(tostring(displayState.selectedUnitCritText or ""))
        local critValue = tonumber(displayState.selectedUnitCritValue)
        local critColor = UI.ResolveColor(nil, "text.secondary")
        if critValue and critValue > 0 then
            critColor = POSITIVE_HIT_COLOR
        elseif critValue and critValue < 0 then
            critColor = NEGATIVE_HIT_COLOR
        end
        self.footerCritText:SetTextColor(
            tonumber(critColor.r) or 1,
            tonumber(critColor.g) or 1,
            tonumber(critColor.b) or 1,
            tonumber(critColor.a) or 1
        )
    end
    if self.castButton and self.castButton.SetEnabled then
        self.castButton:SetEnabled(displayState.canConfirm == true)
    end

    for index = 1, #(displayState.groups or {}) do
        local slot = self:EnsureGroupButton(index)
        local group = displayState.groups[index]
        local button = slot.button
        slot.groupKey = group and group.key or nil
        if button and button.SetText then
            local isActiveGroup = group and group.key == displayState.activeGroupKey
            button:SetText(("%s%s (%d/%d)"):format(
                isActiveGroup and "Viewing: " or "",
                tostring(group and group.label or "Targets"),
                tonumber(group and group.selectedCount or 0) or 0,
                tonumber(group and group.maxTargets or 0) or 0
            ))
        end
        if button and button.SetEnabled then
            button:SetEnabled(#(displayState.groups or {}) > 1 and not (group and group.key == displayState.activeGroupKey))
        end
        local frame = button and button.GetFrame and button:GetFrame() or nil
        if frame then
            frame:SetAlpha(group and group.key == displayState.activeGroupKey and 1 or 0.92)
            frame:Show()
        end
    end

    local eventState = Client.GetEventState and Client:GetEventState() or nil
    for index = 1, 3 do
        local slot = self:EnsureRecentPortrait(index)
        self:ApplyPortraitSelectionState(slot, displayState.recentCandidates and displayState.recentCandidates[index] or nil, eventState)
    end
    self:RefreshVisibleCandidateSelectionState(displayState, eventState)

    self.lastDisplayState = displayState
    return true
end

function TargetingWidget:Refresh(reason, displayState)
    self.lastRefreshReason = reason

    displayState = type(displayState) == "table" and displayState or (Client.GetPendingSpellTargetingDisplayState and Client:GetPendingSpellTargetingDisplayState() or nil)
    if not displayState then
        self:CancelPendingPortraitRefresh()
        self:Hide()
        return false
    end

    self:Build()
    self:Show()

    if (reason == "target-toggle" or reason == "target-metrics")
        and isSelectionOnlyRefreshCompatible(self.lastDisplayState, displayState)
    then
        return self:RefreshSelectionState(reason, displayState)
    end

    local iconTexture = displayState.spellIcon ~= "" and displayState.spellIcon or DEFAULT_ICON
    if self.headerIcon and self.headerIcon.SetTexture then
        self.headerIcon:SetTexture(iconTexture)
    end
    if self.headerText then
        self.headerText:SetText(tostring(displayState.spellName or "Spell"))
    end
    if self.headerSelectionText then
        self.headerSelectionText:SetText(tostring(displayState.selectionText or "Selected 0/0"))
    end
    if self.gridHeaderText then
        self.gridHeaderText:SetText(tostring(displayState.activeGroupLabel or "Targets"))
    end
    if self.detailEyebrowText then
        self.detailEyebrowText:SetText(tostring(displayState.selectedUnitRoleText or "Selected Target"))
    end
    if self.detailNameText then
        self.detailNameText:SetText(tostring(displayState.selectedUnitName or "No target selected"))
        local nameColor = type(displayState.selectedUnitNameColor) == "table" and displayState.selectedUnitNameColor or UI.ResolveColor(nil, "text.primary")
        self.detailNameText:SetTextColor(
            tonumber(nameColor.r) or 1,
            tonumber(nameColor.g) or 1,
            tonumber(nameColor.b) or 1,
            tonumber(nameColor.a) or 1
        )
    end
    if self.detailTeamText then
        self.detailTeamText:SetText(tostring(displayState.selectedUnitTeamText or ""))
    end
    if self.detailTypeSizeText then
        self.detailTypeSizeText:SetText(tostring(displayState.selectedUnitTypeSizeText or ""))
    end
    if self.detailHealthText then
        self.detailHealthText:SetText(tostring(displayState.selectedUnitHealthText or "HP: -"))
    end
    if self.detailSummaryText then
        self.detailSummaryText:SetText(tostring(displayState.selectedUnitSummaryText or ""))
    end
    if self.footerStatText then
        self.footerStatText:SetText(buildInlineIconLabel(displayState.selectedUnitHitStatIcon, displayState.selectedUnitHitStatName or ""))
    end
    if self.footerHitText then
        self.footerHitText:SetText(tostring(displayState.selectedUnitHitText or ""))
        local hitValue = tonumber(displayState.selectedUnitHitValue)
        local hitColor = UI.ResolveColor(nil, "text.secondary")
        if hitValue and hitValue > 0 then
            hitColor = POSITIVE_HIT_COLOR
        elseif hitValue and hitValue < 0 then
            hitColor = NEGATIVE_HIT_COLOR
        end
        self.footerHitText:SetTextColor(
            tonumber(hitColor.r) or 1,
            tonumber(hitColor.g) or 1,
            tonumber(hitColor.b) or 1,
            tonumber(hitColor.a) or 1
        )
    end
    if self.footerCritText then
        self.footerCritText:SetText(tostring(displayState.selectedUnitCritText or ""))
        local critValue = tonumber(displayState.selectedUnitCritValue)
        local critColor = UI.ResolveColor(nil, "text.secondary")
        if critValue and critValue > 0 then
            critColor = POSITIVE_HIT_COLOR
        elseif critValue and critValue < 0 then
            critColor = NEGATIVE_HIT_COLOR
        end
        self.footerCritText:SetTextColor(
            tonumber(critColor.r) or 1,
            tonumber(critColor.g) or 1,
            tonumber(critColor.b) or 1,
            tonumber(critColor.a) or 1
        )
    end
    if self.castButton and self.castButton.SetEnabled then
        self.castButton:SetEnabled(displayState.canConfirm == true)
    end

    local showGroupRow = #(displayState.groups or {}) > 1
    if self.groupPanel and self.groupPanel.GetFrame then
        local groupPanelFrame = self.groupPanel:GetFrame()
        local groupCount = #(displayState.groups or {})
        local groupRows = math.max(1, math.ceil(groupCount / GROUP_BUTTON_COLUMNS))
        local groupLayoutHeight = (groupRows * GROUP_BUTTON_HEIGHT) + (math.max(0, groupRows - 1) * GROUP_BUTTON_SPACING)
        local panelHeight = 4 + 12 + 4 + groupLayoutHeight + 4
        if self.groupPanel.SetHeight then
            self.groupPanel:SetHeight(showGroupRow and panelHeight or 0)
        end
        if groupPanelFrame then
            groupPanelFrame:SetHeight(showGroupRow and panelHeight or 0)
            if showGroupRow then
                groupPanelFrame:Show()
            else
                groupPanelFrame:Hide()
            end
        end
        if self.groupLayout and self.groupLayout.SetHeight then
            self.groupLayout:SetHeight(showGroupRow and groupLayoutHeight or 0)
        end
        if self.groupLabel then
            self.groupLabel:SetText("Target Groups")
        end
    end
    for index = 1, #(displayState.groups or {}) do
        local slot = self:EnsureGroupButton(index)
        local group = displayState.groups[index]
        local button = slot.button
        slot.groupKey = group and group.key or nil
        if button and button.SetText then
            local isActiveGroup = group and group.key == displayState.activeGroupKey
            button:SetText(("%s%s (%d/%d)"):format(
                isActiveGroup and "Viewing: " or "",
                tostring(group and group.label or "Targets"),
                tonumber(group and group.selectedCount or 0) or 0,
                tonumber(group and group.maxTargets or 0) or 0
            ))
        end
        if button and button.SetEnabled then
            button:SetEnabled(showGroupRow and not (group and group.key == displayState.activeGroupKey))
        end
        local frame = button and button.GetFrame and button:GetFrame() or nil
        if frame then
            frame:SetAlpha(group and group.key == displayState.activeGroupKey and 1 or 0.92)
            frame:Show()
        end
    end
    for index = #(displayState.groups or {}) + 1, #self.groupButtons do
        local slot = self.groupButtons[index]
        local frame = slot and slot.button and slot.button.GetFrame and slot.button:GetFrame() or nil
        if frame then
            frame:Hide()
        end
        if slot then
            slot.groupKey = nil
        end
    end

    local candidateCount = #(displayState.candidates or {})

    local eventState = Client.GetEventState and Client:GetEventState() or nil
    local totalRows = math.max(1, math.ceil(candidateCount / GRID_COLUMNS))
    local contentHeight = math.max(GRID_VIEWPORT_HEIGHT, (totalRows * MAIN_PORTRAIT_SLOT_HEIGHT) + ((totalRows - 1) * GRID_SPACING))
    if self.gridScrollChild then
        self.gridScrollChild:SetSize(GRID_VIEWPORT_WIDTH, contentHeight)
    end
    if self.gridLayout and self.gridLayout.SetHeight then
        self.gridLayout:SetHeight(contentHeight)
    elseif self.gridLayout and self.gridLayout.GetFrame then
        self.gridLayout:GetFrame():SetHeight(contentHeight)
    end
    if self.gridScrollFrame and self.gridScrollFrame.SetVerticalScroll then
        if reason == "action-bar-activate" then
            self.gridVisibleStartIndex = 1
            self:SetGridScrollOffset(0)
        else
            self:SetGridScrollOffset(self.gridScrollOffset or 0)
        end
    end
    if self.gridScrollBar then
        self.gridScrollBar:SetMinMaxValues(0, math.max(0, contentHeight - GRID_VIEWPORT_HEIGHT))
        self.gridScrollBar:SetShown(contentHeight > GRID_VIEWPORT_HEIGHT)
    end
    self:QueuePortraitRefresh(displayState, eventState)

    if self.recentRow and self.recentRow.RefreshLayout then
        self.recentRow:RefreshLayout()
    end
    if self.groupLayout and self.groupLayout.RefreshLayout then
        self.groupLayout:RefreshLayout()
    end
    if self.gridHeaderRow and self.gridHeaderRow.RefreshLayout then
        self.gridHeaderRow:RefreshLayout()
    end
    if self.gridLayout and self.gridLayout.RefreshLayout then
        self.gridLayout:RefreshLayout()
    end
    if self.bodyRow and self.bodyRow.RefreshLayout then
        self.bodyRow:RefreshLayout()
    end
    if self.detailContentLayout and self.detailContentLayout.RefreshLayout then
        self.detailContentLayout:RefreshLayout()
    end
    if self.footerInfoLayout and self.footerInfoLayout.RefreshLayout then
        self.footerInfoLayout:RefreshLayout()
    end
    if self.footerActionsRow and self.footerActionsRow.RefreshLayout then
        self.footerActionsRow:RefreshLayout()
    end
    if self.rootLayout and self.rootLayout.RefreshLayout then
        self.rootLayout:RefreshLayout()
    end

    self.lastDisplayState = displayState
    return candidateCount > 0
end

function Client:BuildTargetingWidget()
    return TargetingWidget:Get():Build()
end

function Client:ShowTargetingWidget()
    if self:RequireSetupCompletion("targeting-widget") ~= true then
        return nil
    end

    return TargetingWidget:Get():Show()
end

function Client:HideTargetingWidget()
    return TargetingWidget:Get():Hide()
end

function Client:IsTargetingWidgetVisible()
    local widget = TargetingWidget:Get()
    local window = widget and widget.window or nil
    local frame = window and window.GetFrame and window:GetFrame() or nil
    return frame and frame.IsShown and frame:IsShown() or false
end

function Client:RefreshTargetingWidgetFrame(reason, displayState)
    return TargetingWidget:Get():Refresh(reason, displayState)
end

local initializer = CreateFrame and CreateFrame("Frame")
if initializer then
    initializer:RegisterEvent("ADDON_LOADED")
    initializer:SetScript("OnEvent", function(_, event, loadedAddonName)
        if event ~= "ADDON_LOADED" or loadedAddonName ~= addonName then
            return
        end

        if Client.BuildTargetingWidget then
            Client:BuildTargetingWidget()
        end
    end)
end

return TargetingWidget
