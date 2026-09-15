local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Trait = {}
Trait.__index = Trait
local Condition = Addon.Internal.Database.Classes.Condition or {}

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

local function normalizeCategory(value)
    local category = ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
    if category == "" then
        return ""
    end

    return category
end

local function normalizeUnlockLevel(value)
    local level = math.floor(tonumber(value) or 1)
    if level < 1 then
        return 1
    end

    return level
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

local function normalizeBoolean(value)
    return value == true
end

local function normalizeStatBonuses(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local entry = values[index]
        local statRef = type(entry) == "table" and normalizeRef(entry.statRef or entry.sourceStatRef) or nil
        if statRef then
            normalized[#normalized + 1] = {
                statRef = statRef,
                operation = type(entry) == "table" and tostring(entry.operation or "flat") == "percent" and "percent" or "flat",
                value = tonumber(entry.value) or 0,
            }
        end
    end

    return normalized
end

local function normalizeSkillBonuses(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local entry = values[index]
        local skillRef = type(entry) == "table" and normalizeRef(entry.skillRef) or nil
        if skillRef then
            normalized[#normalized + 1] = {
                skillRef = skillRef,
                value = tonumber(entry.value) or 0,
            }
        end
    end

    return normalized
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

local function normalizeAutoAuraTarget(value)
    local target = string.lower(ensureString(value))
    if target == "all_allies" or target == "all_enemies" then
        return target
    end

    return "self"
end

local function normalizeAutomaticAura(value)
    if type(value) ~= "table" then
        return nil
    end

    local auraRef = normalizeRef(value.auraRef)
    if not auraRef then
        return nil
    end

    return {
        auraRef = auraRef,
        targetScope = normalizeAutoAuraTarget(value.targetScope),
        stacks = math.max(1, math.floor(tonumber(value.stacks) or 1)),
        turns = math.max(1, math.floor(tonumber(value.turns) or 1)),
        powerLevel = tonumber(value.powerLevel) or 0,
    }
end

local function normalizeAutomaticAuras(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local entry = normalizeAutomaticAura(values[index])
        if entry then
            normalized[#normalized + 1] = entry
        end
    end

    return normalized
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

local function normalizeChancePercent(value)
    local numericValue = tonumber(value)
    if numericValue == nil then
        return 100
    end

    return math.max(0, math.min(100, numericValue))
end

local function normalizeAmountMode(value)
    local mode = tostring(value or "flat")
    if mode == "base_percent" then
        return "base_percent"
    end
    if mode == "max_percent" then
        return "max_percent"
    end

    return "flat"
end

local function normalizeEventEffectType(value)
    local effectType = string.lower(ensureString(value))
    if effectType == "heal" then
        return "heal"
    end
    if effectType == "apply_aura" then
        return "apply_aura"
    end
    if effectType == "remove_aura" then
        return "remove_aura"
    end
    if effectType == "resource" then
        return "resource"
    end

    return "damage"
end

local function normalizeEventEffect(value)
    if type(value) ~= "table" then
        return nil
    end

    local effectType = normalizeEventEffectType(value.type)
    if effectType == "heal" then
        return {
            type = "heal",
            baseHealing = tonumber(value.baseHealing) or tonumber(value.baseAmount) or 0,
            amountMode = normalizeAmountMode(value.amountMode),
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

    if effectType == "resource" then
        return {
            type = "resource",
            resourceRef = normalizeRef(value.resourceRef),
            amount = tonumber(value.amount) or tonumber(value.baseAmount) or 0,
            amountMode = normalizeAmountMode(value.amountMode),
        }
    end

    if effectType == "remove_aura" then
        return {
            type = "remove_aura",
            auraRef = normalizeRef(value.auraRef),
            stacks = math.max(1, math.floor(tonumber(value.stacks) or tonumber(value.auraStacks) or 1)),
        }
    end

    return {
        type = "damage",
        baseDamage = tonumber(value.baseDamage) or tonumber(value.baseAmount) or 0,
        amountMode = normalizeAmountMode(value.amountMode),
        statScaling = normalizeStatScaling(value.statScaling),
        damageSchoolRefs = normalizeDamageSchoolRefs(value.damageSchoolRefs),
    }
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
    if not combatEventId then
        return nil
    end

    return {
        combatEventId = combatEventId,
        triggerTarget = normalizeTriggerTarget(value.triggerTarget),
        chance = normalizeChancePercent(value.chance),
        effects = normalizeEventEffects(value.effects),
    }
end

local function normalizeEvents(values)
    local normalized = {}

    local eventKeys = sortedNumericKeys(values)
    for index = 1, #eventKeys do
        local entry = normalizeEvent(values[eventKeys[index].key])
        if entry and #(entry.effects or {}) > 0 then
            normalized[#normalized + 1] = entry
        end
    end

    return normalized
end

function Trait.NormalizeStatBonuses(values)
    return normalizeStatBonuses(values)
end

function Trait.NormalizeSkillBonuses(values)
    return normalizeSkillBonuses(values)
end

function Trait.NormalizeAutomaticAuras(values)
    return normalizeAutomaticAuras(values)
end

function Trait.NormalizeEvents(values)
    return normalizeEvents(values)
end

function Trait.NormalizeRuntimePayload(value)
    local payload = ensureTable(value)
    return {
        name = ensureString(payload.name),
        description = ensureString(payload.description),
        icon = ensureString(payload.icon),
        category = normalizeCategory(payload.category),
        unlockLevel = normalizeUnlockLevel(payload.unlockLevel),
        conditions = Condition.NormalizeList and Condition.NormalizeList(payload.conditions) or {},
        statBonuses = normalizeStatBonuses(payload.statBonuses),
        skillBonuses = normalizeSkillBonuses(payload.skillBonuses),
        automaticAuras = normalizeAutomaticAuras(payload.automaticAuras),
        events = normalizeEvents(payload.events),
    }
end

function Trait:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
        icon = "",
        category = "",
        unlockLevel = 1,
        isEnvironmental = false,
        conditions = {},
        statBonuses = {},
        skillBonuses = {},
        automaticAuras = {},
        events = {},
    }, Trait):Merge(data)
end

function Trait:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        if key ~= "conditions" and key ~= "statBonuses" and key ~= "skillBonuses" and key ~= "automaticAuras" and key ~= "events" then
            self[key] = value
        end
    end

    self.name = ensureString(self.name)
    self.description = ensureString(self.description)
    self.icon = ensureString(self.icon)
    self.category = normalizeCategory(self.category)
    self.unlockLevel = normalizeUnlockLevel(self.unlockLevel)
    self.isEnvironmental = normalizeBoolean(self.isEnvironmental)
    self.conditions = Condition.NormalizeList and Condition.NormalizeList(data.conditions or self.conditions) or {}
    self.statBonuses = normalizeStatBonuses(data.statBonuses or self.statBonuses)
    self.skillBonuses = normalizeSkillBonuses(data.skillBonuses or self.skillBonuses)
    self.automaticAuras = normalizeAutomaticAuras(data.automaticAuras or self.automaticAuras)
    self.events = normalizeEvents(data.events or self.events)

    return self
end

function Trait:ToTable()
    return {
        id = self.id,
        name = self.name,
        description = self.description,
        icon = self.icon,
        category = self.category,
        unlockLevel = self.unlockLevel,
        isEnvironmental = self.isEnvironmental == true,
        conditions = Condition.NormalizeList and Condition.NormalizeList(self.conditions) or {},
        statBonuses = normalizeStatBonuses(self.statBonuses),
        skillBonuses = normalizeSkillBonuses(self.skillBonuses),
        automaticAuras = normalizeAutomaticAuras(self.automaticAuras),
        events = normalizeEvents(self.events),
    }
end

function Trait.FromTable(data)
    return Trait:New(data)
end

Addon.Internal.Database.Classes.Trait = Trait
