local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}

Conditions:RegisterCondition("weapon_type", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("weapon_type")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(context, condition)
        return {
            passed = Conditions:ResolveWeaponTypeMatch(context, condition),
            failureText = Conditions:ResolveConditionText(condition, context),
        }
    end,
    BuildTooltipLine = function(_, condition)
        local labels = {}
        for index = 1, #(condition.weaponTypeRefs or {}) do
            labels[#labels + 1] = Conditions:ResolveWeaponTypeName(condition.weaponTypeRefs[index])
        end
        local slotKey = tostring(condition.slotKey or "")
        local slotText = slotKey ~= "" and (" in %s"):format(slotKey:gsub("_", " ")) or ""
        return ("Requires %s%s"):format(table.concat(labels, ", "), slotText)
    end,
})
