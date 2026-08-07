local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildAchievementPage(page)
    if self.AchievementPageRoot then
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

    if self.AchievementPageEmptyText and self.AchievementPageEmptyText.SetText then
        if not dataset then
            self.AchievementPageEmptyText:SetText("Create or select a dataset to view achievements.")
        elseif #achievements == 0 then
            self.AchievementPageEmptyText:SetText("This dataset has no achievements yet.")
        else
            self.AchievementPageEmptyText:SetText("Achievement icon grid will appear here.")
        end
    end
end
