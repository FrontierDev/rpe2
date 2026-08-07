local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

local function matchesAuraDropdownFilter(aura, filterValue)
    filterValue = tostring(filterValue or "all")
    if filterValue == "all" then
        return true
    end

    if filterValue == "single" then
        return (tonumber(aura and aura.maxStacks) or 1) <= 1
    end

    if filterValue == "stacking" then
        return (tonumber(aura and aura.maxStacks) or 1) > 1
    end

    if filterValue == "temporary" then
        return (tonumber(aura and aura.duration) or 0) > 0
    end

    if filterValue == "permanent" then
        return (tonumber(aura and aura.duration) or 0) <= 0
    end

    if filterValue == "effects" then
        return #(aura and aura.effects or {}) > 0
    end

    return true
end

function DataEditor:BuildAuraPage(page)
    if self.AuraPageRoot then
        return self.AuraPageRoot
    end

    self.AuraPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorAuraPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.AuraPageRoot, page, 0, 0, 0, 0)

    self.AuraPageFilterBar, self.AuraPageFilterInput, self.AuraPageFilterDropdown, self.AuraPageFilterClearButton = self:BuildDataPageFilterBar(
        self.AuraPageRoot:GetFrame(),
        "RPEDataEditorAuraPageFilterBar",
        "auras",
        {
            placeholder = "Search auras",
            inputWidth = 72,
            dropdownWidth = 76,
            dropdownItems = {
                { label = "All", value = "all" },
                { label = "Single Stack", value = "single" },
                { label = "Stacking", value = "stacking" },
                { label = "Temporary", value = "temporary" },
                { label = "Permanent", value = "permanent" },
                { label = "Has Effects", value = "effects" },
            },
        }
    )
    self.AuraPageRoot:AddChild(self.AuraPageFilterBar)

    local listPanel = UI.CreatePanel(self.AuraPageRoot:GetFrame(), "RPEDataEditorAuraListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.AuraPageRoot:AddChild(listPanel)

    self.AuraPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorAuraScroll",
        width = 146,
        height = 248,
        visibleRows = 10,
        autoFitRows = true,
        rowHeight = 16,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 86,
        statusWidth = 46,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.AuraPageScroll:SetParent(listPanel:GetContentFrame())
    self.AuraPageScroll:SetRowRenderer(function(row, rowData)
        local aura = rowData and rowData.entry or nil
        local itemIndex = rowData and rowData.entryIndex or nil
        if row.SetCategory then
            row:SetCategory(self:GetEntryDisplayName("auras", aura))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(("%dt/%ds"):format(tonumber(aura and aura.duration) or 1, tonumber(aura and aura.maxStacks) or 1))
        end
        if row.SetDetail then
            row:SetDetail(aura and aura.description or "")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("auras", itemIndex)
                end
            end)

            local selectedEntry = self.SelectedEntryIndices and self.SelectedEntryIndices.auras or nil
            local isSelected = tonumber(selectedEntry) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.AuraPageScroll:Create()
    UI.Utils.AnchorFill(self.AuraPageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.AuraPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorAuraEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.AuraPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.AuraPageToolbar, self.AuraPageButtons = self:BuildDataPageToolbar(self.AuraPageRoot:GetFrame(), "RPEDataEditorAuraPageToolbar", "auras")
    self.AuraPageRoot:AddChild(self.AuraPageToolbar)

    self:RefreshAuraDataPage()
    return self.AuraPageRoot
end

function DataEditor:RefreshAuraDataPage()
    local dataset = self:GetSelectedDataset()
    local auras = dataset and dataset.auras or {}
    local filteredAuras, filterQuery = self:GetFilteredDatasetEntries("auras", auras)
    local dropdownFilter = self:GetCollectionDropdownFilterValue("auras")
    local visibleAuras = {}

    self:RefreshDataPageToolbar(self.AuraPageButtons)

    for index = 1, #filteredAuras do
        local rowData = filteredAuras[index]
        if matchesAuraDropdownFilter(rowData and rowData.entry, dropdownFilter) then
            visibleAuras[#visibleAuras + 1] = rowData
        end
    end

    if self.AuraPageScroll and self.AuraPageScroll.SetItems then
        self.AuraPageScroll:SetItems(visibleAuras)
    end

    if self.AuraPageEmptyText and self.AuraPageEmptyText.SetText then
        if not dataset then
            self.AuraPageEmptyText:SetText("Create or select a dataset to view auras.")
        elseif #auras == 0 then
            self.AuraPageEmptyText:SetText("This dataset has no auras yet.")
        elseif #visibleAuras == 0 and (filterQuery ~= "" or dropdownFilter ~= "all") then
            self.AuraPageEmptyText:SetText("No auras match the current filters.")
        else
            self.AuraPageEmptyText:SetText("")
        end
    end
end
