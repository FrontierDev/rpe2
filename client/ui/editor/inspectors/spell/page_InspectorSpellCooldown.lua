local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildSpellInspectorCooldownPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorSpellInspectorCooldownLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorCooldownLabel", "Cooldown"))
    self.SpellInspectorCooldownSlider = UI.SliderBar:New({
        name = "RPEDataEditorSpellInspectorCooldownSlider",
        width = self.SpellInspectorFieldWidth,
        height = 18,
        minValue = 1,
        maxValue = 10,
        step = 1,
        value = 1,
        valueFormat = "%d",
        deferValueChangedUntilMouseUp = true,
        onValueChanged = function(value)
            if self._refreshingSpellInspector then
                return
            end

            self:CommitSelectedSpell(function(spell)
                spell.cooldown = tonumber(value) or 1
            end)
        end,
    })
    self.SpellInspectorCooldownSlider:SetParent(root:GetFrame())
    self.SpellInspectorCooldownSlider:Create()
    root:AddChild(self.SpellInspectorCooldownSlider)

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorChargesLabel", "Charges"))
    self.SpellInspectorChargesInput = UI.CreateTextInput(root:GetFrame(), "SpellInspectorChargesInput", {
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.SpellInspectorChargesInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedSpell(function(spell)
            spell.charges = tonumber(self.SpellInspectorChargesInput:GetText()) or 0
        end)
    end)
    self.SpellInspectorChargesInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedSpell(function(spell)
            spell.charges = tonumber(self.SpellInspectorChargesInput:GetText()) or 0
        end)
    end)
    root:AddChild(self.SpellInspectorChargesInput)

    self.SpellInspectorUseCooldownChargesCheckbox = self:CreateSpellInspectorCheckbox(root:GetFrame(), "RPEDataEditorSpellInspectorUseCooldownChargesCheckbox", "Uses Cooldown Charges", false, function(checked)
        if self._refreshingSpellInspector then
            return
        end

        self:CommitSelectedSpell(function(spell)
            spell.useCooldownCharges = checked == true
        end)
    end)
    root:AddChild(self.SpellInspectorUseCooldownChargesCheckbox)

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorCooldownGroupLabel", "Cooldown Group"))
    self.SpellInspectorCooldownGroupInput = UI.CreateTextInput(root:GetFrame(), "SpellInspectorCooldownGroupInput", {
        width = self.SpellInspectorFieldWidth,
        height = self.SpellInspectorControlHeight,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.SpellInspectorCooldownGroupInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedSpell(function(spell)
            spell.cooldownGroup = tostring(self.SpellInspectorCooldownGroupInput:GetText() or "")
        end)
    end)
    self.SpellInspectorCooldownGroupInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedSpell(function(spell)
            spell.cooldownGroup = tostring(self.SpellInspectorCooldownGroupInput:GetText() or "")
        end)
    end)
    root:AddChild(self.SpellInspectorCooldownGroupInput)
end
