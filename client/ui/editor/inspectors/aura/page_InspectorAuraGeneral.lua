local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}
local TooltipTemplate = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.TooltipTemplate or nil
local Debug = Addon.Debug or {}

local function hasStoredAuraTooltipTemplate(aura)
    if type(aura) ~= "table" then
        return false
    end

    if type(TooltipTemplate) == "table" and type(TooltipTemplate.NormalizeAuraPayload) == "function" then
        return type(TooltipTemplate.NormalizeAuraPayload(aura.tooltipTemplateData)) == "table"
    end

    return type(aura.tooltipTemplateData) == "table"
end

local function logInternal(message, ...)
    if type(Debug.SetLevelEnabled) == "function" and type(Debug.IsLevelEnabled) == "function" and not Debug.IsLevelEnabled("internal") then
        Debug.SetLevelEnabled("internal", true)
    end
    if type(Debug.Internal) == "function" then
        Debug.Internal(message, ...)
    end
end

local function summarizeText(value, limit)
    local text = tostring(value or ""):gsub("%s+", " ")
    limit = math.max(8, math.floor(tonumber(limit) or 80))
    if text == "" then
        return "-"
    end
    if #text <= limit then
        return text
    end

    return text:sub(1, limit - 3) .. "..."
end

local function summarizeAuraTooltipPayload(payload)
    if type(payload) ~= "table" then
        return "payload=nil"
    end

    return ("body=%s bodyTokens=%d stacking=%s stackingTokens=%d"):format(
        summarizeText(payload.bodyText, 72),
        #(payload.bodyTokens or {}),
        summarizeText(payload.stackingText, 48),
        #(payload.stackingTokens or {})
    )
end

function DataEditor:BuildAuraInspectorGeneralPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorAuraInspectorGeneralLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildAuraInspectorLabel(root:GetFrame(), "RPEDataEditorAuraInspectorNameLabel", "Name"))
    self.AuraInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorAuraInspectorNameInput", {
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorNameInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedAura(function(aura)
            aura.name = self.AuraInspectorNameInput:GetText()
        end)
    end)
    self.AuraInspectorNameInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedAura(function(aura)
            aura.name = self.AuraInspectorNameInput:GetText()
        end)
    end)
    root:AddChild(self.AuraInspectorNameInput)

    self.AuraInspectorIdText = UI.CreateText(root:GetFrame(), "RPEDataEditorAuraInspectorIdText", "ID: -", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = self.AuraInspectorFieldWidth,
        height = 12,
        justifyH = "LEFT",
    })
    root:AddChild(self.AuraInspectorIdText)

    root:AddChild(self:BuildAuraInspectorLabel(root:GetFrame(), "RPEDataEditorAuraInspectorIconLabel", "Icon"))
    self.AuraInspectorIconField = UI.EditorIconField:New({
        name = "RPEDataEditorAuraInspectorIconField",
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        buttonText = "Select Icon",
        labelText = "-",
        iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
    })
    self.AuraInspectorIconField:SetParent(root:GetFrame())
    self.AuraInspectorIconField:Create()
    local iconButton = self.AuraInspectorIconField:GetButton()
    if iconButton and iconButton.SetScript then
        iconButton:SetScript("OnClick", function()
            local _, aura = self:GetSelectedAuraAndDataset()
            if not aura or not Client.OpenIconFinder then
                return
            end

            Client:OpenIconFinder(function(_, filePath)
                self:CommitSelectedAura(function(selectedAura)
                    selectedAura.icon = filePath or ""
                end)
            end, {
                filter = aura.icon or "",
            })
        end)
    end
    root:AddChild(self.AuraInspectorIconField)

    self.AuraInspectorIconInput = {
        SetText = function(_, value)
            local iconPath = value ~= nil and tostring(value) or ""
            self.AuraInspectorIconField:SetIcon(iconPath ~= "" and iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
            self.AuraInspectorIconField:SetLabelText(iconPath ~= "" and iconPath or "-")
        end,
        SetEnabled = function(_, enabled)
            self.AuraInspectorIconField:SetEnabled(enabled)
        end,
        SetReadOnly = function(_, readOnly)
            self.AuraInspectorIconField:SetEnabled(readOnly ~= true)
        end,
    }

    root:AddChild(self:BuildAuraInspectorLabel(root:GetFrame(), "RPEDataEditorAuraInspectorDurationLabel", "Duration"))
    self.AuraInspectorDurationInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorAuraInspectorDurationInput", {
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorDurationInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedAura(function(aura)
            aura.duration = math.max(1, tonumber(self.AuraInspectorDurationInput:GetText()) or 1)
        end)
    end)
    self.AuraInspectorDurationInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedAura(function(aura)
            aura.duration = math.max(1, tonumber(self.AuraInspectorDurationInput:GetText()) or 1)
        end)
    end)
    root:AddChild(self.AuraInspectorDurationInput)

    root:AddChild(self:BuildAuraInspectorLabel(root:GetFrame(), "RPEDataEditorAuraInspectorStackBehaviorLabel", "Stack Behavior"))
    self.AuraInspectorStackBehaviorDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorAuraInspectorStackBehaviorDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        items = self:GetAuraInspectorStackBehaviorItems(),
        onValueChanged = function(value)
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAura(function(aura)
                aura.stackBehavior = value == "independent_duration" and "independent_duration" or "refresh_duration"
            end)
        end,
    })
    root:AddChild(self.AuraInspectorStackBehaviorDropdown)

    root:AddChild(self:BuildAuraInspectorLabel(root:GetFrame(), "RPEDataEditorAuraInspectorMaxStacksLabel", "Max Stacks"))
    self.AuraInspectorMaxStacksInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorAuraInspectorMaxStacksInput", {
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorMaxStacksInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedAura(function(aura)
            aura.maxStacks = math.max(1, tonumber(self.AuraInspectorMaxStacksInput:GetText()) or 1)
        end)
    end)
    self.AuraInspectorMaxStacksInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedAura(function(aura)
            aura.maxStacks = math.max(1, tonumber(self.AuraInspectorMaxStacksInput:GetText()) or 1)
        end)
    end)
    root:AddChild(self.AuraInspectorMaxStacksInput)

    self.AuraInspectorAbsorbValidationText = UI.CreateText(root:GetFrame(), "RPEDataEditorAuraInspectorAbsorbValidationText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "warning"),
        width = self.AuraInspectorFieldWidth,
        height = 24,
        justifyH = "LEFT",
        wordWrap = true,
    })
    root:AddChild(self.AuraInspectorAbsorbValidationText)

    self.AuraInspectorTooltipTemplateStatusText = self:BuildAuraInspectorLabel(root:GetFrame(), "RPEDataEditorAuraInspectorTooltipTemplateLabel", "Tooltip Template")
    root:AddChild(self.AuraInspectorTooltipTemplateStatusText)

    self.AuraInspectorGenerateTooltipTemplateButton = UI.CreateButton(root:GetFrame(), "RPEDataEditorAuraInspectorGenerateTooltipTemplateButton", "Generate Template", 120, function()
        self:GenerateAuraTooltipTemplate()
    end)
    root:AddChild(self.AuraInspectorGenerateTooltipTemplateButton)
end

function DataEditor:GenerateAuraTooltipTemplate()
    local dataset, selectedAura = self:GetSelectedAuraAndDataset()
    if not dataset or not selectedAura then
        return
    end

    local AuraDescriptionBuilder = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.AuraDescriptionBuilder or nil
    if type(AuraDescriptionBuilder) ~= "table" or type(AuraDescriptionBuilder.BuildTooltipTemplatePayload) ~= "function" then
        logInternal("Aura template generate: aura=%s builder-missing=true", tostring(selectedAura and selectedAura.name or selectedAura and selectedAura.id or "unknown"))
        return
    end

    local auraRef = dataset.id and selectedAura.id and ("%s:%s"):format(dataset.id, selectedAura.id) or nil
    local payload = nil
    local generationSucceeded, generationError = pcall(function()
        payload = AuraDescriptionBuilder:BuildTooltipTemplatePayload(selectedAura, {
            auraRef = auraRef,
            dataset = dataset,
            datasetId = dataset.id,
            spellDatasetId = dataset.id,
        })
    end)
    local normalizedPayload = generationSucceeded
        and type(TooltipTemplate) == "table"
        and type(TooltipTemplate.NormalizeAuraPayload) == "function"
        and TooltipTemplate.NormalizeAuraPayload(payload)
        or nil
    local success = generationSucceeded and type(normalizedPayload) == "table"

    if success then
        logInternal(
            "Aura template generate: aura=%s %s",
            tostring(selectedAura.name or selectedAura.id or "unknown"),
            summarizeAuraTooltipPayload(normalizedPayload)
        )
    else
        logInternal(
            "Aura template generate FAILED: aura=%s generationSucceeded=%s error=%s",
            tostring(selectedAura.name or selectedAura.id or "unknown"),
            tostring(generationSucceeded),
            tostring(generationError or "")
        )
    end

    self:CommitSelectedAura(function(aura)
        aura.tooltipTemplate = success == true
        aura.tooltipTemplateData = success and normalizedPayload or nil
    end)

    local _, currentAura = self:GetSelectedAuraAndDataset()
    logInternal(
        "Aura template apply: aura=%s applied=%s hasPayload=%s",
        tostring(currentAura and currentAura.name or selectedAura.name or selectedAura.id or "unknown"),
        tostring(currentAura and currentAura.tooltipTemplate == true),
        tostring(hasStoredAuraTooltipTemplate(currentAura))
    )

    if self.AuraInspectorTooltipTemplateStatusText then
        if success and hasStoredAuraTooltipTemplate(currentAura) then
            self.AuraInspectorTooltipTemplateStatusText:SetText("Tooltip Template: Generated")
        elseif currentAura and currentAura.tooltipTemplate == true then
            self.AuraInspectorTooltipTemplateStatusText:SetText("Tooltip Template: Legacy Flag Only")
        else
            self.AuraInspectorTooltipTemplateStatusText:SetText("Tooltip Template: Failed to Generate")
        end
    end

    if type(self.RefreshAuraInspectorPage) == "function" then
        self:RefreshAuraInspectorPage()
    end
    if success and type(self.ApplyDeferredConfigurationPreview) == "function" then
        self:ApplyDeferredConfigurationPreview("aura-tooltip-template-generated", {
            dataset.id,
        })
    end
end
