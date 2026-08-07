local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}

Conditions:RegisterCondition("resource_type", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("resource_type")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(context, condition)
        return {
            passed = Conditions:IsAllowedSpellResourceRef(condition, context),
            failureText = Conditions:ResolveConditionText(condition, context),
        }
    end,
    BuildTooltipLine = function(context, condition)
        local resourceName = Conditions:ResolveResourceName(condition.resourceRef)
        local allowedRefs = Conditions:GetAllowedSpellResourceRefs(context, condition)
        local labels = {}
        for index = 1, #allowedRefs do
            labels[#labels + 1] = Conditions:ResolveResourceName(allowedRefs[index])
        end
        return ("%s cost requires %s"):format(resourceName, table.concat(labels, " or "))
    end,
})
