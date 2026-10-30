local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

local function getMarketTypeLabel(market)
    return tostring(market and market.marketType or "exchange") == "tracker" and "Tracker" or "Exchange"
end

function DataEditor:BuildMarketsPage(page)
    if self.MarketsPageRoot then
        self:RefreshMarketDataPage()
        return self.MarketsPageRoot
    end

    self.MarketsPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorMarketsPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.MarketsPageRoot, page, 0, 0, 0, 0)

    local listPanel = UI.CreatePanel(self.MarketsPageRoot:GetFrame(), "RPEDataEditorMarketsListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.MarketsPageRoot:AddChild(listPanel)

    self.MarketsPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorMarketsScroll",
        width = 146,
        height = 248,
        visibleRows = 10,
        autoFitRows = true,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 86,
        statusWidth = 54,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.MarketsPageScroll:SetParent(listPanel:GetContentFrame())
    self.MarketsPageScroll:SetRowRenderer(function(row, market, itemIndex)
        row:SetCategory(self:GetEntryDisplayName("markets", market))
        row:SetTestName("")
        row:SetStatus(getMarketTypeLabel(market))
        row:SetDetail(("Index: %s"):format(tostring(market and market.index or "-")))

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("markets", itemIndex)
                end
            end)

            local selectedEntry = self.SelectedEntryIndices and self.SelectedEntryIndices.markets or nil
            local isSelected = tonumber(selectedEntry) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local color = UI.ResolveColor(nil, isSelected and "list.rowHover" or "list.rowBackground")
                row.entryBackground:SetColorTexture(color.r, color.g, color.b, color.a)
            end
        end
    end)
    self.MarketsPageScroll:Create()
    UI.Utils.AnchorFill(self.MarketsPageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.MarketsPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorMarketsEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.MarketsPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.MarketsPageToolbar, self.MarketsPageButtons = self:BuildDataPageToolbar(
        self.MarketsPageRoot:GetFrame(),
        "RPEDataEditorMarketsPageToolbar",
        "markets"
    )
    self.MarketsPageRoot:AddChild(self.MarketsPageToolbar)

    self:RefreshMarketDataPage()
    return self.MarketsPageRoot
end

function DataEditor:RefreshMarketDataPage()
    if not self.MarketsPageRoot then
        return
    end

    local dataset = self:GetSelectedDataset()
    local markets = dataset and dataset.markets or {}
    self:RefreshDataPageToolbar(self.MarketsPageButtons)

    if self.MarketsPageScroll and self.MarketsPageScroll.SetItems then
        self.MarketsPageScroll:SetItems(markets)
    end

    if self.MarketsPageEmptyText and self.MarketsPageEmptyText.SetText then
        if not dataset then
            self.MarketsPageEmptyText:SetText("Create or select a dataset to manage Markets.")
        elseif #markets == 0 then
            self.MarketsPageEmptyText:SetText("This dataset has no Markets yet.")
        else
            self.MarketsPageEmptyText:SetText("")
        end
    end
end
