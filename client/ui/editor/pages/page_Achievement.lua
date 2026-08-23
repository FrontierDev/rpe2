local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildAchievementPage(page)
    if self.AchievementPageRoot then
        self:RefreshAchievementDataPage()
        return self.AchievementPageRoot
    end

    self.AchievementPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorAchievementPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.AchievementPageRoot, page, 0, 0, 0, 0)

    local gridPanel = UI.CreatePanel(self.AchievementPageRoot:GetFrame(), "RPEDataEditorAchievementGridPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.AchievementPageRoot:AddChild(gridPanel)

    self.AchievementPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorAchievementScroll",
        width = 146,
        height = 248,
        visibleRows = 10,
        autoFitRows = true,
        rowHeight = 20,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 88,
        statusWidth = 50,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.AchievementPageScroll:SetParent(gridPanel:GetContentFrame())
    self.AchievementPageScroll:SetRowRenderer(function(row, achievement, entryIndex)
        local icon = achievement and achievement.icon
        local iconMarkup = ("|T%s:14:14:0:0|t "):format(tostring(icon ~= nil and icon ~= "" and icon or "Interface\\Icons\\INV_Misc_QuestionMark"))
        local criteria = achievement and achievement.criteria or {}

        if row.SetCategory then
            row:SetCategory(iconMarkup .. self:GetEntryDisplayName("achievements", achievement))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(("ID %s"):format(tostring(achievement and achievement.id or "-")))
        end
        if row.SetDetail then
            row:SetDetail(("%d criteria%s"):format(#criteria, achievement and achievement.description ~= "" and (" - " .. achievement.description) or ""))
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("achievements", entryIndex)
                end
            end)

            local selectedEntry = self.SelectedEntryIndices and self.SelectedEntryIndices.achievements or nil
            local isSelected = tonumber(selectedEntry) == tonumber(entryIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.AchievementPageScroll:Create()
    self.AchievementPageScroll:SetPoint("TOPLEFT", gridPanel:GetContentFrame(), "TOPLEFT", 0, 0)
    self.AchievementPageScroll:SetPoint("BOTTOMRIGHT", gridPanel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)

    self.AchievementPageEmptyText = UI.CreateText(gridPanel:GetContentFrame(), "RPEDataEditorAchievementEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.AchievementPageEmptyText:GetFrame():SetPoint("CENTER", gridPanel:GetContentFrame(), "CENTER", 0, 0)

    self.AchievementPageToolbar, self.AchievementPageButtons = self:BuildDataPageToolbar(self.AchievementPageRoot:GetFrame(), "RPEDataEditorAchievementPageToolbar", "achievements")
    self.AchievementPageRoot:AddChild(self.AchievementPageToolbar)

    self:RefreshAchievementDataPage()
    return self.AchievementPageRoot
end

function DataEditor:RefreshAchievementDataPage()
    local dataset = self:GetSelectedDataset()
    local achievements = dataset and dataset.achievements or {}

    self:RefreshDataPageToolbar(self.AchievementPageButtons)

    if self.AchievementPageScroll and self.AchievementPageScroll.SetItems then
        self.AchievementPageScroll:SetItems(achievements)
    end

    if self.AchievementPageEmptyText and self.AchievementPageEmptyText.SetText then
        if not dataset then
            self.AchievementPageEmptyText:SetText("Create or select a dataset to view achievements.")
        elseif #achievements == 0 then
            self.AchievementPageEmptyText:SetText("This dataset has no achievements yet.")
        else
            self.AchievementPageEmptyText:SetText("")
        end
    end
end
