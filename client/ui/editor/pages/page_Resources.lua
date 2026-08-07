local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildResourcesPage(page)
    if self.ResourcesPageRoot then
        return self.ResourcesPageRoot
    end

    self.ResourcesPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorResourcesPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.ResourcesPageRoot, page, 0, 0, 0, 0)

    local listPanel = UI.CreatePanel(self.ResourcesPageRoot:GetFrame(), "RPEDataEditorResourcesListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.ResourcesPageRoot:AddChild(listPanel)

    self.ResourcesPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorResourcesScroll",
        width = 146,
        height = 248,
        visibleRows = 10,
        autoFitRows = true,
        rowHeight = 16,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 90,
        statusWidth = 42,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.ResourcesPageScroll:SetParent(listPanel:GetContentFrame())
    self.ResourcesPageScroll:SetRowRenderer(function(row, resource, itemIndex)
        if row.SetCategory then
            row:SetCategory(self:GetEntryDisplayName("resources", resource))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(resource and resource.valueMode == "derived" and "Derived" or "Manual")
        end
        if row.SetDetail then
            row:SetDetail(resource and resource.description or "")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("resources", itemIndex)
                end
            end)

            local selectedEntry = self.SelectedEntryIndices and self.SelectedEntryIndices.resources or nil
            local isSelected = tonumber(selectedEntry) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.ResourcesPageScroll:Create()
    UI.Utils.AnchorFill(self.ResourcesPageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.ResourcesPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorResourcesEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 36,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.ResourcesPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.ResourcesPageToolbar, self.ResourcesPageButtons = self:BuildDataPageToolbar(self.ResourcesPageRoot:GetFrame(), "RPEDataEditorResourcesPageToolbar", "resources")
    self.ResourcesPageRoot:AddChild(self.ResourcesPageToolbar)

    self:RefreshResourcesDataPage()
    return self.ResourcesPageRoot
end

function DataEditor:RefreshResourcesDataPage()
    local dataset = self:GetSelectedDataset()
    local resources = dataset and dataset.resources or {}

    self:RefreshDataPageToolbar(self.ResourcesPageButtons)

    if self.ResourcesPageScroll and self.ResourcesPageScroll.SetItems then
        self.ResourcesPageScroll:SetItems(resources)
    end

    if self.ResourcesPageEmptyText and self.ResourcesPageEmptyText.SetText then
        if not dataset then
            self.ResourcesPageEmptyText:SetText("Create or select a dataset to view resources.")
        elseif #resources == 0 then
            self.ResourcesPageEmptyText:SetText("This dataset has no resources yet.")
        else
            self.ResourcesPageEmptyText:SetText("")
        end
    end
end
