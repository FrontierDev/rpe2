local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Shared = DataEditor.ItemInspectorShared or {}
local FIELD_WIDTH = Shared.FIELD_WIDTH or 236
local CONTROL_HEIGHT = Shared.CONTROL_HEIGHT or 20
local ITEM_TYPE_ITEMS = Shared.ITEM_TYPE_ITEMS or {}
local CONSUMABLE_TYPE_ITEMS = Shared.CONSUMABLE_TYPE_ITEMS or {}
local CONSUMABLE_ELIXIR_TYPE_ITEMS = Shared.CONSUMABLE_ELIXIR_TYPE_ITEMS or {}
local ARMOR_WEIGHT_ITEMS = Shared.ARMOR_WEIGHT_ITEMS or {}
local DAMAGE_MODE_ITEMS = Shared.DAMAGE_MODE_ITEMS or {}
local copyTable = Shared.copyTable
local buildHintText = Shared.buildHintText
local createCheckbox = Shared.createCheckbox
local createEquipmentFieldGroup = Shared.createEquipmentFieldGroup
local applyItemTypeDefaults = Shared.applyItemTypeDefaults

local function buildEquipmentPage(self, page)
    local function handleMouseWheel(_, delta)
        local _, maxValue = self.ItemInspectorEquipmentScrollBar:GetMinMaxValues()
        local current = self.ItemInspectorEquipmentScrollBar:GetValue() or 0
        local nextValue = math.max(0, math.min(maxValue or 0, current - ((delta or 0) * 24)))
        self.ItemInspectorEquipmentScrollBar:SetValue(nextValue)
    end

    local function attachMouseWheel(target)
        local frame = target and target.GetFrame and target:GetFrame() or target
        if not frame then
            return
        end

        if frame.EnableMouseWheel then
            frame:EnableMouseWheel(true)
        end

        if frame.HookScript then
            frame:HookScript("OnMouseWheel", handleMouseWheel)
        elseif frame.SetScript then
            frame:SetScript("OnMouseWheel", handleMouseWheel)
        end
    end

    self.ItemInspectorEquipmentScrollFrame = CreateFrame("ScrollFrame", "RPEDataEditorItemInspectorEquipmentScrollFrame", page)
    self.ItemInspectorEquipmentScrollFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    self.ItemInspectorEquipmentScrollFrame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -20, 0)
    self.ItemInspectorEquipmentScrollFrame:EnableMouseWheel(true)
    self.ItemInspectorEquipmentScrollFrame:SetClipsChildren(true)
    attachMouseWheel(page)
    attachMouseWheel(self.ItemInspectorEquipmentScrollFrame)

    self.ItemInspectorEquipmentScrollBar = CreateFrame("Slider", "RPEDataEditorItemInspectorEquipmentScrollBar", page)
    self.ItemInspectorEquipmentScrollBar:SetPoint("TOPRIGHT", page, "TOPRIGHT", -4, -2)
    self.ItemInspectorEquipmentScrollBar:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -4, 2)
    self.ItemInspectorEquipmentScrollBar:SetOrientation("VERTICAL")
    self.ItemInspectorEquipmentScrollBar:SetMinMaxValues(0, 0)
    self.ItemInspectorEquipmentScrollBar:SetValueStep(12)
    if self.ItemInspectorEquipmentScrollBar.SetObeyStepOnDrag then
        self.ItemInspectorEquipmentScrollBar:SetObeyStepOnDrag(true)
    end
    self.ItemInspectorEquipmentScrollBar:SetWidth(12)

    self.ItemInspectorEquipmentScrollBarTrack = self.ItemInspectorEquipmentScrollBarTrack or self.ItemInspectorEquipmentScrollBar:CreateTexture(nil, "BACKGROUND")
    self.ItemInspectorEquipmentScrollBarTrack:SetAllPoints(self.ItemInspectorEquipmentScrollBar)
    do
        local trackColor = UI.ResolveColor(nil, "scrollbar.track")
        self.ItemInspectorEquipmentScrollBarTrack:SetColorTexture(trackColor.r or 0.08, trackColor.g or 0.09, trackColor.b or 0.11, trackColor.a or 0.95)
    end

    self.ItemInspectorEquipmentScrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    do
        local thumb = self.ItemInspectorEquipmentScrollBar.GetThumbTexture and self.ItemInspectorEquipmentScrollBar:GetThumbTexture() or nil
        if thumb and thumb.SetVertexColor then
            local thumbColor = UI.ResolveColor(nil, "scrollbar.thumb")
            thumb:SetVertexColor(thumbColor.r or 0.42, thumbColor.g or 0.46, thumbColor.b or 0.52, thumbColor.a or 1)
        end
    end
    self.ItemInspectorEquipmentScrollBar:SetValue(0)

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, self.ItemInspectorEquipmentScrollFrame, "RPEDataEditorItemInspectorEquipmentLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        autoSize = true,
    })
    root:GetFrame():SetPoint("TOPLEFT", self.ItemInspectorEquipmentScrollFrame, "TOPLEFT", 0, 0)
    root:GetFrame():SetPoint("TOPRIGHT", self.ItemInspectorEquipmentScrollFrame, "TOPRIGHT", 0, 0)
    self.ItemInspectorEquipmentLayout = root
    self.ItemInspectorEquipmentScrollFrame:SetScrollChild(root:GetFrame())
    self.ItemInspectorEquipmentScrollBar:SetScript("OnValueChanged", function(_, value)
        self.ItemInspectorEquipmentScrollFrame:SetVerticalScroll(value or 0)
    end)
    self.ItemInspectorEquipmentScrollFrame:SetScript("OnMouseWheel", handleMouseWheel)
    self.ItemInspectorEquipmentScrollFrame:SetScript("OnSizeChanged", function(scrollFrame)
        local width = math.max(1, (scrollFrame:GetWidth() or FIELD_WIDTH) - 4)
        root:GetFrame():SetWidth(width)
        if root.RefreshLayout then
            root:RefreshLayout()
        end
    end)

    self.ItemInspectorItemTypeGroup = createEquipmentFieldGroup(root, "RPEDataEditorItemInspectorTypeGroup", "Item Type", 18)
    self.ItemInspectorItemTypeDropdown = UI.CreateDropdown(self.ItemInspectorItemTypeGroup:GetFrame(), "RPEDataEditorItemInspectorItemTypeDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = ITEM_TYPE_ITEMS,
        onValueChanged = function(value)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                item.itemType = value or "none"
                applyItemTypeDefaults(item)
            end)
        end,
    })
    self.ItemInspectorItemTypeGroup:AddChild(self.ItemInspectorItemTypeDropdown)

    self.ItemInspectorConsumableTypeGroup = createEquipmentFieldGroup(root, "RPEDataEditorItemInspectorConsumableTypeGroup", "Consumable Type", 18)
    self.ItemInspectorConsumableTypeDropdown = UI.CreateDropdown(self.ItemInspectorConsumableTypeGroup:GetFrame(), "RPEDataEditorItemInspectorConsumableTypeDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = CONSUMABLE_TYPE_ITEMS,
        onValueChanged = function(value)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                item.consumableType = value or ""
                if item.consumableType == "elixir" then
                    item.consumableElixirType = tostring(item.consumableElixirType or "") ~= "" and item.consumableElixirType or "generic"
                else
                    item.consumableElixirType = ""
                end
            end)
        end,
    })
    self.ItemInspectorConsumableTypeGroup:AddChild(self.ItemInspectorConsumableTypeDropdown)

    self.ItemInspectorConsumableElixirTypeGroup = createEquipmentFieldGroup(root, "RPEDataEditorItemInspectorConsumableElixirTypeGroup", "Elixir Type", 18)
    self.ItemInspectorConsumableElixirTypeDropdown = UI.CreateDropdown(self.ItemInspectorConsumableElixirTypeGroup:GetFrame(), "RPEDataEditorItemInspectorConsumableElixirTypeDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = CONSUMABLE_ELIXIR_TYPE_ITEMS,
        onValueChanged = function(value)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                item.consumableElixirType = value or "generic"
            end)
        end,
    })
    self.ItemInspectorConsumableElixirTypeGroup:AddChild(self.ItemInspectorConsumableElixirTypeDropdown)

    self.ItemInspectorWeaponTypeGroup = createEquipmentFieldGroup(root, "RPEDataEditorItemInspectorWeaponTypeGroup", "Weapon Type", 18)
    self.ItemInspectorWeaponTypeDropdown = UI.CreateDropdown(self.ItemInspectorWeaponTypeGroup:GetFrame(), "RPEDataEditorItemInspectorWeaponTypeDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = self:BuildItemInspectorWeaponTypeItems(),
        onValueChanged = function(value)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                item.weaponTypeRef = value ~= "" and value or nil
            end)
        end,
    })
    self.ItemInspectorWeaponTypeGroup:AddChild(self.ItemInspectorWeaponTypeDropdown)

    self.ItemInspectorArmorWeightGroup = createEquipmentFieldGroup(root, "RPEDataEditorItemInspectorArmorWeightGroup", "Armor Weight", 18)
    self.ItemInspectorArmorWeightDropdown = UI.CreateDropdown(self.ItemInspectorArmorWeightGroup:GetFrame(), "RPEDataEditorItemInspectorArmorWeightDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = ARMOR_WEIGHT_ITEMS,
        onValueChanged = function(value)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                item.armorWeight = value or "cosmetic"
            end)
        end,
    })
    self.ItemInspectorArmorWeightGroup:AddChild(self.ItemInspectorArmorWeightDropdown)

    self.ItemInspectorIsTwoHandedGroup = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), "RPEDataEditorItemInspectorTwoHandedGroup", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 0,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.ItemInspectorIsTwoHandedGroup._visibleHeight = 18
    root:AddChild(self.ItemInspectorIsTwoHandedGroup)
    self.ItemInspectorIsTwoHandedCheckbox = createCheckbox(self.ItemInspectorIsTwoHandedGroup:GetFrame(), "RPEDataEditorItemInspectorTwoHandedCheckbox", "Two-Handed", false, function(checked)
        if self._refreshingItemInspector then
            return
        end

        self:CommitSelectedItem(function(item)
            item.isTwoHanded = checked == true
        end)
    end)
    self.ItemInspectorIsTwoHandedGroup:AddChild(self.ItemInspectorIsTwoHandedCheckbox)

    self.ItemInspectorDamageModeGroup = createEquipmentFieldGroup(root, "RPEDataEditorItemInspectorDamageModeGroup", "Damage Mode", 18)
    self.ItemInspectorDamageModeDropdown = UI.CreateDropdown(self.ItemInspectorDamageModeGroup:GetFrame(), "RPEDataEditorItemInspectorDamageModeDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = DAMAGE_MODE_ITEMS,
        onValueChanged = function(value)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                item.damageMode = value or "fixed"
            end)
        end,
    })
    self.ItemInspectorDamageModeGroup:AddChild(self.ItemInspectorDamageModeDropdown)

    self.ItemInspectorDamagePerTurnGroup = createEquipmentFieldGroup(root, "RPEDataEditorItemInspectorFixedDamageGroup", "Fixed Damage Per Turn", CONTROL_HEIGHT)
    self.ItemInspectorDamagePerTurnInput = UI.CreateTextInput(self.ItemInspectorDamagePerTurnGroup:GetFrame(), "RPEDataEditorItemInspectorDamagePerTurnInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorDamagePerTurnInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedItem(function(item)
            item.damagePerTurn = tonumber(self.ItemInspectorDamagePerTurnInput:GetText()) or 0
        end)
    end)
    self.ItemInspectorDamagePerTurnInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedItem(function(item)
            item.damagePerTurn = tonumber(self.ItemInspectorDamagePerTurnInput:GetText()) or 0
        end)
    end)
    self.ItemInspectorDamagePerTurnGroup:AddChild(self.ItemInspectorDamagePerTurnInput)

    self.ItemInspectorMinDamagePerTurnGroup = createEquipmentFieldGroup(root, "RPEDataEditorItemInspectorMinDamageGroup", "Min Damage Per Turn", CONTROL_HEIGHT)
    self.ItemInspectorMinDamagePerTurnInput = UI.CreateTextInput(self.ItemInspectorMinDamagePerTurnGroup:GetFrame(), "RPEDataEditorItemInspectorMinDamagePerTurnInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorMinDamagePerTurnInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedItem(function(item)
            item.minDamagePerTurn = tonumber(self.ItemInspectorMinDamagePerTurnInput:GetText()) or 0
        end)
    end)
    self.ItemInspectorMinDamagePerTurnInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedItem(function(item)
            item.minDamagePerTurn = tonumber(self.ItemInspectorMinDamagePerTurnInput:GetText()) or 0
        end)
    end)
    self.ItemInspectorMinDamagePerTurnGroup:AddChild(self.ItemInspectorMinDamagePerTurnInput)

    self.ItemInspectorMaxDamagePerTurnGroup = createEquipmentFieldGroup(root, "RPEDataEditorItemInspectorMaxDamageGroup", "Max Damage Per Turn", CONTROL_HEIGHT)
    self.ItemInspectorMaxDamagePerTurnInput = UI.CreateTextInput(self.ItemInspectorMaxDamagePerTurnGroup:GetFrame(), "RPEDataEditorItemInspectorMaxDamagePerTurnInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorMaxDamagePerTurnInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedItem(function(item)
            item.maxDamagePerTurn = tonumber(self.ItemInspectorMaxDamagePerTurnInput:GetText()) or 0
        end)
    end)
    self.ItemInspectorMaxDamagePerTurnInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedItem(function(item)
            item.maxDamagePerTurn = tonumber(self.ItemInspectorMaxDamagePerTurnInput:GetText()) or 0
        end)
    end)
    self.ItemInspectorMaxDamagePerTurnGroup:AddChild(self.ItemInspectorMaxDamagePerTurnInput)

    self.ItemInspectorDamageSchoolGroup = createEquipmentFieldGroup(root, "RPEDataEditorItemInspectorDamageSchoolGroup", "Damage School", 18)
    self.ItemInspectorDamageSchoolDropdown = UI.CreateDropdown(self.ItemInspectorDamageSchoolGroup:GetFrame(), "RPEDataEditorItemInspectorDamageSchoolDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = {
            { label = "None", value = "" },
        },
        onValueChanged = function(value)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                item.damageSchoolRef = value ~= "" and value or nil
            end)
        end,
    })
    self.ItemInspectorDamageSchoolGroup:AddChild(self.ItemInspectorDamageSchoolDropdown)

    self.ItemInspectorValidSlotsGroup = createEquipmentFieldGroup(root, "RPEDataEditorItemInspectorValidSlotsGroup", "Valid Slots", 18)
    self.ItemInspectorValidSlotsDropdown = UI.CreateDropdown(self.ItemInspectorValidSlotsGroup:GetFrame(), "RPEDataEditorItemInspectorValidSlotsDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = self:BuildItemInspectorItemSlotItems(),
        multiSelect = true,
        showSelectionActions = false,
        onValueChanged = function(values)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                item.validSlotRefs = copyTable(values or {})
            end)
        end,
    })
    self.ItemInspectorValidSlotsGroup:AddChild(self.ItemInspectorValidSlotsDropdown)

    self.ItemInspectorItemLevelOverrideGroup = createEquipmentFieldGroup(root, "RPEDataEditorItemInspectorItemLevelOverrideGroup", "Item Level Override (0 = auto)", CONTROL_HEIGHT)
    self.ItemInspectorItemLevelOverrideInput = UI.CreateTextInput(self.ItemInspectorItemLevelOverrideGroup:GetFrame(), "RPEDataEditorItemInspectorItemLevelOverrideInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorItemLevelOverrideInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedItem(function(item)
            item.itemLevel = tonumber(self.ItemInspectorItemLevelOverrideInput:GetText()) or 0
        end)
    end)
    self.ItemInspectorItemLevelOverrideInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedItem(function(item)
            item.itemLevel = tonumber(self.ItemInspectorItemLevelOverrideInput:GetText()) or 0
        end)
    end)
    self.ItemInspectorItemLevelOverrideGroup:AddChild(self.ItemInspectorItemLevelOverrideInput)

    self.ItemInspectorResolvedItemLevelGroup = createEquipmentFieldGroup(root, "RPEDataEditorItemInspectorResolvedItemLevelGroup", "Resolved Item Level", 16)
    self.ItemInspectorResolvedItemLevelText = buildHintText(self.ItemInspectorResolvedItemLevelGroup:GetFrame(), "RPEDataEditorItemInspectorResolvedItemLevelText", "--", FIELD_WIDTH, 16)
    self.ItemInspectorResolvedItemLevelGroup:AddChild(self.ItemInspectorResolvedItemLevelText)

    local function refreshScrollBounds()
        local contentHeight = root:GetFrame() and root:GetFrame():GetHeight() or 0
        local viewportHeight = self.ItemInspectorEquipmentScrollFrame and self.ItemInspectorEquipmentScrollFrame:GetHeight() or 0
        local maxScroll = math.max(0, math.ceil(contentHeight - viewportHeight))

        self.ItemInspectorEquipmentScrollBar:SetMinMaxValues(0, maxScroll)
        if self.ItemInspectorEquipmentScrollBar.SetShown then
            self.ItemInspectorEquipmentScrollBar:SetShown(maxScroll > 0)
        elseif maxScroll > 0 and self.ItemInspectorEquipmentScrollBar.Show then
            self.ItemInspectorEquipmentScrollBar:Show()
        elseif self.ItemInspectorEquipmentScrollBar.Hide then
            self.ItemInspectorEquipmentScrollBar:Hide()
        end
        if (self.ItemInspectorEquipmentScrollBar:GetValue() or 0) > maxScroll then
            self.ItemInspectorEquipmentScrollBar:SetValue(maxScroll)
        end
    end

    self.RefreshItemInspectorEquipmentScrollBounds = refreshScrollBounds
    self.ItemInspectorEquipmentScrollFrame:SetScript("OnShow", refreshScrollBounds)
end

function DataEditor:BuildItemInspectorEquipmentPage(page)
    return buildEquipmentPage(self, page)
end
