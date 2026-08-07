local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildLootPage(page)
    if self.LootPageRoot then
        return self.LootPageRoot
    end

    self.LootPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorLootPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.LootPageRoot, page, 0, 0, 0, 0)

    local listPanel = UI.CreatePanel(self.LootPageRoot:GetFrame(), "RPEDataEditorLootListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.LootPageRoot:AddChild(listPanel)

    self.LootPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorLootScroll",
        width = 146,
        height = 304,
        visibleRows = 12,
        autoFitRows = true,
        rowHeight = 16,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 132,
        statusWidth = 0,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.LootPageScroll:SetParent(listPanel:GetContentFrame())
    self.LootPageScroll:SetRowRenderer(function(row, lootEntry, itemIndex)
        if row.SetCategory then
            row:SetCategory(self:GetEntryDisplayName("loot", lootEntry))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus("")
        end
        if row.SetDetail then
            row:SetDetail(lootEntry and lootEntry.description or "")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("loot", itemIndex)
                end
            end)

            local selectedEntry = self.SelectedEntryIndices and self.SelectedEntryIndices.loot or nil
            local isSelected = tonumber(selectedEntry) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.LootPageScroll:Create()
    UI.Utils.AnchorFill(self.LootPageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.LootPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorLootEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.LootPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.LootPageToolbar, self.LootPageButtons = self:BuildDataPageToolbar(self.LootPageRoot:GetFrame(), "RPEDataEditorLootPageToolbar", "loot")
    self.LootPageRoot:AddChild(self.LootPageToolbar)

    self:RefreshLootDataPage()
    return self.LootPageRoot
end

function DataEditor:RefreshLootDataPage()
    local dataset = self:GetSelectedDataset()
    local loot = dataset and dataset.loot or {}

    self:RefreshDataPageToolbar(self.LootPageButtons)

    if self.LootPageScroll and self.LootPageScroll.SetItems then
        self.LootPageScroll:SetItems(loot)
    end

    if self.LootPageEmptyText and self.LootPageEmptyText.SetText then
        if not dataset then
            self.LootPageEmptyText:SetText("Create or select a dataset to view loot tables.")
        elseif #loot == 0 then
            self.LootPageEmptyText:SetText("This dataset has no loot tables yet.")
        else
            self.LootPageEmptyText:SetText("")
        end
    end
end
