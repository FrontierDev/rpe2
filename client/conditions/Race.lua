local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}

Conditions:RegisterCondition("race", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("race")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(context, condition)
        local raceRef = Conditions:GetProfileRaceRef(context)
        local passed = false
        for index = 1, #(condition.raceRefs or {}) do
            if tostring(condition.raceRefs[index]) == tostring(raceRef) then
                passed = true
                break
            end
        end
        return {
            passed = passed,
            failureText = Conditions:ResolveConditionText(condition, context),
        }
    end,
    BuildTooltipLine = function(_, condition)
        local labels = {}
        for index = 1, #(condition.raceRefs or {}) do
            labels[#labels + 1] = Conditions:ResolveEntryName(condition.raceRefs[index], "races")
        end
        return ("Requires race: %s"):format(table.concat(labels, ", "))
    end,
})
