local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local TooltipTemplate = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.TooltipTemplate or nil

local function hasStoredSpellTooltipTemplate(spell)
    if type(spell) ~= "table" then
        return false
    end

    if type(TooltipTemplate) == "table" and type(TooltipTemplate.NormalizeSpellPayload) == "function" then
        return type(TooltipTemplate.NormalizeSpellPayload(spell.tooltipTemplateData)) == "table"
    end

    return type(spell.tooltipTemplateData) == "table"
end

local function displayNumber(value)
    local numericValue = tonumber(value) or 0
    if math.abs(numericValue) < 0.000001 then
        numericValue = 0
    end

    return tostring(numericValue)
end

function DataEditor:BuildSpellInspectorPage(parent)
    if self.SpellInspectorPage then
        self:RefreshSpellInspectorPage()
        return self.SpellInspectorPage
    end

    self.SpellInspectorPage = CreateFrame("Frame", "RPEDataEditorSpellInspectorPage", parent)

    self.SpellInspectorSelectorBar = UI.CreateLayout(UI.HorizontalLayoutGroup, self.SpellInspectorPage, "RPEDataEditorSpellInspectorSelectorBar", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 20,
    })
    self.SpellInspectorSelectorBar:GetFrame():SetPoint("TOPLEFT", self.SpellInspectorPage, "TOPLEFT", 0, 0)
    self.SpellInspectorSelectorBar:GetFrame():SetPoint("TOPRIGHT", self.SpellInspectorPage, "TOPRIGHT", 0, 0)

    self.SpellInspectorPreviousButton = UI.CreateButton(self.SpellInspectorSelectorBar:GetFrame(), "RPEDataEditorSpellInspectorPreviousButton", "Prev", 40, function()
        self:SetSpellInspectorTab((self:GetSpellInspectorPageDefinitions()[(self.ActiveSpellInspectorPageIndex or 1) - 1] or {}).key or "general")
    end, {
        height = 20,
        fontSize = 7,
    })
    self.SpellInspectorSelectorBar:AddChild(self.SpellInspectorPreviousButton)

    self.SpellInspectorPageDropdown = UI.CreateDropdown(self.SpellInspectorSelectorBar:GetFrame(), "RPEDataEditorSpellInspectorPageDropdown", {
        width = 118,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = self:BuildSpellInspectorPageSelectorItems(),
        onValueChanged = function(value)
            if self._refreshingSpellInspectorPageSelector then
                return
            end

            self:SetSpellInspectorTab(value)
        end,
    })
    self.SpellInspectorSelectorBar:AddChild(self.SpellInspectorPageDropdown)

    self.SpellInspectorNextButton = UI.CreateButton(self.SpellInspectorSelectorBar:GetFrame(), "RPEDataEditorSpellInspectorNextButton", "Next", 40, function()
        self:SetSpellInspectorTab((self:GetSpellInspectorPageDefinitions()[(self.ActiveSpellInspectorPageIndex or 1) + 1] or {}).key or "conditions")
    end, {
        height = 20,
        fontSize = 7,
    })
    self.SpellInspectorSelectorBar:AddChild(self.SpellInspectorNextButton)

    self.SpellInspectorGeneralPage = CreateFrame("Frame", "RPEDataEditorSpellInspectorGeneralPage", self.SpellInspectorPage)
    self.SpellInspectorGeneralPage:SetPoint("TOPLEFT", self.SpellInspectorPage, "TOPLEFT", self.SpellInspectorSidePadding, -24)
    self.SpellInspectorGeneralPage:SetPoint("TOPRIGHT", self.SpellInspectorPage, "TOPRIGHT", -self.SpellInspectorSidePadding, -24)
    self.SpellInspectorGeneralPage:SetPoint("BOTTOMLEFT", self.SpellInspectorPage, "BOTTOMLEFT", self.SpellInspectorSidePadding, 24)
    self.SpellInspectorGeneralPage:SetPoint("BOTTOMRIGHT", self.SpellInspectorPage, "BOTTOMRIGHT", -self.SpellInspectorSidePadding, 24)
    self:BuildSpellInspectorGeneralPage(self.SpellInspectorGeneralPage)

    self.SpellInspectorLearningPage = CreateFrame("Frame", "RPEDataEditorSpellInspectorLearningPage", self.SpellInspectorPage)
    self.SpellInspectorLearningPage:SetPoint("TOPLEFT", self.SpellInspectorPage, "TOPLEFT", self.SpellInspectorSidePadding, -24)
    self.SpellInspectorLearningPage:SetPoint("TOPRIGHT", self.SpellInspectorPage, "TOPRIGHT", -self.SpellInspectorSidePadding, -24)
    self.SpellInspectorLearningPage:SetPoint("BOTTOMLEFT", self.SpellInspectorPage, "BOTTOMLEFT", self.SpellInspectorSidePadding, 24)
    self.SpellInspectorLearningPage:SetPoint("BOTTOMRIGHT", self.SpellInspectorPage, "BOTTOMRIGHT", -self.SpellInspectorSidePadding, 24)
    self:BuildSpellInspectorLearningPage(self.SpellInspectorLearningPage)

    self.SpellInspectorCastingPage = CreateFrame("Frame", "RPEDataEditorSpellInspectorCastingPage", self.SpellInspectorPage)
    self.SpellInspectorCastingPage:SetPoint("TOPLEFT", self.SpellInspectorPage, "TOPLEFT", self.SpellInspectorSidePadding, -24)
    self.SpellInspectorCastingPage:SetPoint("TOPRIGHT", self.SpellInspectorPage, "TOPRIGHT", -self.SpellInspectorSidePadding, -24)
    self.SpellInspectorCastingPage:SetPoint("BOTTOMLEFT", self.SpellInspectorPage, "BOTTOMLEFT", self.SpellInspectorSidePadding, 24)
    self.SpellInspectorCastingPage:SetPoint("BOTTOMRIGHT", self.SpellInspectorPage, "BOTTOMRIGHT", -self.SpellInspectorSidePadding, 24)
    self:BuildSpellInspectorCastingPage(self.SpellInspectorCastingPage)

    self.SpellInspectorCooldownPage = CreateFrame("Frame", "RPEDataEditorSpellInspectorCooldownPage", self.SpellInspectorPage)
    self.SpellInspectorCooldownPage:SetPoint("TOPLEFT", self.SpellInspectorPage, "TOPLEFT", self.SpellInspectorSidePadding, -24)
    self.SpellInspectorCooldownPage:SetPoint("TOPRIGHT", self.SpellInspectorPage, "TOPRIGHT", -self.SpellInspectorSidePadding, -24)
    self.SpellInspectorCooldownPage:SetPoint("BOTTOMLEFT", self.SpellInspectorPage, "BOTTOMLEFT", self.SpellInspectorSidePadding, 24)
    self.SpellInspectorCooldownPage:SetPoint("BOTTOMRIGHT", self.SpellInspectorPage, "BOTTOMRIGHT", -self.SpellInspectorSidePadding, 24)
    self:BuildSpellInspectorCooldownPage(self.SpellInspectorCooldownPage)

    self.SpellInspectorCostPage = CreateFrame("Frame", "RPEDataEditorSpellInspectorCostPage", self.SpellInspectorPage)
    self.SpellInspectorCostPage:SetPoint("TOPLEFT", self.SpellInspectorPage, "TOPLEFT", self.SpellInspectorSidePadding, -24)
    self.SpellInspectorCostPage:SetPoint("TOPRIGHT", self.SpellInspectorPage, "TOPRIGHT", -self.SpellInspectorSidePadding, -24)
    self.SpellInspectorCostPage:SetPoint("BOTTOMLEFT", self.SpellInspectorPage, "BOTTOMLEFT", self.SpellInspectorSidePadding, 24)
    self.SpellInspectorCostPage:SetPoint("BOTTOMRIGHT", self.SpellInspectorPage, "BOTTOMRIGHT", -self.SpellInspectorSidePadding, 24)
    self:BuildSpellInspectorCostPage(self.SpellInspectorCostPage)

    self.SpellInspectorConditionsPage = CreateFrame("Frame", "RPEDataEditorSpellInspectorConditionsPage", self.SpellInspectorPage)
    self.SpellInspectorConditionsPage:SetPoint("TOPLEFT", self.SpellInspectorPage, "TOPLEFT", self.SpellInspectorSidePadding, -24)
    self.SpellInspectorConditionsPage:SetPoint("TOPRIGHT", self.SpellInspectorPage, "TOPRIGHT", -self.SpellInspectorSidePadding, -24)
    self.SpellInspectorConditionsPage:SetPoint("BOTTOMLEFT", self.SpellInspectorPage, "BOTTOMLEFT", self.SpellInspectorSidePadding, 24)
    self.SpellInspectorConditionsPage:SetPoint("BOTTOMRIGHT", self.SpellInspectorPage, "BOTTOMRIGHT", -self.SpellInspectorSidePadding, 24)
    self:BuildSpellInspectorConditionsPage(self.SpellInspectorConditionsPage)

    self.SpellInspectorComponentsPage = CreateFrame("Frame", "RPEDataEditorSpellInspectorComponentsPage", self.SpellInspectorPage)
    self.SpellInspectorComponentsPage:SetPoint("TOPLEFT", self.SpellInspectorPage, "TOPLEFT", self.SpellInspectorSidePadding, -24)
    self.SpellInspectorComponentsPage:SetPoint("TOPRIGHT", self.SpellInspectorPage, "TOPRIGHT", -self.SpellInspectorSidePadding, -24)
    self.SpellInspectorComponentsPage:SetPoint("BOTTOMLEFT", self.SpellInspectorPage, "BOTTOMLEFT", self.SpellInspectorSidePadding, 24)
    self.SpellInspectorComponentsPage:SetPoint("BOTTOMRIGHT", self.SpellInspectorPage, "BOTTOMRIGHT", -self.SpellInspectorSidePadding, 24)
    self:BuildSpellInspectorComponentsPage(self.SpellInspectorComponentsPage)

    self.SpellInspectorEmptyText = UI.CreateText(self.SpellInspectorPage, "RPEDataEditorSpellInspectorEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = self.SpellInspectorFieldWidth,
        height = 20,
        justifyH = "LEFT",
    })
    self.SpellInspectorEmptyText:GetFrame():SetPoint("BOTTOMLEFT", self.SpellInspectorPage, "BOTTOMLEFT", 0, 0)

    self.ActiveSpellInspectorPageIndex = self.ActiveSpellInspectorPageIndex or self:GetSpellInspectorPageIndexByKey(self.ActiveSpellInspectorTabKey or "general")
    self:SetSpellInspectorTab("general")
    self:RefreshSpellInspectorPage()
    return self.SpellInspectorPage
end

function DataEditor:RefreshSpellInspectorPage()
    local _, spell = self:GetSelectedSpellAndDataset()
    local hasSpell = spell ~= nil
    local activeTabKey = self.ActiveSpellInspectorTabKey or "general"
    local shouldRefreshConditions = activeTabKey == "conditions"
    local shouldRefreshCost = activeTabKey == "cost"
    local shouldRefreshComponents = activeTabKey == "components"

    self._refreshingSpellInspector = true

    if self.SpellInspectorNameInput then
        self.SpellInspectorNameInput:SetText(spell and (spell.name or "") or "")
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorNameInput, hasSpell)
    end
    if self.SpellInspectorIdText then
        self.SpellInspectorIdText:SetText(("ID: %s"):format(spell and spell.id ~= nil and tostring(spell.id) or "-"))
    end
    if self.SpellInspectorIconInput then
        self.SpellInspectorIconInput:SetText(spell and (spell.icon or "") or "")
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorIconInput, hasSpell)
    end
    if self.SpellInspectorTagsInput then
        self.SpellInspectorTagsInput:SetText(UI.Utils.JoinCommaSeparatedList(spell and spell.tags or nil))
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorTagsInput, hasSpell)
    end
    if self.SpellInspectorSeedNPCSpellCheckbox then
        self.SpellInspectorSeedNPCSpellCheckbox:SetChecked(spell and spell.seedNPCSpell == true or false, true)
        self:SetSpellInspectorCheckboxEnabled(self.SpellInspectorSeedNPCSpellCheckbox, hasSpell)
    end
    if self.SpellInspectorLearnModeDropdown then
        self.SpellInspectorLearnModeDropdown:SetItems(self:GetSpellInspectorLearnModeItems())
        self.SpellInspectorLearnModeDropdown:SetSelectedValue(spell and spell.learnMode or "trainer", true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorLearnModeDropdown, hasSpell)
    end
    if self.SpellInspectorSpellbookCategoryInput then
        self.SpellInspectorSpellbookCategoryInput:SetText(spell and (spell.spellbookCategory or "") or "")
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorSpellbookCategoryInput, hasSpell)
    end
    if self.SpellInspectorTooltipTemplateStatusText then
        local hasStoredTemplate = hasStoredSpellTooltipTemplate(spell)
        if hasStoredTemplate then
            self.SpellInspectorTooltipTemplateStatusText:SetText("Tooltip Template: Generated")
        elseif spell and spell.tooltipTemplate == true then
            self.SpellInspectorTooltipTemplateStatusText:SetText("Tooltip Template: Legacy Flag Only")
        else
            self.SpellInspectorTooltipTemplateStatusText:SetText("Tooltip Template: Not Generated")
        end
    end
    if self.SpellInspectorGenerateTooltipTemplateButton then
        self.SpellInspectorGenerateTooltipTemplateButton:SetEnabled(hasSpell)
    end

    if self.SpellInspectorCastTimeSlider then
        self.SpellInspectorCastTimeSlider:SetValue(spell and spell.castTime or 0, true)
        self:SetSpellInspectorSliderEnabled(self.SpellInspectorCastTimeSlider, hasSpell)
    end
    if self.SpellInspectorCooldownSlider then
        self.SpellInspectorCooldownSlider:SetValue(spell and spell.cooldown or 1, true)
        self:SetSpellInspectorSliderEnabled(self.SpellInspectorCooldownSlider, hasSpell)
    end
    if self.SpellInspectorChargesInput then
        self.SpellInspectorChargesInput:SetText(tostring(spell and spell.charges or 0))
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorChargesInput, hasSpell and spell and spell.useCooldownCharges == true)
    end
    if self.SpellInspectorUseCooldownChargesCheckbox then
        self.SpellInspectorUseCooldownChargesCheckbox:SetChecked(spell and spell.useCooldownCharges == true or false, true)
        self:SetSpellInspectorCheckboxEnabled(self.SpellInspectorUseCooldownChargesCheckbox, hasSpell)
    end
    if self.SpellInspectorCooldownGroupInput then
        self.SpellInspectorCooldownGroupInput:SetText(spell and (spell.cooldownGroup or "") or "")
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorCooldownGroupInput, hasSpell)
    end
    if self.SpellInspectorCooldownChannelDropdown then
        local channelItems, effectiveChannelId = self:BuildSpellInspectorCooldownChannelItems(spell)
        self.SpellInspectorCooldownChannelDropdown:SetItems(channelItems)
        self.SpellInspectorCooldownChannelDropdown:SetSelectedValue(effectiveChannelId, true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorCooldownChannelDropdown, hasSpell and effectiveChannelId ~= nil)
    end
    if self.SpellInspectorMountedCombatOnlyCheckbox then
        self.SpellInspectorMountedCombatOnlyCheckbox:SetChecked(spell and spell.mountedCombatOnly == true or false, true)
        self:SetSpellInspectorCheckboxEnabled(self.SpellInspectorMountedCombatOnlyCheckbox, hasSpell)
    end
    if self.SpellInspectorAllowDeadTargetsCheckbox then
        self.SpellInspectorAllowDeadTargetsCheckbox:SetChecked(spell and spell.allowDeadTargets == true or false, true)
        self:SetSpellInspectorCheckboxEnabled(self.SpellInspectorAllowDeadTargetsCheckbox, hasSpell)
    end
    if self.SpellInspectorCanTargetHiddenUnitsCheckbox then
        self.SpellInspectorCanTargetHiddenUnitsCheckbox:SetChecked(spell and spell.canTargetHiddenUnits == true or false, true)
        self:SetSpellInspectorCheckboxEnabled(self.SpellInspectorCanTargetHiddenUnitsCheckbox, hasSpell)
    end
    if self.SpellInspectorDoesNotRevealCasterCheckbox then
        self.SpellInspectorDoesNotRevealCasterCheckbox:SetChecked(spell and spell.doesNotRevealCaster == true or false, true)
        self:SetSpellInspectorCheckboxEnabled(self.SpellInspectorDoesNotRevealCasterCheckbox, hasSpell)
    end
    if self.SpellInspectorPendingResourceRefDropdown then
        self.SpellInspectorPendingResourceRefDropdown:SetItems(self:BuildSpellInspectorResourcesAcrossDatasets())
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorPendingResourceRefDropdown, hasSpell)
    end
    if self.SpellInspectorPendingResourceCastPhaseDropdown then
        self.SpellInspectorPendingResourceCastPhaseDropdown:SetSelectedValue("on_cast_end", true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorPendingResourceCastPhaseDropdown, hasSpell)
    end
    if self.SpellInspectorPendingResourceAmountModeDropdown then
        self.SpellInspectorPendingResourceAmountModeDropdown:SetSelectedValue("flat", true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorPendingResourceAmountModeDropdown, hasSpell)
    end
    if self.SpellInspectorPendingResourceAmountInput then
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorPendingResourceAmountInput, hasSpell)
    end
    if self.SpellInspectorAddResourceCostButton then
        self.SpellInspectorAddResourceCostButton:SetEnabled(hasSpell)
    end

    if shouldRefreshConditions then
        self:RefreshSpellInspectorConditionsPage()
    end
    if shouldRefreshComponents then
        self:RefreshSpellInspectorComponentsTable()
    end

    local component = self:GetSelectedSpellInspectorComponent()
    local target = component and component.target or {}
    local effect = component and component.effect or {}
    local effectType = effect and tostring(effect.type or "damage") or "damage"
    local isDamage = effectType == "damage"
    local isHeal = effectType == "heal"
    local isApplyAura = effectType == "apply_aura"
    local isRemoveAura = effectType == "remove_aura"
    local isRemoveAuraByTag = effectType == "remove_aura_by_tag"
    local isRemoveAuraTag = isRemoveAuraByTag or (isRemoveAura and tostring(effect.match or "aura") == "tag")
    local isRemoveAuraExact = isRemoveAura and not isRemoveAuraTag
    local isResource = effectType == "resource"
    local isTaunt = effectType == "taunt"
    local isSummonPet = effectType == "summon_pet"
    local targetType = tostring(target.type or "single")
    local isPetTarget = targetType == "pet"
    local isLastAttackersTarget = targetType == "last_attackers"
    local isLastMeleeAttackerTarget = targetType == "last_melee_attacker"
    local isAllAlliesTarget = targetType == "all_allies"
    local isMultiTarget = targetType == "multi"
    local isMinTargetCountEditable = isMultiTarget or targetType == "all_allies" or targetType == "raid_marker"
    local isMaxTargetCountEditable = isMultiTarget or targetType == "raid_marker"
    local supportsScaling = isDamage or isHeal
    local supportsLegacyAuraApplication = isDamage or isHeal
    local showsAuraApplicationControls = isApplyAura or isRemoveAuraExact or (supportsLegacyAuraApplication and effect.applyAura == true)
    local isCasterTarget = targetType == "caster"
    local supportsTargetSelection = component ~= nil and not isCasterTarget and not isSummonPet and not isPetTarget

    if shouldRefreshCost then
        self:RefreshSpellInspectorResourceCostsTable()
    end
    if shouldRefreshComponents then
        self:RefreshSpellInspectorScalingTable()
    end
    if shouldRefreshComponents and self.RefreshSpellInspectorComponentsScrollBounds then
        self:RefreshSpellInspectorComponentsScrollBounds()
    end

    if self.SpellInspectorComponentPhaseDropdown then
        self.SpellInspectorComponentPhaseDropdown:SetSelectedValue(component and component.castPhase or "on_cast_end", true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorComponentPhaseDropdown, component ~= nil)
    end
    if self.SpellInspectorComponentCastingGroupText then
        self.SpellInspectorComponentCastingGroupText:SetText(
            component and self:GetAutomaticSpellInspectorCastingGroupLabel(component) or "-"
        )
    end
    if self.SpellInspectorComponentTargetTypeDropdown then
        local effectiveTargetType = isSummonPet and "caster" or targetType
        self.SpellInspectorComponentTargetTypeDropdown:SetSelectedValue(effectiveTargetType, true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorComponentTargetTypeDropdown, component ~= nil and not isSummonPet)
    end
    if self.SpellInspectorComponentRequiresTargetCheckbox then
        self.SpellInspectorComponentRequiresTargetCheckbox:SetChecked((isSummonPet or isPetTarget) and false or target.requiresTarget == true, true)
        self:SetSpellInspectorCheckboxEnabled(self.SpellInspectorComponentRequiresTargetCheckbox, supportsTargetSelection)
    end
    if self.SpellInspectorComponentDisableSelfCastCheckbox then
        self.SpellInspectorComponentDisableSelfCastCheckbox:SetChecked(target.disableSelfCast == true, true)
        self:SetSpellInspectorCheckboxEnabled(self.SpellInspectorComponentDisableSelfCastCheckbox, supportsTargetSelection)
    end
    if self.SpellInspectorComponentTargetDispositionDropdown then
        self.SpellInspectorComponentTargetDispositionDropdown:SetSelectedValue((isSummonPet or isPetTarget) and "ally" or target.targetDisposition or "enemy", true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorComponentTargetDispositionDropdown, supportsTargetSelection and not isLastAttackersTarget and not isLastMeleeAttackerTarget and not isAllAlliesTarget)
    end
    if self.SpellInspectorComponentMinTargetsInput then
        self.SpellInspectorComponentMinTargetsInput:SetText(tostring((isSummonPet or isPetTarget or isLastAttackersTarget or isLastMeleeAttackerTarget) and 1 or target.minTargets or 0))
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorComponentMinTargetsInput, supportsTargetSelection and isMinTargetCountEditable)
    end
    if self.SpellInspectorComponentMaxTargetsInput then
        self.SpellInspectorComponentMaxTargetsInput:SetText(isAllAlliesTarget
            and "All"
            or tostring((isSummonPet or isPetTarget or isLastAttackersTarget or isLastMeleeAttackerTarget) and 1 or target.maxTargets or 0))
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorComponentMaxTargetsInput, supportsTargetSelection and isMaxTargetCountEditable)
    end
    if self.SpellInspectorEffectTypeDropdown then
        self.SpellInspectorEffectTypeDropdown:SetSelectedValue(effectType, true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorEffectTypeDropdown, component ~= nil)
    end
    if self.SpellInspectorBaseDamageInput then
        self.SpellInspectorBaseDamageInput:SetText(displayNumber(effect.baseDamage or 0))
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorBaseDamageInput, isDamage and component ~= nil)
    end
    if self.SpellInspectorThreatCoefficientInput then
        self.SpellInspectorThreatCoefficientInput:SetText(displayNumber(effect.threatCoefficient or 1))
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorThreatCoefficientInput, isDamage and component ~= nil)
    end
    if self.SpellInspectorBaseHealingInput then
        self.SpellInspectorBaseHealingInput:SetText(displayNumber(effect.baseHealing or 0))
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorBaseHealingInput, isHeal and component ~= nil)
    end
    if self.SpellInspectorBasePowerInput then
        self.SpellInspectorBasePowerInput:SetText(displayNumber(effect.basePower or 0))
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorBasePowerInput, isApplyAura and component ~= nil)
    end
    if self.SpellInspectorWeaponDamageModeDropdown then
        self.SpellInspectorWeaponDamageModeDropdown:SetSelectedValue(effect.weaponDamageMode or "none", true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorWeaponDamageModeDropdown, isDamage and component ~= nil)
    end
    if self.SpellInspectorWeaponDamageCoefficientInput then
        self.SpellInspectorWeaponDamageCoefficientInput:SetText(displayNumber(effect.weaponDamageCoefficient or 1))
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorWeaponDamageCoefficientInput, isDamage and component ~= nil)
    end
    if self.SpellInspectorDamageSchoolsDropdown then
        self.SpellInspectorDamageSchoolsDropdown:SetItems(self:BuildSpellInspectorDamageSchoolsAcrossDatasets())
        self.SpellInspectorDamageSchoolsDropdown:SetSelectedValues(effect.damageSchoolRefs or {}, true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorDamageSchoolsDropdown, isDamage and component ~= nil)
    end
    if self.SpellInspectorAuraDropdown then
        self.SpellInspectorAuraDropdown:SetItems(self:BuildSpellInspectorAurasAcrossDatasets())
        self.SpellInspectorAuraDropdown:SetSelectedValue(effect.auraRef or "", true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorAuraDropdown, showsAuraApplicationControls and component ~= nil)
    end
    if self.SpellInspectorRemoveAuraMatchDropdown then
        self.SpellInspectorRemoveAuraMatchDropdown:SetSelectedValue("aura", true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorRemoveAuraMatchDropdown, component ~= nil and isRemoveAura)
    end
    if self.SpellInspectorRemoveAuraTagInput then
        local tagText = isRemoveAuraByTag
            and table.concat(effect.tags or {}, ", ")
            or (isRemoveAuraTag and tostring(effect.tag or "") or "")
        self.SpellInspectorRemoveAuraTagInput:SetText(tagText)
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorRemoveAuraTagInput, component ~= nil and isRemoveAuraTag)
    end
    if self.SpellInspectorRemoveAuraMaxAurasInput then
        self.SpellInspectorRemoveAuraMaxAurasInput:SetText(isRemoveAuraTag and tostring(effect.maxAuras or "") or "")
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorRemoveAuraMaxAurasInput, component ~= nil and isRemoveAuraTag)
    end
    if self.SpellInspectorResourceEffectDropdown then
        self.SpellInspectorResourceEffectDropdown:SetItems(self:BuildSpellInspectorResourcesAcrossDatasets())
        self.SpellInspectorResourceEffectDropdown:SetSelectedValue(effect.resourceRef or "", true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorResourceEffectDropdown, isResource and component ~= nil)
    end
    if self.SpellInspectorResourceAmountModeDropdown then
        self.SpellInspectorResourceAmountModeDropdown:SetSelectedValue(effect.amountMode or "flat", true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorResourceAmountModeDropdown, isResource and component ~= nil)
    end
    if self.SpellInspectorSummonPetUnitDropdown then
        self.SpellInspectorSummonPetUnitDropdown:SetItems(self:BuildSpellInspectorUnitsAcrossDatasets())
        self.SpellInspectorSummonPetUnitDropdown:SetSelectedValue(effect.unitRef or "", true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorSummonPetUnitDropdown, isSummonPet and component ~= nil)
    end
    if self.SpellInspectorHitTypeDropdown then
        self.SpellInspectorHitTypeDropdown:SetSelectedValue(effect.hitType or "ability", true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorHitTypeDropdown, isDamage and component ~= nil)
    end
    if self.SpellInspectorDamageTypeDropdown then
        self.SpellInspectorDamageTypeDropdown:SetSelectedValue(effect.damageType or "spell", true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorDamageTypeDropdown, isDamage and component ~= nil)
    end
    if self.SpellInspectorPendingScalingStatDropdown then
        self.SpellInspectorPendingScalingStatDropdown:SetItems(self:BuildSpellInspectorStatsAcrossDatasets())
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorPendingScalingStatDropdown, supportsScaling and component ~= nil)
    end
    if self.SpellInspectorPendingScalingCoefficientInput then
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorPendingScalingCoefficientInput, supportsScaling and component ~= nil)
    end
    if self.SpellInspectorAddScalingButton then
        self.SpellInspectorAddScalingButton:SetEnabled(supportsScaling and component ~= nil)
    end
    if self.SpellInspectorApplyAuraCheckbox then
        self.SpellInspectorApplyAuraCheckbox:SetChecked(effect.applyAura == true, true)
        self:SetSpellInspectorCheckboxEnabled(self.SpellInspectorApplyAuraCheckbox, supportsLegacyAuraApplication and component ~= nil)
        self:SetSpellInspectorGroupVisible(self.SpellInspectorApplyAuraCheckbox, supportsLegacyAuraApplication)
    end
    if self.SpellInspectorAlwaysHitsCheckbox then
        self.SpellInspectorAlwaysHitsCheckbox:SetChecked(effect.alwaysHits == true, true)
        self:SetSpellInspectorCheckboxEnabled(self.SpellInspectorAlwaysHitsCheckbox, isDamage and component ~= nil)
        self:SetSpellInspectorGroupVisible(self.SpellInspectorAlwaysHitsCheckbox, isDamage)
    end
    if self.SpellInspectorAuraStacksInput then
        self.SpellInspectorAuraStacksInput:SetText(tostring(effect.stacks or effect.auraStacks or 1))
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorAuraStacksInput, showsAuraApplicationControls and component ~= nil)
    end
    if self.SpellInspectorApplyAuraDurationInput then
        self.SpellInspectorApplyAuraDurationInput:SetText(tostring(effect.duration or 12))
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorApplyAuraDurationInput, isApplyAura and component ~= nil)
    end
    if self.SpellInspectorTauntDurationInput then
        self.SpellInspectorTauntDurationInput:SetText(tostring(effect.duration or 2))
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorTauntDurationInput, isTaunt and component ~= nil)
    end
    if self.SpellInspectorResourceAmountInput then
        self.SpellInspectorResourceAmountInput:SetText(tostring(effect.amount or 0))
        self:SetSpellInspectorTextElementEnabled(self.SpellInspectorResourceAmountInput, isResource and component ~= nil)
    end
    if self.SpellInspectorCasterEventsDropdown then
        self.SpellInspectorCasterEventsDropdown:SetSelectedValues(spell and spell.casterEvents or {}, true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorCasterEventsDropdown, spell ~= nil)
    end
    if self.SpellInspectorTargetEventsDropdown then
        self.SpellInspectorTargetEventsDropdown:SetSelectedValues(effect.targetEvents or {}, true)
        self:SetSpellInspectorDropdownEnabled(self.SpellInspectorTargetEventsDropdown, component ~= nil and not isSummonPet)
    end

    self:SetSpellInspectorGroupVisible(self.SpellInspectorBaseDamageGroup, isDamage)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorBaseHealingGroup, isHeal)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorBasePowerGroup, isApplyAura)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorWeaponDamageModeGroup, isDamage)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorScalingGroup, supportsScaling)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorDamageSchoolsGroup, isDamage)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorAuraGroup, showsAuraApplicationControls)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorRemoveAuraMatchGroup, isRemoveAura)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorRemoveAuraTagGroup, isRemoveAuraTag)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorRemoveAuraMaxAurasGroup, isRemoveAuraTag)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorResourceEffectGroup, isResource)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorSummonPetUnitGroup, isSummonPet)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorHitTypeGroup, isDamage)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorDamageTypeGroup, isDamage)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorAuraStacksGroup, showsAuraApplicationControls)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorApplyAuraDurationGroup, isApplyAura)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorTauntDurationGroup, isTaunt)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorResourceAmountGroup, isResource)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorResourceAmountModeGroup, isResource)
    self:SetSpellInspectorGroupVisible(self.SpellInspectorTargetEventsGroup, not isSummonPet)
    if self.SpellInspectorComponentsRoot and self.SpellInspectorComponentsRoot.RefreshLayout then
        self.SpellInspectorComponentsRoot:RefreshLayout()
    end
    if self.RefreshSpellInspectorComponentsScrollBounds then
        self:RefreshSpellInspectorComponentsScrollBounds()
    end

    self._refreshingSpellInspector = false

    if self.SpellInspectorEmptyText then
        self.SpellInspectorEmptyText:SetText(hasSpell and "Adjust the selected spell definition here." or "Select a spell to inspect it.")
    end

    if hasSpell and self.ActiveSpellInspectorTabKey == nil then
        self:SetSpellInspectorTab("general")
    end
end
