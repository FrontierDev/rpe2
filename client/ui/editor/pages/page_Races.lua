local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

local function buildPage(page, rootKey, scrollKey, emptyTextKey, toolbarKey, buttonsKey, collectionKey, emptyMessage)
    if DataEditor[rootKey] then
        return DataEditor[rootKey]
    end

    DataEditor[rootKey] = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditor" .. collectionKey .. "PageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(DataEditor[rootKey], page, 0, 0, 0, 0)

    local listPanel = UI.CreatePanel(DataEditor[rootKey]:GetFrame(), "RPEDataEditor" .. collectionKey .. "ListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    DataEditor[rootKey]:AddChild(listPanel)

    DataEditor[scrollKey] = UI.ScrollLayout:New({
        name = "RPEDataEditor" .. collectionKey .. "Scroll",
        width = 146,
        height = 248,
        visibleRows = 10,
        autoFitRows = true,
        rowHeight = 16,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 96,
        statusWidth = 36,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    DataEditor[scrollKey]:SetParent(listPanel:GetContentFrame())
    DataEditor[scrollKey]:SetRowRenderer(function(row, entry, itemIndex)
        if row.SetCategory then
            row:SetCategory(DataEditor:GetEntryDisplayName(collectionKey, entry))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(tostring(#(entry and entry.resourceProgressions or {})))
        end
        if row.SetDetail then
            row:SetDetail(entry and entry.description or "")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    DataEditor:SetSelectedDatasetEntryIndex(collectionKey, itemIndex)
                end
            end)

            local selectedEntry = DataEditor.SelectedEntryIndices and DataEditor.SelectedEntryIndices[collectionKey] or nil
            local isSelected = tonumber(selectedEntry) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    DataEditor[scrollKey]:Create()
    UI.Utils.AnchorFill(DataEditor[scrollKey], listPanel:GetContentFrame(), 0, 0, 0, 0)

    DataEditor[emptyTextKey] = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditor" .. collectionKey .. "EmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 36,
        justifyH = "CENTER",
        wordWrap = true,
    })
    DataEditor[emptyTextKey]:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    DataEditor[toolbarKey], DataEditor[buttonsKey] = DataEditor:BuildDataPageToolbar(DataEditor[rootKey]:GetFrame(), "RPEDataEditor" .. collectionKey .. "PageToolbar", collectionKey)
    DataEditor[rootKey]:AddChild(DataEditor[toolbarKey])

    return DataEditor[rootKey]
end

function DataEditor:BuildRacesPage(page)
    local root = buildPage(page, "RacesPageRoot", "RacesPageScroll", "RacesPageEmptyText", "RacesPageToolbar", "RacesPageButtons", "races", "This dataset has no races yet.")
    self:RefreshRacesDataPage()
    return root
end

function DataEditor:RefreshRacesDataPage()
    local dataset = self:GetSelectedDataset()
    local races = dataset and dataset.races or {}

    self:RefreshDataPageToolbar(self.RacesPageButtons)

    if self.RacesPageScroll and self.RacesPageScroll.SetItems then
        self.RacesPageScroll:SetItems(races)
    end

    if self.RacesPageEmptyText and self.RacesPageEmptyText.SetText then
        if not dataset then
            self.RacesPageEmptyText:SetText("Create or select a dataset to view races.")
        elseif #races == 0 then
            self.RacesPageEmptyText:SetText("This dataset has no races yet.")
        else
            self.RacesPageEmptyText:SetText("")
        end
    end
end
