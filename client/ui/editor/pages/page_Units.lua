local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

local function buildUnitStatusText(unit)
    unit = unit or {}
    return ("S:%d  T:%d  R:%d"):format(#(unit.spells or {}), #(unit.stats or {}), #(unit.resources or {}))
end

local function buildUnitDetailText(unit)
    unit = unit or {}
    local attributes = unit.attributes or {}
    if #attributes > 0 then
        local labels = {}
        for index = 1, #attributes do
            local attribute = tostring(attributes[index] or "")
            labels[#labels + 1] = attribute:gsub("(^%l)", string.upper)
        end
        return table.concat(labels, ", ")
    end

    local hasModel = unit.displayId ~= nil or unit.fileDataId ~= nil
    if hasModel then
        return ("display=%s file=%s"):format(tostring(unit.displayId or "-"), tostring(unit.fileDataId or "-"))
    end

    return ("%d resistance%s"):format(#(unit.resistances or {}), #(unit.resistances or {}) == 1 and "" or "s")
end

function DataEditor:BuildUnitsPage(page)
    if self.UnitsPageRoot then
        return self.UnitsPageRoot
    end

    self.UnitsPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorUnitsPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.UnitsPageRoot, page, 0, 0, 0, 0)

    local listPanel = UI.CreatePanel(self.UnitsPageRoot:GetFrame(), "RPEDataEditorUnitsListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.UnitsPageRoot:AddChild(listPanel)

    self.UnitsPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorUnitsScroll",
        width = 146,
        height = 248,
        visibleRows = 10,
        autoFitRows = true,
        rowHeight = 16,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 82,
        statusWidth = 50,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.UnitsPageScroll:SetParent(listPanel:GetContentFrame())
    self.UnitsPageScroll:SetRowRenderer(function(row, unit, itemIndex)
        if row.SetCategory then
            row:SetCategory(self:GetEntryDisplayName("units", unit))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(buildUnitStatusText(unit))
        end
        if row.SetDetail then
            row:SetDetail(buildUnitDetailText(unit))
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedUnitIndex(itemIndex)
                end
            end)

            local isSelected = tonumber(self.SelectedUnitIndex) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.UnitsPageScroll:Create()
    UI.Utils.AnchorFill(self.UnitsPageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.UnitsPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorUnitsEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 36,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.UnitsPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.UnitsPageToolbar, self.UnitsPageButtons = self:BuildDataPageToolbar(self.UnitsPageRoot:GetFrame(), "RPEDataEditorUnitsPageToolbar", "units")
    self.UnitsPageRoot:AddChild(self.UnitsPageToolbar)

    self:RefreshUnitsDataPage()
    return self.UnitsPageRoot
end

function DataEditor:RefreshUnitsDataPage()
    local dataset = self:GetSelectedDataset()
    local units = dataset and dataset.units or {}

    self:RefreshDataPageToolbar(self.UnitsPageButtons)

    if self.UnitsPageScroll and self.UnitsPageScroll.SetItems then
        self.UnitsPageScroll:SetItems(units)
    end

    if self.UnitsPageEmptyText and self.UnitsPageEmptyText.SetText then
        if not dataset then
            self.UnitsPageEmptyText:SetText("Create or select a dataset to view units.")
        elseif #units == 0 then
            self.UnitsPageEmptyText:SetText("This dataset has no units yet.")
        else
            self.UnitsPageEmptyText:SetText("")
        end
    end
end
