local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}

Conditions:RegisterCondition("trait_requirement", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("trait_requirement")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(_, condition)
        return {
            passed = Conditions:IsTraitActive(condition.traitRef),
            failureText = Conditions:ResolveConditionText(condition),
        }
    end,
    BuildTooltipLine = function(_, condition)
        return ("Requires %s"):format(Conditions:ResolveTraitName(condition.traitRef))
    end,
})
