local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}
local EventUnit = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.EventUnit
    or nil

Conditions:RegisterCondition("hidden", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("hidden")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(context, condition)
        local unit = Conditions:GetConditionUnit(context, condition and condition.unit)
        local hidden = type(EventUnit) == "table" and type(EventUnit.IsHidden) == "function"
            and EventUnit.IsHidden(unit)
            or (type(unit) == "table" and unit.hidden == true)
        return {
            passed = hidden == true,
            failureText = Conditions:ResolveConditionText(condition, context),
        }
    end,
    BuildTooltipLine = function(_, condition)
        local subject = condition and condition.unit == "target" and "Target" or "Caster"
        if condition and condition.invert == true then
            return subject .. " must not be hidden"
        end
        return subject .. " must be hidden"
    end,
})
