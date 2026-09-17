local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local TooltipTemplate = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.TooltipTemplate or nil

local function hasStoredAuraTooltipTemplate(aura)
    if type(aura) ~= "table" then
        return false
    end

    if type(TooltipTemplate) == "table" and type(TooltipTemplate.NormalizeAuraPayload) == "function" then
        return type(TooltipTemplate.NormalizeAuraPayload(aura.tooltipTemplateData)) == "table"
    end

    return type(aura.tooltipTemplateData) == "table"
end

function DataEditor:BuildAuraInspectorPage(parent)
    if self.AuraInspectorPage then
        self:RefreshAuraInspectorPage()
        return self.AuraInspectorPage
    end

    self.AuraInspectorPage = CreateFrame("Frame", "RPEDataEditorAuraInspectorPage", parent)

    self.AuraInspectorSelectorBar = UI.CreateLayout(UI.HorizontalLayoutGroup, self.AuraInspectorPage, "RPEDataEditorAuraInspectorSelectorBar", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 20,
    })
    self.AuraInspectorSelectorBar:GetFrame():SetPoint("TOPLEFT", self.AuraInspectorPage, "TOPLEFT", 0, 0)
    self.AuraInspectorSelectorBar:GetFrame():SetPoint("TOPRIGHT", self.AuraInspectorPage, "TOPRIGHT", 0, 0)

    self.AuraInspectorPreviousButton = UI.CreateButton(self.AuraInspectorSelectorBar:GetFrame(), "RPEDataEditorAuraInspectorPreviousButton", "Prev", 40, function()
        self:SetAuraInspectorTab((self:GetAuraInspectorPageDefinitions()[(self.ActiveAuraInspectorPageIndex or 1) - 1] or {}).key or "general")
    end, {
        height = 20,
        fontSize = 7,
    })
    self.AuraInspectorSelectorBar:AddChild(self.AuraInspectorPreviousButton)

    self.AuraInspectorPageDropdown = UI.CreateDropdown(self.AuraInspectorSelectorBar:GetFrame(), "RPEDataEditorAuraInspectorPageDropdown", {
        width = 118,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = self:BuildAuraInspectorPageSelectorItems(),
        onValueChanged = function(value)
            if self._refreshingAuraInspectorPageSelector then
                return
            end

            self:SetAuraInspectorTab(value)
        end,
    })
    self.AuraInspectorSelectorBar:AddChild(self.AuraInspectorPageDropdown)

    self.AuraInspectorNextButton = UI.CreateButton(self.AuraInspectorSelectorBar:GetFrame(), "RPEDataEditorAuraInspectorNextButton", "Next", 40, function()
        local pages = self:GetAuraInspectorPageDefinitions()
        self:SetAuraInspectorTab((pages[(self.ActiveAuraInspectorPageIndex or 1) + 1] or {}).key or pages[#pages].key or "effects")
    end, {
        height = 20,
        fontSize = 7,
    })
    self.AuraInspectorSelectorBar:AddChild(self.AuraInspectorNextButton)

    self.AuraInspectorGeneralPage = CreateFrame("Frame", "RPEDataEditorAuraInspectorGeneralPage", self.AuraInspectorPage)
    self.AuraInspectorGeneralPage:SetPoint("TOPLEFT", self.AuraInspectorPage, "TOPLEFT", self.AuraInspectorSidePadding, -24)
    self.AuraInspectorGeneralPage:SetPoint("TOPRIGHT", self.AuraInspectorPage, "TOPRIGHT", -self.AuraInspectorSidePadding, -24)
    self.AuraInspectorGeneralPage:SetPoint("BOTTOMLEFT", self.AuraInspectorPage, "BOTTOMLEFT", self.AuraInspectorSidePadding, 24)
    self.AuraInspectorGeneralPage:SetPoint("BOTTOMRIGHT", self.AuraInspectorPage, "BOTTOMRIGHT", -self.AuraInspectorSidePadding, 24)
    self:BuildAuraInspectorGeneralPage(self.AuraInspectorGeneralPage)

    self.AuraInspectorEffectsPage = CreateFrame("Frame", "RPEDataEditorAuraInspectorEffectsPage", self.AuraInspectorPage)
    self.AuraInspectorEffectsPage:SetPoint("TOPLEFT", self.AuraInspectorPage, "TOPLEFT", self.AuraInspectorSidePadding, -24)
    self.AuraInspectorEffectsPage:SetPoint("TOPRIGHT", self.AuraInspectorPage, "TOPRIGHT", -self.AuraInspectorSidePadding, -24)
    self.AuraInspectorEffectsPage:SetPoint("BOTTOMLEFT", self.AuraInspectorPage, "BOTTOMLEFT", self.AuraInspectorSidePadding, 24)
    self.AuraInspectorEffectsPage:SetPoint("BOTTOMRIGHT", self.AuraInspectorPage, "BOTTOMRIGHT", -self.AuraInspectorSidePadding, 24)
    self:BuildAuraInspectorEffectsPage(self.AuraInspectorEffectsPage)

    self.AuraInspectorEventsPage = CreateFrame("Frame", "RPEDataEditorAuraInspectorEventsPage", self.AuraInspectorPage)
    self.AuraInspectorEventsPage:SetPoint("TOPLEFT", self.AuraInspectorPage, "TOPLEFT", self.AuraInspectorSidePadding, -24)
    self.AuraInspectorEventsPage:SetPoint("TOPRIGHT", self.AuraInspectorPage, "TOPRIGHT", -self.AuraInspectorSidePadding, -24)
    self.AuraInspectorEventsPage:SetPoint("BOTTOMLEFT", self.AuraInspectorPage, "BOTTOMLEFT", self.AuraInspectorSidePadding, 24)
    self.AuraInspectorEventsPage:SetPoint("BOTTOMRIGHT", self.AuraInspectorPage, "BOTTOMRIGHT", -self.AuraInspectorSidePadding, 24)
    self:BuildAuraInspectorEventsPage(self.AuraInspectorEventsPage)

    self.AuraInspectorEmptyText = UI.CreateText(self.AuraInspectorPage, "RPEDataEditorAuraInspectorEmptyText", "", {
        width = self.AuraInspectorFieldWidth,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.AuraInspectorEmptyText:GetFrame():SetPoint("BOTTOMLEFT", self.AuraInspectorPage, "BOTTOMLEFT", 0, 0)

    self.ActiveAuraInspectorPageIndex = self.ActiveAuraInspectorPageIndex or self:GetAuraInspectorPageIndexByKey(self.ActiveAuraInspectorTabKey or "general")
    self:SetAuraInspectorTab("general")
    self:RefreshAuraInspectorPage()
    return self.AuraInspectorPage
end

function DataEditor:RefreshAuraInspectorPage()
    local _, aura = self:GetSelectedAuraAndDataset()
    local hasAura = aura ~= nil

    if hasAura then
        aura.effects = aura.effects or {}
        aura.events = aura.events or {}
        self:RefreshAuraInspectorEffectsTable()
        local effect = self:GetSelectedAuraInspectorEffect()
        if effect then
            self:NormalizeAuraInspectorEffect(effect)
            effect.statScaling = effect.statScaling or {}
            if #(effect.statScaling or {}) > 0 then
                local scalingIndex = tonumber(self.SelectedAuraScalingIndex) or 1
                self.SelectedAuraScalingIndex = math.max(1, math.min(scalingIndex, #effect.statScaling))
            else
                self.SelectedAuraScalingIndex = nil
            end
        else
            self.SelectedAuraScalingIndex = nil
        end

        self:RefreshAuraInspectorEventsTable()
        local auraEvent = self:GetSelectedAuraInspectorEvent()
        if auraEvent then
            self:NormalizeAuraInspectorEvent(auraEvent)
            self:RefreshAuraInspectorEventEffectsTable()

            local eventEffect = self:GetSelectedAuraInspectorEventEffect()
            if eventEffect then
                self:NormalizeAuraInspectorEventEffect(eventEffect)
                eventEffect.statScaling = eventEffect.statScaling or {}
                if #(eventEffect.statScaling or {}) > 0 then
                    local eventScalingIndex = tonumber(self.SelectedAuraEventScalingIndex) or 1
                    self.SelectedAuraEventScalingIndex = math.max(1, math.min(eventScalingIndex, #eventEffect.statScaling))
                else
                    self.SelectedAuraEventScalingIndex = nil
                end
            else
                self.SelectedAuraEventScalingIndex = nil
            end
        else
            self.SelectedAuraEventEffectIndex = nil
            self.SelectedAuraEventScalingIndex = nil
            if self.AuraInspectorEventEffectsScroll and self.AuraInspectorEventEffectsScroll.SetItems then
                self.AuraInspectorEventEffectsScroll:SetItems({})
            end
            if self.AuraInspectorEventScalingScroll and self.AuraInspectorEventScalingScroll.SetItems then
                self.AuraInspectorEventScalingScroll:SetItems({})
            end
        end
    else
        self.SelectedAuraEffectIndex = nil
        self.SelectedAuraScalingIndex = nil
        self.SelectedAuraEventIndex = nil
        self.SelectedAuraEventEffectIndex = nil
        self.SelectedAuraEventScalingIndex = nil
        if self.AuraInspectorEffectsScroll and self.AuraInspectorEffectsScroll.SetItems then
            self.AuraInspectorEffectsScroll:SetItems({})
        end
        if self.AuraInspectorEventsScroll and self.AuraInspectorEventsScroll.SetItems then
            self.AuraInspectorEventsScroll:SetItems({})
        end
        if self.AuraInspectorEventEffectsScroll and self.AuraInspectorEventEffectsScroll.SetItems then
            self.AuraInspectorEventEffectsScroll:SetItems({})
        end
        if self.AuraInspectorEventScalingScroll and self.AuraInspectorEventScalingScroll.SetItems then
            self.AuraInspectorEventScalingScroll:SetItems({})
        end
    end

    local effect = self:GetSelectedAuraInspectorEffect()
    local effectType = tostring(effect and effect.type or "damage")
    local isDamage = effectType == "damage"
    local isHeal = effectType == "heal"
    local isAbsorb = effectType == "absorb"
    local isStat = effectType == "stat"
    local isSkill = effectType == "skill"
    local isControl = effectType == "control"
    local isApplyAura = effectType == "apply_aura"
    local isResource = effectType == "resource"
    local auraEvent = self:GetSelectedAuraInspectorEvent()
    local hasAuraEventTrigger = auraEvent ~= nil and type(auraEvent.combatEventId) == "string" and auraEvent.combatEventId ~= ""
    local isDefenceEvent = hasAuraEventTrigger and auraEvent.combatEventId == "on_defence"
    local eventEffect = self:GetSelectedAuraInspectorEventEffect()
    local eventEffectType = tostring(eventEffect and eventEffect.type or "damage")
    local isEventDamage = eventEffectType == "damage"
    local isEventHeal = eventEffectType == "heal"
    local isEventApplyAura = eventEffectType == "apply_aura"
    local isEventRemoveAura = eventEffectType == "remove_aura"
    local isEventResource = eventEffectType == "resource"
    local supportsEventScaling = isEventDamage or isEventHeal

    self._refreshingAuraInspector = true

    if self.AuraInspectorNameInput then
        self.AuraInspectorNameInput:SetText(aura and (aura.name or "") or "")
        self:SetAuraInspectorTextElementEnabled(self.AuraInspectorNameInput, hasAura)
    end
    if self.AuraInspectorIdText then
        self.AuraInspectorIdText:SetText(("ID: %s"):format(aura and tostring(aura.id or "") or "-"))
    end
    if self.AuraInspectorIconInput then
        self.AuraInspectorIconInput:SetText(aura and (aura.icon or "") or "")
        self:SetAuraInspectorTextElementEnabled(self.AuraInspectorIconInput, hasAura)
    end
    if self.AuraInspectorDurationInput then
        self.AuraInspectorDurationInput:SetText(tostring(aura and aura.duration or 1))
        self:SetAuraInspectorTextElementEnabled(self.AuraInspectorDurationInput, hasAura)
    end
    if self.AuraInspectorStackBehaviorDropdown then
        self.AuraInspectorStackBehaviorDropdown:SetSelectedValue(aura and aura.stackBehavior or "refresh_duration", true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorStackBehaviorDropdown, hasAura)
    end
    if self.AuraInspectorMaxStacksInput then
        self.AuraInspectorMaxStacksInput:SetText(tostring(aura and aura.maxStacks or 1))
        self:SetAuraInspectorTextElementEnabled(self.AuraInspectorMaxStacksInput, hasAura)
    end
    if self.AuraInspectorAbsorbValidationText then
        local validation = self:ValidateAuraAbsorption(aura)
        local message = validation and validation.valid ~= true and validation.reason or ""
        self.AuraInspectorAbsorbValidationText:SetText(message ~= "" and ("Warning: " .. message) or "")
    end
    if self.AuraInspectorTooltipTemplateStatusText then
        local hasStoredTemplate = hasStoredAuraTooltipTemplate(aura)
        if hasStoredTemplate then
            self.AuraInspectorTooltipTemplateStatusText:SetText("Tooltip Template: Generated")
        elseif aura and aura.tooltipTemplate == true then
            self.AuraInspectorTooltipTemplateStatusText:SetText("Tooltip Template: Legacy Flag Only")
        else
            self.AuraInspectorTooltipTemplateStatusText:SetText("Tooltip Template: Not Generated")
        end
    end
    if self.AuraInspectorGenerateTooltipTemplateButton then
        self.AuraInspectorGenerateTooltipTemplateButton:SetEnabled(hasAura)
    end

    if hasAura then
        self:RefreshAuraInspectorScalingTable()
    elseif self.AuraInspectorScalingScroll and self.AuraInspectorScalingScroll.SetItems then
        self.AuraInspectorScalingScroll:SetItems({})
    end

    if hasAura and auraEvent then
        self:RefreshAuraInspectorEventScalingTable()
    elseif self.AuraInspectorEventScalingScroll and self.AuraInspectorEventScalingScroll.SetItems then
        self.AuraInspectorEventScalingScroll:SetItems({})
    end

    if self.AuraInspectorAddEffectButton then
        self.AuraInspectorAddEffectButton:SetEnabled(hasAura)
    end
    if self.AuraInspectorDeleteEffectButton then
        self.AuraInspectorDeleteEffectButton:SetEnabled(effect ~= nil)
    end
    if self.AuraInspectorSelectedEffectHeader then
        self.AuraInspectorSelectedEffectHeader:SetText(effect and ("Editing effect %d"):format(self.SelectedAuraEffectIndex or 1) or "Select an effect to edit it.")
    end
    if self.AuraInspectorEffectTypeDropdown then
        self.AuraInspectorEffectTypeDropdown:SetSelectedValue(effectType, true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorEffectTypeDropdown, effect ~= nil)
    end
    if self.AuraInspectorBaseAmountLabel then
        if isHeal then
            self.AuraInspectorBaseAmountLabel:SetText("Base Healing")
        elseif isAbsorb then
            self.AuraInspectorBaseAmountLabel:SetText("Base Absorption")
        elseif isStat or isSkill then
            self.AuraInspectorBaseAmountLabel:SetText("Base Amount")
        else
            self.AuraInspectorBaseAmountLabel:SetText("Base Damage")
        end
    end
    if self.AuraInspectorBaseAmountInput then
        local amount = isHeal and (effect and effect.baseHealing or 0)
            or isAbsorb and (effect and effect.baseAbsorption or 0)
            or (isStat or isSkill) and (effect and effect.baseAmount or 0)
            or (effect and effect.baseDamage or 0)
        self.AuraInspectorBaseAmountInput:SetText(tostring(amount or 0))
        self:SetAuraInspectorTextElementEnabled(self.AuraInspectorBaseAmountInput, effect ~= nil and not isApplyAura and not isResource and not isControl)
    end
    if self.AuraInspectorAmountModeDropdown then
        self.AuraInspectorAmountModeDropdown:SetSelectedValue(effect and effect.amountMode or "flat", true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorAmountModeDropdown, effect ~= nil and (isDamage or isHeal or isAbsorb))
    end
    if self.AuraInspectorDamageSchoolsDropdown then
        self.AuraInspectorDamageSchoolsDropdown:SetItems(self:BuildSpellInspectorDamageSchoolsAcrossDatasets())
        self.AuraInspectorDamageSchoolsDropdown:SetSelectedValues(effect and effect.damageSchoolRefs or {}, true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorDamageSchoolsDropdown, effect ~= nil and (isDamage or isAbsorb))
    end
    if self.AuraInspectorStatRefDropdown then
        self.AuraInspectorStatRefDropdown:SetItems(self:BuildSpellInspectorStatsAcrossDatasets())
        self.AuraInspectorStatRefDropdown:SetSelectedValue(effect and effect.statRef or "", true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorStatRefDropdown, effect ~= nil and isStat)
    end
    if self.AuraInspectorSkillRefDropdown then
        self.AuraInspectorSkillRefDropdown:SetItems(self:BuildSpellInspectorSkillsAcrossDatasets())
        self.AuraInspectorSkillRefDropdown:SetSelectedValue(effect and effect.skillRef or "", true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorSkillRefDropdown, effect ~= nil and isSkill)
    end
    if self.AuraInspectorOperationDropdown then
        self.AuraInspectorOperationDropdown:SetSelectedValue(effect and effect.operation or "flat", true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorOperationDropdown, effect ~= nil and isStat)
    end
    if self.AuraInspectorControlCancelOnDamageCheckbox then
        self.AuraInspectorControlCancelOnDamageCheckbox:SetChecked(effect and effect.cancelOnDamage == true or false, true)
        self:SetAuraInspectorCheckboxEnabled(self.AuraInspectorControlCancelOnDamageCheckbox, effect ~= nil and isControl)
    end
    if self.AuraInspectorControlPreventCastingCheckbox then
        self.AuraInspectorControlPreventCastingCheckbox:SetChecked(effect and effect.preventCasting == true or false, true)
        self:SetAuraInspectorCheckboxEnabled(self.AuraInspectorControlPreventCastingCheckbox, effect ~= nil and isControl)
    end
    if self.AuraInspectorControlMovementZeroCheckbox then
        self.AuraInspectorControlMovementZeroCheckbox:SetChecked(tonumber(effect and effect.movementRangeOverride) == 0, true)
        self:SetAuraInspectorCheckboxEnabled(self.AuraInspectorControlMovementZeroCheckbox, effect ~= nil and isControl)
    end
    if self.AuraInspectorControlForceAutoHitCheckbox then
        self.AuraInspectorControlForceAutoHitCheckbox:SetChecked(effect and effect.forceAutoHitAgainstTarget == true or false, true)
        self:SetAuraInspectorCheckboxEnabled(self.AuraInspectorControlForceAutoHitCheckbox, effect ~= nil and isControl)
    end
    if self.AuraInspectorAuraDropdown then
        self.AuraInspectorAuraDropdown:SetItems(self:BuildSpellInspectorAurasAcrossDatasets())
        self.AuraInspectorAuraDropdown:SetSelectedValue(effect and effect.auraRef or "", true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorAuraDropdown, effect ~= nil and isApplyAura)
    end
    if self.AuraInspectorAuraStacksInput then
        self.AuraInspectorAuraStacksInput:SetText(tostring(effect and effect.stacks or 1))
        self:SetAuraInspectorTextElementEnabled(self.AuraInspectorAuraStacksInput, effect ~= nil and isApplyAura)
    end
    if self.AuraInspectorApplyAuraDurationInput then
        self.AuraInspectorApplyAuraDurationInput:SetText(tostring(effect and effect.duration or 12))
        self:SetAuraInspectorTextElementEnabled(self.AuraInspectorApplyAuraDurationInput, effect ~= nil and isApplyAura)
    end
    if self.AuraInspectorBasePowerInput then
        self.AuraInspectorBasePowerInput:SetText(tostring(effect and effect.basePower or 0))
        self:SetAuraInspectorTextElementEnabled(self.AuraInspectorBasePowerInput, effect ~= nil and isApplyAura)
    end
    if self.AuraInspectorResourceDropdown then
        self.AuraInspectorResourceDropdown:SetItems(self:BuildSpellInspectorResourcesAcrossDatasets())
        self.AuraInspectorResourceDropdown:SetSelectedValue(effect and effect.resourceRef or "", true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorResourceDropdown, effect ~= nil and isResource)
    end
    if self.AuraInspectorResourceAmountInput then
        self.AuraInspectorResourceAmountInput:SetText(tostring(effect and effect.amount or 0))
        self:SetAuraInspectorTextElementEnabled(self.AuraInspectorResourceAmountInput, effect ~= nil and isResource)
    end
    if self.AuraInspectorResourceAmountModeDropdown then
        self.AuraInspectorResourceAmountModeDropdown:SetSelectedValue(effect and effect.amountMode or "flat", true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorResourceAmountModeDropdown, effect ~= nil and isResource)
    end
    if self.AuraInspectorPendingScalingStatDropdown then
        self.AuraInspectorPendingScalingStatDropdown:SetItems(self:BuildSpellInspectorStatsAcrossDatasets())
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorPendingScalingStatDropdown, effect ~= nil and not isControl and not isSkill and not isApplyAura and not isResource)
    end
    if self.AuraInspectorPendingScalingCoefficientInput then
        self:SetAuraInspectorTextElementEnabled(self.AuraInspectorPendingScalingCoefficientInput, effect ~= nil and not isControl and not isSkill and not isApplyAura and not isResource)
    end
    if self.AuraInspectorAddScalingButton then
        self.AuraInspectorAddScalingButton:SetEnabled(effect ~= nil and not isControl and not isSkill and not isApplyAura and not isResource)
    end
    if self.AuraInspectorDeleteScalingButton then
        self.AuraInspectorDeleteScalingButton:SetEnabled(effect ~= nil and not isControl and not isSkill and not isApplyAura and not isResource and tonumber(self.SelectedAuraScalingIndex) ~= nil)
    end

    self:SetAuraInspectorGroupVisible(self.AuraInspectorEffectTypeGroup, effect ~= nil)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorBaseAmountGroup, effect ~= nil and not isControl and not isApplyAura and not isResource)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorAmountModeGroup, effect ~= nil and (isDamage or isHeal or isAbsorb))
    self:SetAuraInspectorGroupVisible(self.AuraInspectorDamageSchoolsGroup, effect ~= nil and (isDamage or isAbsorb))
    self:SetAuraInspectorGroupVisible(self.AuraInspectorStatRefGroup, effect ~= nil and isStat)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorSkillRefGroup, effect ~= nil and isSkill)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorOperationGroup, effect ~= nil and isStat)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorControlGroup, effect ~= nil and isControl)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorAuraGroup, effect ~= nil and isApplyAura)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorAuraStacksGroup, effect ~= nil and isApplyAura)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorApplyAuraDurationGroup, effect ~= nil and isApplyAura)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorBasePowerGroup, effect ~= nil and isApplyAura)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorResourceGroup, effect ~= nil and isResource)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorResourceAmountGroup, effect ~= nil and isResource)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorResourceAmountModeGroup, effect ~= nil and isResource)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorScalingGroup, effect ~= nil and not isControl and not isSkill and not isApplyAura and not isResource)
    if self.AuraInspectorEffectsRoot and self.AuraInspectorEffectsRoot.RefreshLayout then
        self.AuraInspectorEffectsRoot:RefreshLayout()
    end
    if self.RefreshAuraInspectorEffectsScrollBounds then
        self:RefreshAuraInspectorEffectsScrollBounds()
    end

    if self.AuraInspectorAddEventButton then
        self.AuraInspectorAddEventButton:SetEnabled(hasAura)
    end
    if self.AuraInspectorDeleteEventButton then
        self.AuraInspectorDeleteEventButton:SetEnabled(auraEvent ~= nil)
    end
    if self.AuraInspectorSelectedEventHeader then
        self.AuraInspectorSelectedEventHeader:SetText(auraEvent and ("Editing event %d"):format(self.SelectedAuraEventIndex or 1) or "Select an event to edit it.")
    end
    if self.AuraInspectorCombatEventDropdown then
        self.AuraInspectorCombatEventDropdown:SetItems(self:GetAuraInspectorCombatEventItems())
        self.AuraInspectorCombatEventDropdown:SetSelectedValue(auraEvent and auraEvent.combatEventId or "", true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorCombatEventDropdown, auraEvent ~= nil)
    end
    if self.AuraInspectorTriggerTargetDropdown then
        self.AuraInspectorTriggerTargetDropdown:SetItems(self:GetAuraInspectorTriggerTargetItems())
        self.AuraInspectorTriggerTargetDropdown:SetSelectedValue(auraEvent and auraEvent.triggerTarget or "event_other", true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorTriggerTargetDropdown, auraEvent ~= nil and hasAuraEventTrigger)
    end
    if self.AuraInspectorDefenceStatDropdown then
        self.AuraInspectorDefenceStatDropdown:SetItems(self:BuildSpellInspectorDefenceStatsAcrossDatasets())
        self.AuraInspectorDefenceStatDropdown:SetSelectedValue(auraEvent and auraEvent.defenceStatRef or "", true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorDefenceStatDropdown, isDefenceEvent)
    end
    if self.AuraInspectorEventChanceInput then
        self.AuraInspectorEventChanceInput:SetText(tostring(auraEvent and auraEvent.chance or 100))
        self:SetAuraInspectorTextElementEnabled(self.AuraInspectorEventChanceInput, auraEvent ~= nil)
    end
    if self.AuraInspectorAddEventEffectButton then
        self.AuraInspectorAddEventEffectButton:SetEnabled(auraEvent ~= nil)
    end
    if self.AuraInspectorDeleteEventEffectButton then
        self.AuraInspectorDeleteEventEffectButton:SetEnabled(eventEffect ~= nil)
    end
    if self.AuraInspectorSelectedEventEffectHeader then
        self.AuraInspectorSelectedEventEffectHeader:SetText(eventEffect and ("Editing event effect %d"):format(self.SelectedAuraEventEffectIndex or 1) or "Select an event effect to edit it.")
    end
    if self.AuraInspectorEventEffectTypeDropdown then
        self.AuraInspectorEventEffectTypeDropdown:SetSelectedValue(eventEffectType, true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorEventEffectTypeDropdown, eventEffect ~= nil)
    end
    if self.AuraInspectorEventBaseAmountLabel then
        self.AuraInspectorEventBaseAmountLabel:SetText(isEventHeal and "Base Healing" or "Base Damage")
    end
    if self.AuraInspectorEventBaseAmountInput then
        local eventAmount = isEventHeal and (eventEffect and eventEffect.baseHealing or 0) or (eventEffect and eventEffect.baseDamage or 0)
        self.AuraInspectorEventBaseAmountInput:SetText(tostring(eventAmount or 0))
        self:SetAuraInspectorTextElementEnabled(self.AuraInspectorEventBaseAmountInput, eventEffect ~= nil and (isEventDamage or isEventHeal))
    end
    if self.AuraInspectorEventAmountModeDropdown then
        self.AuraInspectorEventAmountModeDropdown:SetSelectedValue(eventEffect and eventEffect.amountMode or "flat", true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorEventAmountModeDropdown, eventEffect ~= nil and (isEventDamage or isEventHeal))
    end
    if self.AuraInspectorEventDamageSchoolsDropdown then
        self.AuraInspectorEventDamageSchoolsDropdown:SetItems(self:BuildSpellInspectorDamageSchoolsAcrossDatasets())
        self.AuraInspectorEventDamageSchoolsDropdown:SetSelectedValues(eventEffect and eventEffect.damageSchoolRefs or {}, true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorEventDamageSchoolsDropdown, eventEffect ~= nil and isEventDamage)
    end
    if self.AuraInspectorEventAuraDropdown then
        self.AuraInspectorEventAuraDropdown:SetItems(self:BuildSpellInspectorAurasAcrossDatasets())
        self.AuraInspectorEventAuraDropdown:SetSelectedValue(eventEffect and eventEffect.auraRef or "", true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorEventAuraDropdown, eventEffect ~= nil and (isEventApplyAura or isEventRemoveAura))
    end
    if self.AuraInspectorEventAuraStacksInput then
        self.AuraInspectorEventAuraStacksInput:SetText(tostring(eventEffect and eventEffect.stacks or 1))
        self:SetAuraInspectorTextElementEnabled(self.AuraInspectorEventAuraStacksInput, eventEffect ~= nil and (isEventApplyAura or isEventRemoveAura))
    end
    if self.AuraInspectorEventAuraDurationInput then
        self.AuraInspectorEventAuraDurationInput:SetText(tostring(eventEffect and eventEffect.duration or 12))
        self:SetAuraInspectorTextElementEnabled(self.AuraInspectorEventAuraDurationInput, eventEffect ~= nil and isEventApplyAura)
    end
    if self.AuraInspectorEventBasePowerInput then
        self.AuraInspectorEventBasePowerInput:SetText(tostring(eventEffect and eventEffect.basePower or 0))
        self:SetAuraInspectorTextElementEnabled(self.AuraInspectorEventBasePowerInput, eventEffect ~= nil and isEventApplyAura)
    end
    if self.AuraInspectorEventResourceDropdown then
        self.AuraInspectorEventResourceDropdown:SetItems(self:BuildSpellInspectorResourcesAcrossDatasets())
        self.AuraInspectorEventResourceDropdown:SetSelectedValue(eventEffect and eventEffect.resourceRef or "", true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorEventResourceDropdown, eventEffect ~= nil and isEventResource)
    end
    if self.AuraInspectorEventResourceAmountInput then
        self.AuraInspectorEventResourceAmountInput:SetText(tostring(eventEffect and eventEffect.amount or 0))
        self:SetAuraInspectorTextElementEnabled(self.AuraInspectorEventResourceAmountInput, eventEffect ~= nil and isEventResource)
    end
    if self.AuraInspectorEventResourceAmountModeDropdown then
        self.AuraInspectorEventResourceAmountModeDropdown:SetSelectedValue(eventEffect and eventEffect.amountMode or "flat", true)
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorEventResourceAmountModeDropdown, eventEffect ~= nil and isEventResource)
    end
    if self.AuraInspectorPendingEventScalingStatDropdown then
        self.AuraInspectorPendingEventScalingStatDropdown:SetItems(self:BuildSpellInspectorStatsAcrossDatasets())
        self:SetAuraInspectorDropdownEnabled(self.AuraInspectorPendingEventScalingStatDropdown, eventEffect ~= nil and supportsEventScaling)
    end
    if self.AuraInspectorPendingEventScalingCoefficientInput then
        self:SetAuraInspectorTextElementEnabled(self.AuraInspectorPendingEventScalingCoefficientInput, eventEffect ~= nil and supportsEventScaling)
    end
    if self.AuraInspectorAddEventScalingButton then
        self.AuraInspectorAddEventScalingButton:SetEnabled(eventEffect ~= nil and supportsEventScaling)
    end
    if self.AuraInspectorDeleteEventScalingButton then
        self.AuraInspectorDeleteEventScalingButton:SetEnabled(eventEffect ~= nil and supportsEventScaling and tonumber(self.SelectedAuraEventScalingIndex) ~= nil)
    end

    self:SetAuraInspectorGroupVisible(self.AuraInspectorCombatEventGroup, auraEvent ~= nil)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorTriggerTargetGroup, auraEvent ~= nil and hasAuraEventTrigger)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorDefenceStatGroup, isDefenceEvent)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorEventChanceGroup, auraEvent ~= nil)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorEventEffectTypeGroup, eventEffect ~= nil)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorEventBaseAmountGroup, eventEffect ~= nil and (isEventDamage or isEventHeal))
    self:SetAuraInspectorGroupVisible(self.AuraInspectorEventAmountModeGroup, eventEffect ~= nil and (isEventDamage or isEventHeal))
    self:SetAuraInspectorGroupVisible(self.AuraInspectorEventDamageSchoolsGroup, eventEffect ~= nil and isEventDamage)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorEventAuraGroup, eventEffect ~= nil and (isEventApplyAura or isEventRemoveAura))
    self:SetAuraInspectorGroupVisible(self.AuraInspectorEventAuraStacksGroup, eventEffect ~= nil and (isEventApplyAura or isEventRemoveAura))
    self:SetAuraInspectorGroupVisible(self.AuraInspectorEventAuraDurationGroup, eventEffect ~= nil and isEventApplyAura)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorEventBasePowerGroup, eventEffect ~= nil and isEventApplyAura)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorEventResourceGroup, eventEffect ~= nil and isEventResource)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorEventResourceAmountGroup, eventEffect ~= nil and isEventResource)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorEventResourceAmountModeGroup, eventEffect ~= nil and isEventResource)
    self:SetAuraInspectorGroupVisible(self.AuraInspectorEventScalingGroup, eventEffect ~= nil and supportsEventScaling)
    if self.AuraInspectorEventsRoot and self.AuraInspectorEventsRoot.RefreshLayout then
        self.AuraInspectorEventsRoot:RefreshLayout()
    end
    if self.RefreshAuraInspectorEventsScrollBounds then
        self:RefreshAuraInspectorEventsScrollBounds()
    end

    self._refreshingAuraInspector = false

    if self.AuraInspectorEmptyText then
        self.AuraInspectorEmptyText:SetText(hasAura and "Adjust the selected aura here." or "Select an aura to inspect it.")
    end

    if hasAura and self.ActiveAuraInspectorTabKey == nil then
        self:SetAuraInspectorTab("general")
    else
        self:RefreshAuraInspectorPageSelector()
    end
end
