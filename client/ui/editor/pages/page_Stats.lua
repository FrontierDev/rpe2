local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildStatsPage(page)
    if self.StatsPageRoot then
        return self.StatsPageRoot
    end

    self.StatsPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorStatsPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.StatsPageRoot, page, 0, 0, 0, 0)

    local listPanel = UI.CreatePanel(self.StatsPageRoot:GetFrame(), "RPEDataEditorStatsListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.StatsPageRoot:AddChild(listPanel)

    self.StatsPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorStatsScroll",
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
    self.StatsPageScroll:SetParent(listPanel:GetContentFrame())
    self.StatsPageScroll:SetRowRenderer(function(row, stat, itemIndex)
        if row.SetCategory then
            row:SetCategory(self:GetEntryDisplayName("stats", stat))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(stat and stat.valueMode == "derived" and "Derived" or "Manual")
        end
        if row.SetDetail then
            row:SetDetail(stat and stat.description or "")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("stats", itemIndex)
                end
            end)

            local selectedEntry = self.SelectedEntryIndices and self.SelectedEntryIndices.stats or nil
            local isSelected = tonumber(selectedEntry) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.StatsPageScroll:Create()
    UI.Utils.AnchorFill(self.StatsPageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.StatsPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorStatsEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 36,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.StatsPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.StatsPageToolbar, self.StatsPageButtons = self:BuildDataPageToolbar(self.StatsPageRoot:GetFrame(), "RPEDataEditorStatsPageToolbar", "stats")
    self.StatsPageRoot:AddChild(self.StatsPageToolbar)

    self:RefreshStatsDataPage()
    return self.StatsPageRoot
end

function DataEditor:RefreshStatsDataPage()
    local dataset = self:GetSelectedDataset()
    local stats = dataset and dataset.stats or {}

    self:RefreshDataPageToolbar(self.StatsPageButtons)

    if self.StatsPageScroll and self.StatsPageScroll.SetItems then
        self.StatsPageScroll:SetItems(stats)
    end

    if self.StatsPageEmptyText and self.StatsPageEmptyText.SetText then
        if not dataset then
            self.StatsPageEmptyText:SetText("Create or select a dataset to view stats.")
        elseif #stats == 0 then
            self.StatsPageEmptyText:SetText("This dataset has no stats yet.")
        else
            self.StatsPageEmptyText:SetText("")
        end
    end
end
