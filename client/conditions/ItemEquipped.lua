local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}
local Equipment = Addon.Internal and Addon.Internal.Profile and Addon.Internal.Profile.Equipment or {}

Conditions:RegisterCondition("item_equipped", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("item_equipped")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(context, condition)
        return {
            passed = Conditions:ResolveItemEquippedMatch(context, condition),
            failureText = Conditions:ResolveConditionText(condition, context),
        }
    end,
    BuildTooltipLine = function(_, condition)
        local labels = {}
        if condition.requiresShield == true then
            labels[#labels + 1] = "shield"
        end
        for index = 1, #(condition.weaponTypeRefs or {}) do
            labels[#labels + 1] = Conditions:ResolveWeaponTypeName(condition.weaponTypeRefs[index])
        end
        local slotKey = tostring(condition.slotKey or "")
        local slotLabel = slotKey ~= "" and (Equipment.PrettySlotLabel and Equipment.PrettySlotLabel(slotKey) or slotKey:gsub("_", " ")) or ""
        local slotText = slotLabel ~= "" and (" in %s"):format(slotLabel) or ""
        if condition.requiresShield == true and #(condition.weaponTypeRefs or {}) == 0 and condition.invert == true then
            return ("Requires no shield equipped%s"):format(slotText)
        end
        if #labels == 0 then
            return ("Requires any item equipped%s"):format(slotText)
        end
        return ("Requires %s equipped%s"):format(table.concat(labels, ", "), slotText)
    end,
})
