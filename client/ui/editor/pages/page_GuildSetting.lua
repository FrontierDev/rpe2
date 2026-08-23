local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

local function getGuildBinding(guildSetting)
    local guildName = tostring(guildSetting and guildSetting.guildName or "")
    return guildName ~= "" and guildName or "Any Guild"
end

function DataEditor:BuildGuildSettingPage(page)
    if self.GuildSettingPageRoot then
        self:RefreshGuildSettingDataPage()
        return self.GuildSettingPageRoot
    end

    self.GuildSettingPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorGuildSettingPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.GuildSettingPageRoot, page, 0, 0, 0, 0)

    local listPanel = UI.CreatePanel(self.GuildSettingPageRoot:GetFrame(), "RPEDataEditorGuildSettingListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.GuildSettingPageRoot:AddChild(listPanel)

    self.GuildSettingPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorGuildSettingScroll",
        width = 146,
        height = 304,
        visibleRows = 12,
        autoFitRows = true,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 94,
        statusWidth = 48,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.GuildSettingPageScroll:SetParent(listPanel:GetContentFrame())
    self.GuildSettingPageScroll:SetRowRenderer(function(row, guildSetting, itemIndex)
        if row.SetCategory then
            row:SetCategory(self:GetEntryDisplayName("guildSettings", guildSetting))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(getGuildBinding(guildSetting))
        end
        if row.SetDetail then
            row:SetDetail(guildSetting and guildSetting.description or "")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("guildSettings", itemIndex)
                end
            end)

            local selectedEntry = self.SelectedEntryIndices and self.SelectedEntryIndices.guildSettings or nil
            local isSelected = tonumber(selectedEntry) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.GuildSettingPageScroll:Create()
    UI.Utils.AnchorFill(self.GuildSettingPageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.GuildSettingPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorGuildSettingEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.GuildSettingPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.GuildSettingPageToolbar, self.GuildSettingPageButtons = self:BuildDataPageToolbar(self.GuildSettingPageRoot:GetFrame(), "RPEDataEditorGuildSettingPageToolbar", "guildSettings")
    self.GuildSettingPageRoot:AddChild(self.GuildSettingPageToolbar)

    self:RefreshGuildSettingDataPage()
    return self.GuildSettingPageRoot
end

function DataEditor:RefreshGuildSettingDataPage()
    if not self.GuildSettingPageRoot then
        return
    end

    local dataset = self:GetSelectedDataset()
    local guildSettings = dataset and dataset.guildSettings or {}

    self:RefreshDataPageToolbar(self.GuildSettingPageButtons)

    if self.GuildSettingPageScroll and self.GuildSettingPageScroll.SetItems then
        self.GuildSettingPageScroll:SetItems(guildSettings)
    end

    if self.GuildSettingPageEmptyText and self.GuildSettingPageEmptyText.SetText then
        if not dataset then
            self.GuildSettingPageEmptyText:SetText("Create or select a dataset to view Guild Ranks.")
        elseif #guildSettings == 0 then
            self.GuildSettingPageEmptyText:SetText("This dataset has no Guild Ranks yet.")
        else
            self.GuildSettingPageEmptyText:SetText("")
        end
    end
end
