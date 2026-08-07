local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

local function buildDatasetStatus(dataset)
    if not dataset then
        return ""
    end

    local total = #(dataset.units or {})
        + #(dataset.items or {})
        + #(dataset.spells or {})
        + #(dataset.skills or {})
        + #(dataset.stats or {})
        + #(dataset.resources or {})
        + #(dataset.races or {})
        + #(dataset.classes or {})
        + #(dataset.itemSlots or {})
        + #(dataset.damageSchools or {})
        + #(dataset.loot or {})
        + #(dataset.recipes or {})
        + #(dataset.auras or {})
        + #(dataset.interactions or {})
        + #(dataset.achievements or {})
        + #(dataset.currencies or {})
    if total <= 0 then
        return "Empty"
    end

    return tostring(total)
end

local function buildDatasetGroupLabel(self, dataset)
    local groupName = self.Database and self.Database.GetDatasetGroupName and self.Database.GetDatasetGroupName(dataset) or (dataset and dataset.groupName) or ""
    groupName = tostring(groupName or "")
    if groupName == "" then
        return "Ungrouped"
    end

    return groupName
end

local function buildDatasetTooltip(self, dataset)
    if not dataset then
        return nil
    end

    local lockState = dataset.lockState ~= nil and tostring(dataset.lockState) or "open"
    local tagState = dataset.tagState ~= nil and tostring(dataset.tagState) or "standard"
    local activated = self:IsDatasetActivated(dataset.id)
    local dependencyNames = {}
    local dependencies = dataset.dependencies or {}

    for index = 1, #dependencies do
        local dependencyId = dependencies[index]
        local dependencyDataset = self.Database and self.Database.GetDatasetByID and self.Database.GetDatasetByID(dependencyId) or nil
        dependencyNames[#dependencyNames + 1] = dependencyDataset and self:GetDatasetDisplayName(dependencyDataset) or tostring(dependencyId)
    end

    return {
        type = "custom",
        title = self:GetDatasetDisplayName(dataset),
        lines = {
            ("ID: %s"):format(dataset.id or "-"),
            ("Group: %s"):format(buildDatasetGroupLabel(self, dataset)),
            ("State: %s"):format(activated and "Activated" or "Inactive"),
            ("Lock: %s"):format(lockState),
            ("Tag: %s"):format(tagState),
            ("Depends On: %s"):format(#dependencyNames > 0 and table.concat(dependencyNames, ", ") or "-"),
        },
    }
end

local function commitDatasetName(self)
    local dataset = self:GetSelectedDataset()
    if not dataset or not self.DatasetPaneNameInput or not self.Database or not self.Database.RenameDataset then
        return
    end

    self.Database.RenameDataset(dataset.id, self.DatasetPaneNameInput:GetText())
    self:RefreshAll()
end

local function commitDatasetGroupName(self)
    local dataset = self:GetSelectedDataset()
    if not dataset or not self.DatasetPaneGroupInput or not self.Database or not self.Database.UpdateDatasetMetadata then
        return
    end

    self.Database.UpdateDatasetMetadata(dataset.id, {
        groupName = self.DatasetPaneGroupInput:GetText(),
    })
    self:RefreshAll()
end

local function updateDatasetMetadata(self, values)
    local dataset = self:GetSelectedDataset()
    if not dataset or not self.Database or not self.Database.UpdateDatasetMetadata then
        return
    end

    self.Database.UpdateDatasetMetadata(dataset.id, values)
    self:RefreshAll()
end

function DataEditor:GetDatasetGroupFoldoutState(groupLabel)
    self.DatasetGroupFoldoutStates = self.DatasetGroupFoldoutStates or {}
    if self.DatasetGroupFoldoutStates[groupLabel] == nil then
        self.DatasetGroupFoldoutStates[groupLabel] = true
    end

    return self.DatasetGroupFoldoutStates[groupLabel]
end

function DataEditor:ToggleDatasetGroupFoldout(groupLabel)
    if not groupLabel or groupLabel == "" then
        return
    end

    self.DatasetGroupFoldoutStates = self.DatasetGroupFoldoutStates or {}
    self.DatasetGroupFoldoutStates[groupLabel] = not self:GetDatasetGroupFoldoutState(groupLabel)
    self:RefreshDatasetsPane()
end

function DataEditor:BuildDatasetListItems()
    local items = {}
    local datasets = self:GetDatasets()
    local currentGroupLabel = nil

    for index = 1, #datasets do
        local dataset = datasets[index]
        local groupLabel = buildDatasetGroupLabel(self, dataset)

        if groupLabel ~= currentGroupLabel then
            currentGroupLabel = groupLabel
            items[#items + 1] = {
                kind = "group",
                groupLabel = groupLabel,
            }
        end

        if self:GetDatasetGroupFoldoutState(groupLabel) then
            items[#items + 1] = {
                kind = "dataset",
                dataset = dataset,
                groupLabel = groupLabel,
            }
        end
    end

    return items
end

function DataEditor:BuildDatasetsPane(parent)
    if self.DatasetsPane then
        return self.DatasetsPane
    end

    self.DatasetsPane = UI.CreatePanel(parent, "RPEDataEditorDatasetsPane", {
        width = 160,
        height = 332,
        expandWidth = true,
        weight = 160,
        contentInset = 0,
        showBorder = false,
    })

    local content = self.DatasetsPane:GetContentFrame()
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, content, "RPEDataEditorDatasetsRootLayout", {
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, content, 0, 0, 0, 12)

    local toolbar = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorDatasetsToolbar", {
        spacing = 8,
        autoSize = true,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })

    self.AddDatasetButton = UI.CreateButton(toolbar:GetFrame(), "RPEDataEditorAddDatasetButton", "New Dataset", 104, function()
        self:CreateDatasetAndSelect()
    end)
    toolbar:AddChild(self.AddDatasetButton)

    self.ImportDatasetButton = UI.CreateButton(toolbar:GetFrame(), "RPEDataEditorImportDatasetButton", "Import", 48, function()
        self:ShowDatasetImportWindow()
    end)
    toolbar:AddChild(self.ImportDatasetButton)
    root:AddChild(toolbar)

    local listPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorDatasetListPanel", {
        width = 160,
        height = 126,
        contentInset = 2,
        showBorder = false,
    })
    root:AddChild(listPanel)

    self.DatasetList = UI.ScrollLayout:New({
        name = "RPEDataEditorDatasetList",
        width = 156,
        height = 122,
        visibleRows = 7,
        rowHeight = 16,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 118,
        statusWidth = 30,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.DatasetList:SetParent(listPanel:GetContentFrame())
    self.DatasetList:SetRowRenderer(function(row, item)
        local frame = row.GetFrame and row:GetFrame() or nil
        local rowKind = item and item.kind or "dataset"

        if rowKind == "group" then
            local expanded = self:GetDatasetGroupFoldoutState(item.groupLabel)
            if row.SetCategory then
                row:SetCategory(("%s %s"):format(expanded and "v" or ">", item.groupLabel or "Ungrouped"))
            end
            if row.SetTestName then
                row:SetTestName("")
            end
            if row.SetStatus then
                row:SetStatus("Group")
            end
            if row.SetDetail then
                row:SetDetail("Dataset group")
            end
            if row.SetTooltip then
                row:SetTooltip({
                    type = "custom",
                    title = item.groupLabel or "Ungrouped",
                    lines = {
                        expanded and "Click to collapse this dataset group." or "Click to expand this dataset group.",
                    },
                })
            end
            if row.categoryRegion and row.categoryRegion.SetTextColor then
                local color = UI.ResolveColor(nil, "text.primary")
                row.categoryRegion:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
            end
            if row.SetStatusColor then
                local color = UI.ResolveColor(nil, "text.secondary")
                row:SetStatusColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
            end
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local color = UI.ResolveColor(nil, "list.rowHover")
                row.entryBackground:SetColorTexture(color.r or 0.12, color.g or 0.13, color.b or 0.16, 0.65)
            end
            if frame then
                frame:EnableMouse(true)
                if frame.SetAlpha then
                    frame:SetAlpha(1)
                end
                frame:SetScript("OnMouseUp", function(_, button)
                    if button == "LeftButton" then
                        self:ToggleDatasetGroupFoldout(item.groupLabel)
                    end
                end)
            end
            return
        end

        local dataset = item and item.dataset or nil
        local isActivated = dataset and dataset.id and self:IsDatasetActivated(dataset.id) or false

        if row.SetCategory then
            row:SetCategory(("  %s"):format(self:GetDatasetDisplayName(dataset)))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(buildDatasetStatus(dataset))
        end
        if row.SetDetail then
            row:SetDetail(dataset and dataset.id or "")
        end
        if row.SetTooltip then
            row:SetTooltip(buildDatasetTooltip(self, dataset))
        end
        if row.categoryRegion and row.categoryRegion.SetTextColor then
            local token = isActivated and "success" or "text.secondary"
            local color = UI.ResolveColor(nil, token)
            row.categoryRegion:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
        end
        if row.nameRegion and row.nameRegion.SetTextColor then
            local color = UI.ResolveColor(nil, "text.primary")
            row.nameRegion:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
        end

        if frame then
            frame:EnableMouse(true)
            if frame.SetAlpha then
                frame:SetAlpha(1)
            end
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" and dataset and dataset.id then
                    self:SetSelectedDatasetId(dataset.id)
                    if self.DatasetContextMenu and self.DatasetContextMenu.HideMenus then
                        self.DatasetContextMenu:HideMenus()
                    end
                elseif button == "RightButton" and dataset and dataset.id then
                    self:SetSelectedDatasetId(dataset.id)
                    self:ShowDatasetContextMenu(frame, dataset)
                end
            end)

            local isSelected = dataset and dataset.id == self.SelectedDatasetId
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.DatasetList:Create()
    UI.Utils.AnchorFill(self.DatasetList, listPanel:GetContentFrame(), 0, 0, 0, 0)

    local renamePanel = UI.CreatePanel(content, "RPEDataEditorDatasetRenamePanel", {
        width = 152,
        height = 154,
        contentInset = 4,
        showBorder = true,
    })
    renamePanel:GetFrame():ClearAllPoints()
    renamePanel:GetFrame():SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 12)
    renamePanel:GetFrame():SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -8, 12)

    local detailsLayout = UI.CreateLayout(UI.VerticalLayoutGroup, renamePanel:GetContentFrame(), "RPEDataEditorDatasetDetailsLayout", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(detailsLayout, renamePanel:GetContentFrame(), 0, 0, 0, 0)

    self.DatasetPaneNameInput = UI.CreateTextInput(detailsLayout:GetFrame(), "RPEDataEditorDatasetPaneNameInput", {
        width = 136,
        height = 24,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.DatasetPaneNameInput:SetScript("OnEnterPressed", function()
        commitDatasetName(self)
    end)
    self.DatasetPaneNameInput:SetScript("OnEditFocusLost", function()
        commitDatasetName(self)
    end)
    detailsLayout:AddChild(self.DatasetPaneNameInput)

    self.DatasetPaneGroupLabel = UI.CreateText(detailsLayout:GetFrame(), "RPEDataEditorDatasetPaneGroupLabel", "Group", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 136,
        height = 12,
        justifyH = "LEFT",
    })
    detailsLayout:AddChild(self.DatasetPaneGroupLabel)

    self.DatasetPaneGroupInput = UI.CreateTextInput(detailsLayout:GetFrame(), "RPEDataEditorDatasetPaneGroupInput", {
        width = 136,
        height = 24,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.DatasetPaneGroupInput:SetScript("OnEnterPressed", function()
        commitDatasetGroupName(self)
    end)
    self.DatasetPaneGroupInput:SetScript("OnEditFocusLost", function()
        commitDatasetGroupName(self)
    end)
    detailsLayout:AddChild(self.DatasetPaneGroupInput)

    self.DatasetPaneIdText = UI.CreateText(detailsLayout:GetFrame(), "RPEDataEditorDatasetPaneIdText", "ID: -", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 136,
        height = 12,
        justifyH = "LEFT",
    })
    detailsLayout:AddChild(self.DatasetPaneIdText)

    self.DatasetPaneAuthorText = UI.CreateText(detailsLayout:GetFrame(), "RPEDataEditorDatasetPaneAuthorText", "Author: -", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 136,
        height = 12,
        justifyH = "LEFT",
    })
    detailsLayout:AddChild(self.DatasetPaneAuthorText)

    self.DatasetPaneLockDropdown = UI.CreateDropdown(detailsLayout:GetFrame(), "RPEDataEditorDatasetPaneLockDropdown", {
        width = 136,
        height = 18,
        items = {
            { label = "Open", value = "open" },
            { label = "Readonly", value = "readonly" },
            { label = "Secret", value = "secret" },
        },
        onValueChanged = function(value)
            updateDatasetMetadata(self, { lockState = value })
        end,
    })
    detailsLayout:AddChild(self.DatasetPaneLockDropdown)

    self.DatasetPaneTagDropdown = UI.CreateDropdown(detailsLayout:GetFrame(), "RPEDataEditorDatasetPaneTagDropdown", {
        width = 136,
        height = 18,
        items = {
            { label = "Standard", value = "standard" },
            { label = "Short-term", value = "short-term" },
            { label = "Long-term", value = "long-term" },
        },
        onValueChanged = function(value)
            updateDatasetMetadata(self, { tagState = value })
        end,
    })
    detailsLayout:AddChild(self.DatasetPaneTagDropdown)

    self:RefreshDatasetsPane()
    return self.DatasetsPane
end

function DataEditor:EnsureDatasetContextMenu()
    if self.DatasetContextMenu then
        return self.DatasetContextMenu
    end

    self.DatasetContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorDatasetContextMenu",
        width = 140,
        panelWidth = 140,
        visibleRows = 4,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            local action = item and item.value or nil
            local datasetId = self.ContextMenuDatasetId
            if not datasetId then
                return
            end

            if action == "toggle-activation" then
                self:SetDatasetActivated(datasetId, not self:IsDatasetActivated(datasetId))
            elseif action == "export" then
                self:ExportDatasetToClipboard(datasetId)
            elseif action == "delete" then
                self:ConfirmDeleteDataset(datasetId)
            end

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.DatasetContextMenu:SetParent(self.Window and self.Window:GetFrame() or UIParent)
    self.DatasetContextMenu:Create()
    return self.DatasetContextMenu
end

function DataEditor:ShowDatasetContextMenu(anchorFrame, dataset)
    if not dataset or not dataset.id then
        return
    end

    local menu = self:EnsureDatasetContextMenu()
    local isActivated = self:IsDatasetActivated(dataset.id)

    self.ContextMenuDatasetId = dataset.id
    menu:SetItems({
        {
            label = isActivated and "Deactivate" or "Activate",
            value = "toggle-activation",
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

function DataEditor:RefreshDatasetsPane()
    local dataset = self:GetSelectedDataset()

    if self.DatasetList and self.DatasetList.SetItems then
        self.DatasetList:SetItems(self:BuildDatasetListItems())
    end

    if self.DatasetPaneNameInput and self.DatasetPaneNameInput.SetText then
        self.DatasetPaneNameInput:SetText(dataset and (dataset.name or "") or "")
        self.DatasetPaneNameInput:SetEnabled(dataset ~= nil)
        self.DatasetPaneNameInput:SetReadOnly(dataset == nil)
    end

    if self.DatasetPaneGroupInput and self.DatasetPaneGroupInput.SetText then
        self.DatasetPaneGroupInput:SetText(dataset and (dataset.groupName or "") or "")
        self.DatasetPaneGroupInput:SetEnabled(dataset ~= nil)
        self.DatasetPaneGroupInput:SetReadOnly(dataset == nil)
    end

    if self.DatasetPaneIdText and self.DatasetPaneIdText.SetText then
        self.DatasetPaneIdText:SetText(("ID: %s"):format(dataset and dataset.id or "-"))
    end

    if self.DatasetPaneAuthorText and self.DatasetPaneAuthorText.SetText then
        self.DatasetPaneAuthorText:SetText(("Author: %s"):format(dataset and dataset.authorName ~= "" and dataset.authorName or "-"))
    end

    if self.DatasetPaneLockDropdown and self.DatasetPaneLockDropdown.SetSelectedValue then
        self.DatasetPaneLockDropdown:SetSelectedValue(dataset and dataset.lockState or "open", true)
    end

    if self.DatasetPaneTagDropdown and self.DatasetPaneTagDropdown.SetSelectedValue then
        self.DatasetPaneTagDropdown:SetSelectedValue(dataset and dataset.tagState or "standard", true)
    end
end
