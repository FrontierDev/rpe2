local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildSpellInspectorCastingPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorSpellInspectorCastingLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorCastTimeLabel", "Cast Time"))
    self.SpellInspectorCastTimeSlider = UI.SliderBar:New({
        name = "RPEDataEditorSpellInspectorCastTimeSlider",
        width = self.SpellInspectorFieldWidth,
        height = 18,
        minValue = 0,
        maxValue = 10,
        step = 1,
        value = 0,
        valueFormat = "%d",
        deferValueChangedUntilMouseUp = true,
        onValueChanged = function(value)
            if self._refreshingSpellInspector then
                return
            end

            self:CommitSelectedSpell(function(spell)
                spell.castTime = tonumber(value) or 0
            end)
        end,
    })
    self.SpellInspectorCastTimeSlider:SetParent(root:GetFrame())
    self.SpellInspectorCastTimeSlider:Create()
    root:AddChild(self.SpellInspectorCastTimeSlider)

    self.SpellInspectorTriggersGCDCheckbox = self:CreateSpellInspectorCheckbox(root:GetFrame(), "RPEDataEditorSpellInspectorTriggersGCDCheckbox", "Triggers GCD", true, function(checked)
        if self._refreshingSpellInspector then
            return
        end

        self:CommitSelectedSpell(function(spell)
            spell.triggersGCD = checked == true
            if checked == true then
                spell.ignoreGCD = false
            end
        end)
    end)
    root:AddChild(self.SpellInspectorTriggersGCDCheckbox)

    self.SpellInspectorIgnoreGCDCheckbox = self:CreateSpellInspectorCheckbox(root:GetFrame(), "RPEDataEditorSpellInspectorIgnoreGCDCheckbox", "Ignores GCD", false, function(checked)
        if self._refreshingSpellInspector then
            return
        end

        self:CommitSelectedSpell(function(spell)
            spell.ignoreGCD = checked == true
            if checked == true then
                spell.triggersGCD = false
            end
        end)
    end)
    root:AddChild(self.SpellInspectorIgnoreGCDCheckbox)

    self.SpellInspectorMountedCombatOnlyCheckbox = self:CreateSpellInspectorCheckbox(root:GetFrame(), "RPEDataEditorSpellInspectorMountedCombatOnlyCheckbox", "Mounted Combat Only", false, function(checked)
        if self._refreshingSpellInspector then
            return
        end

        self:CommitSelectedSpell(function(spell)
            spell.mountedCombatOnly = checked == true
        end)
    end)
    root:AddChild(self.SpellInspectorMountedCombatOnlyCheckbox)

    self.SpellInspectorAllowDeadTargetsCheckbox = self:CreateSpellInspectorCheckbox(root:GetFrame(), "RPEDataEditorSpellInspectorAllowDeadTargetsCheckbox", "Can Affect Dead Targets", false, function(checked)
        if self._refreshingSpellInspector then
            return
        end

        self:CommitSelectedSpell(function(spell)
            spell.allowDeadTargets = checked == true
        end)
    end)
    root:AddChild(self.SpellInspectorAllowDeadTargetsCheckbox)
end
