local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Ruleset = Addon.Client.UI.Ruleset or {}

local Client = Addon.Client
local RulesetWindow = Addon.Client.UI.Ruleset
local UI = Addon.UI or {}
local RulesetLogic = Addon.Internal and Addon.Internal.Ruleset or {}
Addon.Debug = Addon.Debug or {}
Addon.Debug.Clipboard = Addon.Debug.Clipboard or {}

RulesetWindow.__index = RulesetWindow
RulesetWindow.Database = Addon.Internal and Addon.Internal.Database or {}

local function getClipboard()
    return Addon.Debug and Addon.Debug.Clipboard or nil
end

local function buildRulesetTooltip(self, ruleset)
    if not ruleset then
        return nil
    end

    local isActive = self:IsRulesetActive(ruleset.id)
    local description = tostring(ruleset.description or "")

    return {
        type = "custom",
        title = self:GetRulesetDisplayName(ruleset),
        lines = {
            ("ID: %s"):format(ruleset.id or "-"),
            ("State: %s"):format(isActive and "Active" or "Inactive"),
            ("Tag: %s"):format(ruleset.tagState or "standard"),
            ("Description: %s"):format(description ~= "" and description or "-"),
        },
    }
end

local function commitRulesetName(self)
    local ruleset = self:GetSelectedRuleset()
    if not ruleset or not self.RulesetPaneNameInput or not self.Database or not self.Database.RenameRuleset then
        return
    end

    self.Database.RenameRuleset(ruleset.id, self.RulesetPaneNameInput:GetText())
    self:RefreshAll()
end

function RulesetWindow:GetRulesets()
    return RulesetLogic.GetRulesets()
end

function RulesetWindow:GetRulesetDisplayName(ruleset)
    return RulesetLogic.GetRulesetDisplayName(ruleset)
end

function RulesetWindow:GetSelectedRuleset()
    if self.SelectedRulesetId then
        local selected = RulesetLogic.GetRulesetByID(self.SelectedRulesetId)
        if selected then
            return selected
        end
    end

    local active = RulesetLogic.GetActiveRuleset()
    if active then
        self.SelectedRulesetId = active.id
        return active
    end

    local rulesets = self:GetRulesets()
    local firstRuleset = rulesets[1]
    self.SelectedRulesetId = firstRuleset and firstRuleset.id or nil
    return firstRuleset
end

function RulesetWindow:SetSelectedRulesetId(rulesetId)
    self.SelectedRulesetId = rulesetId
    self.SelectedRulesetRuleKey = nil
    self.ActiveInspectorPageKey = "ruleset"
    self:RefreshAll()
end

function RulesetWindow:GetActiveRulesetId()
    return RulesetLogic.GetActiveRulesetId()
end

function RulesetWindow:IsRulesetActive(rulesetId)
    return RulesetLogic.IsRulesetActive(rulesetId)
end

function RulesetWindow:SetActiveRulesetId(rulesetId)
    local activeId = RulesetLogic.SetActiveRulesetId(rulesetId)
    if activeId ~= nil or rulesetId == nil then
        self:RefreshAll()
    end
    return activeId
end

function RulesetWindow:CreateRulesetAndSelect()
    local ruleset = RulesetLogic.CreateRuleset("New Ruleset")
    if ruleset then
        self.SelectedRulesetId = ruleset.id
        self.SelectedRulesetRuleKey = nil
        self.ActiveInspectorPageKey = "ruleset"
        self:RefreshAll()
    end
    return ruleset
end

function RulesetWindow:ExportRulesetToClipboard(rulesetId)
    local targetRulesetId = rulesetId or self.SelectedRulesetId
    if not targetRulesetId or not RulesetLogic or not RulesetLogic.ExportRuleset then
        return nil
    end

    local exportText = RulesetLogic.ExportRuleset(targetRulesetId)
    if not exportText then
        return nil
    end

    local clipboard = getClipboard()
    if clipboard and clipboard.Show then
        clipboard:Show(exportText)
    end

    return exportText
end

function RulesetWindow:ImportRulesetFromText(text)
    if not RulesetLogic or not RulesetLogic.ImportRuleset then
        return nil, "Ruleset import is unavailable."
    end

    local ruleset, err = RulesetLogic.ImportRuleset(text)
    if not ruleset then
        return nil, err or "Ruleset import failed."
    end

    self:SetSelectedRulesetId(ruleset.id)
    return ruleset
end

function RulesetWindow:BuildRulesetImportWindow()
    if self.RulesetImportWindow then
        return self.RulesetImportWindow
    end

    local window = UI.Window:New({
        name = "RPERulesetImportWindow",
        width = 540,
        height = 360,
        point = "CENTER",
        relativeTo = UIParent,
        relativePoint = "CENTER",
        frameStrata = "HIGH",
        frameLevel = 30,
        movable = true,
        clampedToScreen = true,
        toplevel = true,
        hidden = true,
        contentInsetLeft = 10,
        contentInsetRight = 10,
        contentInsetTop = 28,
        contentInsetBottom = 10,
    })
    window:SetTitle("Import Ruleset")
    window:Create()
    self.RulesetImportWindow = window

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, window:GetContentFrame(), "RPERulesetImportRoot", {
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(root, window:GetContentFrame(), 0, 0, 0, 0)

    self.RulesetImportInstructionText = UI.CreateText(root:GetFrame(), "RPERulesetImportInstructionText",
        "Paste a ruleset export string below and click Import.", {
            width = 500,
            height = 14,
            justifyH = "LEFT",
            textColor = UI.ResolveColor(nil, "text.secondary"),
        }
    )
    root:AddChild(self.RulesetImportInstructionText)

    self.RulesetImportTextArea = UI.CreateTextArea(root:GetFrame(), "RPERulesetImportTextArea", {
        width = 500,
        height = 260,
        expandWidth = true,
        expandHeight = true,
        weight = 1,
        text = "",
        readOnly = false,
        borderColor = UI.ResolveColor(nil, "panel.border"),
        backgroundColor = UI.ResolveColor(nil, "window.background"),
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    root:AddChild(self.RulesetImportTextArea)

    self.RulesetImportStatusText = UI.CreateText(root:GetFrame(), "RPERulesetImportStatusText", "", {
        width = 500,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.RulesetImportStatusText)

    local actions = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPERulesetImportActions", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 20,
    })
    root:AddChild(actions)

    self.RulesetImportConfirmButton = UI.CreateButton(actions:GetFrame(), "RPERulesetImportConfirmButton", "Import", 60, function()
        local importText = self.RulesetImportTextArea and self.RulesetImportTextArea.GetText and self.RulesetImportTextArea:GetText() or ""
        local ruleset, err = self:ImportRulesetFromText(importText)
        if not ruleset then
            if self.RulesetImportStatusText and self.RulesetImportStatusText.SetText then
                self.RulesetImportStatusText:SetText(tostring(err or "Import failed."))
            end
            return
        end

        if self.RulesetImportStatusText and self.RulesetImportStatusText.SetText then
            self.RulesetImportStatusText:SetText("")
        end
        if self.RulesetImportWindow and self.RulesetImportWindow.Hide then
            self.RulesetImportWindow:Hide()
        end
    end, {
        height = 20,
        fontSize = 7,
    })
    actions:AddChild(self.RulesetImportConfirmButton)

    self.RulesetImportCancelButton = UI.CreateButton(actions:GetFrame(), "RPERulesetImportCancelButton", "Cancel", 60, function()
        if self.RulesetImportWindow and self.RulesetImportWindow.Hide then
            self.RulesetImportWindow:Hide()
        end
    end, {
        height = 20,
        fontSize = 7,
    })
    actions:AddChild(self.RulesetImportCancelButton)

    return window
end

function RulesetWindow:ShowRulesetImportWindow()
    local window = self:BuildRulesetImportWindow()
    if self.RulesetImportTextArea and self.RulesetImportTextArea.SetText then
        self.RulesetImportTextArea:SetText("")
    end
    if self.RulesetImportStatusText and self.RulesetImportStatusText.SetText then
        self.RulesetImportStatusText:SetText("")
    end
    if window and window.Show then
        window:Show()
    end
    if self.RulesetImportTextArea and self.RulesetImportTextArea.Focus then
        self.RulesetImportTextArea:Focus()
    end
    return window
end

function RulesetWindow:DeleteRuleset(rulesetId)
    local selectedId = self.SelectedRulesetId
    local rulesets = self:GetRulesets()
    local fallbackId = nil

    for index = 1, #rulesets do
        local candidateId = rulesets[index] and rulesets[index].id or nil
        if candidateId == rulesetId then
            local nextRuleset = rulesets[index + 1] or rulesets[index - 1]
            fallbackId = nextRuleset and nextRuleset.id or nil
            break
        end
    end

    local deleted = RulesetLogic.DeleteRuleset(rulesetId)
    if not deleted then
        return false
    end

    if selectedId == rulesetId then
        self.SelectedRulesetId = fallbackId
        self.SelectedRulesetRuleKey = nil
    end

    self.ActiveInspectorPageKey = "ruleset"
    self:RefreshAll()
    return true
end

function RulesetWindow:ConfirmDeleteRuleset(rulesetId)
    if not rulesetId or not (UI.Popup and UI.Popup.ShowConfirmation) then
        return false
    end

    local ruleset = RulesetLogic.GetRulesetByID and RulesetLogic.GetRulesetByID(rulesetId) or nil
    local rulesetName = ruleset and ruleset.name or nil
    local displayName = rulesetName ~= nil and rulesetName ~= "" and tostring(rulesetName) or "Unnamed Ruleset"

    return UI.Popup:ShowConfirmation({
        title = "Delete Ruleset",
        message = ('Delete ruleset "%s"? This cannot be undone.'):format(displayName),
        confirmText = "Delete",
        cancelText = "Cancel",
        onConfirm = function()
            return self:DeleteRuleset(rulesetId)
        end,
    })
end

function RulesetWindow:BuildRulesetsPane(parent)
    if self.RulesetsPane then
        return self.RulesetsPane
    end

    self.RulesetsPane = UI.CreatePanel(parent, "RPERulesetPane", {
        width = 190,
        height = 272,
        expandWidth = true,
        weight = 190,
        contentInset = 0,
        showBorder = false,
    })

    local content = self.RulesetsPane:GetContentFrame()
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, content, "RPERulesetPaneRootLayout", {
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, content, 0, 0, 0, 12)

    local toolbar = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPERulesetToolbar", {
        spacing = 8,
        autoSize = true,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })

    self.AddRulesetButton = UI.CreateButton(toolbar:GetFrame(), "RPEAddRulesetButton", "New Ruleset", 124, function()
        self:CreateRulesetAndSelect()
    end)
    toolbar:AddChild(self.AddRulesetButton)

    self.ImportRulesetButton = UI.CreateButton(toolbar:GetFrame(), "RPEImportRulesetButton", "Import", 58, function()
        self:ShowRulesetImportWindow()
    end)
    toolbar:AddChild(self.ImportRulesetButton)
    root:AddChild(toolbar)

    local listPanel = UI.CreatePanel(root:GetFrame(), "RPERulesetListPanel", {
        width = 180,
        height = 144,
        contentInset = 2,
        showBorder = false,
    })
    root:AddChild(listPanel)

    self.RulesetList = UI.ScrollLayout:New({
        name = "RPERulesetList",
        width = 176,
        height = 140,
        visibleRows = 9,
        rowHeight = 16,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 118,
        statusWidth = 44,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.RulesetList:SetParent(listPanel:GetContentFrame())
    self.RulesetList:SetRowRenderer(function(row, ruleset)
        local isActive = ruleset and ruleset.id and self:IsRulesetActive(ruleset.id) or false

        if row.SetCategory then
            row:SetCategory(self:GetRulesetDisplayName(ruleset))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(isActive and "Active" or "")
        end
        if row.SetDetail then
            row:SetDetail(ruleset and ruleset.id or "")
        end
        if row.SetTooltip then
            row:SetTooltip(buildRulesetTooltip(self, ruleset))
        end
        if row.categoryRegion and row.categoryRegion.SetTextColor then
            local token = isActive and "success" or "text.secondary"
            local color = UI.ResolveColor(nil, token)
            row.categoryRegion:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" and ruleset and ruleset.id then
                    self:SetSelectedRulesetId(ruleset.id)
                    if self.RulesetContextMenu and self.RulesetContextMenu.HideMenus then
                        self.RulesetContextMenu:HideMenus()
                    end
                elseif button == "RightButton" and ruleset and ruleset.id then
                    self:SetSelectedRulesetId(ruleset.id)
                    self:ShowRulesetContextMenu(frame, ruleset)
                end
            end)

            local isSelected = ruleset and ruleset.id == self.SelectedRulesetId
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.RulesetList:Create()
    UI.Utils.AnchorFill(self.RulesetList, listPanel:GetContentFrame(), 0, 0, 0, 0)

    local metadataPanel = UI.CreatePanel(content, "RPERulesetMetadataPanel", {
        width = 176,
        height = 96,
        contentInset = 4,
        showBorder = true,
    })
    metadataPanel:GetFrame():ClearAllPoints()
    metadataPanel:GetFrame():SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 12)
    metadataPanel:GetFrame():SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -8, 12)

    local detailsLayout = UI.CreateLayout(UI.VerticalLayoutGroup, metadataPanel:GetContentFrame(), "RPERulesetMetadataLayout", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(detailsLayout, metadataPanel:GetContentFrame(), 0, 0, 0, 0)

    self.RulesetPaneNameInput = UI.CreateTextInput(detailsLayout:GetFrame(), "RPERulesetPaneNameInput", {
        width = 160,
        height = 24,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.RulesetPaneNameInput:SetScript("OnEnterPressed", function()
        commitRulesetName(self)
    end)
    self.RulesetPaneNameInput:SetScript("OnEditFocusLost", function()
        commitRulesetName(self)
    end)
    detailsLayout:AddChild(self.RulesetPaneNameInput)

    self.RulesetPaneIdText = UI.CreateText(detailsLayout:GetFrame(), "RPERulesetPaneIdText", "ID: -", {
        width = 160,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    detailsLayout:AddChild(self.RulesetPaneIdText)

    self.RulesetPaneAuthorText = UI.CreateText(detailsLayout:GetFrame(), "RPERulesetPaneAuthorText", "Author: -", {
        width = 160,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    detailsLayout:AddChild(self.RulesetPaneAuthorText)

    self.RulesetPaneStateText = UI.CreateText(detailsLayout:GetFrame(), "RPERulesetPaneStateText", "State: -", {
        width = 160,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    detailsLayout:AddChild(self.RulesetPaneStateText)

    self:RefreshRulesetsPane()
    return self.RulesetsPane
end

function RulesetWindow:EnsureRulesetContextMenu()
    if self.RulesetContextMenu then
        return self.RulesetContextMenu
    end

    self.RulesetContextMenu = UI.ContextMenu:New({
        name = "RPERulesetContextMenu",
        width = 140,
        panelWidth = 140,
        visibleRows = 4,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            local action = item and item.value or nil
            local rulesetId = self.ContextMenuRulesetId
            if not rulesetId then
                return
            end

            if action == "activate" then
                self:SetActiveRulesetId(rulesetId)
            elseif action == "export" then
                self:ExportRulesetToClipboard(rulesetId)
            elseif action == "delete" then
                self:ConfirmDeleteRuleset(rulesetId)
            end

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.RulesetContextMenu:SetParent(self.Window and self.Window:GetFrame() or UIParent)
    self.RulesetContextMenu:Create()
    return self.RulesetContextMenu
end

function RulesetWindow:ShowRulesetContextMenu(anchorFrame, ruleset)
    if not ruleset or not ruleset.id then
        return
    end

    local menu = self:EnsureRulesetContextMenu()
    local isActive = self:IsRulesetActive(ruleset.id)

    self.ContextMenuRulesetId = ruleset.id
    menu:SetItems({
        {
            label = isActive and "Active Ruleset" or "Activate",
            value = "activate",
            enabled = not isActive,
        },
        {
            label = "Export",
            value = "export",
        },
        {
            label = "Delete",
            value = "delete",
        },
    })
    menu:ShowAt(anchorFrame)
end

function RulesetWindow:RefreshRulesetsPane()
    local ruleset = self:GetSelectedRuleset()

    if self.RulesetList and self.RulesetList.SetItems then
        self.RulesetList:SetItems(self:GetRulesets())
    end

    if self.RulesetPaneNameInput and self.RulesetPaneNameInput.SetText then
        self.RulesetPaneNameInput:SetText(ruleset and (ruleset.name or "") or "")
        self.RulesetPaneNameInput:SetEnabled(ruleset ~= nil)
        self.RulesetPaneNameInput:SetReadOnly(ruleset == nil)
    end

    if self.RulesetPaneIdText and self.RulesetPaneIdText.SetText then
        self.RulesetPaneIdText:SetText(("ID: %s"):format(ruleset and ruleset.id or "-"))
    end

    if self.RulesetPaneAuthorText and self.RulesetPaneAuthorText.SetText then
        self.RulesetPaneAuthorText:SetText(("Author: %s"):format(ruleset and ruleset.authorName ~= "" and ruleset.authorName or "-"))
    end

    if self.RulesetPaneStateText and self.RulesetPaneStateText.SetText then
        self.RulesetPaneStateText:SetText(("State: %s"):format(ruleset and self:IsRulesetActive(ruleset.id) and "Active" or "Inactive"))
    end
end

function RulesetWindow:GetRulesetCategoryIndexByKey(categoryKey)
    return RulesetLogic.GetRulesetCategoryIndexByKey(categoryKey)
end

function RulesetWindow:SetActiveRulesetCategory(index)
    local definitions = RulesetLogic.GetRulesetCategoryDefinitions()
    if #definitions == 0 then
        self.ActiveRulesetCategoryKey = nil
        self.SelectedRulesetRuleKey = nil
    else
        local clamped = math.max(1, math.min(index or 1, #definitions))
        self.ActiveRulesetCategoryKey = definitions[clamped].key
        self.SelectedRulesetRuleKey = nil
    end

    if self.RefreshRulesetInspectorPage then
        self:RefreshRulesetInspectorPage()
    end
end

function RulesetWindow:SetSelectedRulesetRuleKey(ruleKey)
    local categoryDefinition = RulesetLogic.GetRulesetCategoryDefinition(self.ActiveRulesetCategoryKey)
    local ruleDefinition = RulesetLogic.GetRulesetRuleDefinition(categoryDefinition and categoryDefinition.key or nil, ruleKey)
    self.SelectedRulesetRuleKey = ruleDefinition and ruleDefinition.key or RulesetLogic.GetDefaultRulesetRuleKey(categoryDefinition and categoryDefinition.key or nil)

    if self.RefreshRulesetInspectorPage then
        self:RefreshRulesetInspectorPage()
    end
end

function RulesetWindow:ShowInspectorPage(pageKey)
    self.InspectorPages = self.InspectorPages or {}

    local builders = {
        ruleset = "BuildRulesetInspectorPage",
    }

    for key, _ in pairs(builders) do
        if self.InspectorPages[key] and self.InspectorPages[key].Hide then
            self.InspectorPages[key]:Hide()
        end
    end

    local builderName = builders[pageKey] or builders.ruleset
    local page = self.InspectorPages[pageKey]
    if not page and self[builderName] then
        page = self[builderName](self, self.InspectorHost)
        self.InspectorPages[pageKey] = page
        if page then
            UI.Utils.AnchorFill(page, self.InspectorHost, 0, 0, 0, 0)
        end
    end

    if page and page.Show then
        page:Show()
    end
end

function RulesetWindow:RefreshAll()
    self:GetSelectedRuleset()

    if self.RefreshRulesetsPane then
        self:RefreshRulesetsPane()
    end
    if self.RefreshRulesetInspectorPage then
        self:RefreshRulesetInspectorPage()
    end

    self.ActiveInspectorPageKey = self.ActiveInspectorPageKey or "ruleset"
    self:ShowInspectorPage(self.ActiveInspectorPageKey)
end

function RulesetWindow:BuildWindow()
    if self.Window then
        return self.Window
    end

    local window = UI.Window:New({
        name = "RPERulesetWindow",
        width = 612,
        height = 340,
        point = "CENTER",
        relativeTo = UIParent,
        relativePoint = "CENTER",
        frameStrata = "HIGH",
        frameLevel = 20,
        movable = true,
        clampedToScreen = true,
        toplevel = true,
        hidden = false,
        titleFontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        titleFontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Heading1) or 18,
        titleOffsetY = (UI.Constants and UI.Constants.Window and UI.Constants.Window.TitleOffsetY) or 16,
        contentInsetLeft = 8,
        contentInsetRight = 8,
        contentInsetTop = 28,
        contentInsetBottom = 8,
        borderSize = (UI.Constants and UI.Constants.Window and UI.Constants.Window.BorderSize) or 2,
    })

    window:SetTitle("Rulesets")
    window:Create()

    self.Window = window

    local content = window:GetContentFrame()
    self.RootLayout = UI.CreateLayout(UI.HorizontalLayoutGroup, content, "RPERulesetRootLayout", {
        spacing = 10,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.RootLayout, content, 0, 0, 0, 0)

    self.RootLayout:AddChild(self:BuildRulesetsPane(self.RootLayout:GetFrame()))

    self.InspectorPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPERulesetInspectorPanel", {
        width = 390,
        height = 272,
        expandWidth = true,
        weight = 430,
        contentInset = 0,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.InspectorPanel)

    self.InspectorHost = CreateFrame("Frame", "RPERulesetInspectorHost", self.InspectorPanel:GetContentFrame())
    UI.Utils.AnchorFill(self.InspectorHost, self.InspectorPanel:GetContentFrame(), 0, 0, 0, 0)

    self.ActiveInspectorPageKey = "ruleset"
    self.ActiveRulesetCategoryKey = self.ActiveRulesetCategoryKey or "character"
    self:RefreshAll()
    return window
end

function RulesetWindow:ShowWindow()
    local window = self:BuildWindow()
    if window and window.Show then
        window:Show()
    end

    self:RefreshAll()
    return window
end

function RulesetWindow:HideWindow()
    if self.Window and self.Window.Hide then
        self.Window:Hide()
    end

    return self.Window
end

function Client:BuildRulesetWindow()
    return RulesetWindow:BuildWindow()
end

function Client:ShowRulesetWindow()
    if self:RequireSetupCompletion("ruleset-window") ~= true then
        return nil
    end

    return RulesetWindow:ShowWindow()
end

function Client:HideRulesetWindow()
    return RulesetWindow:HideWindow()
end
