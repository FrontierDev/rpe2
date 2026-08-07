local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildInteractionPage(page)
    if self.InteractionPageRoot then
        return self.InteractionPageRoot
    end

    self.InteractionPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorInteractionPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.InteractionPageRoot, page, 0, 0, 0, 0)

    local listPanel = UI.CreatePanel(self.InteractionPageRoot:GetFrame(), "RPEDataEditorInteractionListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.InteractionPageRoot:AddChild(listPanel)

    self.InteractionPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorInteractionScroll",
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
    self.InteractionPageScroll:SetParent(listPanel:GetContentFrame())
    self.InteractionPageScroll:SetRowRenderer(function(row, interaction, itemIndex)
        if row.SetCategory then
            row:SetCategory(self:GetEntryDisplayName("interactions", interaction))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus("")
        end
        if row.SetDetail then
            row:SetDetail(interaction and interaction.description or "")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("interactions", itemIndex)
                end
            end)

            local selectedEntry = self.SelectedEntryIndices and self.SelectedEntryIndices.interactions or nil
            local isSelected = tonumber(selectedEntry) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.InteractionPageScroll:Create()
    UI.Utils.AnchorFill(self.InteractionPageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.InteractionPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorInteractionEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.InteractionPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.InteractionPageToolbar, self.InteractionPageButtons = self:BuildDataPageToolbar(self.InteractionPageRoot:GetFrame(), "RPEDataEditorInteractionPageToolbar", "interactions")
    self.InteractionPageRoot:AddChild(self.InteractionPageToolbar)

    self:RefreshInteractionDataPage()
    return self.InteractionPageRoot
end

function DataEditor:RefreshInteractionDataPage()
    local dataset = self:GetSelectedDataset()
    local interactions = dataset and dataset.interactions or {}

    self:RefreshDataPageToolbar(self.InteractionPageButtons)

    if self.InteractionPageScroll and self.InteractionPageScroll.SetItems then
        self.InteractionPageScroll:SetItems(interactions)
    end

    if self.InteractionPageEmptyText and self.InteractionPageEmptyText.SetText then
        if not dataset then
            self.InteractionPageEmptyText:SetText("Create or select a dataset to view interactions.")
        elseif #interactions == 0 then
            self.InteractionPageEmptyText:SetText("This dataset has no interactions yet.")
        else
            self.InteractionPageEmptyText:SetText("")
        end
    end
end
