local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildSkillsPage(page)
    if self.SkillsPageRoot then
        return self.SkillsPageRoot
    end

    self.SkillsPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorSkillsPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.SkillsPageRoot, page, 0, 0, 0, 0)

    local listPanel = UI.CreatePanel(self.SkillsPageRoot:GetFrame(), "RPEDataEditorSkillsListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.SkillsPageRoot:AddChild(listPanel)

    self.SkillsPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorSkillsScroll",
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
    self.SkillsPageScroll:SetParent(listPanel:GetContentFrame())
    self.SkillsPageScroll:SetRowRenderer(function(row, skill, itemIndex)
        if row.SetCategory then
            row:SetCategory(self:GetEntryDisplayName("skills", skill))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(skill and tostring(skill.skillType or "noncombat") or "")
        end
        if row.SetDetail then
            row:SetDetail(skill and skill.description or "")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("skills", itemIndex)
                end
            end)

            local selectedEntry = self.SelectedEntryIndices and self.SelectedEntryIndices.skills or nil
            local isSelected = tonumber(selectedEntry) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.SkillsPageScroll:Create()
    UI.Utils.AnchorFill(self.SkillsPageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.SkillsPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorSkillsEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 36,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.SkillsPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.SkillsPageToolbar, self.SkillsPageButtons = self:BuildDataPageToolbar(self.SkillsPageRoot:GetFrame(), "RPEDataEditorSkillsPageToolbar", "skills")
    self.SkillsPageRoot:AddChild(self.SkillsPageToolbar)

    self:RefreshSkillsDataPage()
    return self.SkillsPageRoot
end

function DataEditor:RefreshSkillsDataPage()
    local dataset = self:GetSelectedDataset()
    local skills = dataset and dataset.skills or {}

    self:RefreshDataPageToolbar(self.SkillsPageButtons)

    if self.SkillsPageScroll and self.SkillsPageScroll.SetItems then
        self.SkillsPageScroll:SetItems(skills)
    end

    if self.SkillsPageEmptyText and self.SkillsPageEmptyText.SetText then
        if not dataset then
            self.SkillsPageEmptyText:SetText("Create or select a dataset to view skills.")
        elseif #skills == 0 then
            self.SkillsPageEmptyText:SetText("This dataset has no skills yet.")
        else
            self.SkillsPageEmptyText:SetText("")
        end
    end
end
