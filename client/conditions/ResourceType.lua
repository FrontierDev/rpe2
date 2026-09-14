local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}

local function isEventUnitResourceAllowed(context, condition)
    local casterUnit = type(context) == "table" and context.casterUnit or nil
    if type(casterUnit) ~= "table" or casterUnit.isPlayer == true then
        return nil
    end

    local resourceRef = tostring(type(condition) == "table" and condition.resourceRef or "")
    if resourceRef == "" then
        return false
    end

    local healthResourceRef = nil
    if type(Conditions.GetAllowedSpellResourceRefs) == "function" then
        healthResourceRef = select(2, Conditions:GetAllowedSpellResourceRefs(context, {
            allowHealth = true,
        }))
    end
    if resourceRef == tostring(healthResourceRef or "")
        and type(condition) == "table"
        and condition.allowHealth ~= true
    then
        return false
    end

    for index = 1, #(casterUnit.resources or {}) do
        local resource = casterUnit.resources[index]
        if type(resource) == "table" and tostring(resource.resourceRef or "") == resourceRef then
            return true
        end
    end

    return false
end

Conditions:RegisterCondition("resource_type", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("resource_type")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(context, condition)
        local eventUnitAllowed = isEventUnitResourceAllowed(context, condition)
        return {
            passed = eventUnitAllowed ~= nil
                and eventUnitAllowed
                or Conditions:IsAllowedSpellResourceRef(condition, context),
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
