local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor

local function appendUniqueItem(items, label, value)
    local output = items or {}
    for index = 1, #output do
        if tostring(output[index] and output[index].value or "") == value then
            return output
        end
    end
    output[#output + 1] = {
        label = label,
        value = value,
    }
    return output
end

local originalGetConditionTypeItems = DataEditor.GetInspectorConditionTypeItems
if type(originalGetConditionTypeItems) == "function" then
    function DataEditor:GetInspectorConditionTypeItems()
        return appendUniqueItem(originalGetConditionTypeItems(self), "Hidden", "hidden")
    end
end

local originalBuildConditionRows = DataEditor.BuildInspectorConditionRows
if type(originalBuildConditionRows) == "function" then
    function DataEditor:BuildInspectorConditionRows(ownerKey)
        local rows = originalBuildConditionRows(self, ownerKey)
        for index = 1, #(rows or {}) do
            if rows[index] and rows[index].typeText == "hidden" then
                rows[index].typeText = "Hidden"
            end
        end
        return rows
    end
end

local originalRefreshConditionsPage = DataEditor.RefreshInspectorConditionsPage
if type(originalRefreshConditionsPage) == "function" then
    function DataEditor:RefreshInspectorConditionsPage(ownerKey)
        originalRefreshConditionsPage(self, ownerKey)

        local condition = self:GetSelectedInspectorCondition(ownerKey)
        if type(condition) ~= "table" or tostring(condition.type or "") ~= "hidden" then
            return
        end

        local ui = self.ConditionInspectorUi and self.ConditionInspectorUi[ownerKey] or nil
        local group = ui and ui.UnitGroup or nil
        if not group then
            return
        end

        local height = group._visibleHeight or 32
        if group.SetHeight then
            group:SetHeight(height)
        elseif group.options then
            group.options.height = height
        end

        local frame = group.GetFrame and group:GetFrame() or nil
        if frame then
            if frame.SetHeight then
                frame:SetHeight(height)
            end
            frame:Show()
        end

        if ui.EditorRoot and ui.EditorRoot.RefreshLayout then
            ui.EditorRoot:RefreshLayout()
        end
        if type(self.RefreshInspectorConditionsScrollBounds) == "function" then
            self:RefreshInspectorConditionsScrollBounds(ownerKey)
        end
    end
end

local originalGetSpellEffectTypeItems = DataEditor.GetSpellInspectorEffectTypeItems
if type(originalGetSpellEffectTypeItems) == "function" then
    function DataEditor:GetSpellInspectorEffectTypeItems()
        return appendUniqueItem(originalGetSpellEffectTypeItems(self), "Hide", "hide")
    end
end

local originalGetAuraEventEffectTypeItems = DataEditor.GetAuraInspectorEventEffectTypeItems
if type(originalGetAuraEventEffectTypeItems) == "function" then
    function DataEditor:GetAuraInspectorEventEffectTypeItems()
        return appendUniqueItem(originalGetAuraEventEffectTypeItems(self), "Remove Hidden", "remove_hidden")
    end
end

local originalNormalizeAuraEventEffect = DataEditor.NormalizeAuraInspectorEventEffect
if type(originalNormalizeAuraEventEffect) == "function" then
    function DataEditor:NormalizeAuraInspectorEventEffect(effect)
        if type(effect) == "table" and tostring(effect.type or "") == "remove_hidden" then
            for key in pairs(effect) do
                if key ~= "type" then
                    effect[key] = nil
                end
            end
            effect.type = "remove_hidden"
            return
        end

        return originalNormalizeAuraEventEffect(self, effect)
    end
end
