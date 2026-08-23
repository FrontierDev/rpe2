local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Spell = {}
Spell.__index = Spell
local Condition = Addon.Internal.Database.Classes.Condition or {}

local FIXED_ID_LENGTH = 8
local GUID_ALPHABET = "0123456789abcdef"
local guidRandomSeeded = false

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

local function trimText(value)
    local text = ensureString(value)
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

local function copyScalarFields(source, keys)
    local copied = {}
    for index = 1, #keys do
        local key = keys[index]
        local value = type(source) == "table" and source[key] or nil
        if type(value) == "string" then
            copied[key] = value
        elseif type(value) == "number" then
            copied[key] = value
        elseif type(value) == "boolean" then
            copied[key] = value
        end
    end

    return copied
end

local function normalizeTooltipTemplateToken(token)
    if type(token) ~= "table" then
        return nil
    end

    local key = trimText(token.key)
    local tokenType = trimText(token.tokenType)
    if key == "" or tokenType == "" then
        return nil
    end

    local normalized = copyScalarFields(token, {
        "componentIndex",
        "effectIndex",
        "eventIndex",
        "baseField",
        "amountMode",
        "operation",
        "resourceRef",
        "statRef",
        "skillRef",
        "auraRef",
        "targetDisposition",
        "targetType",
        "applyMode",
    })
    normalized.key = key
    normalized.tokenType = tokenType
    return normalized
end

local function normalizeTooltipTemplateTokens(values)
    local normalized = {}
    for index = 1, #(values or {}) do
        local token = normalizeTooltipTemplateToken(values[index])
        if token then
            normalized[#normalized + 1] = token
        end
    end

    return normalized
end

local function normalizeTooltipTargetContext(value)
    if type(value) ~= "table" then
        return nil
    end

    return {
        subject = ensureString(value.subject),
        object = ensureString(value.object),
        possessive = ensureString(value.possessive),
        reflexive = ensureString(value.reflexive),
    }
end

local function normalizeSpellAuraSectionTemplate(section)
    if type(section) ~= "table" then
        return nil
    end

    local nameText = trimText(section.nameText)
    local descriptionText = trimText(section.descriptionText)
    if nameText == "" and descriptionText == "" then
        return nil
    end

    local normalized = {
        auraRef = ensureString(section.auraRef),
        datasetId = ensureString(section.datasetId),
        spellDatasetId = ensureString(section.spellDatasetId),
        nameText = nameText,
        icon = ensureString(section.icon),
        descriptionText = descriptionText,
        tokens = normalizeTooltipTemplateTokens(section.tokens),
        powerLevel = tonumber(section.powerLevel) or 0,
        stacks = math.max(1, math.floor(tonumber(section.stacks) or 1)),
    }
    if section.duration ~= nil then
        normalized.duration = math.max(0, math.floor(tonumber(section.duration) or 0))
    end
    normalized.targetContext = normalizeTooltipTargetContext(section.targetContext)
    return normalized
end

local function normalizeSpellTooltipTemplateData(value)
    if type(value) ~= "table" then
        return nil
    end

    local normalized = {
        version = math.max(1, math.floor(tonumber(value.version) or 1)),
        mainText = trimText(value.mainText),
        tokens = normalizeTooltipTemplateTokens(value.tokens),
        auraSections = {},
    }
    for index = 1, #(value.auraSections or {}) do
        local section = normalizeSpellAuraSectionTemplate(value.auraSections[index])
        if section then
            normalized.auraSections[#normalized.auraSections + 1] = section
        end
    end

    if normalized.mainText == "" and #normalized.auraSections == 0 then
        return nil
    end

    return normalized
end

local function normalizeCooldownGroup(value)
    local group = ensureString(value)
    if group == "" then
        return ""
    end

    return group
end

local function normalizeBool(value, fallback)
    if value == nil then
        return fallback == true
    end

    return value == true
end

local function ensureGuidRandomSeed()
    if guidRandomSeeded then
        return
    end

    local seed = 0
    if type(time) == "function" then
        seed = time()
    elseif type(GetServerTime) == "function" then
        seed = GetServerTime()
    end

    if type(GetTimePreciseSec) == "function" then
        seed = seed + math.floor(GetTimePreciseSec() * 1000)
    elseif type(GetTime) == "function" then
        seed = seed + math.floor(GetTime() * 1000)
    end

    if type(UnitGUID) == "function" then
        local playerGuid = tostring(UnitGUID("player") or "")
        for index = 1, #playerGuid do
            seed = seed + string.byte(playerGuid, index)
        end
    end

    if type(math.randomseed) == "function" then
        math.randomseed(seed)
        math.random()
        math.random()
        math.random()
    end

    guidRandomSeeded = true
end

local function generateGuidLikeId()
    ensureGuidRandomSeed()

    local chars = {}
    for index = 1, FIXED_ID_LENGTH do
        local offset = type(math.random) == "function" and math.random(1, #GUID_ALPHABET) or ((index - 1) % #GUID_ALPHABET) + 1
        chars[index] = GUID_ALPHABET:sub(offset, offset)
    end

    return table.concat(chars)
end

local function normalizeCastPhase(value)
    local phase = tostring(value or "on_cast_end")
    if phase == "on_cast_start" or phase == "on_cast_end" or phase == "on_channel_tick" then
        return phase
    end

    return "on_cast_end"
end

local function normalizeResourceCostAmountMode(value)
    local mode = tostring(value or "flat")
    if mode == "base_percent" then
        return "base_percent"
    end
    if mode == "max_percent" then
        return "max_percent"
    end

    return "flat"
end

local function normalizeWeaponDamageMode(value)
    local mode = tostring(value or "none")
    if mode == "main_hand" or mode == "off_hand" or mode == "both" then
        return mode
    end

    return "none"
end

local function normalizeHitType(value)
    local hitType = tostring(value or "ability")
    if hitType == "auto" or hitType == "pet" then
        return hitType
    end

    return "ability"
end

local function normalizeDamageType(value)
    local damageType = tostring(value or "spell")
    if damageType == "melee" or damageType == "ranged" then
        return damageType
    end

    return "spell"
end

local function normalizeLearnMode(value)
    local mode = tostring(value or "trainer")
    if mode == "always_learned" or mode == "trainer" or mode == "book" or mode == "unavailable" then
        return mode
    end

    return "trainer"
end

local function normalizeSpellbookCategory(value)
    local category = ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
    if category == "" then
        return ""
    end

    return category
end

local function normalizeEventKey(value)
    local key = tostring(value or "")
    if key == "on_auto_attack_hit"
        or key == "on_auto_attack_taken"
        or key == "on_melee_hit"
        or key == "on_melee_taken"
        or key == "on_ranged_hit"
        or key == "on_ranged_taken"
        or key == "on_spell_hit"
        or key == "on_spell_taken"
        or key == "on_heal"
        or key == "on_heal_taken"
        or key == "on_critical_hit"
        or key == "on_critical_hit_taken"
        or key == "on_critical_heal"
        or key == "on_critical_heal_taken"
    then
        return key
    end

    return nil
end

local function normalizeEventList(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local key = normalizeEventKey(values[index])
        if key then
            normalized[#normalized + 1] = key
        end
    end

    return normalized
end

local function normalizeRef(value)
    local ref = ensureString(value)
    if ref == "" then
        return nil
    end

    return ref
end

local function normalizeCastingGroup(value)
    local group = ensureString(value)
    if group == "" then
        return "default"
    end

    return group
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
        local ref = normalizeRef(values[index])
        if ref then
            normalized[#normalized + 1] = ref
        end
    end

    return normalized
end

local function normalizeResourceCosts(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local entry = values[index]
        local resourceRef = type(entry) == "table" and normalizeRef(entry.resourceRef) or nil
        if resourceRef then
            normalized[#normalized + 1] = {
                resourceRef = resourceRef,
                castPhase = normalizeCastPhase(entry.castPhase),
                amountMode = normalizeResourceCostAmountMode(entry.amountMode),
                refundOnInterrupt = tonumber(entry.refundOnInterrupt) or 0,
                amount = tonumber(entry.amount) or 0,
            }
        end
    end

    return normalized
end

local function buildDefaultEffect(effectType)
    local normalizedType = tostring(effectType or "damage")

    if normalizedType == "interrupt" then
        return {
            type = "interrupt",
            targetEvents = {},
        }
    end

    if normalizedType == "revert" then
        return {
            type = "revert",
            targetEvents = {},
        }
    end

    if normalizedType == "summon_pet" then
        return {
            type = "summon_pet",
            unitRef = nil,
            targetEvents = {},
        }
    end

    if normalizedType == "heal" then
        return {
            type = "heal",
            baseHealing = 0,
            amountMode = "flat",
            statScaling = {},
            usesProjectile = false,
            projectilePath = "",
            projectileSpeed = 0,
            applyAura = false,
            auraRef = nil,
            auraStacks = 1,
            targetEvents = {},
        }
    end

    if normalizedType == "apply_aura" then
        return {
            type = "apply_aura",
            auraRef = nil,
            stacks = 1,
            duration = 12,
            basePower = 0,
            targetEvents = {},
        }
    end

    if normalizedType == "remove_aura" then
        return {
            type = "remove_aura",
            auraRef = nil,
            stacks = 1,
            targetEvents = {},
        }
    end

    if normalizedType == "resource" then
        return {
            type = "resource",
            resourceRef = nil,
            amount = 0,
            amountMode = "flat",
            targetEvents = {},
        }
    end

        return {
            type = "damage",
            baseDamage = 0,
            amountMode = "flat",
            threatCoefficient = 1,
            weaponDamageMode = "none",
            weaponDamageCoefficient = 1,
            statScaling = {},
        damageSchoolRefs = {},
        hitType = "ability",
        damageType = "spell",
        alwaysHits = false,
        usesProjectile = false,
        projectilePath = "",
        projectileSpeed = 0,
        applyAura = false,
        auraRef = nil,
        auraStacks = 1,
        targetEvents = {},
    }
end

local function normalizeEffect(value)
    local data = type(value) == "table" and value or {}
    local effect = buildDefaultEffect(data.type)

    if effect.type == "damage" then
        effect.baseDamage = tonumber(data.baseDamage) or 0
        effect.amountMode = normalizeResourceCostAmountMode(data.amountMode)
        effect.threatCoefficient = tonumber(data.threatCoefficient) or 1
        effect.weaponDamageMode = normalizeWeaponDamageMode(data.weaponDamageMode)
        effect.weaponDamageCoefficient = tonumber(data.weaponDamageCoefficient) or 1
        effect.statScaling = normalizeStatScaling(data.statScaling)
        effect.damageSchoolRefs = normalizeDamageSchoolRefs(data.damageSchoolRefs)
        effect.hitType = normalizeHitType(data.hitType)
        effect.damageType = normalizeDamageType(data.damageType)
        effect.alwaysHits = normalizeBool(data.alwaysHits, false)
        effect.usesProjectile = normalizeBool(data.usesProjectile, false)
        effect.projectilePath = ensureString(data.projectilePath)
        effect.projectileSpeed = tonumber(data.projectileSpeed) or 0
        effect.applyAura = normalizeBool(data.applyAura, false)
        effect.auraRef = normalizeRef(data.auraRef)
        effect.auraStacks = math.max(1, math.floor(tonumber(data.auraStacks) or 1))
        effect.targetEvents = normalizeEventList(data.targetEvents)
        return effect
    end

    if effect.type == "heal" then
        effect.baseHealing = tonumber(data.baseHealing) or 0
        effect.amountMode = normalizeResourceCostAmountMode(data.amountMode)
        effect.statScaling = normalizeStatScaling(data.statScaling)
        effect.usesProjectile = normalizeBool(data.usesProjectile, false)
        effect.projectilePath = ensureString(data.projectilePath)
        effect.projectileSpeed = tonumber(data.projectileSpeed) or 0
        effect.applyAura = normalizeBool(data.applyAura, false)
        effect.auraRef = normalizeRef(data.auraRef)
        effect.auraStacks = math.max(1, math.floor(tonumber(data.auraStacks) or 1))
        effect.targetEvents = normalizeEventList(data.targetEvents)
        return effect
    end

    if effect.type == "apply_aura" then
        effect.auraRef = normalizeRef(data.auraRef)
        effect.stacks = math.max(1, math.floor(tonumber(data.stacks) or 1))
        effect.duration = tonumber(data.duration) or 12
        effect.basePower = tonumber(data.basePower) or 0
        effect.targetEvents = normalizeEventList(data.targetEvents)
        return effect
    end

    if effect.type == "remove_aura" then
        effect.auraRef = normalizeRef(data.auraRef)
        effect.stacks = math.max(1, math.floor(tonumber(data.stacks) or 1))
        effect.targetEvents = normalizeEventList(data.targetEvents)
        return effect
    end

    if effect.type == "summon_pet" then
        effect.unitRef = normalizeRef(data.unitRef)
        effect.targetEvents = normalizeEventList(data.targetEvents)
        return effect
    end

    if effect.type == "interrupt" or effect.type == "revert" then
        effect.targetEvents = normalizeEventList(data.targetEvents)
        return effect
    end

    effect.resourceRef = normalizeRef(data.resourceRef)
    effect.amount = tonumber(data.amount) or 0
    effect.amountMode = normalizeResourceCostAmountMode(data.amountMode)
    effect.targetEvents = normalizeEventList(data.targetEvents)
    return effect
end

local function normalizeTarget(value)
    local data = type(value) == "table" and value or {}
    local targetType = tostring(data.type or "single")
    if targetType ~= "caster"
        and targetType ~= "single"
        and targetType ~= "multi"
        and targetType ~= "pet"
        and targetType ~= "last_attackers"
    then
        targetType = "single"
    end

    local targetDisposition = tostring(data.targetDisposition or "enemy")
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
    local minTargets = math.max(0, math.floor(tonumber(data.minTargets) or fallbackMinTargets))
    local maxTargets = math.max(minTargets, math.floor(tonumber(data.maxTargets) or math.max(1, minTargets)))

    return {
        type = targetType,
        requiresTarget = requiresTarget,
        targetDisposition = targetDisposition,
        minTargets = minTargets,
        maxTargets = maxTargets,
        allowDeadTargets = normalizeBool(data.allowDeadTargets, false),
        disableSelfCast = normalizeBool(data.disableSelfCast, false),
    }
end

local function normalizeComponents(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local entry = values[index]
        if type(entry) == "table" then
            normalized[#normalized + 1] = {
                key = ensureString(entry.key) ~= "" and tostring(entry.key) or generateGuidLikeId(),
                castingGroup = normalizeCastingGroup(entry.castingGroup),
                castPhase = normalizeCastPhase(entry.castPhase),
                target = normalizeTarget(entry.target),
                effect = normalizeEffect(entry.effect),
            }
        end
    end

    return normalized
end

function Spell:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
        tooltipTemplate = false,
        tooltipTemplateData = nil,
        icon = "",
        seedNPCSpell = false,
        learnMode = "trainer",
        spellbookCategory = "",
        castTime = 0,
        cooldown = 0,
        cooldownGroup = "",
        charges = 0,
        useCooldownCharges = false,
        cooldownScalesWithHaste = false,
        triggersGCD = true,
        ignoreGCD = false,
        range = 0,
        canMoveWhileCasting = false,
        allowDeadTargets = false,
        mountedCombatOnly = false,
        totalTicks = 0,
        casterEvents = {},
        resourceCosts = {},
        conditions = {},
        components = {},
        tags = {},
    }, Spell):Merge(data)
end

function Spell:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        if key ~= "resourceCosts" and key ~= "components" and key ~= "cost" and key ~= "effects" and key ~= "conditions" and key ~= "isChanneled" then
            self[key] = value
        end
    end

    self.description = ensureString(self.description)
    self.tooltipTemplate = normalizeBool(self.tooltipTemplate, false)
    self.tooltipTemplateData = normalizeSpellTooltipTemplateData(self.tooltipTemplateData)
    self.icon = ensureString(self.icon)
    self.seedNPCSpell = normalizeBool(self.seedNPCSpell, false)
    self.learnMode = normalizeLearnMode(self.learnMode)
    self.spellbookCategory = normalizeSpellbookCategory(self.spellbookCategory)
    self.castTime = tonumber(self.castTime) or 0
    self.cooldown = tonumber(self.cooldown) or 0
    self.cooldownGroup = normalizeCooldownGroup(self.cooldownGroup)
    self.charges = tonumber(self.charges) or 0
    self.useCooldownCharges = normalizeBool(self.useCooldownCharges, false)
    self.cooldownScalesWithHaste = normalizeBool(self.cooldownScalesWithHaste, false)
    self.triggersGCD = normalizeBool(self.triggersGCD, true)
    self.ignoreGCD = normalizeBool(self.ignoreGCD, false)
    if self.ignoreGCD then
        self.triggersGCD = false
    end
    self.range = tonumber(self.range) or 0
    self.canMoveWhileCasting = normalizeBool(self.canMoveWhileCasting, false)
    self.allowDeadTargets = normalizeBool(self.allowDeadTargets, false)
    self.mountedCombatOnly = normalizeBool(self.mountedCombatOnly, false)
    self.totalTicks = tonumber(self.totalTicks) or 0
    self.casterEvents = normalizeEventList(self.casterEvents)
    self.tags = ensureTable(self.tags)
    self.resourceCosts = normalizeResourceCosts(data.resourceCosts or data.cost)
    self.conditions = Condition.NormalizeList and Condition.NormalizeList(data.conditions or self.conditions) or {}
    self.components = normalizeComponents(data.components or data.effects)

    return self
end

function Spell:ToTable()
    return {
        id = self.id,
        name = self.name,
        description = self.description,
        tooltipTemplate = self.tooltipTemplate,
        tooltipTemplateData = normalizeSpellTooltipTemplateData(self.tooltipTemplateData),
        icon = self.icon,
        seedNPCSpell = self.seedNPCSpell == true,
        learnMode = self.learnMode,
        spellbookCategory = self.spellbookCategory,
        castTime = self.castTime,
        cooldown = self.cooldown,
        cooldownGroup = self.cooldownGroup,
        charges = self.charges,
        useCooldownCharges = self.useCooldownCharges == true,
        cooldownScalesWithHaste = self.cooldownScalesWithHaste == true,
        triggersGCD = self.triggersGCD == true,
        ignoreGCD = self.ignoreGCD == true,
        range = self.range,
        canMoveWhileCasting = self.canMoveWhileCasting == true,
        allowDeadTargets = self.allowDeadTargets == true,
        mountedCombatOnly = self.mountedCombatOnly == true,
        totalTicks = self.totalTicks,
        casterEvents = normalizeEventList(self.casterEvents),
        resourceCosts = normalizeResourceCosts(self.resourceCosts),
        conditions = Condition.NormalizeList and Condition.NormalizeList(self.conditions) or {},
        components = normalizeComponents(self.components),
        tags = self.tags,
    }
end

function Spell.FromTable(data)
    return Spell:New(data)
end

Addon.Internal.Database.Classes.Spell = Spell
