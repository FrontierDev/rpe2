local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Combat = Addon.Client.Combat or {}
Addon.Utils = Addon.Utils or {}

local Combat = Addon.Client.Combat
local Common = Addon.Utils.Common or {}

local Normalization = {}

function Normalization.TrimText(value)
    local text = tostring(value or "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

function Normalization.NormalizeToken(value)
    local token = Normalization.TrimText(value)
    if token == "" then
        return nil
    end

    return token
end

function Normalization.NormalizeResultToken(value)
    local token = string.lower(Normalization.TrimText(value or ""))
    if token == "pass" or token == "fail" then
        return token
    end

    return nil
end

function Normalization.SplitList(value)
    if type(value) == "table" then
        local normalized = {}
        for index = 1, #value do
            local token = Normalization.NormalizeToken(value[index])
            if token then
                normalized[#normalized + 1] = token
            end
        end
        return normalized
    end

    local text = Normalization.NormalizeToken(value)
    if not text then
        return {}
    end

    local values = {}
    local segments = Common.SplitPreservingEmpty and Common.SplitPreservingEmpty(text, ",") or { text }
    for index = 1, #segments do
        local token = Normalization.NormalizeToken(segments[index])
        if token then
            values[#values + 1] = token
        end
    end

    return values
end

function Normalization.EnsureString(value)
    return type(value) == "string" and value or tostring(value or "")
end

function Normalization.EnsureTable(value)
    if type(value) == "table" then
        return value
    end

    return {}
end

function Normalization.NormalizeBool(value, fallback)
    if value == nil then
        return fallback == true
    end

    return value == true
end

function Normalization.NormalizeNumber(value, fallback)
    local numeric = tonumber(value)
    if numeric == nil then
        return fallback or 0
    end

    return numeric
end

function Normalization.NormalizeInteger(value, fallback, minimum)
    local numeric = math.floor(Normalization.NormalizeNumber(value, fallback or 0))
    if minimum ~= nil and numeric < minimum then
        return minimum
    end

    return numeric
end

function Normalization.NormalizeRef(value)
    local ref = Normalization.TrimText(value)
    if ref == "" then
        return nil
    end

    return ref
end

local function normalizeCastPhase(value)
    local phase = Normalization.TrimText(value)
    if phase == "on_cast_start" or phase == "on_cast_end" or phase == "on_channel_tick" then
        return phase
    end

    return "on_cast_end"
end

local function normalizeWeaponDamageMode(value)
    local mode = string.lower(Normalization.TrimText(value))
    if mode == "main_hand" or mode == "off_hand" or mode == "both" then
        return mode
    end

    return "none"
end

local function normalizeAmountMode(value)
    local mode = string.lower(Normalization.TrimText(value))
    if mode == "base_percent" then
        return "base_percent"
    end
    if mode == "max_percent" then
        return "max_percent"
    end

    return "flat"
end

local function normalizeHitType(value)
    local hitType = string.lower(Normalization.TrimText(value))
    if hitType == "auto" or hitType == "pet" then
        return hitType
    end

    return "ability"
end

local function normalizeDamageType(value)
    local damageType = string.lower(Normalization.TrimText(value))
    if damageType == "melee" or damageType == "ranged" then
        return damageType
    end

    return "spell"
end

local function normalizeEventList(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local key = Normalization.TrimText(values[index])
        if key ~= "" then
            normalized[#normalized + 1] = key
        end
    end

    return normalized
end

local function normalizeStatScaling(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local entry = values[index]
        local statRef = type(entry) == "table" and Normalization.NormalizeRef(entry.statRef) or nil
        if statRef then
            normalized[#normalized + 1] = {
                statRef = statRef,
                coefficient = Normalization.NormalizeNumber(entry.coefficient, 0),
            }
        end
    end

    return normalized
end

local function normalizeDamageSchoolRefs(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local ref = Normalization.NormalizeRef(values[index])
        if ref then
            normalized[#normalized + 1] = ref
        end
    end

    return normalized
end

local function normalizeTarget(value)
    local data = Normalization.EnsureTable(value)
    local targetType = Normalization.TrimText(data.type)
    if targetType ~= "caster"
        and targetType ~= "single"
        and targetType ~= "multi"
        and targetType ~= "pet"
        and targetType ~= "last_attackers"
    then
        targetType = "single"
    end

    local targetDisposition = Normalization.TrimText(data.targetDisposition)
    if targetDisposition ~= "ally" and targetDisposition ~= "enemy" and targetDisposition ~= "any" then
        targetDisposition = "enemy"
    end

    if targetType == "caster" then
        return {
            type = "caster",
            requiresTarget = false,
            targetDisposition = "ally",
            minTargets = 0,
            maxTargets = 0,
            allowDeadTargets = false,
            disableSelfCast = false,
        }
    end

    if targetType == "pet" then
        return {
            type = "pet",
            requiresTarget = false,
            targetDisposition = "ally",
            minTargets = 1,
            maxTargets = 1,
            allowDeadTargets = false,
            disableSelfCast = false,
        }
    end

    local requiresTarget = data.requiresTarget ~= false
    local fallbackMinTargets = requiresTarget and 1 or 0
    local minTargets = math.max(0, math.floor(Normalization.NormalizeNumber(data.minTargets, fallbackMinTargets)))
    local maxTargets = math.max(minTargets, math.floor(Normalization.NormalizeNumber(data.maxTargets, math.max(1, minTargets))))

    return {
        type = targetType,
        requiresTarget = requiresTarget,
        targetDisposition = targetDisposition,
        minTargets = minTargets,
        maxTargets = maxTargets,
        allowDeadTargets = Normalization.NormalizeBool(data.allowDeadTargets, false),
        disableSelfCast = Normalization.NormalizeBool(data.disableSelfCast, false),
    }
end

local function normalizeCastingGroup(value)
    local group = Normalization.TrimText(value)
    if group == "" then
        return "default"
    end

    return group
end

local function normalizeDamageEffect(value)
    local data = Normalization.EnsureTable(value)
    return {
        type = "damage",
        baseDamage = Normalization.NormalizeNumber(data.baseDamage, 0),
        amountMode = normalizeAmountMode(data.amountMode),
        threatCoefficient = Normalization.NormalizeNumber(data.threatCoefficient, 1),
        weaponDamageMode = normalizeWeaponDamageMode(data.weaponDamageMode),
        weaponDamageCoefficient = Normalization.NormalizeNumber(data.weaponDamageCoefficient, 1),
        statScaling = normalizeStatScaling(data.statScaling),
        damageSchoolRefs = normalizeDamageSchoolRefs(data.damageSchoolRefs),
        hitType = normalizeHitType(data.hitType),
        damageType = normalizeDamageType(data.damageType),
        alwaysHits = Normalization.NormalizeBool(data.alwaysHits, false),
        usesProjectile = Normalization.NormalizeBool(data.usesProjectile, false),
        projectilePath = Normalization.EnsureString(data.projectilePath),
        projectileSpeed = Normalization.NormalizeNumber(data.projectileSpeed, 0),
        applyAura = Normalization.NormalizeBool(data.applyAura, false),
        auraRef = Normalization.NormalizeRef(data.auraRef),
        auraStacks = math.max(1, Normalization.NormalizeInteger(data.auraStacks, 1, 1)),
        targetEvents = normalizeEventList(data.targetEvents),
    }
end

local function normalizeHealEffect(value)
    local data = Normalization.EnsureTable(value)
    return {
        type = "heal",
        baseHealing = Normalization.NormalizeNumber(data.baseHealing, 0),
        amountMode = normalizeAmountMode(data.amountMode),
        statScaling = normalizeStatScaling(data.statScaling),
        usesProjectile = Normalization.NormalizeBool(data.usesProjectile, false),
        projectilePath = Normalization.EnsureString(data.projectilePath),
        projectileSpeed = Normalization.NormalizeNumber(data.projectileSpeed, 0),
        applyAura = Normalization.NormalizeBool(data.applyAura, false),
        auraRef = Normalization.NormalizeRef(data.auraRef),
        auraStacks = math.max(1, Normalization.NormalizeInteger(data.auraStacks, 1, 1)),
        targetEvents = normalizeEventList(data.targetEvents),
    }
end

local function normalizeAuraEffect(value)
    local data = Normalization.EnsureTable(value)
    return {
        type = "apply_aura",
        auraRef = Normalization.NormalizeRef(data.auraRef),
        stacks = math.max(1, Normalization.NormalizeInteger(data.stacks, 1, 1)),
        duration = Normalization.NormalizeNumber(data.duration, 12),
        basePower = Normalization.NormalizeNumber(data.basePower, 0),
        targetEvents = normalizeEventList(data.targetEvents),
    }
end

local function normalizeResourceEffect(value)
    local data = Normalization.EnsureTable(value)
    return {
        type = "resource",
        resourceRef = Normalization.NormalizeRef(data.resourceRef),
        amount = Normalization.NormalizeNumber(data.amount, 0),
        amountMode = normalizeAmountMode(data.amountMode),
        targetEvents = normalizeEventList(data.targetEvents),
    }
end

local function normalizeInterruptEffect(value)
    local data = Normalization.EnsureTable(value)
    return {
        type = "interrupt",
        targetEvents = normalizeEventList(data.targetEvents),
    }
end

local function normalizeRevertEffect(value)
    local data = Normalization.EnsureTable(value)
    return {
        type = "revert",
        targetEvents = normalizeEventList(data.targetEvents),
    }
end

local function normalizeRemoveAuraEffect(value)
    local data = Normalization.EnsureTable(value)
    return {
        type = "remove_aura",
        auraRef = Normalization.NormalizeRef(data.auraRef),
        stacks = math.max(1, Normalization.NormalizeInteger(data.stacks, 1, 1)),
        targetEvents = normalizeEventList(data.targetEvents),
    }
end

local function normalizeSummonPetEffect(value)
    local data = Normalization.EnsureTable(value)
    return {
        type = "summon_pet",
        unitRef = Normalization.NormalizeRef(data.unitRef),
        targetEvents = normalizeEventList(data.targetEvents),
    }
end

function Normalization.NormalizeCastPhase(value)
    return normalizeCastPhase(value)
end

function Normalization.NormalizeWeaponDamageMode(value)
    return normalizeWeaponDamageMode(value)
end

function Normalization.NormalizeHitType(value)
    return normalizeHitType(value)
end

function Normalization.NormalizeDamageType(value)
    return normalizeDamageType(value)
end

function Normalization.NormalizeEventList(values)
    return normalizeEventList(values)
end

function Normalization.NormalizeStatScaling(values)
    return normalizeStatScaling(values)
end

function Normalization.NormalizeDamageSchoolRefs(values)
    return normalizeDamageSchoolRefs(values)
end

function Normalization.NormalizeTarget(value)
    return normalizeTarget(value)
end

function Normalization.NormalizeCastingGroup(value)
    return normalizeCastingGroup(value)
end

function Normalization.NormalizeDamageEffect(value)
    return normalizeDamageEffect(value)
end

function Normalization.NormalizeHealEffect(value)
    return normalizeHealEffect(value)
end

function Normalization.NormalizeAuraEffect(value)
    return normalizeAuraEffect(value)
end

function Normalization.NormalizeResourceEffect(value)
    return normalizeResourceEffect(value)
end

function Normalization.NormalizeRemoveAuraEffect(value)
    return normalizeRemoveAuraEffect(value)
end

function Normalization.NormalizeSummonPetEffect(value)
    return normalizeSummonPetEffect(value)
end

function Normalization.NormalizeInterruptEffect(value)
    return normalizeInterruptEffect(value)
end

function Normalization.NormalizeRevertEffect(value)
    return normalizeRevertEffect(value)
end

function Normalization.NormalizeEffectType(value)
    local effectType = Normalization.TrimText(value)
    if effectType == "" then
        return nil
    end

    return string.lower(effectType)
end

function Normalization.NormalizeEffectData(effectType, value)
    local normalizedType = Normalization.NormalizeEffectType(effectType)
    if normalizedType == "damage" then
        return normalizeDamageEffect(value)
    end

    if normalizedType == "heal" then
        return normalizeHealEffect(value)
    end

    if normalizedType == "apply_aura" then
        return normalizeAuraEffect(value)
    end

    if normalizedType == "resource" then
        return normalizeResourceEffect(value)
    end

    if normalizedType == "interrupt" then
        return normalizeInterruptEffect(value)
    end

    if normalizedType == "revert" then
        return normalizeRevertEffect(value)
    end

    if normalizedType == "remove_aura" then
        return normalizeRemoveAuraEffect(value)
    end

    if normalizedType == "summon_pet" then
        return normalizeSummonPetEffect(value)
    end

    return nil
end

function Normalization.NormalizeEffect(value)
    if type(value) ~= "table" then
        return nil
    end

    local effectType = Normalization.NormalizeEffectType(value.type)
    if not effectType then
        return nil
    end

    if not Combat:GetEffect(effectType) then
        return nil
    end

    return Normalization.NormalizeEffectData(effectType, value)
end

function Normalization.NormalizeComponent(value)
    if type(value) ~= "table" then
        return nil
    end

    local effect = Normalization.NormalizeEffect(value.effect)
    if not effect then
        return {
            key = Normalization.NormalizeRef(value.key),
            castingGroup = normalizeCastingGroup(value.castingGroup),
            castPhase = normalizeCastPhase(value.castPhase),
            target = normalizeTarget(value.target),
            effect = nil,
        }
    end

    return {
        key = Normalization.NormalizeRef(value.key),
        castingGroup = normalizeCastingGroup(value.castingGroup),
        castPhase = normalizeCastPhase(value.castPhase),
        target = normalizeTarget(value.target),
        effect = effect,
    }
end

Combat.Normalization = Normalization
Combat.NormalizeCastPhase = Combat.NormalizeCastPhase or function(valueOrSelf, value)
    return Normalization.NormalizeCastPhase(value ~= nil and value or valueOrSelf)
end
Combat.NormalizeTarget = Combat.NormalizeTarget or function(valueOrSelf, value)
    return Normalization.NormalizeTarget(value ~= nil and value or valueOrSelf)
end
Combat.NormalizeCastingGroup = Combat.NormalizeCastingGroup or function(valueOrSelf, value)
    return Normalization.NormalizeCastingGroup(value ~= nil and value or valueOrSelf)
end
Combat.NormalizeComponent = Combat.NormalizeComponent or function(valueOrSelf, value)
    return Normalization.NormalizeComponent(value ~= nil and value or valueOrSelf)
end
Combat.NormalizeEffect = Combat.NormalizeEffect or function(valueOrSelf, value)
    return Normalization.NormalizeEffect(value ~= nil and value or valueOrSelf)
end

return Normalization
