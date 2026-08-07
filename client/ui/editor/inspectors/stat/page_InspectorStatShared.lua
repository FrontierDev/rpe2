local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

DataEditor.StatInspectorSidePadding = DataEditor.StatInspectorSidePadding or 8

function DataEditor:GetSelectedStatAndDataset()
    return self:GetSelectedDataset(), self:GetSelectedStat()
end

function DataEditor:NormalizeStatDisplayMode(value)
    local mode = tostring(value or "signed_value")
    if mode == "value" or mode == "signed_percent" then
        return mode
    end

    return "signed_value"
end

function DataEditor:NormalizeStatPriority(value)
    return math.floor(tonumber(value) or 0)
end

function DataEditor:NormalizeStatColor(color)
    local colorPicker = UI.ColorPicker or {}
    if colorPicker.NormalizeColor then
        return colorPicker.NormalizeColor(color, {
            r = 1,
            g = 1,
            b = 1,
            a = 1,
        })
    end

    return {
        r = math.max(0, math.min(1, tonumber(color and color.r) or 1)),
        g = math.max(0, math.min(1, tonumber(color and color.g) or 1)),
        b = math.max(0, math.min(1, tonumber(color and color.b) or 1)),
        a = math.max(0, math.min(1, tonumber(color and color.a) or 1)),
    }
end

function DataEditor:CommitSelectedStatDisplayColor(color)
    self:CommitSelectedStat(function(stat)
        stat.color = self:NormalizeStatColor(color)
    end)
end

function DataEditor:EnsureStatInspectorColorPicker()
    if self.StatInspectorColorPicker then
        return self.StatInspectorColorPicker
    end

    local picker = UI.ColorPicker:New({
        name = "RPEDataEditorStatInspectorColorPicker",
        width = 280,
        height = 228,
        hidden = true,
        title = "Stat Display Color",
        paletteSettingKey = "statColorPalette",
    })
    picker:SetParent(UIParent)
    picker:Create()
    self.StatInspectorColorPicker = picker
    return self.StatInspectorColorPicker
end

function DataEditor:OpenStatInspectorColorPicker()
    local _, stat = self:GetSelectedStatAndDataset()
    if not stat then
        return
    end

    local picker = self:EnsureStatInspectorColorPicker()
    picker:Open({
        color = self:NormalizeStatColor(stat.color),
        onApply = function(color)
            self:CommitSelectedStatDisplayColor(color)
        end,
    })
end

function DataEditor:CommitSelectedStatDisplayMode(value)
    self:CommitSelectedStat(function(stat)
        stat.displayMode = self:NormalizeStatDisplayMode(value)
    end)
end

function DataEditor:CommitSelectedStatPriority(value)
    self:CommitSelectedStat(function(stat)
        stat.priority = self:NormalizeStatPriority(value)
    end)
end

function DataEditor:CommitSelectedStatCategory(value)
    self:CommitSelectedStat(function(stat)
        stat.category = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    end)
end

function DataEditor:CommitSelectedStatVisibility(value)
    self:CommitSelectedStat(function(stat)
        stat.visibility = value == true
    end)
end

function DataEditor:RefreshStatDisplayFields(stat, hasStat)
    if self.StatInspectorDisplayModeDropdown then
        self.StatInspectorDisplayModeDropdown:SetSelectedValue(self:NormalizeStatDisplayMode(stat and stat.displayMode or "signed_value"), true)
        self:SetInspectorDropdownEnabled(self.StatInspectorDisplayModeDropdown, hasStat)
    end

    if self.StatInspectorPriorityInput then
        self.StatInspectorPriorityInput:SetText(tostring(self:NormalizeStatPriority(stat and stat.priority or 0)))
        self:SetInspectorTextElementEnabled(self.StatInspectorPriorityInput, hasStat)
    end

    if self.StatInspectorSelectedColor then
        self.StatInspectorSelectedColor:SetColor(self:NormalizeStatColor(stat and stat.color or nil))
        self.StatInspectorSelectedColor:SetEnabled(hasStat)
    end

    if self.StatInspectorCategoryDropdown then
        self.StatInspectorCategoryDropdown:SetSelectedValue(tostring(stat and stat.category or ""), true)
        self:SetInspectorDropdownEnabled(self.StatInspectorCategoryDropdown, hasStat)
    end

    if self.StatInspectorVisibilityCheckbox then
        self.StatInspectorVisibilityCheckbox:SetChecked(stat and stat.visibility == true or false, true)
        local frame = self.StatInspectorVisibilityCheckbox.GetFrame and self.StatInspectorVisibilityCheckbox:GetFrame() or nil
        if frame and frame.EnableMouse then
            frame:EnableMouse(hasStat == true)
        end
        if frame and frame.SetAlpha then
            frame:SetAlpha(hasStat == true and 1 or 0.5)
        end
    end
end

function DataEditor:GetStatInspectorDependenciesApi()
    local database = Addon.Internal and Addon.Internal.Database or nil
    return database and database.Dependecies or {}
end

function DataEditor:GetStatInspectorDerivedSources(stat)
    local normalized = {}

    if type(stat) ~= "table" then
        return normalized
    end

    if type(stat.derivedSources) == "table" then
        for index = 1, #stat.derivedSources do
            local source = stat.derivedSources[index]
            if type(source) == "table" and type(source.sourceStatRef) == "string" and source.sourceStatRef ~= "" then
                normalized[#normalized + 1] = {
                    sourceStatRef = source.sourceStatRef,
                    coefficient = tonumber(source.coefficient) or 1,
                }
            end
        end
    elseif type(stat.sourceStatRef) == "string" and stat.sourceStatRef ~= "" then
        normalized[1] = {
            sourceStatRef = stat.sourceStatRef,
            coefficient = 1,
        }
    end

    return normalized
end

function DataEditor:SetInspectorDropdownEnabled(dropdown, enabled)
    local frame = dropdown and dropdown.GetFrame and dropdown:GetFrame() or nil
    if not frame then
        return
    end

    if frame.EnableMouse then
        frame:EnableMouse(enabled == true)
    end

    if frame.SetAlpha then
        frame:SetAlpha(enabled == true and 1 or 0.5)
    end
end

function DataEditor:SetInspectorTextElementEnabled(element, enabled)
    if not element then
        return
    end

    if element.SetEnabled then
        element:SetEnabled(enabled == true)
    end
    if element.SetReadOnly then
        element:SetReadOnly(enabled ~= true)
    end
end

function DataEditor:BuildStatInspectorLabel(parent, name, text, width)
    return UI.CreateText(parent, name, text, {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = width or 236,
        height = 12,
        justifyH = "LEFT",
    })
end

function DataEditor:BuildStatInspectorDatasetItems()
    local items = {
        { label = "None", value = "" },
    }

    local datasets = self:GetDatasets()
    for index = 1, #datasets do
        local dataset = datasets[index]
        items[#items + 1] = {
            label = self:GetDatasetDisplayName(dataset),
            value = dataset.id,
        }
    end

    return items
end

function DataEditor:BuildStatInspectorStatItems(sourceDatasetId, currentDatasetId, currentStatId)
    local items = {
        { label = "None", value = "" },
    }

    if not sourceDatasetId or sourceDatasetId == "" or not self.Database or not self.Database.GetDatasetByID then
        return items
    end

    local dataset = self.Database.GetDatasetByID(sourceDatasetId)
    local stats = dataset and dataset.stats or {}

    for index = 1, #stats do
        local stat = stats[index]
        if stat and stat.id and not (sourceDatasetId == currentDatasetId and stat.id == currentStatId) then
            items[#items + 1] = {
                label = self:GetEntryDisplayName("stats", stat),
                value = stat.id,
            }
        end
    end

    return items
end

function DataEditor:BuildStatInspectorDerivedSourceRowItems(stat)
    local dependencies = self:GetStatInspectorDependenciesApi()
    local rows = {}
    local sources = self:GetStatInspectorDerivedSources(stat)

    for index = 1, #sources do
        local source = sources[index]
        local datasetId, statId = nil, nil
        if dependencies.ParseSourceStatRef and source and source.sourceStatRef then
            datasetId, statId = dependencies.ParseSourceStatRef(source.sourceStatRef)
        end

        local dataset = datasetId and self.Database and self.Database.GetDatasetByID and self.Database.GetDatasetByID(datasetId) or nil
        local sourceStat = nil
        if dataset and dataset.stats then
            for statIndex = 1, #dataset.stats do
                if dataset.stats[statIndex] and dataset.stats[statIndex].id == statId then
                    sourceStat = dataset.stats[statIndex]
                    break
                end
            end
        end

        rows[#rows + 1] = {
            rowIndex = index,
            datasetId = datasetId or "",
            statId = statId or "",
            datasetName = dataset and self:GetDatasetDisplayName(dataset) or (datasetId ~= "" and datasetId or "-"),
            statName = sourceStat and self:GetEntryDisplayName("stats", sourceStat) or (statId ~= "" and statId or "-"),
            coefficientText = tostring(source.coefficient or 1),
        }
    end

    return rows
end

function DataEditor:CommitSelectedStat(mutate)
    local dataset, stat = self:GetSelectedStatAndDataset()
    if not dataset or not stat or type(mutate) ~= "function" then
        return
    end

    mutate(stat, dataset)
    stat.derivedSources = self:GetStatInspectorDerivedSources(stat)
    stat.sourceStatRef = nil

    if self.Database and self.Database.NotifyDatasetEntryChanged then
        self.Database.NotifyDatasetEntryChanged(dataset.id, "stats", {
            deferConfigurationChanged = true,
        })
    end

    self:RefreshAfterDatasetEntryChanged("stats")
end

function DataEditor:SetStatInspectorTab(tabKey)
    self.ActiveStatInspectorTabKey = tabKey or "general"

    if self.StatInspectorGeneralPage then
        if self.ActiveStatInspectorTabKey == "general" then
            self.StatInspectorGeneralPage:Show()
        else
            self.StatInspectorGeneralPage:Hide()
        end
    end

    if self.StatInspectorMechanicsPage then
        if self.ActiveStatInspectorTabKey == "mechanics" then
            self.StatInspectorMechanicsPage:Show()
        else
            self.StatInspectorMechanicsPage:Hide()
        end
    end

    if self.StatInspectorDisplayPage then
        if self.ActiveStatInspectorTabKey == "display" then
            self.StatInspectorDisplayPage:Show()
        else
            self.StatInspectorDisplayPage:Hide()
        end
    end

    local activeColor = UI.ResolveColor(nil, "tab.active")
    local inactiveColor = UI.ResolveColor(nil, "tab.inactive")

    local function styleButton(button, isActive)
        if not button then
            return
        end

        if button.SetLabelColor then
            local color = isActive and activeColor or inactiveColor
            button:SetLabelColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
        end

        local frame = button.GetFrame and button:GetFrame() or nil
        if frame and frame.SetAlpha then
            frame:SetAlpha(isActive and 1 or 0.8)
        end
    end

    styleButton(self.StatInspectorGeneralTabButton, self.ActiveStatInspectorTabKey == "general")
    styleButton(self.StatInspectorDisplayTabButton, self.ActiveStatInspectorTabKey == "display")
    styleButton(self.StatInspectorMechanicsTabButton, self.ActiveStatInspectorTabKey == "mechanics")
end

function DataEditor:RefreshStatInspectorPendingSourceStatDropdown()
    local dataset, stat = self:GetSelectedStatAndDataset()
    local currentDatasetId = dataset and dataset.id or nil
    local currentStatId = stat and stat.id or nil
    local selectedDatasetId = self.StatInspectorPendingSourceDatasetDropdown and self.StatInspectorPendingSourceDatasetDropdown.GetSelectedValue and self.StatInspectorPendingSourceDatasetDropdown:GetSelectedValue() or ""

    if self.StatInspectorPendingSourceStatDropdown and self.StatInspectorPendingSourceStatDropdown.SetItems then
        self.StatInspectorPendingSourceStatDropdown:SetItems(self:BuildStatInspectorStatItems(selectedDatasetId, currentDatasetId, currentStatId))
    end
end

function DataEditor:EnsureStatInspectorDerivedSourceContextMenu()
    if self.StatInspectorDerivedSourceContextMenu then
        return self.StatInspectorDerivedSourceContextMenu
    end

    self.StatInspectorDerivedSourceContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorStatInspectorDerivedSourceContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 2,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            if not item or item.value ~= "remove-source" or not self.ContextMenuDerivedSourceRowIndex then
                return
            end

            local removeIndex = self.ContextMenuDerivedSourceRowIndex
            self:CommitSelectedStat(function(stat)
                local sources = self:GetStatInspectorDerivedSources(stat)
                table.remove(sources, removeIndex)
                stat.derivedSources = sources
            end)

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.StatInspectorDerivedSourceContextMenu:SetParent(self.StatInspectorPage or UIParent)
    self.StatInspectorDerivedSourceContextMenu:Create()
    return self.StatInspectorDerivedSourceContextMenu
end

function DataEditor:ShowStatInspectorDerivedSourceContextMenu(anchorFrame, rowData)
    if not rowData or not rowData.rowIndex then
        return
    end

    local menu = self:EnsureStatInspectorDerivedSourceContextMenu()
    self.ContextMenuDerivedSourceRowIndex = rowData.rowIndex
    menu:SetItems({
        { label = "Remove", value = "remove-source" },
    })
    menu:ShowAt(anchorFrame)
end

function DataEditor:RefreshStatInspectorDerivedSourceTable()
    local dataset, stat = self:GetSelectedStatAndDataset()
    local rows = self:BuildStatInspectorDerivedSourceRowItems(stat)

    if self.StatInspectorDerivedSourcesScroll and self.StatInspectorDerivedSourcesScroll.SetItems then
        self.StatInspectorDerivedSourcesScroll:SetItems(rows)
    end

    self.StatInspectorDerivedSourceRows = {}
    for index = 1, #rows do
        local rowDatasetId = rows[index].datasetId
        local rowStatId = rows[index].statId
        self.StatInspectorDerivedSourceRows[index] = {
            datasetId = rowDatasetId,
            statId = rowStatId,
            coefficient = rows[index].coefficientText,
            datasetDropdown = {
                items = self:BuildStatInspectorDatasetItems(),
                GetSelectedValue = function()
                    return rowDatasetId
                end,
            },
            statDropdown = {
                items = self:BuildStatInspectorStatItems(rowDatasetId, dataset and dataset.id or nil, stat and stat.id or nil),
                GetSelectedValue = function()
                    return rowStatId
                end,
            },
        }
    end
end
