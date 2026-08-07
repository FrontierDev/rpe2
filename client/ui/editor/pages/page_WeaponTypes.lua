local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildWeaponTypesPage(page)
    if self.WeaponTypesPageRoot then
        return self.WeaponTypesPageRoot
    end

    self.WeaponTypesPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorWeaponTypesPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.WeaponTypesPageRoot, page, 0, 0, 0, 0)

    local listPanel = UI.CreatePanel(self.WeaponTypesPageRoot:GetFrame(), "RPEDataEditorWeaponTypesListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.WeaponTypesPageRoot:AddChild(listPanel)

    self.WeaponTypesPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorWeaponTypesScroll",
        width = 146,
        height = 248,
        visibleRows = 10,
        autoFitRows = true,
        rowHeight = 16,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 112,
        statusWidth = 20,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.WeaponTypesPageScroll:SetParent(listPanel:GetContentFrame())
    self.WeaponTypesPageScroll:SetRowRenderer(function(row, weaponType, itemIndex)
        if row.SetCategory then
            row:SetCategory(self:GetEntryDisplayName("weaponTypes", weaponType))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus("")
        end
        if row.SetDetail then
            row:SetDetail("")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("weaponTypes", itemIndex)
                end
            end)

            local selectedEntry = self.SelectedEntryIndices and self.SelectedEntryIndices.weaponTypes or nil
            local isSelected = tonumber(selectedEntry) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.WeaponTypesPageScroll:Create()
    UI.Utils.AnchorFill(self.WeaponTypesPageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.WeaponTypesPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorWeaponTypesEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 36,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.WeaponTypesPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.WeaponTypesPageToolbar, self.WeaponTypesPageButtons = self:BuildDataPageToolbar(self.WeaponTypesPageRoot:GetFrame(), "RPEDataEditorWeaponTypesPageToolbar", "weaponTypes")
    self.WeaponTypesPageRoot:AddChild(self.WeaponTypesPageToolbar)

    self:RefreshWeaponTypesDataPage()
    return self.WeaponTypesPageRoot
end

function DataEditor:RefreshWeaponTypesDataPage()
    local dataset = self:GetSelectedDataset()
    local weaponTypes = dataset and dataset.weaponTypes or {}

    self:RefreshDataPageToolbar(self.WeaponTypesPageButtons)

    if self.WeaponTypesPageScroll and self.WeaponTypesPageScroll.SetItems then
        self.WeaponTypesPageScroll:SetItems(weaponTypes)
    end

    if self.WeaponTypesPageEmptyText and self.WeaponTypesPageEmptyText.SetText then
        if not dataset then
            self.WeaponTypesPageEmptyText:SetText("Create or select a dataset to view weapon types.")
        elseif #weaponTypes == 0 then
            self.WeaponTypesPageEmptyText:SetText("This dataset has no weapon types yet.")
        else
            self.WeaponTypesPageEmptyText:SetText("")
        end
    end
end
