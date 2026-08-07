local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}

local BUILTIN_SECTION_HEIGHT = 96

local function buildBuiltinRows()
    local definitions = Profile.GetBuiltinCurrencyDefinitions and Profile.GetBuiltinCurrencyDefinitions() or {}
    local rows = {}

    for index = 1, #definitions do
        local definition = definitions[index]
        rows[#rows + 1] = {
            key = definition.key,
            label = ("%s %s"):format(("|T%s:14:14:0:0|t"):format(tostring(definition.icon or "Interface\\Icons\\INV_Misc_QuestionMark")), tostring(definition.name or "Currency")),
            description = definition.description or "",
            status = ("Cap %d"):format(math.max(0, math.floor(tonumber(definition.max) or 0))),
        }
    end

    return rows
end

function DataEditor:BuildCurrencyPage(page)
    if self.CurrencyPageRoot then
        return self.CurrencyPageRoot
    end

    self.CurrencyPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorCurrencyPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.CurrencyPageRoot, page, 0, 0, 0, 0)

    local builtinsPanel = UI.CreatePanel(self.CurrencyPageRoot:GetFrame(), "RPEDataEditorCurrencyBuiltinsPanel", {
        width = 150,
        height = BUILTIN_SECTION_HEIGHT,
        contentInset = 2,
        showBorder = false,
    })
    self.CurrencyPageRoot:AddChild(builtinsPanel)

    self.CurrencyBuiltinsTitle = UI.CreateText(builtinsPanel:GetContentFrame(), "RPEDataEditorCurrencyBuiltinsTitle", "Built-In Currencies", {
        width = 140,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.CurrencyBuiltinsTitle:GetFrame():SetPoint("TOPLEFT", builtinsPanel:GetContentFrame(), "TOPLEFT", 2, -2)

    self.CurrencyBuiltinsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorCurrencyBuiltinsScroll",
        width = 146,
        height = BUILTIN_SECTION_HEIGHT - 16,
        visibleRows = 5,
        autoFitRows = true,
        rowHeight = 16,
        rowSpacing = 0,
        border = false,
        compact = true,
        rowElementClass = UI.ScrollListEntry,
        compactCategoryWidth = 0,
        compactStatusWidth = 56,
        compactNameInsetLeft = 4,
        compactStatusInsetRight = 4,
    })
    self.CurrencyBuiltinsScroll:SetParent(builtinsPanel:GetContentFrame())
    self.CurrencyBuiltinsScroll:SetRowRenderer(function(row, builtinRow)
        row:SetCategory("")
        row:SetTestName(builtinRow and builtinRow.label or "")
        row:SetStatus(builtinRow and builtinRow.status or "")
        row:SetDetail(builtinRow and builtinRow.description or "")
        row:SetTooltip({
            type = "custom",
            title = builtinRow and builtinRow.label or "Built-In Currency",
            lines = {
                { text = builtinRow and builtinRow.description or "" },
                { text = builtinRow and builtinRow.status or "" },
            },
        })
    end)
    self.CurrencyBuiltinsScroll:Create()
    self.CurrencyBuiltinsScroll:SetPoint("TOPLEFT", builtinsPanel:GetContentFrame(), "TOPLEFT", 0, -16)
    self.CurrencyBuiltinsScroll:SetPoint("BOTTOMRIGHT", builtinsPanel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)

    local listPanel = UI.CreatePanel(self.CurrencyPageRoot:GetFrame(), "RPEDataEditorCurrencyListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.CurrencyPageRoot:AddChild(listPanel)

    self.CurrencyCustomTitle = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorCurrencyCustomTitle", "Custom Dataset Currencies", {
        width = 140,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.CurrencyCustomTitle:GetFrame():SetPoint("TOPLEFT", listPanel:GetContentFrame(), "TOPLEFT", 2, -2)

    self.CurrencyPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorCurrencyScroll",
        width = 146,
        height = 232,
        visibleRows = 10,
        autoFitRows = true,
        rowHeight = 16,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 88,
        statusWidth = 50,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.CurrencyPageScroll:SetParent(listPanel:GetContentFrame())
    self.CurrencyPageScroll:SetRowRenderer(function(row, currency, itemIndex)
        local iconMarkup = ("|T%s:14:14:0:0|t "):format(tostring(currency and currency.icon ~= "" and currency.icon or "Interface\\Icons\\INV_Misc_QuestionMark"))
        if row.SetCategory then
            row:SetCategory(iconMarkup .. self:GetEntryDisplayName("currencies", currency))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(("Cap %d"):format(math.max(0, math.floor(tonumber(currency and currency.max) or 0))))
        end
        if row.SetDetail then
            row:SetDetail(currency and currency.description or "")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("currencies", itemIndex)
                end
            end)

            local selectedEntry = self.SelectedEntryIndices and self.SelectedEntryIndices.currencies or nil
            local isSelected = tonumber(selectedEntry) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.CurrencyPageScroll:Create()
    self.CurrencyPageScroll:SetPoint("TOPLEFT", listPanel:GetContentFrame(), "TOPLEFT", 0, -16)
    self.CurrencyPageScroll:SetPoint("BOTTOMRIGHT", listPanel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)

    self.CurrencyPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorCurrencyEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.CurrencyPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 10)

    self.CurrencyPageToolbar, self.CurrencyPageButtons = self:BuildDataPageToolbar(self.CurrencyPageRoot:GetFrame(), "RPEDataEditorCurrencyPageToolbar", "currencies")
    self.CurrencyPageRoot:AddChild(self.CurrencyPageToolbar)

    self:RefreshCurrencyDataPage()
    return self.CurrencyPageRoot
end

function DataEditor:RefreshCurrencyDataPage()
    local dataset = self:GetSelectedDataset()
    local currencies = dataset and dataset.currencies or {}

    self:RefreshDataPageToolbar(self.CurrencyPageButtons)

    if self.CurrencyBuiltinsScroll and self.CurrencyBuiltinsScroll.SetItems then
        self.CurrencyBuiltinsScroll:SetItems(buildBuiltinRows())
    end

    if self.CurrencyPageScroll and self.CurrencyPageScroll.SetItems then
        self.CurrencyPageScroll:SetItems(currencies)
    end

    if self.CurrencyPageEmptyText and self.CurrencyPageEmptyText.SetText then
        if not dataset then
            self.CurrencyPageEmptyText:SetText("Create or select a dataset to manage custom currencies.")
        elseif #currencies == 0 then
            self.CurrencyPageEmptyText:SetText("This dataset has no custom currencies yet.")
        else
            self.CurrencyPageEmptyText:SetText("")
        end
    end
end
