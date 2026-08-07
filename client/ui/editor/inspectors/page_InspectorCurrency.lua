local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}

local INSPECTOR_SIDE_PADDING = 8
local CONTROL_HEIGHT = 20

local function commitSelectedCurrency(self, mutate)
    local currency = self:GetSelectedCurrency()
    local dataset = self:GetSelectedDataset()
    if not dataset or not currency or type(mutate) ~= "function" then
        return
    end

    mutate(currency, dataset)
    currency.max = math.max(0, math.floor(tonumber(currency.max) or 0))

    if self.Database and self.Database.NotifyDatasetEntryChanged then
        self.Database.NotifyDatasetEntryChanged(dataset.id, "currencies", {
            deferConfigurationChanged = true,
        })
    end
    self:RefreshAfterDatasetEntryChanged("currencies")
end

function DataEditor:BuildCurrencyInspectorPage(parent)
    if self.CurrencyInspectorPage then
        return self.CurrencyInspectorPage
    end

    self.CurrencyInspectorPage = CreateFrame("Frame", "RPEDataEditorCurrencyInspectorPage", parent)

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, self.CurrencyInspectorPage, "RPEDataEditorCurrencyInspectorLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, self.CurrencyInspectorPage, INSPECTOR_SIDE_PADDING, 0, INSPECTOR_SIDE_PADDING, 24)

    root:AddChild(UI.CreateText(root:GetFrame(), "RPEDataEditorCurrencyInspectorNameLabel", "Name", {
        width = 236, height = 12, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    }))
    self.CurrencyInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorCurrencyInspectorNameInput", {
        width = 236, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.CurrencyInspectorNameInput:SetScript("OnEnterPressed", function()
        commitSelectedCurrency(self, function(currency)
            currency.name = self.CurrencyInspectorNameInput:GetText()
        end)
    end)
    self.CurrencyInspectorNameInput:SetScript("OnEditFocusLost", function()
        commitSelectedCurrency(self, function(currency)
            currency.name = self.CurrencyInspectorNameInput:GetText()
        end)
    end)
    root:AddChild(self.CurrencyInspectorNameInput)

    self.CurrencyInspectorIdText = UI.CreateText(root:GetFrame(), "RPEDataEditorCurrencyInspectorIdText", "ID: -", {
        width = 236, height = 12, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.CurrencyInspectorIdText)

    root:AddChild(UI.CreateText(root:GetFrame(), "RPEDataEditorCurrencyInspectorIconLabel", "Icon", {
        width = 236, height = 12, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    }))
    self.CurrencyInspectorIconField = UI.EditorIconField:New({
        name = "RPEDataEditorCurrencyInspectorIconField",
        width = 236,
        height = CONTROL_HEIGHT,
        buttonText = "Select Icon",
        labelText = "-",
        iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
    })
    self.CurrencyInspectorIconField:SetParent(root:GetFrame())
    self.CurrencyInspectorIconField:Create()
    local iconButton = self.CurrencyInspectorIconField:GetButton()
    if iconButton and iconButton.SetScript then
        iconButton:SetScript("OnClick", function()
            local currency = self:GetSelectedCurrency()
            if not currency or not Client.OpenIconFinder then
                return
            end

            Client:OpenIconFinder(function(_, filePath)
                commitSelectedCurrency(self, function(selectedCurrency)
                    selectedCurrency.icon = filePath or ""
                end)
            end, {
                filter = currency.icon or "",
            })
        end)
    end
    root:AddChild(self.CurrencyInspectorIconField)

    root:AddChild(UI.CreateText(root:GetFrame(), "RPEDataEditorCurrencyInspectorMaxLabel", "Maximum Amount", {
        width = 236, height = 12, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    }))
    self.CurrencyInspectorMaxInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorCurrencyInspectorMaxInput", {
        width = 236, height = CONTROL_HEIGHT, text = "0", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.CurrencyInspectorMaxInput:SetScript("OnEnterPressed", function()
        commitSelectedCurrency(self, function(currency)
            currency.max = math.max(0, math.floor(tonumber(self.CurrencyInspectorMaxInput:GetText()) or 0))
        end)
    end)
    self.CurrencyInspectorMaxInput:SetScript("OnEditFocusLost", function()
        commitSelectedCurrency(self, function(currency)
            currency.max = math.max(0, math.floor(tonumber(self.CurrencyInspectorMaxInput:GetText()) or 0))
        end)
    end)
    root:AddChild(self.CurrencyInspectorMaxInput)

    root:AddChild(UI.CreateText(root:GetFrame(), "RPEDataEditorCurrencyInspectorDescriptionLabel", "Description", {
        width = 236, height = 12, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    }))
    self.CurrencyInspectorDescriptionInput = UI.CreateTextArea(root:GetFrame(), "RPEDataEditorCurrencyInspectorDescriptionInput", {
        width = 236, height = 88, text = "", readOnly = false, borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.CurrencyInspectorDescriptionInput:SetScript("OnEditFocusLost", function()
        commitSelectedCurrency(self, function(currency)
            currency.description = self.CurrencyInspectorDescriptionInput:GetText()
        end)
    end)
    root:AddChild(self.CurrencyInspectorDescriptionInput)

    self.CurrencyInspectorIconInput = {
        SetText = function(_, value)
            local iconPath = value ~= nil and tostring(value) or ""
            self.CurrencyInspectorIconField:SetIcon(iconPath ~= "" and iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
            self.CurrencyInspectorIconField:SetLabelText(iconPath ~= "" and iconPath or "-")
        end,
        SetEnabled = function(_, enabled)
            self.CurrencyInspectorIconField:SetEnabled(enabled)
        end,
        SetReadOnly = function(_, readOnly)
            self.CurrencyInspectorIconField:SetEnabled(readOnly ~= true)
        end,
    }

    self.CurrencyInspectorEmptyText = UI.CreateText(self.CurrencyInspectorPage, "RPEDataEditorCurrencyInspectorEmptyText", "", {
        width = 236, height = 20, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.CurrencyInspectorEmptyText:GetFrame():SetPoint("BOTTOMLEFT", self.CurrencyInspectorPage, "BOTTOMLEFT", 0, 0)

    self:RefreshCurrencyInspectorPage()
    return self.CurrencyInspectorPage
end

function DataEditor:RefreshCurrencyInspectorPage()
    local currency = self:GetSelectedCurrency()
    local hasCurrency = currency ~= nil

    if self.CurrencyInspectorNameInput then
        self.CurrencyInspectorNameInput:SetText(currency and (currency.name or "") or "")
        self.CurrencyInspectorNameInput:SetEnabled(hasCurrency)
        self.CurrencyInspectorNameInput:SetReadOnly(not hasCurrency)
    end
    if self.CurrencyInspectorIdText then
        self.CurrencyInspectorIdText:SetText(("ID: %s"):format(currency and tostring(currency.id or "") or "-"))
    end
    if self.CurrencyInspectorIconInput then
        self.CurrencyInspectorIconInput:SetText(currency and (currency.icon or "") or "")
        self.CurrencyInspectorIconInput:SetEnabled(hasCurrency)
    end
    if self.CurrencyInspectorMaxInput then
        self.CurrencyInspectorMaxInput:SetText(tostring(math.max(0, math.floor(tonumber(currency and currency.max) or 0))))
        self.CurrencyInspectorMaxInput:SetEnabled(hasCurrency)
        self.CurrencyInspectorMaxInput:SetReadOnly(not hasCurrency)
    end
    if self.CurrencyInspectorDescriptionInput then
        self.CurrencyInspectorDescriptionInput:SetText(currency and (currency.description or "") or "")
        self.CurrencyInspectorDescriptionInput:SetEnabled(hasCurrency)
        self.CurrencyInspectorDescriptionInput:SetReadOnly(not hasCurrency)
    end
    if self.CurrencyInspectorEmptyText then
        self.CurrencyInspectorEmptyText:SetText(hasCurrency and "Adjust the selected custom currency here." or "Select a custom currency to inspect it.")
    end
end
