local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

local function buildMitigationStatus(damageSchool)
    local mode = damageSchool and tostring(damageSchool.mitigationMode or "direct") or "direct"
    local coefficient = damageSchool and tonumber(damageSchool.mitigationCoefficient or 1) or 1
    local referenceAmount = damageSchool and tonumber(damageSchool.mitigationReferenceAmount or 0) or 0
    local referencePercent = damageSchool and tonumber(damageSchool.mitigationReferencePercent or 0) or 0
    return ("%s %.2f | %g=>%g%%"):format(
        mode == "percent" and "P" or "D",
        coefficient,
        referenceAmount,
        referencePercent
    )
end

function DataEditor:BuildDamageSchoolsPage(page)
    if self.DamageSchoolsPageRoot then
        return self.DamageSchoolsPageRoot
    end

    self.DamageSchoolsPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorDamageSchoolsPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.DamageSchoolsPageRoot, page, 0, 0, 0, 0)

    local listPanel = UI.CreatePanel(self.DamageSchoolsPageRoot:GetFrame(), "RPEDataEditorDamageSchoolsListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.DamageSchoolsPageRoot:AddChild(listPanel)

    self.DamageSchoolsPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorDamageSchoolsScroll",
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
    self.DamageSchoolsPageScroll:SetParent(listPanel:GetContentFrame())
    self.DamageSchoolsPageScroll:SetRowRenderer(function(row, damageSchool, itemIndex)
        if row.SetCategory then
            row:SetCategory(self:GetEntryDisplayName("damageSchools", damageSchool))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(buildMitigationStatus(damageSchool))
        end
        if row.SetDetail then
            row:SetDetail(damageSchool and damageSchool.description or "")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("damageSchools", itemIndex)
                end
            end)

            local selectedEntry = self.SelectedEntryIndices and self.SelectedEntryIndices.damageSchools or nil
            local isSelected = tonumber(selectedEntry) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.DamageSchoolsPageScroll:Create()
    UI.Utils.AnchorFill(self.DamageSchoolsPageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.DamageSchoolsPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorDamageSchoolsEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 36,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.DamageSchoolsPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.DamageSchoolsPageToolbar, self.DamageSchoolsPageButtons = self:BuildDataPageToolbar(self.DamageSchoolsPageRoot:GetFrame(), "RPEDataEditorDamageSchoolsPageToolbar", "damageSchools")
    self.DamageSchoolsPageRoot:AddChild(self.DamageSchoolsPageToolbar)

    self:RefreshDamageSchoolsDataPage()
    return self.DamageSchoolsPageRoot
end

function DataEditor:RefreshDamageSchoolsDataPage()
    local dataset = self:GetSelectedDataset()
    local damageSchools = dataset and dataset.damageSchools or {}

    self:RefreshDataPageToolbar(self.DamageSchoolsPageButtons)

    if self.DamageSchoolsPageScroll and self.DamageSchoolsPageScroll.SetItems then
        self.DamageSchoolsPageScroll:SetItems(damageSchools)
    end

    if self.DamageSchoolsPageEmptyText and self.DamageSchoolsPageEmptyText.SetText then
        if not dataset then
            self.DamageSchoolsPageEmptyText:SetText("Create or select a dataset to view damage schools.")
        elseif #damageSchools == 0 then
            self.DamageSchoolsPageEmptyText:SetText("This dataset has no damage schools yet.")
        else
            self.DamageSchoolsPageEmptyText:SetText("")
        end
    end
end
