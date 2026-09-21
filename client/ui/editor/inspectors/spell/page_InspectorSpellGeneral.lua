local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}
local TooltipTemplate = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.TooltipTemplate or nil
local Debug = Addon.Debug or {}
local SpellClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Spell or nil

local function normalizePositiveInteger(value)
    local numeric = tonumber(value)
    if numeric and numeric > 0 and numeric < math.huge and math.floor(numeric) == numeric then
        return numeric
    end

    return nil
end

local function commitLearningIntegerInput(editor, input, spellField, resolveValue, fallback)
    if not editor or not input or type(resolveValue) ~= "function" then
        return
    end

    local value = normalizePositiveInteger(input:GetText())
    if value then
        editor:CommitSelectedSpell(function(spell)
            spell[spellField] = value
        end)
    end

    local _, selectedSpell = editor:GetSelectedSpellAndDataset()
    local normalizedValue = selectedSpell and resolveValue(selectedSpell) or fallback
    input:SetText(tostring(normalizedValue or fallback))
end

local function hasStoredSpellTooltipTemplate(spell)
    if type(spell) ~= "table" then
        return false
    end

    if type(TooltipTemplate) == "table" and type(TooltipTemplate.NormalizeSpellPayload) == "function" then
        return type(TooltipTemplate.NormalizeSpellPayload(spell.tooltipTemplateData)) == "table"
    end

    return type(spell.tooltipTemplateData) == "table"
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

local function summarizeSpellTooltipPayload(payload)
    if type(payload) ~= "table" then
        return "payload=nil"
    end

    return ("main=%s tokens=%d auraSections=%d"):format(
        summarizeText(payload.mainText, 96),
        #(payload.tokens or {}),
        #(payload.auraSections or {})
    )
end

local function applyNormalizedDefinition(target, normalized)
    if type(target) ~= "table" or type(normalized) ~= "table" then
        return
    end

    for key in pairs(target) do
        if normalized[key] == nil then
            target[key] = nil
        end
    end
    for key, value in pairs(normalized) do
        target[key] = value
    end
end

function DataEditor:GenerateAuraTooltipTemplateForDefinition(dataset, aura, options)
    if type(dataset) ~= "table" or type(aura) ~= "table" then
        return false, nil, "missing-dataset-or-aura"
    end

    local AuraDescriptionBuilder = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.AuraDescriptionBuilder or nil
    if type(AuraDescriptionBuilder) ~= "table" or type(AuraDescriptionBuilder.BuildTooltipTemplatePayload) ~= "function" then
        if not (options and options.suppressFailureLog == true) then
            logInternal("Aura template generate FAILED: aura=%s error=builder-missing", tostring(aura.name or aura.id or "unknown"))
        end
        return false, nil, "builder-missing"
    end

    local auraRef = dataset.id and aura.id and ("%s:%s"):format(dataset.id, aura.id) or aura.id
    local payload = nil
    local generationSucceeded, generationError = pcall(function()
        payload = AuraDescriptionBuilder:BuildTooltipTemplatePayload(aura, {
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

    aura.tooltipTemplate = success == true
    aura.tooltipTemplateData = success and normalizedPayload or nil

    local normalizedAura = self:NormalizeAuraDefinition(aura)
    if type(normalizedAura) == "table" then
        applyNormalizedDefinition(aura, normalizedAura)
    end

    if success then
        if not (options and options.suppressSuccessLog == true) then
            logInternal(
                "Aura template generate: aura=%s body=%s",
                tostring(aura.name or aura.id or "unknown"),
                summarizeText(normalizedPayload.bodyText, 96)
            )
        end
        return true, normalizedPayload, nil
    end

    if not (options and options.suppressFailureLog == true) then
        logInternal(
            "Aura template generate FAILED: aura=%s generationSucceeded=%s error=%s",
            tostring(aura.name or aura.id or "unknown"),
            tostring(generationSucceeded),
            tostring(generationError or "")
        )
    end
    return false, nil, generationError
end

function DataEditor:GenerateSpellTooltipTemplateForDefinition(dataset, spell, options)
    if type(dataset) ~= "table" or type(spell) ~= "table" then
        return false, nil, "missing-dataset-or-spell", 0
    end

    local DescriptionBuilder = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.DescriptionBuilder or nil
    if type(DescriptionBuilder) ~= "table" or type(DescriptionBuilder.BuildTooltipTemplatePayload) ~= "function" then
        if not (options and options.suppressFailureLog == true) then
            logInternal("Spell template generate FAILED: spell=%s error=builder-missing", tostring(spell.name or spell.id or "unknown"))
        end
        return false, nil, "builder-missing", 0
    end

    local spellRef = dataset.id and spell.id and ("%s:%s"):format(dataset.id, spell.id) or nil
    local payload = nil
    local generationSucceeded, generationError = pcall(function()
        payload = DescriptionBuilder:BuildTooltipTemplatePayload({
            dataset = dataset,
            spellRef = spellRef,
            spell = spell,
        })
    end)
    local normalizedPayload = generationSucceeded
        and type(TooltipTemplate) == "table"
        and type(TooltipTemplate.NormalizeSpellPayload) == "function"
        and TooltipTemplate.NormalizeSpellPayload(payload)
        or nil
    local success = generationSucceeded and type(normalizedPayload) == "table"

    spell.tooltipTemplate = success == true
    spell.tooltipTemplateData = success and normalizedPayload or nil

    local normalizedSpell = self:NormalizeSpellDefinition(spell)
    if type(normalizedSpell) == "table" then
        applyNormalizedDefinition(spell, normalizedSpell)
    end

    local generatedAuraCount = 0
    if success and type(dataset.auras) == "table" then
        local seenAuras = {}
        for compIndex = 1, #(spell.components or {}) do
            local component = spell.components[compIndex]
            local effect = component and component.effect or nil
            local auraRef = effect and effect.auraRef or nil
            if auraRef and auraRef ~= "" and not seenAuras[auraRef] then
                seenAuras[auraRef] = true
                for auraIndex = 1, #dataset.auras do
                    local aura = dataset.auras[auraIndex]
                    if aura and aura.id == auraRef then
                        local auraSuccess = self:GenerateAuraTooltipTemplateForDefinition(dataset, aura, {
                            suppressSuccessLog = options and options.suppressAuraSuccessLog,
                            suppressFailureLog = options and options.suppressAuraFailureLog,
                        })
                        if auraSuccess then
                            generatedAuraCount = generatedAuraCount + 1
                        end
                        break
                    end
                end
            end
        end
    end

    if success then
        if not (options and options.suppressSuccessLog == true) then
            logInternal(
                "Spell template generate: spell=%s %s",
                tostring(spell.name or spell.id or "unknown"),
                summarizeSpellTooltipPayload(normalizedPayload)
            )
        end
        return true, normalizedPayload, nil, generatedAuraCount
    end

    if not (options and options.suppressFailureLog == true) then
        logInternal(
            "Spell template generate FAILED: spell=%s generationSucceeded=%s error=%s",
            tostring(spell.name or spell.id or "unknown"),
            tostring(generationSucceeded),
            tostring(generationError or "")
        )
    end
    return false, nil, generationError, 0
end

function DataEditor:RegenerateDatasetSpellTemplates(dataset)
    if type(dataset) ~= "table" or dataset.id == nil then
        return false, "missing-dataset"
    end

    local spells = dataset.spells or {}
    if type(spells) ~= "table" or #spells <= 0 then
        logInternal("Spell template batch: dataset=%s spells=0 generated=0 failed=0 auras=0", tostring(self:GetDatasetDisplayName(dataset)))
        return true
    end

    local generatedSpellCount = 0
    local failedSpellCount = 0
    local generatedAuraCount = 0

    for spellIndex = 1, #spells do
        local spell = spells[spellIndex]
        local success, _, generationError, auraCount = self:GenerateSpellTooltipTemplateForDefinition(dataset, spell, {
            suppressSuccessLog = true,
            suppressAuraSuccessLog = true,
        })
        if success then
            generatedSpellCount = generatedSpellCount + 1
            generatedAuraCount = generatedAuraCount + math.max(0, math.floor(tonumber(auraCount) or 0))
        else
            failedSpellCount = failedSpellCount + 1
            logInternal(
                "Spell template batch FAILED: dataset=%s spell=%s error=%s",
                tostring(self:GetDatasetDisplayName(dataset)),
                tostring(spell and spell.name or spell and spell.id or spellIndex),
                tostring(generationError or "")
            )
        end
    end

    self:QueuePendingDatasetEntryChanged(dataset.id, "spells", {
        changeCount = math.max(1, #spells),
    })
    if generatedAuraCount > 0 then
        self:QueuePendingDatasetEntryChanged(dataset.id, "auras", {
            changeCount = generatedAuraCount,
        })
    end

    if type(self.ApplyDeferredConfigurationPreview) == "function" then
        self:ApplyDeferredConfigurationPreview("dataset-spell-tooltip-templates-generated", {
            dataset.id,
        })
    end

    logInternal(
        "Spell template batch: dataset=%s spells=%d generated=%d failed=%d auras=%d",
        tostring(self:GetDatasetDisplayName(dataset)),
        #spells,
        generatedSpellCount,
        failedSpellCount,
        generatedAuraCount
    )

    return failedSpellCount <= 0, failedSpellCount > 0 and "spell-generation-failed" or nil
end

function DataEditor:RegenerateDatasetAuraTemplates(dataset)
    if type(dataset) ~= "table" or dataset.id == nil then
        return false, "missing-dataset"
    end

    local auras = dataset.auras or {}
    if type(auras) ~= "table" or #auras <= 0 then
        logInternal("Aura template batch: dataset=%s auras=0 generated=0 failed=0", tostring(self:GetDatasetDisplayName(dataset)))
        return true
    end

    local generatedAuraCount = 0
    local failedAuraCount = 0

    for auraIndex = 1, #auras do
        local aura = auras[auraIndex]
        local success, _, generationError = self:GenerateAuraTooltipTemplateForDefinition(dataset, aura, {
            suppressSuccessLog = true,
        })
        if success then
            generatedAuraCount = generatedAuraCount + 1
        else
            failedAuraCount = failedAuraCount + 1
            logInternal(
                "Aura template batch FAILED: dataset=%s aura=%s error=%s",
                tostring(self:GetDatasetDisplayName(dataset)),
                tostring(aura and aura.name or aura and aura.id or auraIndex),
                tostring(generationError or "")
            )
        end
    end

    self:QueuePendingDatasetEntryChanged(dataset.id, "auras", {
        changeCount = math.max(1, #auras),
    })

    if type(self.ApplyDeferredConfigurationPreview) == "function" then
        self:ApplyDeferredConfigurationPreview("dataset-aura-tooltip-templates-generated", {
            dataset.id,
        })
    end

    logInternal(
        "Aura template batch: dataset=%s auras=%d generated=%d failed=%d",
        tostring(self:GetDatasetDisplayName(dataset)),
        #auras,
        generatedAuraCount,
        failedAuraCount
    )

    return failedAuraCount <= 0, failedAuraCount > 0 and "aura-generation-failed" or nil
end

function DataEditor:BuildSpellInspectorGeneralPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorSpellInspectorGeneralLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorNameLabel", "Name"))
    self.SpellInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorSpellInspectorNameInput", {
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.SpellInspectorNameInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedSpell(function(spell)
            spell.name = self.SpellInspectorNameInput:GetText()
        end)
    end)
    self.SpellInspectorNameInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedSpell(function(spell)
            spell.name = self.SpellInspectorNameInput:GetText()
        end)
    end)
    root:AddChild(self.SpellInspectorNameInput)

    self.SpellInspectorIdText = UI.CreateText(root:GetFrame(), "RPEDataEditorSpellInspectorIdText", "ID: -", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = self.SpellInspectorFieldWidth,
        height = 12,
        justifyH = "LEFT",
    })
    root:AddChild(self.SpellInspectorIdText)

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorIconLabel", "Icon"))
    self.SpellInspectorIconField = UI.EditorIconField:New({
        name = "RPEDataEditorSpellInspectorIconField",
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        buttonText = "Select Icon",
        labelText = "-",
        iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
    })
    self.SpellInspectorIconField:SetParent(root:GetFrame())
    self.SpellInspectorIconField:Create()
    local iconButton = self.SpellInspectorIconField:GetButton()
    if iconButton and iconButton.SetScript then
        iconButton:SetScript("OnClick", function()
            local _, spell = self:GetSelectedSpellAndDataset()
            if not spell or not Client.OpenIconFinder then
                return
            end

            Client:OpenIconFinder(function(_, filePath)
                self:CommitSelectedSpell(function(selectedSpell)
                    selectedSpell.icon = filePath or ""
                end)
            end, {
                filter = spell.icon or "",
            })
        end)
    end
    root:AddChild(self.SpellInspectorIconField)

    self.SpellInspectorIconInput = {
        SetText = function(_, value)
            local iconPath = value ~= nil and tostring(value) or ""
            self.SpellInspectorIconField:SetIcon(iconPath ~= "" and iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
            self.SpellInspectorIconField:SetLabelText(iconPath ~= "" and iconPath or "-")
        end,
        SetEnabled = function(_, enabled)
            self.SpellInspectorIconField:SetEnabled(enabled)
        end,
        SetReadOnly = function(_, readOnly)
            self.SpellInspectorIconField:SetEnabled(readOnly ~= true)
        end,
    }

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorTagsLabel", "Tags"))
    self.SpellInspectorTagsInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorSpellInspectorTagsInput", {
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.SpellInspectorTagsInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedSpell(function(spell)
            spell.tags = UI.Utils.ParseCommaSeparatedList(self.SpellInspectorTagsInput:GetText())
        end)
    end)
    self.SpellInspectorTagsInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedSpell(function(spell)
            spell.tags = UI.Utils.ParseCommaSeparatedList(self.SpellInspectorTagsInput:GetText())
        end)
    end)
    root:AddChild(self.SpellInspectorTagsInput)

    self.SpellInspectorSeedNPCSpellCheckbox = self:CreateSpellInspectorCheckbox(root:GetFrame(), "RPEDataEditorSpellInspectorSeedNPCSpellCheckbox", "Seed NPC Spell", false, function(checked)
        self:CommitSelectedSpell(function(spell)
            spell.seedNPCSpell = checked == true
        end)
    end)
    root:AddChild(self.SpellInspectorSeedNPCSpellCheckbox)

    -- Tooltip Template Status Label
    self.SpellInspectorTooltipTemplateStatusText = self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorTooltipTemplateLabel", "Tooltip Template")
    root:AddChild(self.SpellInspectorTooltipTemplateStatusText)

    -- Tooltip Template Generation Button
    self.SpellInspectorGenerateTooltipTemplateButton = UI.CreateButton(root:GetFrame(), "RPEDataEditorSpellInspectorGenerateTooltipTemplateButton", "Generate Template", 120, function()
        self:GenerateSpellTooltipTemplate()
    end)
    root:AddChild(self.SpellInspectorGenerateTooltipTemplateButton)
end

function DataEditor:BuildSpellInspectorLearningPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorSpellInspectorLearningLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    self.SpellInspectorUsesRanksCheckbox = self:CreateSpellInspectorCheckbox(
        root:GetFrame(),
        "RPEDataEditorSpellInspectorUsesRanksCheckbox",
        "Uses Ranks",
        true,
        function(checked)
            if self._refreshingSpellInspector then
                return
            end

            self:CommitSelectedSpell(function(spell)
                spell.usesRanks = checked == true
            end)
            self:RefreshSpellInspectorPage()
        end
    )
    root:AddChild(self.SpellInspectorUsesRanksCheckbox)

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorLearnModeLabel", "Learn Mode"))
    self.SpellInspectorLearnModeDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorSpellInspectorLearnModeDropdown", {
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        items = self:GetSpellInspectorLearnModeItems(),
        onValueChanged = function(value)
            if self._refreshingSpellInspector then
                return
            end

            self:CommitSelectedSpell(function(spell)
                spell.learnMode = value or "trainer"
            end)
        end,
    })
    root:AddChild(self.SpellInspectorLearnModeDropdown)

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorSpellbookCategoryLabel", "Spellbook Category"))
    self.SpellInspectorSpellbookCategoryInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorSpellInspectorSpellbookCategoryInput", {
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.SpellInspectorSpellbookCategoryInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedSpell(function(spell)
            spell.spellbookCategory = self.SpellInspectorSpellbookCategoryInput:GetText()
        end)
    end)
    self.SpellInspectorSpellbookCategoryInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedSpell(function(spell)
            spell.spellbookCategory = self.SpellInspectorSpellbookCategoryInput:GetText()
        end)
    end)
    root:AddChild(self.SpellInspectorSpellbookCategoryInput)

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorLearnLevelLabel", "Learn Level"))
    self.SpellInspectorLearnLevelInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorSpellInspectorLearnLevelInput", {
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local learnLevelEditBox = self.SpellInspectorLearnLevelInput.GetEditBox and self.SpellInspectorLearnLevelInput:GetEditBox() or nil
    if learnLevelEditBox and learnLevelEditBox.SetNumeric then
        learnLevelEditBox:SetNumeric(true)
    end
    local function commitLearnLevel()
        commitLearningIntegerInput(self, self.SpellInspectorLearnLevelInput, "learnLevel",
            SpellClass and SpellClass.ResolveLearnLevel or nil, 1)
    end
    self.SpellInspectorLearnLevelInput:SetScript("OnEnterPressed", commitLearnLevel)
    self.SpellInspectorLearnLevelInput:SetScript("OnEditFocusLost", commitLearnLevel)
    root:AddChild(self.SpellInspectorLearnLevelInput)

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorRankIntervalLabel", "Rank Interval"))
    self.SpellInspectorRankIntervalInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorSpellInspectorRankIntervalInput", {
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        text = "8",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local rankIntervalEditBox = self.SpellInspectorRankIntervalInput.GetEditBox and self.SpellInspectorRankIntervalInput:GetEditBox() or nil
    if rankIntervalEditBox and rankIntervalEditBox.SetNumeric then
        rankIntervalEditBox:SetNumeric(true)
    end
    local function commitRankInterval()
        commitLearningIntegerInput(self, self.SpellInspectorRankIntervalInput, "rankInterval",
            SpellClass and SpellClass.ResolveRankInterval or nil, 8)
    end
    self.SpellInspectorRankIntervalInput:SetScript("OnEnterPressed", commitRankInterval)
    self.SpellInspectorRankIntervalInput:SetScript("OnEditFocusLost", commitRankInterval)
    root:AddChild(self.SpellInspectorRankIntervalInput)

    self.SpellInspectorLearningHintText = UI.CreateText(root:GetFrame(), "RPEDataEditorSpellInspectorLearningHintText", "Always Learned spells are added to the effective spellbook automatically.", {
        width = self.SpellInspectorFieldWidth,
        height = 38,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.SpellInspectorLearningHintText)

    self.SpellInspectorRankProgressionHintText = UI.CreateText(root:GetFrame(), "RPEDataEditorSpellInspectorRankProgressionHintText", "Rank 1 is learned at Learn Level. A new rank is gained every Rank Interval levels.", {
        width = self.SpellInspectorFieldWidth,
        height = 38,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.SpellInspectorRankProgressionHintText)
end

function DataEditor:GenerateSpellTooltipTemplate()
    local dataset, selectedSpell = self:GetSelectedSpellAndDataset()
    if not dataset or not selectedSpell then
        return
    end

    local success, _, _, generatedAuraCount = self:GenerateSpellTooltipTemplateForDefinition(dataset, selectedSpell)
    self:QueuePendingDatasetEntryChanged(dataset.id, "spells")
    if math.max(0, math.floor(tonumber(generatedAuraCount) or 0)) > 0 then
        self:QueuePendingDatasetEntryChanged(dataset.id, "auras", {
            changeCount = generatedAuraCount,
        })
    end

    local _, currentSpell = self:GetSelectedSpellAndDataset()
    logInternal(
        "Spell template apply: spell=%s applied=%s hasPayload=%s",
        tostring(currentSpell and currentSpell.name or selectedSpell.name or selectedSpell.id or "unknown"),
        tostring(currentSpell and currentSpell.tooltipTemplate == true),
        tostring(hasStoredSpellTooltipTemplate(currentSpell))
    )

    if self.SpellInspectorTooltipTemplateStatusText then
        if success and hasStoredSpellTooltipTemplate(currentSpell) then
            self.SpellInspectorTooltipTemplateStatusText:SetText("Tooltip Template: Generated")
        elseif currentSpell and currentSpell.tooltipTemplate == true then
            self.SpellInspectorTooltipTemplateStatusText:SetText("Tooltip Template: Legacy Flag Only")
        else
            self.SpellInspectorTooltipTemplateStatusText:SetText("Tooltip Template: Failed to Generate")
        end
    end

    if type(self.RefreshSpellInspectorPage) == "function" then
        self:RefreshSpellInspectorPage()
    end
    if success and type(self.ApplyDeferredConfigurationPreview) == "function" then
        self:ApplyDeferredConfigurationPreview("spell-tooltip-template-generated", {
            dataset.id,
        })
    end
end
