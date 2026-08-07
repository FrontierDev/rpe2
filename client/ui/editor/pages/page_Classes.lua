local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildClassesPage(page)
    if self.ClassesPageRoot then
        return self.ClassesPageRoot
    end

    self.ClassesPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorClassesPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.ClassesPageRoot, page, 0, 0, 0, 0)

    local listPanel = UI.CreatePanel(self.ClassesPageRoot:GetFrame(), "RPEDataEditorClassesListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.ClassesPageRoot:AddChild(listPanel)

    self.ClassesPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorClassesScroll",
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
    self.ClassesPageScroll:SetParent(listPanel:GetContentFrame())
    self.ClassesPageScroll:SetRowRenderer(function(row, entry, itemIndex)
        if row.SetCategory then
            row:SetCategory(self:GetEntryDisplayName("classes", entry))
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
                    self:SetSelectedDatasetEntryIndex("classes", itemIndex)
                end
            end)

            local selectedEntry = self.SelectedEntryIndices and self.SelectedEntryIndices.classes or nil
            local isSelected = tonumber(selectedEntry) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.ClassesPageScroll:Create()
    UI.Utils.AnchorFill(self.ClassesPageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.ClassesPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorClassesEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 36,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.ClassesPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.ClassesPageToolbar, self.ClassesPageButtons = self:BuildDataPageToolbar(self.ClassesPageRoot:GetFrame(), "RPEDataEditorClassesPageToolbar", "classes")
    self.ClassesPageRoot:AddChild(self.ClassesPageToolbar)

    self:RefreshClassesDataPage()
    return self.ClassesPageRoot
end

function DataEditor:RefreshClassesDataPage()
    local dataset = self:GetSelectedDataset()
    local classes = dataset and dataset.classes or {}

    self:RefreshDataPageToolbar(self.ClassesPageButtons)

    if self.ClassesPageScroll and self.ClassesPageScroll.SetItems then
        self.ClassesPageScroll:SetItems(classes)
    end

    if self.ClassesPageEmptyText and self.ClassesPageEmptyText.SetText then
        if not dataset then
            self.ClassesPageEmptyText:SetText("Create or select a dataset to view classes.")
        elseif #classes == 0 then
            self.ClassesPageEmptyText:SetText("This dataset has no classes yet.")
        else
            self.ClassesPageEmptyText:SetText("")
        end
    end
end
