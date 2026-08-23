local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local ItemClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Item or nil
local Shared = DataEditor.ItemInspectorShared or {}
local INSPECTOR_SIDE_PADDING = Shared.INSPECTOR_SIDE_PADDING or 8
local FIELD_WIDTH = Shared.FIELD_WIDTH or 236
local ensureString = Shared.ensureString
local parseDatasetQualifiedRef = Shared.parseDatasetQualifiedRef
local getSelectedItemAndDataset = Shared.getSelectedItemAndDataset
local getItemTypeLabel = Shared.getItemTypeLabel
local getQualityLabel = Shared.getQualityLabel
local getEmbeddedItemTrait = Shared.getEmbeddedItemTrait
local itemSupportsEmbeddedTrait = Shared.itemSupportsEmbeddedTrait
local normalizeArmorWeightValue = Shared.normalizeArmorWeightValue
local setDropdownEnabled = Shared.setDropdownEnabled
local setTextElementEnabled = Shared.setTextElementEnabled
local setCheckboxEnabled = Shared.setCheckboxEnabled
local setElementGroupVisible = Shared.setElementGroupVisible
local buildItemSocketRows = Shared.buildItemSocketRows
local getItemGenericLimitMap = Shared.getItemGenericLimitMap
local normalizeSocketColor = Shared.normalizeSocketColor

function DataEditor:BuildItemInspectorPage(parent)
    if self.ItemInspectorPage then
        self:RefreshItemInspectorPage()
        return self.ItemInspectorPage
    end

    self.ItemInspectorPage = CreateFrame("Frame", "RPEDataEditorItemInspectorPage", parent)

    self.ItemInspectorSelectorBar = UI.CreateLayout(UI.HorizontalLayoutGroup, self.ItemInspectorPage, "RPEDataEditorItemInspectorSelectorBar", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 20,
    })
    self.ItemInspectorSelectorBar:GetFrame():SetPoint("TOPLEFT", self.ItemInspectorPage, "TOPLEFT", 0, 0)
    self.ItemInspectorSelectorBar:GetFrame():SetPoint("TOPRIGHT", self.ItemInspectorPage, "TOPRIGHT", 0, 0)

    self.ItemInspectorPreviousButton = UI.CreateButton(self.ItemInspectorSelectorBar:GetFrame(), "RPEDataEditorItemInspectorPreviousButton", "Prev", 40, function()
        self:SetItemInspectorTab((self:GetItemInspectorPageDefinitions()[(self.ActiveItemInspectorPageIndex or 1) - 1] or {}).key or "general")
    end, {
        height = 20,
        fontSize = 7,
    })
    self.ItemInspectorSelectorBar:AddChild(self.ItemInspectorPreviousButton)

    self.ItemInspectorPageDropdown = UI.CreateDropdown(self.ItemInspectorSelectorBar:GetFrame(), "RPEDataEditorItemInspectorPageDropdown", {
        width = 118,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = self:BuildItemInspectorPageSelectorItems(),
        onValueChanged = function(value)
            if self._refreshingItemInspectorPageSelector then
                return
            end

            self:SetItemInspectorTab(value)
        end,
    })
    self.ItemInspectorSelectorBar:AddChild(self.ItemInspectorPageDropdown)

    self.ItemInspectorNextButton = UI.CreateButton(self.ItemInspectorSelectorBar:GetFrame(), "RPEDataEditorItemInspectorNextButton", "Next", 40, function()
        self:SetItemInspectorTab((self:GetItemInspectorPageDefinitions()[(self.ActiveItemInspectorPageIndex or 1) + 1] or {}).key or "conditions")
    end, {
        height = 20,
        fontSize = 7,
    })
    self.ItemInspectorSelectorBar:AddChild(self.ItemInspectorNextButton)

    local function createPage(name)
        local page = CreateFrame("Frame", name, self.ItemInspectorPage)
        page:SetPoint("TOPLEFT", self.ItemInspectorPage, "TOPLEFT", INSPECTOR_SIDE_PADDING, -24)
        page:SetPoint("TOPRIGHT", self.ItemInspectorPage, "TOPRIGHT", -INSPECTOR_SIDE_PADDING, -24)
        page:SetPoint("BOTTOMLEFT", self.ItemInspectorPage, "BOTTOMLEFT", INSPECTOR_SIDE_PADDING, 24)
        page:SetPoint("BOTTOMRIGHT", self.ItemInspectorPage, "BOTTOMRIGHT", -INSPECTOR_SIDE_PADDING, 24)
        return page
    end

    self.ItemInspectorGeneralPage = createPage("RPEDataEditorItemInspectorGeneralPage")
    self:BuildItemInspectorGeneralPage(self.ItemInspectorGeneralPage)

    self.ItemInspectorBehaviorPage = createPage("RPEDataEditorItemInspectorBehaviorPage")
    self:BuildItemInspectorBehaviorPage(self.ItemInspectorBehaviorPage)

    self.ItemInspectorEquipmentPage = createPage("RPEDataEditorItemInspectorEquipmentPage")
    self:BuildItemInspectorEquipmentPage(self.ItemInspectorEquipmentPage)

    self.ItemInspectorModificationsPage = createPage("RPEDataEditorItemInspectorModificationsPage")
    self:BuildItemInspectorModificationsPage(self.ItemInspectorModificationsPage)

    self.ItemInspectorConsumablePage = createPage("RPEDataEditorItemInspectorConsumablePage")
    self:BuildItemInspectorConsumablePage(self.ItemInspectorConsumablePage)

    self.ItemInspectorConditionsPage = createPage("RPEDataEditorItemInspectorConditionsPage")
    self:BuildItemInspectorConditionsPage(self.ItemInspectorConditionsPage)

    self.ItemInspectorStatsPage = createPage("RPEDataEditorItemInspectorStatsPage")
    self:BuildItemInspectorStatsPage(self.ItemInspectorStatsPage)

    self.ItemInspectorEmptyText = UI.CreateText(self.ItemInspectorPage, "RPEDataEditorItemInspectorEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = FIELD_WIDTH,
        height = 20,
        justifyH = "LEFT",
    })
    self.ItemInspectorEmptyText:GetFrame():SetPoint("BOTTOMLEFT", self.ItemInspectorPage, "BOTTOMLEFT", 0, 0)

    self.ActiveItemInspectorPageIndex = self.ActiveItemInspectorPageIndex or self:GetItemInspectorPageIndexByKey(self.ActiveItemInspectorTabKey or "general")
    self:SetItemInspectorTab("general")
    self:RefreshItemInspectorPage()
    return self.ItemInspectorPage
end

function DataEditor:RefreshItemInspectorPage()
    local dataset, item = getSelectedItemAndDataset(self)
    local hasItem = item ~= nil
    local itemType = hasItem and tostring(item.itemType or "none") or "none"
    local damageMode = hasItem and tostring(item.damageMode or "fixed") or "fixed"
    local isWeapon = itemType == "weapon"
    local isArmor = itemType == "armor"
    local isModification = itemType == "modification"
    local isEquipment = isWeapon or isArmor
    local modificationKind = isModification and tostring(item and item.modificationKind or "generic") or "generic"
    local isGenericModification = isModification and modificationKind == "generic"
    local isGemModification = isModification and modificationKind == "gem"
    local isItemLevelEligible = hasItem and ItemClass and ItemClass.IsItemLevelEligible and ItemClass.IsItemLevelEligible(item) or false
    local isConsumable = itemType == "consumable"
    local isMaterial = itemType == "material"
    local hasEmbeddedTrait = hasItem and itemSupportsEmbeddedTrait(item)
    local stackLocked = itemType == "weapon" or itemType == "armor" or itemType == "modification"
    local canEditStackSize = hasItem and item.canStack == true and not stackLocked
    local consumableTrait = hasItem and getEmbeddedItemTrait(item) or nil
    local consumableAutomaticAura = consumableTrait and consumableTrait.automaticAuras and consumableTrait.automaticAuras[1] or nil
    local consumableAutoAuraDatasetId = parseDatasetQualifiedRef(consumableAutomaticAura and consumableAutomaticAura.auraRef or "")

    if self.ActiveItemInspectorTabKey == "consumable" and not hasEmbeddedTrait then
        self:SetItemInspectorTab("general")
    end

    self._refreshingItemInspector = true

    if self.ItemInspectorNameInput then
        self.ItemInspectorNameInput:SetText(item and (item.name or "") or "")
        setTextElementEnabled(self.ItemInspectorNameInput, hasItem)
    end

    if self.ItemInspectorIdText then
        self.ItemInspectorIdText:SetText(("ID: %s"):format(item and item.id ~= nil and tostring(item.id) or "-"))
    end

    if self.ItemInspectorIconInput then
        self.ItemInspectorIconInput:SetText(item and (item.icon or "") or "")
        setTextElementEnabled(self.ItemInspectorIconInput, hasItem)
    end

    if self.ItemInspectorTagsInput then
        self.ItemInspectorTagsInput:SetText(UI.Utils.JoinCommaSeparatedList(item and item.tags or nil))
        setTextElementEnabled(self.ItemInspectorTagsInput, hasItem)
    end

    if self.ItemInspectorQualityDropdown then
        self.ItemInspectorQualityDropdown:SetSelectedValue(item and item.quality or "common", true)
        setDropdownEnabled(self.ItemInspectorQualityDropdown, hasItem)
    end

    if self.ItemInspectorItemSetKeyInput then
        self.ItemInspectorItemSetKeyInput:SetText(item and (item.itemSetKey or "") or "")
        setTextElementEnabled(self.ItemInspectorItemSetKeyInput, hasItem)
    end

    if self.ItemInspectorDescriptionInput then
        self.ItemInspectorDescriptionInput:SetText(item and (item.description or "") or "")
        setTextElementEnabled(self.ItemInspectorDescriptionInput, hasItem)
    end

    self:RefreshItemInspectorConditionsPage()

    if self.ItemInspectorUniqueFlagDropdown then
        self.ItemInspectorUniqueFlagDropdown:SetSelectedValue(item and item.uniqueFlag or "none", true)
        setDropdownEnabled(self.ItemInspectorUniqueFlagDropdown, hasItem)
    end

    if self.ItemInspectorBindingFlagDropdown then
        self.ItemInspectorBindingFlagDropdown:SetSelectedValue(item and item.bindingFlag or "none", true)
        setDropdownEnabled(self.ItemInspectorBindingFlagDropdown, hasItem)
    end

    if self.ItemInspectorCanStackCheckbox then
        self.ItemInspectorCanStackCheckbox:SetChecked(item and item.canStack == true or false, true)
        setCheckboxEnabled(self.ItemInspectorCanStackCheckbox, hasItem and not stackLocked)
    end

    if self.ItemInspectorMaxStackSizeInput then
        self.ItemInspectorMaxStackSizeInput:SetText(tostring(item and item.maxStackSize or 1))
        setTextElementEnabled(self.ItemInspectorMaxStackSizeInput, canEditStackSize)
    end

    if self.ItemInspectorCanTradeCheckbox then
        self.ItemInspectorCanTradeCheckbox:SetChecked(item and item.canTrade ~= false or false, true)
        setCheckboxEnabled(self.ItemInspectorCanTradeCheckbox, hasItem)
    end

    if self.ItemInspectorCanSellCheckbox then
        self.ItemInspectorCanSellCheckbox:SetChecked(item and item.canSell ~= false or false, true)
        setCheckboxEnabled(self.ItemInspectorCanSellCheckbox, hasItem)
    end

    if self.ItemInspectorSellPriceInput then
        self.ItemInspectorSellPriceInput:SetText(tostring(item and item.sellPrice or 0))
        setTextElementEnabled(self.ItemInspectorSellPriceInput, hasItem)
    end

    if self.ItemInspectorCanDisenchantCheckbox then
        self.ItemInspectorCanDisenchantCheckbox:SetChecked(item and item.canDisenchant ~= false or false, true)
        setCheckboxEnabled(self.ItemInspectorCanDisenchantCheckbox, hasItem)
    end

    if self.ItemInspectorAllowWowConversionGroup then
        self.ItemInspectorAllowWowConversionGroup:SetChecked(item and item.allowWowConversion == true or false, true)
        setCheckboxEnabled(self.ItemInspectorAllowWowConversionGroup, hasItem and isMaterial)
        local frame = self.ItemInspectorAllowWowConversionGroup.GetFrame and self.ItemInspectorAllowWowConversionGroup:GetFrame() or nil
        if frame then
            if hasItem and isMaterial then
                frame:Show()
            else
                frame:Hide()
            end
        end
    end

    if self.ItemInspectorWowConversionSkillLabel and self.ItemInspectorWowConversionSkillLabel.GetFrame then
        local frame = self.ItemInspectorWowConversionSkillLabel:GetFrame()
        if hasItem and isMaterial then
            frame:Show()
        else
            frame:Hide()
        end
    end
    if self.ItemInspectorWowConversionSkillDropdown then
        self.ItemInspectorWowConversionSkillDropdown:SetItems(self:BuildItemInspectorCraftingSkillItems())
        self.ItemInspectorWowConversionSkillDropdown:SetSelectedValue(item and item.wowConversionSkillRef or "", true)
        setDropdownEnabled(self.ItemInspectorWowConversionSkillDropdown, hasItem and isMaterial and item and item.allowWowConversion == true)
        local frame = self.ItemInspectorWowConversionSkillDropdown.GetFrame and self.ItemInspectorWowConversionSkillDropdown:GetFrame() or nil
        if frame then
            if hasItem and isMaterial then
                frame:Show()
            else
                frame:Hide()
            end
        end
    end

    if self.ItemInspectorItemTypeDropdown then
        self.ItemInspectorItemTypeDropdown:SetSelectedValue(item and item.itemType or "none", true)
        setDropdownEnabled(self.ItemInspectorItemTypeDropdown, hasItem)
    end
    setElementGroupVisible(self.ItemInspectorItemTypeGroup, hasItem)

    if self.ItemInspectorConsumableTypeDropdown then
        self.ItemInspectorConsumableTypeDropdown:SetSelectedValue(item and item.consumableType or "", true)
        setDropdownEnabled(self.ItemInspectorConsumableTypeDropdown, hasItem and isConsumable)
    end
    setElementGroupVisible(self.ItemInspectorConsumableTypeGroup, hasItem and isConsumable)

    if self.ItemInspectorConsumableElixirTypeDropdown then
        self.ItemInspectorConsumableElixirTypeDropdown:SetSelectedValue(item and item.consumableElixirType or "generic", true)
        setDropdownEnabled(self.ItemInspectorConsumableElixirTypeDropdown, hasItem and isConsumable and tostring(item and item.consumableType or "") == "elixir")
    end
    setElementGroupVisible(self.ItemInspectorConsumableElixirTypeGroup, hasItem and isConsumable and tostring(item and item.consumableType or "") == "elixir")

    if self.ItemInspectorWeaponTypeDropdown then
        self.ItemInspectorWeaponTypeDropdown:SetItems(self:BuildItemInspectorWeaponTypeItems())
        self.ItemInspectorWeaponTypeDropdown:SetSelectedValue(item and item.weaponTypeRef or "", true)
        setDropdownEnabled(self.ItemInspectorWeaponTypeDropdown, hasItem and isWeapon)
    end
    setElementGroupVisible(self.ItemInspectorWeaponTypeGroup, hasItem and isWeapon)

    if self.ItemInspectorArmorWeightDropdown then
        self.ItemInspectorArmorWeightDropdown:SetSelectedValue(normalizeArmorWeightValue(item and item.armorWeight or "cosmetic"), true)
        setDropdownEnabled(self.ItemInspectorArmorWeightDropdown, hasItem and isArmor)
    end
    setElementGroupVisible(self.ItemInspectorArmorWeightGroup, hasItem and isArmor)

    if self.ItemInspectorIsTwoHandedCheckbox then
        self.ItemInspectorIsTwoHandedCheckbox:SetChecked(item and item.isTwoHanded == true or false, true)
        setCheckboxEnabled(self.ItemInspectorIsTwoHandedCheckbox, hasItem and isWeapon)
    end
    setElementGroupVisible(self.ItemInspectorIsTwoHandedGroup, hasItem and isWeapon)

    if self.ItemInspectorDamageModeDropdown then
        self.ItemInspectorDamageModeDropdown:SetSelectedValue(item and item.damageMode or "fixed", true)
        setDropdownEnabled(self.ItemInspectorDamageModeDropdown, hasItem and isWeapon)
    end
    setElementGroupVisible(self.ItemInspectorDamageModeGroup, hasItem and isWeapon)

    if self.ItemInspectorDamagePerTurnInput then
        self.ItemInspectorDamagePerTurnInput:SetText(tostring(item and item.damagePerTurn or 0))
        setTextElementEnabled(self.ItemInspectorDamagePerTurnInput, hasItem and isWeapon and damageMode == "fixed")
    end
    setElementGroupVisible(self.ItemInspectorDamagePerTurnGroup, hasItem and isWeapon and damageMode == "fixed")

    if self.ItemInspectorMinDamagePerTurnInput then
        self.ItemInspectorMinDamagePerTurnInput:SetText(tostring(item and item.minDamagePerTurn or 0))
        setTextElementEnabled(self.ItemInspectorMinDamagePerTurnInput, hasItem and isWeapon and damageMode == "range")
    end
    setElementGroupVisible(self.ItemInspectorMinDamagePerTurnGroup, hasItem and isWeapon and damageMode == "range")

    if self.ItemInspectorMaxDamagePerTurnInput then
        self.ItemInspectorMaxDamagePerTurnInput:SetText(tostring(item and item.maxDamagePerTurn or 0))
        setTextElementEnabled(self.ItemInspectorMaxDamagePerTurnInput, hasItem and isWeapon and damageMode == "range")
    end
    setElementGroupVisible(self.ItemInspectorMaxDamagePerTurnGroup, hasItem and isWeapon and damageMode == "range")

    if self.ItemInspectorDamageSchoolDropdown then
        self.ItemInspectorDamageSchoolDropdown:SetItems(self:BuildItemInspectorDamageSchoolItems())
        self.ItemInspectorDamageSchoolDropdown:SetSelectedValue(item and item.damageSchoolRef or "", true)
        setDropdownEnabled(self.ItemInspectorDamageSchoolDropdown, hasItem and isWeapon)
    end
    setElementGroupVisible(self.ItemInspectorDamageSchoolGroup, hasItem and isWeapon)

    if self.ItemInspectorValidSlotsDropdown then
        self.ItemInspectorValidSlotsDropdown:SetItems(self:BuildItemInspectorItemSlotItems())
        self.ItemInspectorValidSlotsDropdown:SetSelectedValues(item and item.validSlotRefs or {}, true)
        setDropdownEnabled(self.ItemInspectorValidSlotsDropdown, hasItem and not isModification)
    end
    setElementGroupVisible(self.ItemInspectorValidSlotsGroup, hasItem and not isModification)

    local showModificationTypeSection = hasItem and isModification
    local showRestrictionFields = hasItem and isModification and not isGemModification
    local showTwoHandedRestrictionField = showRestrictionFields
    local showGenericPropertyField = hasItem and isGenericModification
    local showGemPropertyField = hasItem and isGemModification
    local showSocketsSection = hasItem and isEquipment
    local showGenericLimitsSection = hasItem and isEquipment

    if self.ItemInspectorModificationTargetSlotsDropdown then
        self.ItemInspectorModificationTargetSlotsDropdown:SetItems(self:BuildItemInspectorItemSlotItems())
        self.ItemInspectorModificationTargetSlotsDropdown:SetSelectedValues(item and item.targetSlotRefs or {}, true)
        setDropdownEnabled(self.ItemInspectorModificationTargetSlotsDropdown, showRestrictionFields)
    end
    if self.ItemInspectorModificationKindDropdown then
        self.ItemInspectorModificationKindDropdown:SetSelectedValue(modificationKind, true)
        setDropdownEnabled(self.ItemInspectorModificationKindDropdown, hasItem and isModification)
    end
    setElementGroupVisible(self.ItemInspectorModificationKindGroup, showModificationTypeSection)
    setElementGroupVisible(self.ItemInspectorModificationTargetSlotsGroup, showRestrictionFields)

    if self.ItemInspectorModificationWeaponTypeDropdown then
        self.ItemInspectorModificationWeaponTypeDropdown:SetItems(self:BuildItemInspectorWeaponTypeItems())
        self.ItemInspectorModificationWeaponTypeDropdown:SetSelectedValue(item and item.targetWeaponTypeRef or "", true)
        setDropdownEnabled(self.ItemInspectorModificationWeaponTypeDropdown, showRestrictionFields)
    end
    setElementGroupVisible(self.ItemInspectorModificationWeaponTypeGroup, showRestrictionFields)

    if self.ItemInspectorModificationTwoHandedCheckbox then
        self.ItemInspectorModificationTwoHandedCheckbox:SetChecked(item and item.targetTwoHandedOnly == true or false, true)
        setCheckboxEnabled(self.ItemInspectorModificationTwoHandedCheckbox, showTwoHandedRestrictionField)
    end
    setElementGroupVisible(self.ItemInspectorModificationTwoHandedGroup, showTwoHandedRestrictionField)

    if self.ItemInspectorModificationArmorWeightDropdown then
        self.ItemInspectorModificationArmorWeightDropdown:SetSelectedValue(item and item.targetArmorWeight or "none", true)
        setDropdownEnabled(self.ItemInspectorModificationArmorWeightDropdown, showRestrictionFields)
    end
    setElementGroupVisible(self.ItemInspectorModificationArmorWeightGroup, showRestrictionFields)

    if self.ItemInspectorModificationGenericKeyInput then
        self.ItemInspectorModificationGenericKeyInput:SetText(item and ensureString(item.genericModificationKey) or "")
        setTextElementEnabled(self.ItemInspectorModificationGenericKeyInput, hasItem and isGenericModification)
    end
    setElementGroupVisible(self.ItemInspectorModificationGenericKeyGroup, showGenericPropertyField)

    if self.ItemInspectorModificationGemColorDropdown then
        self.ItemInspectorModificationGemColorDropdown:SetSelectedValue(normalizeSocketColor(item and item.gemColor or nil) or "red", true)
        setDropdownEnabled(self.ItemInspectorModificationGemColorDropdown, hasItem and isGemModification)
    end
    setElementGroupVisible(self.ItemInspectorModificationGemColorGroup, showGemPropertyField)

    local selectedSocketRows = buildItemSocketRows(item)
    local selectedSocketIndex = tonumber(self.SelectedItemInspectorSocketIndex)
    if selectedSocketIndex and not selectedSocketRows[selectedSocketIndex] then
        self.SelectedItemInspectorSocketIndex = nil
        selectedSocketIndex = nil
    end
    if self.ItemInspectorModificationSocketColorDropdown then
        local selectedSocketColor = selectedSocketIndex and selectedSocketRows[selectedSocketIndex] and selectedSocketRows[selectedSocketIndex].color or "red"
        self.ItemInspectorModificationSocketColorDropdown:SetSelectedValue(selectedSocketColor or "red", true)
        setDropdownEnabled(self.ItemInspectorModificationSocketColorDropdown, showSocketsSection)
    end
    if self.ItemInspectorModificationAddSocketButton then
        self.ItemInspectorModificationAddSocketButton:SetEnabled(showSocketsSection)
    end
    if self.ItemInspectorModificationRemoveSocketButton then
        self.ItemInspectorModificationRemoveSocketButton:SetEnabled(showSocketsSection and selectedSocketIndex ~= nil)
    end
    setElementGroupVisible(self.ItemInspectorModificationSocketsLabel, showSocketsSection)
    setElementGroupVisible(self.ItemInspectorModificationSocketsHeader, showSocketsSection)
    setElementGroupVisible(self.ItemInspectorModificationSocketsPanel, showSocketsSection)
    setElementGroupVisible(self.ItemInspectorModificationSocketToolbar, showSocketsSection)
    self:RefreshItemInspectorSocketTable()

    local selectedGenericLimitKey = string.lower(ensureString(self.SelectedItemInspectorGenericLimitKey))
    local selectedGenericLimitValue = getItemGenericLimitMap(item)[selectedGenericLimitKey]
    if selectedGenericLimitKey ~= "" and selectedGenericLimitValue == nil then
        self.SelectedItemInspectorGenericLimitKey = nil
        selectedGenericLimitKey = ""
    end
    if self.ItemInspectorModificationGenericLimitKeyInput then
        self.ItemInspectorModificationGenericLimitKeyInput:SetText(selectedGenericLimitKey)
        setTextElementEnabled(self.ItemInspectorModificationGenericLimitKeyInput, showGenericLimitsSection)
    end
    if self.ItemInspectorModificationGenericLimitValueInput then
        self.ItemInspectorModificationGenericLimitValueInput:SetText(tostring(selectedGenericLimitValue or 1))
        setTextElementEnabled(self.ItemInspectorModificationGenericLimitValueInput, showGenericLimitsSection)
    end
    if self.ItemInspectorModificationSaveGenericLimitButton then
        self.ItemInspectorModificationSaveGenericLimitButton:SetEnabled(showGenericLimitsSection)
    end
    if self.ItemInspectorModificationRemoveGenericLimitButton then
        self.ItemInspectorModificationRemoveGenericLimitButton:SetEnabled(showGenericLimitsSection and selectedGenericLimitKey ~= "")
    end
    setElementGroupVisible(self.ItemInspectorModificationGenericLimitsLabel, showGenericLimitsSection)
    setElementGroupVisible(self.ItemInspectorModificationGenericLimitsHeader, showGenericLimitsSection)
    setElementGroupVisible(self.ItemInspectorModificationGenericLimitPanel, showGenericLimitsSection)
    setElementGroupVisible(self.ItemInspectorModificationGenericLimitKeyGroup, showGenericLimitsSection)
    setElementGroupVisible(self.ItemInspectorModificationGenericLimitValueGroup, showGenericLimitsSection)
    setElementGroupVisible(self.ItemInspectorModificationGenericLimitActionRow, showGenericLimitsSection)
    self:RefreshItemInspectorGenericLimitTable()

    if self.ItemInspectorItemLevelOverrideInput then
        self.ItemInspectorItemLevelOverrideInput:SetText(tostring(item and item.itemLevel or 0))
        setTextElementEnabled(self.ItemInspectorItemLevelOverrideInput, isItemLevelEligible)
    end
    setElementGroupVisible(self.ItemInspectorItemLevelOverrideGroup, isItemLevelEligible)

    if self.ItemInspectorResolvedItemLevelText and self.ItemInspectorResolvedItemLevelText.SetText then
        local resolvedItemLevel = isItemLevelEligible and ItemClass and ItemClass.ResolveItemLevel and ItemClass.ResolveItemLevel(item) or 0
        self.ItemInspectorResolvedItemLevelText:SetText(resolvedItemLevel > 0 and tostring(resolvedItemLevel) or "--")
    end
    setElementGroupVisible(self.ItemInspectorResolvedItemLevelGroup, isItemLevelEligible)

    if self.ItemInspectorEquipmentLayout and self.ItemInspectorEquipmentLayout.RefreshLayout then
        self.ItemInspectorEquipmentLayout:RefreshLayout()
    end
    if self.RefreshItemInspectorEquipmentScrollBounds then
        self:RefreshItemInspectorEquipmentScrollBounds()
    end

    if self.ItemInspectorModificationsLayout and self.ItemInspectorModificationsLayout.RefreshLayout then
        self.ItemInspectorModificationsLayout:RefreshLayout()
    end
    if self.RefreshItemInspectorModificationsScrollBounds then
        self:RefreshItemInspectorModificationsScrollBounds()
    end

    if self.ItemInspectorConsumableHintText and self.ItemInspectorConsumableHintText.SetText then
        self.ItemInspectorConsumableHintText:SetText(isConsumable
            and "Consumable items can embed one start-phase or end-phase trait."
            or (hasEmbeddedTrait
                and "Equipped weapons, armor, and applied modifications use their embedded trait while active."
                or "Set the item type to Consumable, Weapon, Armor, or Modification to author an embedded trait."))
    end
    if self.ItemInspectorConsumablePhaseDropdown then
        self.ItemInspectorConsumablePhaseDropdown:SetSelectedValue(consumableTrait and consumableTrait.phase or "event_start", true)
        setDropdownEnabled(self.ItemInspectorConsumablePhaseDropdown, hasItem and isConsumable)
    end
    setElementGroupVisible(self.ItemInspectorConsumablePhaseGroup, hasItem and isConsumable)
    if self.ItemInspectorConsumableDescriptionInput then
        self.ItemInspectorConsumableDescriptionInput:SetText(consumableTrait and ensureString(consumableTrait.description) or "")
        setTextElementEnabled(self.ItemInspectorConsumableDescriptionInput, hasEmbeddedTrait)
    end
    local selectedConsumableStat = consumableTrait and consumableTrait.statBonuses and consumableTrait.statBonuses[tonumber(self.SelectedItemConsumableTraitStatIndex) or 0] or nil
    local selectedConsumableStatDatasetId = parseDatasetQualifiedRef(selectedConsumableStat and selectedConsumableStat.statRef or "")
    if self.ItemInspectorConsumablePendingStatDatasetDropdown then
        self.ItemInspectorConsumablePendingStatDatasetDropdown:SetItems(self:BuildItemInspectorDatasetItems())
        self.ItemInspectorConsumablePendingStatDatasetDropdown:SetSelectedValue(selectedConsumableStatDatasetId or "", true)
        setDropdownEnabled(self.ItemInspectorConsumablePendingStatDatasetDropdown, hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumablePendingStatDropdown then
        self:RefreshItemInspectorConsumablePendingStatDropdown()
        self.ItemInspectorConsumablePendingStatDropdown:SetSelectedValue(selectedConsumableStat and selectedConsumableStat.statRef or "", true)
        setDropdownEnabled(self.ItemInspectorConsumablePendingStatDropdown, hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumablePendingStatOperationDropdown then
        self.ItemInspectorConsumablePendingStatOperationDropdown:SetItems(self:GetAuraInspectorOperationItems())
        self.ItemInspectorConsumablePendingStatOperationDropdown:SetSelectedValue(selectedConsumableStat and selectedConsumableStat.operation or "flat", true)
        setDropdownEnabled(self.ItemInspectorConsumablePendingStatOperationDropdown, hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumableSkillsScroll and self.ItemInspectorConsumableSkillsScroll.SetItems then
        self:RefreshItemInspectorConsumableTraitSkillTable()
    end
    if self.ItemInspectorConsumablePendingStatValueInput then
        self.ItemInspectorConsumablePendingStatValueInput:SetText(tostring(selectedConsumableStat and selectedConsumableStat.value or 0))
        setTextElementEnabled(self.ItemInspectorConsumablePendingStatValueInput, hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumableAddStatButton then
        self.ItemInspectorConsumableAddStatButton:SetEnabled(hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumableRemoveStatButton then
        self.ItemInspectorConsumableRemoveStatButton:SetEnabled(hasEmbeddedTrait and tonumber(self.SelectedItemConsumableTraitStatIndex) ~= nil)
    end
    if self.ItemInspectorConsumablePendingSkillDatasetDropdown then
        self.ItemInspectorConsumablePendingSkillDatasetDropdown:SetItems(self:BuildItemInspectorDatasetItems())
        setDropdownEnabled(self.ItemInspectorConsumablePendingSkillDatasetDropdown, hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumablePendingSkillDropdown then
        self:RefreshItemInspectorConsumablePendingSkillDropdown()
        setDropdownEnabled(self.ItemInspectorConsumablePendingSkillDropdown, hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumablePendingSkillValueInput then
        setTextElementEnabled(self.ItemInspectorConsumablePendingSkillValueInput, hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumableAddSkillButton then
        self.ItemInspectorConsumableAddSkillButton:SetEnabled(hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumableRemoveSkillButton then
        self.ItemInspectorConsumableRemoveSkillButton:SetEnabled(hasEmbeddedTrait and tonumber(self.SelectedItemConsumableTraitSkillIndex) ~= nil)
    end

    if self.ItemInspectorConsumableAutoAuraDatasetDropdown then
        self.ItemInspectorConsumableAutoAuraDatasetDropdown:SetItems(self:BuildItemInspectorDatasetItems())
        self.ItemInspectorConsumableAutoAuraDatasetDropdown:SetSelectedValue(consumableAutoAuraDatasetId or "", true)
        setDropdownEnabled(self.ItemInspectorConsumableAutoAuraDatasetDropdown, hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumableAutoAuraDropdown then
        self:RefreshItemInspectorConsumablePendingAuraDropdown()
        self.ItemInspectorConsumableAutoAuraDropdown:SetSelectedValue(consumableAutomaticAura and consumableAutomaticAura.auraRef or "", true)
        setDropdownEnabled(self.ItemInspectorConsumableAutoAuraDropdown, hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumableAutoAuraTargetDropdown then
        self.ItemInspectorConsumableAutoAuraTargetDropdown:SetSelectedValue(consumableAutomaticAura and consumableAutomaticAura.targetScope or "self", true)
        setDropdownEnabled(self.ItemInspectorConsumableAutoAuraTargetDropdown, hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumableAutoAuraStacksInput then
        self.ItemInspectorConsumableAutoAuraStacksInput:SetText(tostring(consumableAutomaticAura and consumableAutomaticAura.stacks or 1))
        setTextElementEnabled(self.ItemInspectorConsumableAutoAuraStacksInput, hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumableAutoAuraTurnsInput then
        self.ItemInspectorConsumableAutoAuraTurnsInput:SetText(tostring(consumableAutomaticAura and consumableAutomaticAura.turns or 1))
        setTextElementEnabled(self.ItemInspectorConsumableAutoAuraTurnsInput, hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumableAutoAuraPowerInput then
        self.ItemInspectorConsumableAutoAuraPowerInput:SetText(tostring(consumableAutomaticAura and consumableAutomaticAura.powerLevel or 0))
        setTextElementEnabled(self.ItemInspectorConsumableAutoAuraPowerInput, hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumableAutoAuraSaveButton then
        self.ItemInspectorConsumableAutoAuraSaveButton:SetEnabled(hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumableAutoAuraClearButton then
        self.ItemInspectorConsumableAutoAuraClearButton:SetEnabled(hasEmbeddedTrait and consumableAutomaticAura ~= nil)
    end

    local selectedConsumableEvent = consumableTrait and consumableTrait.events and consumableTrait.events[tonumber(self.SelectedItemConsumableTraitEventIndex) or 0] or nil
    local selectedConsumableEffect = selectedConsumableEvent and selectedConsumableEvent.effects and selectedConsumableEvent.effects[1] or nil
    local pendingConsumableEffectType = self.ItemInspectorConsumablePendingEffectDropdown and self.ItemInspectorConsumablePendingEffectDropdown.GetSelectedValue and self.ItemInspectorConsumablePendingEffectDropdown:GetSelectedValue() or "damage"
    local pendingConsumableEffectDatasetId = self.ItemInspectorConsumablePendingEffectDatasetDropdown and self.ItemInspectorConsumablePendingEffectDatasetDropdown.GetSelectedValue and self.ItemInspectorConsumablePendingEffectDatasetDropdown:GetSelectedValue() or ""
    local selectedConsumableEffectType = ensureString(selectedConsumableEffect and selectedConsumableEffect.type)
    if selectedConsumableEffectType == "" then
        selectedConsumableEffectType = ensureString(pendingConsumableEffectType)
    end
    local isConsumableEventDamage = selectedConsumableEffectType == "damage"
    local isConsumableEventHeal = selectedConsumableEffectType == "heal"
    local isConsumableEventApplyAura = selectedConsumableEffectType == "apply_aura"
    local isConsumableEventRemoveAura = selectedConsumableEffectType == "remove_aura"
    local isConsumableEventResource = selectedConsumableEffectType == "resource"
    local consumableEventUsesAmountMode = isConsumableEventDamage or isConsumableEventHeal or isConsumableEventResource
    local consumableEffectNeedsReference = isConsumableEventApplyAura or isConsumableEventRemoveAura or isConsumableEventResource
    if self.ItemInspectorConsumablePendingEffectAmountLabel and self.ItemInspectorConsumablePendingEffectAmountLabel.SetText then
        local amountLabel = "Damage"
        if isConsumableEventApplyAura or isConsumableEventRemoveAura then
            amountLabel = "Stacks"
        elseif isConsumableEventResource then
            amountLabel = "Resource Amount"
        elseif selectedConsumableEffectType == "heal" then
            amountLabel = "Healing"
        end
        self.ItemInspectorConsumablePendingEffectAmountLabel:SetText(amountLabel)
    end
    if self.ItemInspectorConsumablePendingEventDetailLabels then
        if self.ItemInspectorConsumablePendingEventDetailLabels[1] and self.ItemInspectorConsumablePendingEventDetailLabels[1].SetText then
            self.ItemInspectorConsumablePendingEventDetailLabels[1]:SetText(isConsumableEventResource and "Resource Dataset" or "Aura Dataset")
        end
        if self.ItemInspectorConsumablePendingEventDetailLabels[2] and self.ItemInspectorConsumablePendingEventDetailLabels[2].SetText then
            self.ItemInspectorConsumablePendingEventDetailLabels[2]:SetText(isConsumableEventResource and "Resource" or "Aura")
        end
    end
    if self.ItemInspectorConsumablePendingEventExtraLabels then
        if self.ItemInspectorConsumablePendingEventExtraLabels[1] and self.ItemInspectorConsumablePendingEventExtraLabels[1].SetText then
            self.ItemInspectorConsumablePendingEventExtraLabels[1]:SetText("Aura Duration")
        end
        if self.ItemInspectorConsumablePendingEventExtraLabels[2] and self.ItemInspectorConsumablePendingEventExtraLabels[2].SetText then
            self.ItemInspectorConsumablePendingEventExtraLabels[2]:SetText("Base Power")
        end
    end
    local consumableEffectDatasetId = parseDatasetQualifiedRef(
        isConsumableEventResource and selectedConsumableEffect and selectedConsumableEffect.resourceRef
            or selectedConsumableEffect and selectedConsumableEffect.auraRef
            or ""
    )
    consumableEffectDatasetId = consumableEffectDatasetId or pendingConsumableEffectDatasetId
    if self.ItemInspectorConsumablePendingCombatEventDropdown then
        self.ItemInspectorConsumablePendingCombatEventDropdown:SetItems(self:GetSpellInspectorEventItems())
        self.ItemInspectorConsumablePendingCombatEventDropdown:SetSelectedValue(selectedConsumableEvent and selectedConsumableEvent.combatEventId or "", true)
        setDropdownEnabled(self.ItemInspectorConsumablePendingCombatEventDropdown, hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumablePendingTriggerTargetDropdown then
        self.ItemInspectorConsumablePendingTriggerTargetDropdown:SetSelectedValue(selectedConsumableEvent and selectedConsumableEvent.triggerTarget or "event_other", true)
        setDropdownEnabled(self.ItemInspectorConsumablePendingTriggerTargetDropdown, hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumablePendingEffectDropdown then
        self.ItemInspectorConsumablePendingEffectDropdown:SetSelectedValue(selectedConsumableEffectType ~= "" and selectedConsumableEffectType or "damage", true)
        setDropdownEnabled(self.ItemInspectorConsumablePendingEffectDropdown, hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumablePendingEffectAmountInput then
        local amountValue = selectedConsumableEffect and (
            selectedConsumableEffect.baseDamage
            or selectedConsumableEffect.baseHealing
            or selectedConsumableEffect.amount
            or selectedConsumableEffect.stacks
        ) or 0
        self.ItemInspectorConsumablePendingEffectAmountInput:SetText(tostring(amountValue))
        setTextElementEnabled(self.ItemInspectorConsumablePendingEffectAmountInput, hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumablePendingEffectAmountModeDropdown then
        self.ItemInspectorConsumablePendingEffectAmountModeDropdown:SetItems(self:GetAuraInspectorAmountModeItems())
        self.ItemInspectorConsumablePendingEffectAmountModeDropdown:SetSelectedValue(selectedConsumableEffect and selectedConsumableEffect.amountMode or "flat", true)
        setDropdownEnabled(self.ItemInspectorConsumablePendingEffectAmountModeDropdown, hasEmbeddedTrait and consumableEventUsesAmountMode)
    end
    if self.ItemInspectorConsumablePendingEventChanceInput then
        self.ItemInspectorConsumablePendingEventChanceInput:SetText(tostring(selectedConsumableEvent and selectedConsumableEvent.chance or 100))
        setTextElementEnabled(self.ItemInspectorConsumablePendingEventChanceInput, hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumablePendingEffectDatasetDropdown then
        self.ItemInspectorConsumablePendingEffectDatasetDropdown:SetItems(self:BuildItemInspectorDatasetItems())
        self.ItemInspectorConsumablePendingEffectDatasetDropdown:SetSelectedValue(consumableEffectDatasetId or "", true)
        setDropdownEnabled(self.ItemInspectorConsumablePendingEffectDatasetDropdown, hasEmbeddedTrait and consumableEffectNeedsReference)
    end
    if self.ItemInspectorConsumablePendingEffectReferenceDropdown then
        self:RefreshItemInspectorConsumablePendingEffectReferenceDropdown()
        self.ItemInspectorConsumablePendingEffectReferenceDropdown:SetSelectedValue(
            isConsumableEventResource and selectedConsumableEffect and selectedConsumableEffect.resourceRef
                or selectedConsumableEffect and selectedConsumableEffect.auraRef
                or "",
            true
        )
        setDropdownEnabled(self.ItemInspectorConsumablePendingEffectReferenceDropdown, hasEmbeddedTrait and consumableEffectNeedsReference)
    end
    if self.ItemInspectorConsumablePendingEventSchoolDropdown then
        self.ItemInspectorConsumablePendingEventSchoolDropdown:SetItems(self:BuildSpellInspectorDamageSchoolsAcrossDatasets())
        self.ItemInspectorConsumablePendingEventSchoolDropdown:SetSelectedValues(selectedConsumableEffect and selectedConsumableEffect.damageSchoolRefs or {}, true)
        setDropdownEnabled(self.ItemInspectorConsumablePendingEventSchoolDropdown, hasEmbeddedTrait and isConsumableEventDamage)
    end
    if self.ItemInspectorConsumablePendingEffectAuxInput then
        self.ItemInspectorConsumablePendingEffectAuxInput:SetText(tostring(selectedConsumableEffect and selectedConsumableEffect.duration or 0))
        setTextElementEnabled(self.ItemInspectorConsumablePendingEffectAuxInput, hasEmbeddedTrait and isConsumableEventApplyAura)
    end
    if self.ItemInspectorConsumablePendingEffectExtraInput then
        self.ItemInspectorConsumablePendingEffectExtraInput:SetText(tostring(selectedConsumableEffect and selectedConsumableEffect.basePower or 0))
        setTextElementEnabled(self.ItemInspectorConsumablePendingEffectExtraInput, hasEmbeddedTrait and isConsumableEventApplyAura)
    end
    setElementGroupVisible(self.ItemInspectorConsumablePendingEventSchoolGroup, hasEmbeddedTrait and isConsumableEventDamage)
    setElementGroupVisible(self.ItemInspectorConsumablePendingEventDetailHeaderRow, hasEmbeddedTrait and consumableEffectNeedsReference)
    setElementGroupVisible(self.ItemInspectorConsumablePendingEventDetailRow, hasEmbeddedTrait and consumableEffectNeedsReference)
    setElementGroupVisible(self.ItemInspectorConsumablePendingEventExtraHeaderRow, hasEmbeddedTrait and isConsumableEventApplyAura)
    setElementGroupVisible(self.ItemInspectorConsumablePendingEventExtraRow, hasEmbeddedTrait and isConsumableEventApplyAura)
    if self.ItemInspectorConsumableAddEventButton then
        self.ItemInspectorConsumableAddEventButton:SetEnabled(hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumableNewEventButton then
        self.ItemInspectorConsumableNewEventButton:SetEnabled(hasEmbeddedTrait)
    end
    if self.ItemInspectorConsumableRemoveEventButton then
        self.ItemInspectorConsumableRemoveEventButton:SetEnabled(hasEmbeddedTrait and tonumber(self.SelectedItemConsumableTraitEventIndex) ~= nil)
    end

    self:RefreshItemInspectorConsumableTraitStatTable()
    self:RefreshItemInspectorConsumableTraitEventTable()

    for index = 1, #(self.ItemInspectorConsumableSections or {}) do
        local section = self.ItemInspectorConsumableSections[index]
        if section and section.UpdateHeight then
            section:UpdateHeight()
        end
    end

    if self.ItemInspectorPendingStatDatasetDropdown then
        self.ItemInspectorPendingStatDatasetDropdown:SetItems(self:BuildItemInspectorDatasetItems())
        setDropdownEnabled(self.ItemInspectorPendingStatDatasetDropdown, hasItem)
    end

    if self.ItemInspectorPendingStatDropdown then
        self:RefreshItemInspectorPendingStatDropdown()
        setDropdownEnabled(self.ItemInspectorPendingStatDropdown, hasItem)
    end

    if self.ItemInspectorPendingStatValueInput then
        setTextElementEnabled(self.ItemInspectorPendingStatValueInput, hasItem)
    end

    if self.ItemInspectorAddStatButton then
        self.ItemInspectorAddStatButton:SetEnabled(hasItem)
    end

    if self.ItemInspectorPendingSkillDatasetDropdown then
        self.ItemInspectorPendingSkillDatasetDropdown:SetItems(self:BuildItemInspectorDatasetItems())
        setDropdownEnabled(self.ItemInspectorPendingSkillDatasetDropdown, hasItem)
    end

    if self.ItemInspectorPendingSkillDropdown then
        self:RefreshItemInspectorPendingSkillDropdown()
        setDropdownEnabled(self.ItemInspectorPendingSkillDropdown, hasItem)
    end

    if self.ItemInspectorPendingSkillValueInput then
        setTextElementEnabled(self.ItemInspectorPendingSkillValueInput, hasItem)
    end

    if self.ItemInspectorAddSkillButton then
        self.ItemInspectorAddSkillButton:SetEnabled(hasItem)
    end

    self:RefreshItemInspectorStatsTable()
    self:RefreshItemInspectorSkillsTable()

    self._refreshingItemInspector = false
    if self.ItemInspectorConsumableRoot and self.ItemInspectorConsumableRoot.RefreshLayout then
        self.ItemInspectorConsumableRoot:RefreshLayout()
    end
    if self.RefreshItemInspectorConsumableScrollBounds then
        self:RefreshItemInspectorConsumableScrollBounds()
    end
    self:RefreshItemInspectorPageSelector()

    if self.ItemInspectorConsumableEmptyText then
        self.ItemInspectorConsumableEmptyText:SetText(
            isConsumable and "Edit the selected consumable trait here."
                or (hasEmbeddedTrait and "Edit the selected embedded trait here." or "This page is only available for consumable, weapon, armor, and modification items.")
        )
    end
    if self.ItemInspectorEmptyText then
        if hasItem then
            self.ItemInspectorEmptyText:SetText(("Adjust the selected %s %s here."):format(getQualityLabel(item and item.quality), getItemTypeLabel(item and item.itemType)))
        else
            self.ItemInspectorEmptyText:SetText("Select an item to inspect it.")
        end
    end

    if hasItem and self.ActiveItemInspectorTabKey == nil then
        self:SetItemInspectorTab("general")
    end
end
