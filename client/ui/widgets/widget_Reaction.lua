local addonName, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI
local UI = Addon.UI or {}
local Image = UI.Image

local WINDOW_WIDTH = 284
local WINDOW_BASE_HEIGHT = 152
local WINDOW_TOP_OFFSET = -210
local CONTENT_WIDTH = WINDOW_WIDTH - 20
local PORTRAIT_SIZE = 44
local ACTION_BUTTON_SIZE = 30
local ACTION_LABEL_HEIGHT = 14
local ACTION_COLUMNS = 4
local ACTION_CELL_HEIGHT = 46
local ACTION_ROW_SPACING = 2
local ACTIONS_BASE_HEIGHT = 46
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

ClientUI.ReactionWidget = ClientUI.ReactionWidget or {}
local ReactionWidget = ClientUI.ReactionWidget
ReactionWidget.__index = ReactionWidget

local function createInstance()
    return setmetatable({
        window = nil,
        rootLayout = nil,
        headerRow = nil,
        portrait = nil,
        headerTextColumn = nil,
        headerPromptText = nil,
        headerNameText = nil,
        failurePreviewRow = nil,
        failurePreviewIcon = nil,
        failurePreviewText = nil,
        actionsLayout = nil,
        actionSlots = {},
    }, ReactionWidget)
end

function ReactionWidget:Get()
    if not self.Instance then
        self.Instance = createInstance()
    end

    return self.Instance
end

function ReactionWidget:Build()
    if self.window then
        return self.window
    end

    self.window = UI.Window:New({
        name = "RPEClientReactionWidgetWindow",
        width = WINDOW_WIDTH,
        height = WINDOW_BASE_HEIGHT,
        point = "TOP",
        relativeTo = UIParent,
        relativePoint = "TOP",
        frameStrata = "DIALOG",
        frameLevel = 85,
        movable = false,
        hidden = true,
        contentInsetLeft = 10,
        contentInsetRight = 10,
        contentInsetTop = 28,
        contentInsetBottom = 10,
    })
    self.window:SetTitle("Reaction")
    self.window:Create()

    local frame = self.window:GetFrame()
    frame:ClearAllPoints()
    frame:SetPoint("TOP", UIParent, "TOP", 0, WINDOW_TOP_OFFSET)

    local contentFrame = self.window:GetContentFrame()
    self.rootLayout = UI.CreateLayout(UI.VerticalLayoutGroup, contentFrame, "RPEClientReactionWidgetRootLayout", {
        width = CONTENT_WIDTH,
        height = WINDOW_BASE_HEIGHT - 38,
        spacing = 10,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(self.rootLayout, contentFrame, 0, 0, 0, 0)

    self.headerRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.rootLayout:GetFrame(), "RPEClientReactionWidgetHeaderRow", {
        width = CONTENT_WIDTH,
        height = 58,
        spacing = 8,
        fitChildrenWidth = false,
        fitChildrenHeight = true,
    })
    self.rootLayout:AddChild(self.headerRow)

    self.portrait = UI.UnitPortrait:New({
        name = "RPEClientReactionWidgetPortrait",
        width = PORTRAIT_SIZE,
        height = PORTRAIT_SIZE,
        portraitWidth = PORTRAIT_SIZE,
        portraitHeight = PORTRAIT_SIZE,
        progressHeight = 0,
        progressSpacing = 0,
        portraitBorderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.portrait:SetParent(self.headerRow:GetFrame())
    self.portrait:Create()
    self.headerRow:AddChild(self.portrait)

    local progressFrame = self.portrait.progressBar and self.portrait.progressBar.GetFrame and self.portrait.progressBar:GetFrame() or nil
    if progressFrame and progressFrame.Hide then
        progressFrame:Hide()
    end

    self.headerTextColumn = UI.CreateLayout(UI.VerticalLayoutGroup, self.headerRow:GetFrame(), "RPEClientReactionWidgetHeaderTextColumn", {
        width = CONTENT_WIDTH - PORTRAIT_SIZE - 8,
        height = 58,
        spacing = 1,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.headerRow:AddChild(self.headerTextColumn)

    self.headerPromptText = UI.CreateText(self.headerTextColumn:GetFrame(), "RPEClientReactionWidgetHeaderPrompt", "You are defending against:", {
        width = CONTENT_WIDTH - PORTRAIT_SIZE - 8,
        height = 16,
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        fontSize = 9,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.headerTextColumn:AddChild(self.headerPromptText)

    self.headerNameText = UI.CreateText(self.headerTextColumn:GetFrame(), "RPEClientReactionWidgetHeaderName", "Unknown Attacker", {
        width = CONTENT_WIDTH - PORTRAIT_SIZE - 8,
        height = 18,
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        fontSize = 11,
        fontFlags = "OUTLINE",
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.headerTextColumn:AddChild(self.headerNameText)

    self.failurePreviewRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.headerTextColumn:GetFrame(), "RPEClientReactionWidgetFailurePreviewRow", {
        width = CONTENT_WIDTH - PORTRAIT_SIZE - 8,
        height = 16,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = true,
    })
    self.headerTextColumn:AddChild(self.failurePreviewRow)

    self.failurePreviewIcon = Image:New({
        name = "RPEClientReactionWidgetFailurePreviewIcon",
        width = 14,
        height = 14,
        texture = DEFAULT_ICON,
    })
    self.failurePreviewIcon:SetParent(self.failurePreviewRow:GetFrame())
    self.failurePreviewIcon:Create()
    self.failurePreviewRow:AddChild(self.failurePreviewIcon)

    self.failurePreviewText = UI.CreateText(self.failurePreviewRow:GetFrame(), "RPEClientReactionWidgetFailurePreviewText", "", {
        width = CONTENT_WIDTH - PORTRAIT_SIZE - 26,
        height = 16,
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        fontSize = 8,
        textColor = UI.ResolveColor(nil, "danger"),
    })
    self.failurePreviewRow:AddChild(self.failurePreviewText)

    self.actionsLayout = UI.CreateLayout(UI.GridLayoutGroup, self.rootLayout:GetFrame(), "RPEClientReactionWidgetActionsLayout", {
        width = CONTENT_WIDTH,
        height = ACTIONS_BASE_HEIGHT,
        columns = ACTION_COLUMNS,
        cellWidth = 52,
        cellHeight = ACTION_CELL_HEIGHT,
        spacing = ACTION_ROW_SPACING,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
        autoSize = false,
    })
    self.rootLayout:AddChild(self.actionsLayout)

    return self.window
end

function ReactionWidget:EnsureActionSlot(index)
    self:Build()
    local slot = self.actionSlots[index]
    if slot then
        return slot
    end

    slot = {
        panel = UI.CreatePanel(self.actionsLayout:GetFrame(), ("RPEClientReactionWidgetActionPanel%d"):format(index), {
            width = 52,
            height = ACTION_CELL_HEIGHT,
            contentInset = 0,
            showBorder = false,
            panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
        }),
        button = nil,
        label = nil,
        actionId = nil,
    }
    self.actionsLayout:AddChild(slot.panel)

    local contentFrame = slot.panel:GetContentFrame()
    slot.button = UI.ImageButton:New({
        name = ("RPEClientReactionWidgetActionButton%d"):format(index),
        width = ACTION_BUTTON_SIZE,
        height = ACTION_BUTTON_SIZE,
        border = false,
        normalTexture = DEFAULT_ICON,
        highlightTexture = DEFAULT_ICON,
        pushedTexture = DEFAULT_ICON,
        disabledTexture = DEFAULT_ICON,
    })
    slot.button:SetParent(contentFrame)
    slot.button:Create()
    local buttonFrame = slot.button:GetFrame()
    buttonFrame:SetPoint("TOP", contentFrame, "TOP", 0, 0)
    slot.button:SetScript("OnClick", function()
        if Client.ResolveCombatReactionAction then
            Client:ResolveCombatReactionAction(slot.actionId)
        end
    end)

    slot.label = UI.CreateText(contentFrame, ("RPEClientReactionWidgetActionLabel%d"):format(index), "", {
        width = 52,
        height = ACTION_LABEL_HEIGHT,
        justifyH = "CENTER",
        justifyV = "TOP",
        fontSize = 7,
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    local labelFrame = slot.label:GetFrame()
    labelFrame:SetPoint("TOP", buttonFrame, "BOTTOM", 0, -2)

    self.actionSlots[index] = slot
    return slot
end

function ReactionWidget:Show()
    self:Build()
    self.window:Show()
    return true
end

function ReactionWidget:Hide()
    if self.window then
        self.window:Hide()
    end
    return true
end

function ReactionWidget:Refresh(reason)
    local displayState = Client.GetReactionDisplayState and Client:GetReactionDisplayState() or nil
    if not displayState then
        self:Hide()
        return false
    end

    self:Build()
    self:Show()

    if self.portrait and self.portrait.SetUnit then
        self.portrait:SetUnit(displayState.attackerUnit)
    end
    if self.headerPromptText then
        self.headerPromptText:SetText("You are defending against:")
    end
    if self.headerNameText then
        self.headerNameText:SetText(tostring(displayState.attackerName or "Unknown Attacker"))
    end
    if self.failurePreviewText then
        self.failurePreviewText:SetText(tostring(displayState.failurePreviewText or ""))
    end
    if self.failurePreviewIcon and self.failurePreviewIcon.SetTexture then
        self.failurePreviewIcon:SetTexture(tostring(displayState.failurePreviewIcon or "") ~= "" and tostring(displayState.failurePreviewIcon) or DEFAULT_ICON)
    end
    local previewRowFrame = self.failurePreviewRow and self.failurePreviewRow.GetFrame and self.failurePreviewRow:GetFrame() or nil
    if previewRowFrame then
        if tostring(displayState.failurePreviewText or "") ~= "" then
            previewRowFrame:Show()
        else
            previewRowFrame:Hide()
        end
    end

    local actions = displayState.actions or {}
    local actionCount = math.max(1, #actions)
    local actionColumns = actionCount
    local cellWidth = math.max(40, math.floor((CONTENT_WIDTH - ((actionColumns - 1) * ACTION_ROW_SPACING)) / actionColumns))
    local actionsHeight = ACTIONS_BASE_HEIGHT
    local windowHeight = WINDOW_BASE_HEIGHT
    if self.actionsLayout and self.actionsLayout.SetOption then
        self.actionsLayout:SetOption("columns", actionColumns)
        self.actionsLayout:SetOption("cellWidth", cellWidth)
        self.actionsLayout:SetOption("cellHeight", ACTION_CELL_HEIGHT)
        self.actionsLayout:SetOption("spacing", ACTION_ROW_SPACING)
    elseif self.actionsLayout and self.actionsLayout.options then
        self.actionsLayout.options.columns = actionColumns
        self.actionsLayout.options.cellWidth = cellWidth
        self.actionsLayout.options.cellHeight = ACTION_CELL_HEIGHT
        self.actionsLayout.options.spacing = ACTION_ROW_SPACING
    end
    if self.actionsLayout and self.actionsLayout.SetHeight then
        self.actionsLayout:SetHeight(actionsHeight)
    elseif self.actionsLayout and self.actionsLayout.GetFrame and self.actionsLayout:GetFrame() and self.actionsLayout:GetFrame().SetHeight then
        self.actionsLayout:GetFrame():SetHeight(actionsHeight)
    end
    if self.window and self.window.SetHeight then
        self.window:SetHeight(windowHeight)
    elseif self.window and self.window.GetFrame and self.window:GetFrame() and self.window:GetFrame().SetHeight then
        self.window:GetFrame():SetHeight(windowHeight)
    end

    for index = 1, #actions do
        local slot = self:EnsureActionSlot(index)
        local action = actions[index]
        slot.actionId = action and action.id or nil
        if slot.panel and slot.panel.SetWidth then
            slot.panel:SetWidth(cellWidth)
        end
        if slot.button then
            slot.button:SetNormalTexture(action and action.icon or DEFAULT_ICON)
            slot.button:SetHighlightTexture(action and action.icon or DEFAULT_ICON)
            slot.button:SetPushedTexture(action and action.icon or DEFAULT_ICON)
            slot.button:SetDisabledTexture(action and action.icon or DEFAULT_ICON)
            local frame = slot.button.GetFrame and slot.button:GetFrame() or nil
            if frame and frame.Show then
                frame:Show()
            end
            if slot.button.SetEnabled then
                slot.button:SetEnabled(action and action.enabled ~= false and slot.actionId ~= nil)
            end
        end
        if slot.label and slot.label.SetText then
            slot.label:SetText(tostring(action and action.label or ""))
            if slot.label.SetWidth then
                slot.label:SetWidth(cellWidth)
            end
            slot.label:SetTextColor(
                (action and action.enabled ~= false) and (UI.ResolveColor(nil, "text.primary").r or 1) or (UI.ResolveColor(nil, "text.secondary").r or 0.7),
                (action and action.enabled ~= false) and (UI.ResolveColor(nil, "text.primary").g or 1) or (UI.ResolveColor(nil, "text.secondary").g or 0.7),
                (action and action.enabled ~= false) and (UI.ResolveColor(nil, "text.primary").b or 1) or (UI.ResolveColor(nil, "text.secondary").b or 0.7),
                (action and action.enabled ~= false) and (UI.ResolveColor(nil, "text.primary").a or 1) or (UI.ResolveColor(nil, "text.secondary").a or 1)
            )
        end
        local panelFrame = slot.panel and slot.panel.GetFrame and slot.panel:GetFrame() or nil
        if panelFrame and panelFrame.Show then
            panelFrame:Show()
        end
    end

    for index = #actions + 1, #self.actionSlots do
        local slot = self.actionSlots[index]
        if slot then
            slot.actionId = nil
            local panelFrame = slot.panel and slot.panel.GetFrame and slot.panel:GetFrame() or nil
            if panelFrame and panelFrame.Hide then
                panelFrame:Hide()
            end
        end
    end

    if self.headerTextColumn and self.headerTextColumn.RefreshLayout then
        self.headerTextColumn:RefreshLayout()
    end
    if self.headerRow and self.headerRow.RefreshLayout then
        self.headerRow:RefreshLayout()
    end
    if self.actionsLayout and self.actionsLayout.RefreshLayout then
        self.actionsLayout:RefreshLayout()
    end
    if self.rootLayout and self.rootLayout.RefreshLayout then
        self.rootLayout:RefreshLayout()
    end

    return reason ~= nil
end

function Client:BuildReactionWidget()
    return ReactionWidget:Get():Build()
end

function Client:ShowReactionWidget()
    return ReactionWidget:Get():Show()
end

function Client:HideReactionWidget()
    return ReactionWidget:Get():Hide()
end

function Client:RefreshReactionWidget(reason)
    return ReactionWidget:Get():Refresh(reason)
end

local initializer = CreateFrame and CreateFrame("Frame")
if initializer then
    initializer:RegisterEvent("ADDON_LOADED")
    initializer:SetScript("OnEvent", function(_, event, loadedAddonName)
        if event ~= "ADDON_LOADED" or loadedAddonName ~= addonName then
            return
        end

        if Client.BuildReactionWidget then
            Client:BuildReactionWidget()
        end
    end)
end

return ReactionWidget
