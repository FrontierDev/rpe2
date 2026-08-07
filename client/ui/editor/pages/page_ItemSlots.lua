local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildItemSlotsPage(page)
    if self.ItemSlotsPageRoot then
        return self.ItemSlotsPageRoot
    end

    self.ItemSlotsPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorItemSlotsPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.ItemSlotsPageRoot, page, 0, 0, 0, 0)

    local listPanel = UI.CreatePanel(self.ItemSlotsPageRoot:GetFrame(), "RPEDataEditorItemSlotsListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.ItemSlotsPageRoot:AddChild(listPanel)

    self.ItemSlotsPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorItemSlotsScroll",
        width = 146,
        height = 248,
        visibleRows = 10,
        autoFitRows = true,
        rowHeight = 16,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 112,
        statusWidth = 20,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.ItemSlotsPageScroll:SetParent(listPanel:GetContentFrame())
    self.ItemSlotsPageScroll:SetRowRenderer(function(row, itemSlot, itemIndex)
        if row.SetCategory then
            row:SetCategory(self:GetEntryDisplayName("itemSlots", itemSlot))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus("")
        end
        if row.SetDetail then
            row:SetDetail("")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("itemSlots", itemIndex)
                end
            end)

            local selectedEntry = self.SelectedEntryIndices and self.SelectedEntryIndices.itemSlots or nil
            local isSelected = tonumber(selectedEntry) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.ItemSlotsPageScroll:Create()
    UI.Utils.AnchorFill(self.ItemSlotsPageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.ItemSlotsPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorItemSlotsEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 36,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.ItemSlotsPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.ItemSlotsPageToolbar, self.ItemSlotsPageButtons = self:BuildDataPageToolbar(self.ItemSlotsPageRoot:GetFrame(), "RPEDataEditorItemSlotsPageToolbar", "itemSlots")
    self.ItemSlotsPageRoot:AddChild(self.ItemSlotsPageToolbar)

    self:RefreshItemSlotsDataPage()
    return self.ItemSlotsPageRoot
end

function DataEditor:RefreshItemSlotsDataPage()
    local dataset = self:GetSelectedDataset()
    local itemSlots = dataset and dataset.itemSlots or {}

    self:RefreshDataPageToolbar(self.ItemSlotsPageButtons)

    if self.ItemSlotsPageScroll and self.ItemSlotsPageScroll.SetItems then
        self.ItemSlotsPageScroll:SetItems(itemSlots)
    end

    if self.ItemSlotsPageEmptyText and self.ItemSlotsPageEmptyText.SetText then
        if not dataset then
            self.ItemSlotsPageEmptyText:SetText("Create or select a dataset to view item slots.")
        elseif #itemSlots == 0 then
            self.ItemSlotsPageEmptyText:SetText("This dataset has no item slots yet.")
        else
            self.ItemSlotsPageEmptyText:SetText("")
        end
    end
end
