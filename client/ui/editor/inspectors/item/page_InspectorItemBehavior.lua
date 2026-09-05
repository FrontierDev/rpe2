local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Shared = DataEditor.ItemInspectorShared or {}
local FIELD_WIDTH = Shared.FIELD_WIDTH or 236
local CONTROL_HEIGHT = Shared.CONTROL_HEIGHT or 20
local UNIQUE_FLAG_ITEMS = Shared.UNIQUE_FLAG_ITEMS or {}
local BINDING_FLAG_ITEMS = Shared.BINDING_FLAG_ITEMS or {}
local buildLabel = Shared.buildLabel
local createCheckbox = Shared.createCheckbox

local function buildBehaviorPage(self, page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorItemInspectorBehaviorLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorItemInspectorUniqueFlagLabel", "Unique Flag"))
    self.ItemInspectorUniqueFlagDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorItemInspectorUniqueFlagDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = UNIQUE_FLAG_ITEMS,
        onValueChanged = function(value)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                item.uniqueFlag = value or "none"
            end)
        end,
    })
    root:AddChild(self.ItemInspectorUniqueFlagDropdown)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorItemInspectorBindingFlagLabel", "Binding Flag"))
    self.ItemInspectorBindingFlagDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorItemInspectorBindingFlagDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = BINDING_FLAG_ITEMS,
        onValueChanged = function(value)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                item.bindingFlag = value or "none"
            end)
        end,
    })
    root:AddChild(self.ItemInspectorBindingFlagDropdown)

    self.ItemInspectorCanStackCheckbox = createCheckbox(root:GetFrame(), "RPEDataEditorItemInspectorCanStackCheckbox", "Can Stack", true, function(checked)
        if self._refreshingItemInspector then
            return
        end

        self:CommitSelectedItem(function(item)
            item.canStack = checked == true
            if item.canStack ~= true then
                item.maxStackSize = 1
            end
        end)
    end)
    root:AddChild(self.ItemInspectorCanStackCheckbox)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorItemInspectorMaxStackSizeLabel", "Max Stack Size"))
    self.ItemInspectorMaxStackSizeInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorItemInspectorMaxStackSizeInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "99",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorMaxStackSizeInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedItem(function(item)
            item.maxStackSize = math.max(1, tonumber(self.ItemInspectorMaxStackSizeInput:GetText()) or 1)
        end)
    end)
    self.ItemInspectorMaxStackSizeInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedItem(function(item)
            item.maxStackSize = math.max(1, tonumber(self.ItemInspectorMaxStackSizeInput:GetText()) or 1)
        end)
    end)
    root:AddChild(self.ItemInspectorMaxStackSizeInput)

    self.ItemInspectorCanTradeCheckbox = createCheckbox(root:GetFrame(), "RPEDataEditorItemInspectorCanTradeCheckbox", "Can Trade", true, function(checked)
        if self._refreshingItemInspector then
            return
        end

        self:CommitSelectedItem(function(item)
            item.canTrade = checked == true
        end)
    end)
    root:AddChild(self.ItemInspectorCanTradeCheckbox)

    self.ItemInspectorCanSellCheckbox = createCheckbox(root:GetFrame(), "RPEDataEditorItemInspectorCanSellCheckbox", "Can Sell", true, function(checked)
        if self._refreshingItemInspector then
            return
        end

        self:CommitSelectedItem(function(item)
            item.canSell = checked == true
        end)
    end)
    root:AddChild(self.ItemInspectorCanSellCheckbox)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorItemInspectorSellPriceLabel", "Sell Price (0 = auto)"))
    self.ItemInspectorSellPriceInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorItemInspectorSellPriceInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorSellPriceInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedItem(function(item)
            item.sellPrice = tonumber(self.ItemInspectorSellPriceInput:GetText()) or 0
        end)
    end)
    self.ItemInspectorSellPriceInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedItem(function(item)
            item.sellPrice = tonumber(self.ItemInspectorSellPriceInput:GetText()) or 0
        end)
    end)
    root:AddChild(self.ItemInspectorSellPriceInput)

    self.ItemInspectorCanDisenchantCheckbox = createCheckbox(root:GetFrame(), "RPEDataEditorItemInspectorCanDisenchantCheckbox", "Can Disenchant", true, function(checked)
        if self._refreshingItemInspector then
            return
        end

        self:CommitSelectedItem(function(item)
            item.canDisenchant = checked == true
        end)
    end)
    root:AddChild(self.ItemInspectorCanDisenchantCheckbox)

    self.ItemInspectorAllowWowConversionGroup = createCheckbox(root:GetFrame(), "RPEDataEditorItemInspectorAllowWowConversionCheckbox", "Allow WoW Conversion", false, function(checked)
        if self._refreshingItemInspector then
            return
        end

        self:CommitSelectedItem(function(item)
            item.allowWowConversion = checked == true
            if item.allowWowConversion ~= true then
                item.wowConversionSkillRef = nil
            end
        end)
    end)
    root:AddChild(self.ItemInspectorAllowWowConversionGroup)

    self.ItemInspectorWowConversionSkillLabel = buildLabel(root:GetFrame(), "RPEDataEditorItemInspectorWowConversionSkillLabel", "Conversion Skill")
    root:AddChild(self.ItemInspectorWowConversionSkillLabel)
    self.ItemInspectorWowConversionSkillDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorItemInspectorWowConversionSkillDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = self:BuildItemInspectorCraftingSkillItems(),
        onValueChanged = function(value)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                item.wowConversionSkillRef = value ~= "" and value or nil
            end)
        end,
    })
    root:AddChild(self.ItemInspectorWowConversionSkillDropdown)
end

function DataEditor:BuildItemInspectorBehaviorPage(page)
    return buildBehaviorPage(self, page)
end
