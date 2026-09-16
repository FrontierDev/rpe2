local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}

local DATASET_TYPE_ITEMS = {
    { label = "General", value = "general" },
    { label = "Campaign", value = "campaign" },
    { label = "Crafting", value = "crafting" },
    { label = "Class", value = "class" },
    { label = "Items", value = "items" },
}

local DATASET_TYPE_LABELS = {
    general = "General",
    campaign = "Campaign",
    crafting = "Crafting",
    class = "Class",
    items = "Items",
}

local DATASET_TYPE_ICONS = {
    general = "Interface\\ICONS\\INV_Misc_Book_09",
    campaign = "Interface\\ICONS\\Achievement_Quests_Completed_08",
    crafting = "Interface\\ICONS\\Trade_BlackSmithing",
    class = "Interface\\ICONS\\Achievement_Level_10",
    items = "Interface\\ICONS\\INV_Misc_Bag_08",
}

local DATASET_LIFETIME_ITEMS = {
    { label = "Permanent", value = "permanent" },
    { label = "1 Hour", value = "1-hour" },
    { label = "6 Hours", value = "6-hour" },
    { label = "12 Hours", value = "12-hour" },
    { label = "24 Hours", value = "24-hour" },
    { label = "3 Days", value = "3-day" },
    { label = "7 Days", value = "7-day" },
}

local function formatDatasetExpiry(expiresAt)
    local timestamp = tonumber(expiresAt)
    if not timestamp then
        return "Expires: Permanent"
    end

    if type(date) == "function" then
        return ("Expires: %s (server time)"):format(date("%d %b %Y %H:%M", math.floor(timestamp)))
    end

    return ("Expires: %d (server time)"):format(math.floor(timestamp))
end

local function updateDatasetExpiryPreview(self, lifetime)
    local database = self.Database
    local dataset = database and database.GetDatasetByID and database.GetDatasetByID(self.MetadataWindowDatasetId) or nil
    if not dataset or not self.DatasetMetadataExpiryText or not self.DatasetMetadataExpiryText.SetText then
        return
    end

    if lifetime == "permanent" then
        self.DatasetMetadataExpiryText:SetText("Expires: Permanent")
        return
    end

    if lifetime == dataset.lifetime and dataset.expiresAt ~= nil then
        self.DatasetMetadataExpiryText:SetText(formatDatasetExpiry(dataset.expiresAt))
        return
    end

    local previewExpiry = database.CalculateDatasetExpiry and database.CalculateDatasetExpiry(lifetime) or nil
    if previewExpiry then
        self.DatasetMetadataExpiryText:SetText(formatDatasetExpiry(previewExpiry))
    else
        self.DatasetMetadataExpiryText:SetText("Expires: calculated when saved")
    end
end

local function getDatasetTypeLabel(datasetType)
    local normalized = tostring(datasetType or "general")
    return DATASET_TYPE_LABELS[normalized] or DATASET_TYPE_LABELS.general
end

local function getDatasetTypeIcon(datasetType)
    local normalized = tostring(datasetType or "general")
    return DATASET_TYPE_ICONS[normalized] or DATASET_TYPE_ICONS.general
end

local function buildDatasetListLabel(self, dataset)
    local icon = getDatasetTypeIcon(dataset and dataset.datasetType)
    local name = self:GetDatasetDisplayName(dataset)
    return ("  |T%s:12:12:0:0|t %s"):format(icon, name)
end

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
        + #(dataset.guildSettings or {})
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

    local datasetType = getDatasetTypeLabel(dataset.datasetType)
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
            ("Type: %s"):format(datasetType),
            ("Lifetime: %s"):format(dataset.lifetime == "permanent" and "Permanent" or tostring(dataset.lifetime or "Unknown")),
            ("State: %s"):format(activated and "Activated" or "Inactive"),
            ("Depends On: %s"):format(#dependencyNames > 0 and table.concat(dependencyNames, ", ") or "-"),
        },
    }
end

local function resolveRecipeOutputName(recipe)
    local itemRef = recipe and recipe.output and recipe.output.itemRef or nil
    if itemRef == nil or itemRef == "" or type(Registry.ResolveItemReference) ~= "function" then
        return nil
    end

    local _, item = Registry:ResolveItemReference(itemRef)
    local name = item and item.name ~= nil and tostring(item.name) or ""
    if name == "" then
        return nil
    end

    return name
end

function DataEditor:RefreshDatasetRecipeNames(dataset)
    if type(dataset) ~= "table" or not dataset.id then
        return 0
    end

    local recipes = dataset.recipes or {}
    local changed = 0
    for index = 1, #recipes do
        local recipe = recipes[index]
        local outputName = resolveRecipeOutputName(recipe)
        if outputName and tostring(recipe.name or "") ~= outputName then
            recipe.name = outputName
            changed = changed + 1
        end
    end

    if changed <= 0 then
        return 0
    end

    self:QueuePendingDatasetEntryChanged(dataset.id, "recipes", {
        changeCount = changed,
        reason = "recipe-names",
    })
    if self.RefreshRecipeDataPage then
        self:RefreshRecipeDataPage()
    end
    if self.RefreshRecipeInspectorPage then
        self:RefreshRecipeInspectorPage()
    end

    return changed
end

local function saveDatasetMetadataWindow(self)
    local datasetId = self.MetadataWindowDatasetId
    local database = self.Database
    if not datasetId or not database then
        return
    end

    local name = self.DatasetMetadataNameInput and self.DatasetMetadataNameInput.GetText and self.DatasetMetadataNameInput:GetText() or ""
    local groupName = self.DatasetMetadataGroupInput and self.DatasetMetadataGroupInput.GetText and self.DatasetMetadataGroupInput:GetText() or ""
    local datasetType = self.DatasetMetadataTypeDropdown and self.DatasetMetadataTypeDropdown.GetSelectedValue and self.DatasetMetadataTypeDropdown:GetSelectedValue() or "general"
    local lifetime = self.DatasetMetadataLifetimeDropdown and self.DatasetMetadataLifetimeDropdown.GetSelectedValue and self.DatasetMetadataLifetimeDropdown:GetSelectedValue() or "permanent"

    if database.RenameDataset then
        database.RenameDataset(datasetId, name)
    end

    if database.UpdateDatasetMetadata then
        database.UpdateDatasetMetadata(datasetId, {
            groupName = groupName,
            datasetType = datasetType,
        })
    end

    if database.SetDatasetLifetime then
        database.SetDatasetLifetime(datasetId, lifetime)
    end

    if self.DatasetMetadataWindow and self.DatasetMetadataWindow.Hide then
        self.DatasetMetadataWindow:Hide()
    end

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
    UI.Utils.AnchorFill(root, content, 0, 0, 0, 0)

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

    self.ExportAllDatasetsButton = UI.CreateButton(root:GetFrame(), "RPEDataEditorExportAllDatasetsButton", "Export All", 160, function()
        self:ExportActiveDatasetsToClipboard()
    end)
    root:AddChild(self.ExportAllDatasetsButton)

    local listPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorDatasetListPanel", {
        width = 160,
        height = 300,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    root:AddChild(listPanel)

    self.DatasetList = UI.ScrollLayout:New({
        name = "RPEDataEditorDatasetList",
        width = 156,
        height = 296,
        visibleRows = 18,
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
            row:SetCategory(buildDatasetListLabel(self, dataset))
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

    self:RefreshDatasetsPane()
    return self.DatasetsPane
end

function DataEditor:EnsureDatasetContextMenu()
    if self.DatasetContextMenu then
        return self.DatasetContextMenu
    end

    self.DatasetContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorDatasetContextMenu",
        width = 170,
        panelWidth = 170,
        visibleRows = 7,
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
            elseif action == "edit-metadata" then
                self:ShowDatasetMetadataWindow(datasetId)
            elseif action == "regenerate-spell-templates" then
                local dataset = self.Database and self.Database.GetDatasetByID and self.Database.GetDatasetByID(datasetId) or nil
                if dataset and type(self.RegenerateDatasetSpellTemplates) == "function" then
                    self:RegenerateDatasetSpellTemplates(dataset)
                end
            elseif action == "regenerate-aura-templates" then
                local dataset = self.Database and self.Database.GetDatasetByID and self.Database.GetDatasetByID(datasetId) or nil
                if dataset and type(self.RegenerateDatasetAuraTemplates) == "function" then
                    self:RegenerateDatasetAuraTemplates(dataset)
                end
            elseif action == "refresh-recipe-names" then
                local dataset = self.Database and self.Database.GetDatasetByID and self.Database.GetDatasetByID(datasetId) or nil
                self:RefreshDatasetRecipeNames(dataset)
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
            label = "Edit Metadata",
            value = "edit-metadata",
        },
        {
            label = "Regenerate Spells",
            value = "regenerate-spell-templates",
        },
        {
            label = "Regenerate Auras",
            value = "regenerate-aura-templates",
        },
        {
            label = "Refresh Recipe Names",
            value = "refresh-recipe-names",
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

function DataEditor:BuildDatasetMetadataWindow()
    if self.DatasetMetadataWindow then
        return self.DatasetMetadataWindow
    end

    local window = UI.Window:New({
        name = "RPEDataEditorDatasetMetadataWindow",
        width = 340,
        height = 318,
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
    window:SetTitle("Dataset Metadata")
    window:Create()
    self.DatasetMetadataWindow = window

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, window:GetContentFrame(), "RPEDataEditorDatasetMetadataRoot", {
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(root, window:GetContentFrame(), 0, 0, 0, 0)

    self.DatasetMetadataNameLabel = UI.CreateText(root:GetFrame(), "RPEDataEditorDatasetMetadataNameLabel", "Name", {
        width = 300,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.DatasetMetadataNameLabel)

    self.DatasetMetadataNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorDatasetMetadataNameInput", {
        width = 300,
        height = 24,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.DatasetMetadataNameInput:SetScript("OnEnterPressed", function()
        saveDatasetMetadataWindow(self)
    end)
    root:AddChild(self.DatasetMetadataNameInput)

    self.DatasetMetadataGroupLabel = UI.CreateText(root:GetFrame(), "RPEDataEditorDatasetMetadataGroupLabel", "Group", {
        width = 300,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.DatasetMetadataGroupLabel)

    self.DatasetMetadataGroupInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorDatasetMetadataGroupInput", {
        width = 300,
        height = 24,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.DatasetMetadataGroupInput:SetScript("OnEnterPressed", function()
        saveDatasetMetadataWindow(self)
    end)
    root:AddChild(self.DatasetMetadataGroupInput)

    self.DatasetMetadataTypeLabel = UI.CreateText(root:GetFrame(), "RPEDataEditorDatasetMetadataTypeLabel", "Type", {
        width = 300,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.DatasetMetadataTypeLabel)

    self.DatasetMetadataTypeDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorDatasetMetadataTypeDropdown", {
        width = 300,
        height = 20,
        items = DATASET_TYPE_ITEMS,
        selectedValue = "general",
    })
    root:AddChild(self.DatasetMetadataTypeDropdown)

    self.DatasetMetadataLifetimeLabel = UI.CreateText(root:GetFrame(), "RPEDataEditorDatasetMetadataLifetimeLabel", "Lifetime", {
        width = 300,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.DatasetMetadataLifetimeLabel)

    self.DatasetMetadataLifetimeDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorDatasetMetadataLifetimeDropdown", {
        width = 300,
        height = 20,
        items = DATASET_LIFETIME_ITEMS,
        selectedValue = "permanent",
        onValueChanged = function(value)
            updateDatasetExpiryPreview(self, value)
        end,
    })
    root:AddChild(self.DatasetMetadataLifetimeDropdown)

    self.DatasetMetadataExpiryText = UI.CreateText(root:GetFrame(), "RPEDataEditorDatasetMetadataExpiryText", "Expires: Permanent", {
        width = 300,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.DatasetMetadataExpiryText)

    self.DatasetMetadataIdText = UI.CreateText(root:GetFrame(), "RPEDataEditorDatasetMetadataIdText", "ID: -", {
        width = 300,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.DatasetMetadataIdText)

    self.DatasetMetadataAuthorText = UI.CreateText(root:GetFrame(), "RPEDataEditorDatasetMetadataAuthorText", "Author: -", {
        width = 300,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.DatasetMetadataAuthorText)

    local actions = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorDatasetMetadataActions", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 20,
    })
    root:AddChild(actions)

    self.DatasetMetadataSaveButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorDatasetMetadataSaveButton", "Save", 60, function()
        saveDatasetMetadataWindow(self)
    end, {
        height = 20,
        fontSize = 7,
    })
    actions:AddChild(self.DatasetMetadataSaveButton)

    self.DatasetMetadataCancelButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorDatasetMetadataCancelButton", "Cancel", 60, function()
        if self.DatasetMetadataWindow and self.DatasetMetadataWindow.Hide then
            self.DatasetMetadataWindow:Hide()
        end
    end, {
        height = 20,
        fontSize = 7,
    })
    actions:AddChild(self.DatasetMetadataCancelButton)

    return window
end

function DataEditor:ShowDatasetMetadataWindow(datasetId)
    local database = self.Database
    local dataset = database and database.GetDatasetByID and database.GetDatasetByID(datasetId) or nil
    if not dataset then
        return nil
    end

    local window = self:BuildDatasetMetadataWindow()
    self.MetadataWindowDatasetId = dataset.id

    if self.DatasetMetadataNameInput and self.DatasetMetadataNameInput.SetText then
        self.DatasetMetadataNameInput:SetText(dataset.name or "")
    end
    if self.DatasetMetadataGroupInput and self.DatasetMetadataGroupInput.SetText then
        self.DatasetMetadataGroupInput:SetText(dataset.groupName or "")
    end
    if self.DatasetMetadataTypeDropdown and self.DatasetMetadataTypeDropdown.SetSelectedValue then
        self.DatasetMetadataTypeDropdown:SetSelectedValue(dataset.datasetType or "general", true)
    end
    if self.DatasetMetadataLifetimeDropdown and self.DatasetMetadataLifetimeDropdown.SetSelectedValue then
        self.DatasetMetadataLifetimeDropdown:SetSelectedValue(dataset.lifetime or "permanent", true)
    end
    if self.DatasetMetadataExpiryText and self.DatasetMetadataExpiryText.SetText then
        self.DatasetMetadataExpiryText:SetText(formatDatasetExpiry(dataset.expiresAt))
    end
    if self.DatasetMetadataIdText and self.DatasetMetadataIdText.SetText then
        self.DatasetMetadataIdText:SetText(("ID: %s"):format(dataset.id or "-"))
    end
    if self.DatasetMetadataAuthorText and self.DatasetMetadataAuthorText.SetText then
        local authorName = dataset.authorName ~= nil and dataset.authorName ~= "" and dataset.authorName or "-"
        self.DatasetMetadataAuthorText:SetText(("Author: %s"):format(authorName))
    end

    if window and window.Show then
        window:Show()
    end
    if self.DatasetMetadataNameInput and self.DatasetMetadataNameInput.Focus then
        self.DatasetMetadataNameInput:Focus()
    end

    return window
end

function DataEditor:RefreshDatasetsPane()
    if self.DatasetList and self.DatasetList.SetItems then
        self.DatasetList:SetItems(self:BuildDatasetListItems())
    end
end
