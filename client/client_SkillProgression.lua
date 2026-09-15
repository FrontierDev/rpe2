local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Profile = Addon.Internal.Profile or {}
local Ruleset = Addon.Internal.Ruleset or {}
local Dice = Addon.Utils.Dice or {}

Client.SkillProgression = Client.SkillProgression or {}
local SkillProgression = Client.SkillProgression

local SUPPORTED_SKILL_TYPES = {
    weapon = true,
    noncombat = true,
    crafting = true,
}

local function normalizeRef(value)
    local ref = tostring(value or "")
    return ref ~= "" and ref or nil
end

local function normalizeInteger(value, minimum)
    return math.max(tonumber(minimum) or 0, math.floor(tonumber(value) or 0))
end

local function clampChance(value)
    return math.max(0, math.min(100, tonumber(value) or 0))
end

local function getRulesetChance(ruleKey, fallback)
    local activeRuleset = type(Ruleset.GetActiveRuleset) == "function" and Ruleset.GetActiveRuleset() or nil
    local definition = type(Ruleset.GetRulesetRuleDefinition) == "function"
        and Ruleset.GetRulesetRuleDefinition("skills", ruleKey)
        or nil
    local value = definition and type(Ruleset.GetRulesetRuleValue) == "function"
        and Ruleset.GetRulesetRuleValue(activeRuleset, "skills", definition)
        or fallback
    return clampChance(value ~= nil and value or fallback)
end

local function refreshVisibleProfileWindow()
    local windowController = Client.UI and Client.UI.Profile and Client.UI.Profile.Window or nil
    if type(windowController) ~= "table" or type(windowController.Get) ~= "function" then
        return false
    end

    local window = windowController:Get()
    if window and type(window.RefreshVisible) == "function" then
        window:RefreshVisible()
        return true
    end
    return false
end

local function notifyGain(result)
    if not (DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage) == "function") then
        return false
    end

    local skillName = tostring(result.skillName or "Skill")
    local level = tonumber(result.level) or 0
    local message
    if tostring(result.skillType or "") == "noncombat" then
        message = ("Your modifier in %s has increased to %d."):format(skillName, level)
    else
        message = ("Your skill in %s has increased to %d."):format(skillName, level)
    end

    local skillColor = type(ChatTypeInfo) == "table" and ChatTypeInfo["SKILL"] or nil
    if type(skillColor) == "table" then
        DEFAULT_CHAT_FRAME:AddMessage(
            message,
            tonumber(skillColor.r) or 1,
            tonumber(skillColor.g) or 1,
            tonumber(skillColor.b) or 1
        )
    else
        DEFAULT_CHAT_FRAME:AddMessage(message)
    end
    return true
end

local function getLocalPlayerEventId(eventState)
    if type(eventState) ~= "table" or eventState.active ~= true
        or type(Client.ResolveLocalEventUnit) ~= "function"
    then
        return nil
    end

    return tonumber((Client:ResolveLocalEventUnit(eventState) or {}).eventID)
end

function SkillProgression:GetRulesetChance(ruleKey, fallback)
    return getRulesetChance(ruleKey, fallback)
end

function SkillProgression:TryGain(skillRef, source, chance, context)
    local normalizedRef = normalizeRef(skillRef)
    if not normalizedRef then
        return { granted = false, reason = "invalid-skill" }
    end
    if type(Profile.GetResolvedSkillRow) ~= "function" or type(Profile.GetSkillLevel) ~= "function"
        or type(Profile.SetSkillLevel) ~= "function"
    then
        return { granted = false, reason = "skill-api-unavailable", skillRef = normalizedRef }
    end

    local row = Profile.GetResolvedSkillRow(normalizedRef)
    local skillType = tostring(row and row.skillType or "")
    if type(row) ~= "table" or not SUPPORTED_SKILL_TYPES[skillType] then
        return { granted = false, reason = "skill-unavailable", skillRef = normalizedRef }
    end

    local minimumLevel = skillType == "crafting" and 1 or 0
    local maximumLevel = normalizeInteger(row.maxValue, minimumLevel)
    local storedLevel = normalizeInteger(Profile.GetSkillLevel(normalizedRef), 0)
    local effectiveBaseLevel = math.max(minimumLevel, storedLevel)
    if effectiveBaseLevel >= maximumLevel then
        return { granted = false, reason = "capped", skillRef = normalizedRef, level = effectiveBaseLevel, maxLevel = maximumLevel }
    end

    local normalizedChance = clampChance(chance)
    if normalizedChance <= 0 then
        return { granted = false, reason = "chance-zero", skillRef = normalizedRef, chance = normalizedChance }
    end

    local roll = tonumber(Dice.RollRandom and Dice.RollRandom(context, 1, 100) or math.random(1, 100)) or 100
    if roll > normalizedChance then
        return { granted = false, reason = "roll-failed", skillRef = normalizedRef, chance = normalizedChance, roll = roll }
    end

    local nextLevel = math.min(maximumLevel, effectiveBaseLevel + 1)
    local stored = Profile.SetSkillLevel(normalizedRef, nextLevel)
    if normalizeInteger(stored, 0) ~= nextLevel then
        return { granted = false, reason = "persistence-failed", skillRef = normalizedRef, chance = normalizedChance, roll = roll }
    end

    local result = {
        granted = true,
        skillRef = normalizedRef,
        skillName = tostring(row.name or row.skillId or normalizedRef),
        skillType = skillType,
        source = tostring(source or ""),
        chance = normalizedChance,
        roll = roll,
        level = nextLevel,
        maxLevel = maximumLevel,
    }
    if type(context) == "table" and type(context.onGain) == "function" then
        pcall(context.onGain, result)
    end
    refreshVisibleProfileWindow()
    notifyGain(result)
    return result
end

function SkillProgression:TryGainWeaponSkillsForHit(entry)
    if type(entry) ~= "table" or type(entry.attackerUnit) ~= "table" or entry.attackerUnit.isPlayer ~= true then
        return {}
    end

    local localEventId = getLocalPlayerEventId(entry.eventState)
    if not localEventId or localEventId ~= tonumber(entry.attackerUnit.eventID) then
        return {}
    end

    local weaponContext = entry.weaponSkillContext
    local weapons = type(weaponContext) == "table" and weaponContext.contributingWeapons or nil
    if type(weapons) ~= "table" or #weapons == 0 or type(Profile.GetResolvedWeaponSkillRowsByWeaponType) ~= "function" then
        return {}
    end

    local rowsByWeaponType = Profile.GetResolvedWeaponSkillRowsByWeaponType() or {}
    local skillRefs = {}
    local seen = {}
    for index = 1, #weapons do
        local weaponTypeRef = normalizeRef(weapons[index] and weapons[index].weaponTypeRef)
        local matches = weaponTypeRef and rowsByWeaponType[weaponTypeRef] or nil
        local row = type(matches) == "table" and #matches == 1 and matches[1] or nil
        local resolvedRef = normalizeRef(row and row.ref)
        if resolvedRef and not seen[resolvedRef] then
            seen[resolvedRef] = true
            skillRefs[#skillRefs + 1] = resolvedRef
        end
    end

    local chance = self:GetRulesetChance("weapon_skill_gain_chance_on_hit", 0)
    local results = {}
    for index = 1, #skillRefs do
        results[#results + 1] = self:TryGain(skillRefs[index], "weapon-hit", chance, entry.context)
    end
    return results
end

return SkillProgression
