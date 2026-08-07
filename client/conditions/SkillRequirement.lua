local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}

Conditions:RegisterCondition("skill_requirement", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("skill_requirement")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(_, condition)
        local value = Conditions:GetProfileSkillValue(condition.skillRef)
        local minimumValue = tonumber(condition.minimumValue)
        local maximumValue = tonumber(condition.maximumValue)
        local passed = (minimumValue == nil or value >= minimumValue) and (maximumValue == nil or value <= maximumValue)
        return {
            passed = passed,
            failureText = Conditions:ResolveConditionText(condition),
        }
    end,
    BuildTooltipLine = function(_, condition)
        local skillName = Conditions:ResolveSkillName(condition.skillRef)
        local minimumValue = tonumber(condition.minimumValue)
        local maximumValue = tonumber(condition.maximumValue)
        if minimumValue ~= nil and maximumValue ~= nil then
            return ("Requires %s %d-%d"):format(skillName, minimumValue, maximumValue)
        end
        if minimumValue ~= nil then
            return ("Requires %s %d+"):format(skillName, minimumValue)
        end
        return ("Requires %s up to %d"):format(skillName, math.floor(maximumValue or 0))
    end,
})
