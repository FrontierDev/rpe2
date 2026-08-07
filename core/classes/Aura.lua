local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Aura = {}
Aura.__index = Aura

local function ensureTable(value)
    if type(value) == "table" then
        return value
    end

    return {}
end

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function normalizeRef(value)
    local ref = ensureString(value)
    if ref == "" then
        return nil
    end

    return ref
end

local function sortedNumericKeys(values)
    local keys = {}
    for key in pairs(values or {}) do
        local numericKey = tonumber(key)
        if numericKey and numericKey > 0 and math.floor(numericKey) == numericKey then
            keys[#keys + 1] = {
                sortKey = numericKey,
                key = key,
            }
        end
    end

    table.sort(keys, function(left, right)
        return left.sortKey < right.sortKey
    end)
    return keys
end

local function normalizeTags(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local tag = ensureString(values[index])
        if tag ~= "" then
            normalized[#normalized + 1] = tag
        end
    end

    return normalized
end

local function normalizeStackBehavior(value)
    local behavior = string.lower(ensureString(value))
    if behavior == "independent_duration" then
        return "independent_duration"
    end

    return "refresh_duration"
end

local function normalizeStatScaling(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local entry = values[index]
        local statRef = type(entry) == "table" and normalizeRef(entry.statRef) or nil
        if statRef then
            normalized[#normalized + 1] = {
                statRef = statRef,
                coefficient = tonumber(entry.coefficient) or 0,
            }
        end
    end

    return normalized
end

local function normalizeDamageSchoolRefs(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local damageSchoolRef = normalizeRef(values[index])
        if damageSchoolRef then
            normalized[#normalized + 1] = damageSchoolRef
        end
    end

    return normalized
end

local function normalizeEffectType(value)
    local effectType = string.lower(ensureString(value))
    if effectType == "heal"
        or effectType == "stat"
        or effectType == "skill"
        or effectType == "control"
        or effectType == "apply_aura"
        or effectType == "resource"
    then
        return effectType
    end

    return "damage"
end

local function normalizeStatOperation(value)
    local operation = string.lower(ensureString(value))
    if operation == "percent" then
        return "percent"
    end

    return "flat"
end

local function normalizeCombatEventId(value)
    local combatEventId = string.lower(ensureString(value))
    if combatEventId == "" then
        return nil
    end

    return combatEventId
end

local function normalizeTriggerTarget(value)
    local triggerTarget = string.lower(ensureString(value))
    if triggerTarget == "event_source"
        or triggerTarget == "aura_caster"
        or triggerTarget == "aura_target"
    then
        return triggerTarget
    end

    return "event_other"
end

local function normalizeEffect(value)
    if type(value) ~= "table" then
        return nil
    end

    local effectType = normalizeEffectType(value.type)
    if effectType == "heal" then
        return {
            type = "heal",
            baseHealing = tonumber(value.baseHealing) or 0,
            statScaling = normalizeStatScaling(value.statScaling),
        }
    end

    if effectType == "stat" then
        return {
            type = "stat",
            statRef = normalizeRef(value.statRef),
            operation = normalizeStatOperation(value.operation),
            baseAmount = tonumber(value.baseAmount) or 0,
            statScaling = normalizeStatScaling(value.statScaling),
        }
    end

    if effectType == "skill" then
        return {
            type = "skill",
            skillRef = normalizeRef(value.skillRef),
            baseAmount = tonumber(value.baseAmount) or 0,
        }
    end

    if effectType == "control" then
        return {
            type = "control",
            cancelOnDamage = value.cancelOnDamage == true,
            preventCasting = value.preventCasting == true,
            movementRangeOverride = value.movementRangeOverride ~= nil and tonumber(value.movementRangeOverride) or nil,
            forceAutoHitAgainstTarget = value.forceAutoHitAgainstTarget == true,
        }
    end

    if effectType == "apply_aura" then
        return {
            type = "apply_aura",
            auraRef = normalizeRef(value.auraRef),
            stacks = math.max(1, math.floor(tonumber(value.stacks) or tonumber(value.auraStacks) or 1)),
            duration = math.max(1, math.floor(tonumber(value.duration) or tonumber(value.turns) or 12)),
            basePower = tonumber(value.basePower) or tonumber(value.powerLevel) or 0,
        }
    end

    if effectType == "resource" then
        return {
            type = "resource",
            resourceRef = normalizeRef(value.resourceRef),
            amount = tonumber(value.amount) or tonumber(value.baseAmount) or 0,
        }
    end

    return {
        type = "damage",
        baseDamage = tonumber(value.baseDamage) or 0,
        statScaling = normalizeStatScaling(value.statScaling),
        damageSchoolRefs = normalizeDamageSchoolRefs(value.damageSchoolRefs),
    }
end

local function normalizeEffects(values)
    local normalized = {}

    local effectKeys = sortedNumericKeys(values)
    for index = 1, #effectKeys do
        local effect = normalizeEffect(values[effectKeys[index].key])
        if effect then
            normalized[#normalized + 1] = effect
        end
    end

    return normalized
end

local function normalizeEventEffect(value)
    if type(value) ~= "table" then
        return nil
    end

    local effectType = string.lower(ensureString(value.type))
    if effectType == "heal" then
        return {
            type = "heal",
            baseHealing = tonumber(value.baseHealing) or 0,
            statScaling = normalizeStatScaling(value.statScaling),
        }
    end

    if effectType == "apply_aura" then
        return {
            type = "apply_aura",
            auraRef = normalizeRef(value.auraRef),
            stacks = math.max(1, math.floor(tonumber(value.stacks) or tonumber(value.auraStacks) or 1)),
            duration = math.max(1, math.floor(tonumber(value.duration) or tonumber(value.turns) or 12)),
            basePower = tonumber(value.basePower) or tonumber(value.powerLevel) or 0,
        }
    end

    if effectType == "remove_aura" then
        return {
            type = "remove_aura",
            auraRef = normalizeRef(value.auraRef),
            stacks = math.max(1, math.floor(tonumber(value.stacks) or tonumber(value.auraStacks) or 1)),
        }
    end

    if effectType == "resource" then
        return {
            type = "resource",
            resourceRef = normalizeRef(value.resourceRef),
            amount = tonumber(value.amount) or tonumber(value.baseAmount) or 0,
        }
    end

    if effectType == "interrupt" then
        return {
            type = "interrupt",
        }
    end

    if effectType == "revert" then
        return {
            type = "revert",
        }
    end

    if effectType == "damage" or effectType == "" then
        return {
            type = "damage",
            baseDamage = tonumber(value.baseDamage) or 0,
            statScaling = normalizeStatScaling(value.statScaling),
            damageSchoolRefs = normalizeDamageSchoolRefs(value.damageSchoolRefs),
        }
    end

    return nil
end

local function normalizeEventEffects(values)
    local normalized = {}

    local effectKeys = sortedNumericKeys(values)
    for index = 1, #effectKeys do
        local effect = normalizeEventEffect(values[effectKeys[index].key])
        if effect then
            normalized[#normalized + 1] = effect
        end
    end

    return normalized
end

local function normalizeEvent(value)
    if type(value) ~= "table" then
        return nil
    end

    local combatEventId = normalizeCombatEventId(value.combatEventId)
    local triggerTarget = combatEventId and normalizeTriggerTarget(value.triggerTarget) or nil

    return {
        combatEventId = combatEventId,
        triggerTarget = triggerTarget,
        effects = normalizeEventEffects(value.effects),
    }
end

local function normalizeEvents(values)
    local normalized = {}

    local eventKeys = sortedNumericKeys(values)
    for index = 1, #eventKeys do
        local event = normalizeEvent(values[eventKeys[index].key])
        if event then
            normalized[#normalized + 1] = event
        end
    end

    return normalized
end

function Aura:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
        icon = nil,
        effects = {},
        events = {},
        duration = 1,
        stackBehavior = "refresh_duration",
        maxStacks = 1,
        tags = {},
    }, Aura):Merge(data)
end

function Aura:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        if key ~= "effects" and key ~= "events" and key ~= "tags" then
            self[key] = value
        end
    end

    self.name = ensureString(self.name)
    self.description = ensureString(self.description)
    self.icon = ensureString(self.icon)
    self.duration = math.max(1, math.floor(tonumber(self.duration) or 1))
    self.stackBehavior = normalizeStackBehavior(self.stackBehavior)
    self.maxStacks = math.max(1, math.floor(tonumber(self.maxStacks) or 1))
    self.effects = normalizeEffects(data.effects or self.effects)
    self.events = normalizeEvents(data.events or self.events)
    self.tags = normalizeTags(data.tags or self.tags)

    return self
end

function Aura:ToTable()
    return {
        id = self.id,
        name = self.name,
        description = self.description,
        icon = self.icon,
        effects = normalizeEffects(self.effects),
        events = normalizeEvents(self.events),
        duration = self.duration,
        stackBehavior = self.stackBehavior,
        maxStacks = self.maxStacks,
        tags = normalizeTags(self.tags),
    }
end

function Aura.FromTable(data)
    return Aura:New(data)
end

Addon.Internal.Database.Classes.Aura = Aura
