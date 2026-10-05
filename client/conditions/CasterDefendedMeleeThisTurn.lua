local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}

local function resolveDefenceStat(condition)
    local reference = condition and condition.defenceStatRef
    if type(reference) ~= "string" or reference == "" then
        return nil, true
    end

    if not reference:match("^[^:]+:[^:]+$") then
        return nil, false
    end

    -- The full Registry is present in the live client. Keep syntactically
    -- valid references usable in isolated/test environments that provide the
    -- combat-history helper without loading the dataset registry.
    if type(Registry.ResolveStatReference) ~= "function" then
        return reference, true
    end

    local _, stat = Registry:ResolveStatReference(reference)
    local defenceLabel = type(stat) == "table" and tostring(stat.defenceLabel or "") or ""
    defenceLabel = defenceLabel:gsub("^%s+", ""):gsub("%s+$", "")
    if defenceLabel == "" then
        return nil, false
    end

    return defenceLabel, true
end

Conditions:RegisterCondition("caster_defended_melee_this_turn", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("caster_defended_melee_this_turn")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(context, condition)
        local caster = context and context.casterUnit
        local eventState = context and context.eventState
        local _, validDefenceStat = resolveDefenceStat(condition)
        local passed = Addon.Client
            and type(Addon.Client.HasSuccessfullyDefendedMeleeThisTurn) == "function"
            and validDefenceStat
            and Addon.Client:HasSuccessfullyDefendedMeleeThisTurn(eventState, caster and caster.eventID, condition.defenceStatRef)
            or false
        return {
            passed = passed == true,
            failureText = Conditions:ResolveConditionText(condition, context),
        }
    end,
    BuildTooltipLine = function(_, condition)
        local defenceLabel = resolveDefenceStat(condition)
        if defenceLabel then
            return ("Requires the caster to have successfully defended using %s this turn"):format(defenceLabel)
        end
        return "Requires the caster to have successfully defended against a melee attack this turn"
    end,
})
