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

local function startSkillTiming(label, context)
    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Start) == "function" then
        if type(timings.IsEnabled) == "function" and not timings:IsEnabled() then
            return nil
        end
        return timings:Start(label, {
            thresholdMs = 4,
            context = context,
        })
    end
    return nil
end

local function stopSkillTiming(timer, cardinality)
    if not timer then
        return
    end

    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Stop) == "function" then
        timings:Stop(timer, { cardinality = cardinality })
    end
end

local function buildMetadataFromResolvedRow(row)
    if type(row) ~= "table" then
        return nil
    end

    return {
        ref = row.ref,
        name = row.name,
        skillId = row.skillId,
        skillType = row.skillType,
        storedValue = row.storedValue,
        maxValue = row.maxValue,
        weaponTypeRef = row.weaponTypeRef,
    }
end

local function resolveSkillMetadata(skillRef, resolvedRow)
    local metadata = buildMetadataFromResolvedRow(resolvedRow)
    if metadata then
        return metadata
    end

    if type(Profile.GetSkillMetadataByRefs) == "function" then
        local rows = Profile.GetSkillMetadataByRefs({ skillRef }) or {}
        if type(rows[1]) == "table" then
            return rows[1]
        end
    end

    if type(Profile.GetResolvedSkillRow) == "function" then
        return buildMetadataFromResolvedRow(Profile.GetResolvedSkillRow(skillRef))
    end

    return nil
end

local function makeProgressionResult(metadata, skillRef, source, chance, roll, level, maxLevel)
    return {
        granted = true,
        skillRef = skillRef,
        skillName = tostring(metadata.name or metadata.skillId or skillRef),
        skillType = tostring(metadata.skillType or ""),
        source = tostring(source or ""),
        chance = chance,
        roll = roll,
        level = level,
        maxLevel = maxLevel,
    }
end

local function commitSkillGain(metadata, skillRef, source, chance, roll, context)
    local nextLevel = math.min(
        normalizeInteger(metadata.maxValue, 0),
        normalizeInteger(metadata.storedValue, 0) + 1
    )
    local stored = Profile.SetSkillLevel(skillRef, nextLevel)
    if normalizeInteger(stored, 0) ~= nextLevel then
        return {
            granted = false,
            reason = "persistence-failed",
            skillRef = skillRef,
            chance = chance,
            roll = roll,
        }
    end

    local result = makeProgressionResult(metadata, skillRef, source, chance, roll, nextLevel, normalizeInteger(metadata.maxValue, 0))
    if type(context) == "table" and type(context.onGain) == "function" then
        pcall(context.onGain, result)
    end
    if type(Client.RefreshActionBarWidget) == "function" then
        Client:RefreshActionBarWidget("skill-gain")
    end
    notifyGain(result)
    return result
end

function SkillProgression:GetRulesetChance(ruleKey, fallback)
    return getRulesetChance(ruleKey, fallback)
end

function SkillProgression:TryGain(skillRef, source, chance, context, resolvedRow)
    local normalizedRef = normalizeRef(skillRef)
    if not normalizedRef then
        return { granted = false, reason = "invalid-skill" }
    end
    if type(Profile.GetSkillLevel) ~= "function"
        or type(Profile.SetSkillLevel) ~= "function"
    then
        return { granted = false, reason = "skill-api-unavailable", skillRef = normalizedRef }
    end

    local timer = startSkillTiming("SkillProgression:TryGain", {
        skillRef = normalizedRef,
        source = tostring(source or ""),
        activeEvent = type(context) == "table" and context.eventState and context.eventState.active == true and 1 or 0,
    })
    local metadataTimer = startSkillTiming("SkillProgression:TryGain:metadata", { skillRef = normalizedRef })
    local metadata = resolveSkillMetadata(normalizedRef, resolvedRow)
    stopSkillTiming(metadataTimer, { cacheHit = metadata ~= nil and 1 or 0 })
    local skillType = tostring(metadata and metadata.skillType or "")
    if type(metadata) ~= "table" or not SUPPORTED_SKILL_TYPES[skillType] then
        stopSkillTiming(timer, { outcome = "unavailable" })
        return { granted = false, reason = "skill-unavailable", skillRef = normalizedRef }
    end

    local minimumLevel = skillType == "crafting" and 1 or 0
    local maximumLevel = normalizeInteger(metadata.maxValue, minimumLevel)
    local storedLevel = normalizeInteger(metadata.storedValue, 0)
    if metadata.storedValue == nil then
        storedLevel = normalizeInteger(Profile.GetSkillLevel(normalizedRef), 0)
    end
    local effectiveBaseLevel = math.max(minimumLevel, storedLevel)
    if effectiveBaseLevel >= maximumLevel then
        stopSkillTiming(timer, { outcome = "capped" })
        return { granted = false, reason = "capped", skillRef = normalizedRef, level = effectiveBaseLevel, maxLevel = maximumLevel }
    end

    local normalizedChance = clampChance(chance)
    if normalizedChance <= 0 then
        stopSkillTiming(timer, { outcome = "chance-zero" })
        return { granted = false, reason = "chance-zero", skillRef = normalizedRef, chance = normalizedChance }
    end

    local rollTimer = startSkillTiming("SkillProgression:TryGain:roll", { skillRef = normalizedRef, chance = normalizedChance })
    local roll = tonumber(Dice.RollRandom and Dice.RollRandom(context, 1, 100) or math.random(1, 100)) or 100
    stopSkillTiming(rollTimer, { roll = roll, chance = normalizedChance })
    if roll > normalizedChance then
        stopSkillTiming(timer, { outcome = "roll-failed", roll = roll })
        return { granted = false, reason = "roll-failed", skillRef = normalizedRef, chance = normalizedChance, roll = roll }
    end

    local rowTimer = startSkillTiming("SkillProgression:TryGain:row", { skillRef = normalizedRef })
    local row = resolvedRow
    if type(row) ~= "table" and type(Profile.GetResolvedSkillRow) == "function" then
        row = Profile.GetResolvedSkillRow(normalizedRef)
    end
    stopSkillTiming(rowTimer, { reused = resolvedRow and 1 or 0, resolved = row and 1 or 0 })
    if type(row) ~= "table" then
        stopSkillTiming(timer, { outcome = "unavailable-after-roll" })
        return { granted = false, reason = "skill-unavailable", skillRef = normalizedRef, chance = normalizedChance, roll = roll }
    end

    local persistenceTimer = startSkillTiming("SkillProgression:TryGain:persistence", { skillRef = normalizedRef })
    metadata.storedValue = effectiveBaseLevel
    metadata.maxValue = normalizeInteger(row.maxValue, maximumLevel)
    local result = commitSkillGain(metadata, normalizedRef, source, normalizedChance, roll, context)
    stopSkillTiming(persistenceTimer, { outcome = result.granted == true and "gain" or "persistence-failed" })
    stopSkillTiming(timer, { outcome = result.granted == true and "gain" or "persistence-failed" })
    return result
end

function SkillProgression:TryGainMany(entries, source, chance, context)
    local candidates = type(entries) == "table" and entries or {}
    local timer = startSkillTiming("SkillProgression:TryGainMany", {
        source = tostring(source or ""),
        activeEvent = type(context) == "table" and context.eventState and context.eventState.active == true and 1 or 0,
        contributingWeapons = #candidates,
    })
    local normalizedChance = clampChance(chance)
    local results = {}
    local successful = {}
    local successfulRefs = {}

    local metadataTimer = startSkillTiming("SkillProgression:TryGainMany:metadata", { candidates = #candidates })
    for index = 1, #candidates do
        local candidate = candidates[index]
        local skillRef = normalizeRef(candidate and candidate.skillRef)
        local metadata = candidate and candidate.metadata or nil
        if not skillRef or type(metadata) ~= "table" then
            results[index] = { granted = false, reason = "skill-unavailable", skillRef = skillRef }
        else
            local minimumLevel = tostring(metadata.skillType or "") == "crafting" and 1 or 0
            local maximumLevel = normalizeInteger(metadata.maxValue, minimumLevel)
            local storedLevel = normalizeInteger(metadata.storedValue, 0)
            if math.max(minimumLevel, storedLevel) >= maximumLevel then
                results[index] = { granted = false, reason = "capped", skillRef = skillRef, level = storedLevel, maxLevel = maximumLevel }
            elseif normalizedChance <= 0 then
                results[index] = { granted = false, reason = "chance-zero", skillRef = skillRef, chance = normalizedChance }
            else
                local rollTimer = startSkillTiming("SkillProgression:TryGainMany:roll", { skillRef = skillRef, chance = normalizedChance })
                local roll = tonumber(Dice.RollRandom and Dice.RollRandom(context, 1, 100) or math.random(1, 100)) or 100
                stopSkillTiming(rollTimer, { roll = roll, chance = normalizedChance })
                if roll <= normalizedChance then
                    successful[#successful + 1] = { index = index, skillRef = skillRef, metadata = metadata, roll = roll }
                    successfulRefs[#successfulRefs + 1] = skillRef
                else
                    results[index] = { granted = false, reason = "roll-failed", skillRef = skillRef, chance = normalizedChance, roll = roll }
                end
            end
        end
    end
    stopSkillTiming(metadataTimer, { candidates = #candidates })

    local rowTimer = startSkillTiming("SkillProgression:TryGainMany:row", { successful = #successful })
    local resolvedRowsByRef = {}
    if #successfulRefs > 0 and type(Profile.GetResolvedSkillRowsByRefs) == "function" then
        local rows = Profile.GetResolvedSkillRowsByRefs(successfulRefs) or {}
        for index = 1, #rows do
            resolvedRowsByRef[rows[index].ref] = rows[index]
        end
    end
    stopSkillTiming(rowTimer, { successful = #successful, resolved = #resolvedRowsByRef })

    local persistenceTimer = startSkillTiming("SkillProgression:TryGainMany:persistence", { successful = #successful })
    for index = 1, #successful do
        local candidate = successful[index]
        local row = resolvedRowsByRef[candidate.skillRef]
        if type(row) ~= "table" then
            results[candidate.index] = { granted = false, reason = "skill-unavailable", skillRef = candidate.skillRef, chance = normalizedChance, roll = candidate.roll }
        else
            candidate.metadata.storedValue = math.max(0, tonumber(row.storedValue) or tonumber(candidate.metadata.storedValue) or 0)
            candidate.metadata.maxValue = normalizeInteger(row.maxValue, candidate.metadata.maxValue)
            results[candidate.index] = commitSkillGain(candidate.metadata, candidate.skillRef, source, normalizedChance, candidate.roll, context)
        end
    end
    stopSkillTiming(persistenceTimer, { successful = #successful })

    stopSkillTiming(timer, {
        outcome = #successful > 0 and "gain" or "no-gain",
        gained = #successful,
        candidates = #candidates,
    })
    return results
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
    if type(weapons) ~= "table" or #weapons == 0
        or (type(Profile.GetSkillMetadataByWeaponType) ~= "function"
            and type(Profile.GetResolvedWeaponSkillRowsByWeaponType) ~= "function")
    then
        return {}
    end

    local metadataByWeaponType = type(Profile.GetSkillMetadataByWeaponType) == "function"
        and Profile.GetSkillMetadataByWeaponType()
        or nil
    local rowsByWeaponType = metadataByWeaponType or (Profile.GetResolvedWeaponSkillRowsByWeaponType() or {})
    local candidates = {}
    local seen = {}
    for index = 1, #weapons do
        local weaponTypeRef = normalizeRef(weapons[index] and weapons[index].weaponTypeRef)
        local matches = weaponTypeRef and rowsByWeaponType[weaponTypeRef] or nil
        local row = type(matches) == "table" and #matches == 1 and matches[1] or nil
        local resolvedRef = normalizeRef(row and row.ref)
        if resolvedRef and not seen[resolvedRef] then
            seen[resolvedRef] = true
            candidates[#candidates + 1] = {
                skillRef = resolvedRef,
                metadata = metadataByWeaponType and row or buildMetadataFromResolvedRow(row),
            }
        end
    end

    local chance = self:GetRulesetChance("weapon_skill_gain_chance_on_hit", 0)
    return self:TryGainMany(candidates, "weapon-hit", chance, entry.context)
end

return SkillProgression
