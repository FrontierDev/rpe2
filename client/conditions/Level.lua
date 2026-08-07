local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}

Conditions:RegisterCondition("level", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("level")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(context, condition)
        local level = Conditions:GetProfileLevel(context)
        local minimumValue = tonumber(condition.minimumValue)
        local maximumValue = tonumber(condition.maximumValue)
        local passed = (minimumValue == nil or level >= minimumValue) and (maximumValue == nil or level <= maximumValue)
        return {
            passed = passed,
            failureText = Conditions:ResolveConditionText(condition, context),
        }
    end,
    BuildTooltipLine = function(_, condition)
        local minimumValue = tonumber(condition.minimumValue)
        local maximumValue = tonumber(condition.maximumValue)
        if minimumValue ~= nil and maximumValue ~= nil then
            return ("Requires level %d-%d"):format(minimumValue, maximumValue)
        end
        if minimumValue ~= nil then
            return ("Requires level %d"):format(minimumValue)
        end
        return ("Requires level %d or lower"):format(math.max(0, math.floor(maximumValue or 0)))
    end,
})
