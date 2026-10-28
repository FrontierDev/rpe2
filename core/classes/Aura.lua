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

local function normalizeAuraTooltipTemplateData(value)
    if type(value) ~= "table" then
        return nil
    end

    local normalized = {
        version = math.max(1, math.floor(tonumber(value.version) or 1)),
        bodyText = trimText(value.bodyText),
        bodyTokens = normalizeTooltipTemplateTokens(value.bodyTokens),
        stackingText = trimText(value.stackingText),
        stackingTokens = normalizeTooltipTemplateTokens(value.stackingTokens),
    }
    if normalized.bodyText == "" and normalized.stackingText == "" then
        return nil
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

local function normalizePolarity(value)
    local polarity = string.lower(trimText(value))
    if polarity == "helpful" or polarity == "harmful" then
        return polarity
    end

    return nil
end

local function normalizeDisposition(value)
    local disposition = string.lower(trimText(value))
    if disposition == "helpful" or disposition == "harmful" or disposition == "auto" then
        return disposition
    end

    return "auto"
end

local function normalizeTickTargetMode(value)
    return trimText(value) == "nearby_players" and "nearby_players" or "single"
end

local function normalizeTickRadius(value)
    local radius = tonumber(value)
    if radius == nil
        or radius ~= radius
        or radius == math.huge
        or radius == -math.huge
        or radius <= 0
    then
        return nil
    end

    return radius
end

local function normalizeBool(value, fallback)
    if type(value) == "boolean" then
        return value
    end

    return fallback == true
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
        or effectType == "absorb"
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

local function normalizeNonNegativeNumber(value)
    local numericValue = tonumber(value)
    if numericValue == nil or numericValue ~= numericValue
        or numericValue == math.huge or numericValue == -math.huge
    then
        return 0
    end

    return math.max(0, numericValue)
end

local function normalizeAuraDuration(value, fallback)
    local numericValue = tonumber(value)
    if numericValue == nil
        or numericValue ~= numericValue
        or numericValue == math.huge
        or numericValue == -math.huge
        or numericValue < 0
    then
        numericValue = tonumber(fallback) or 1
    end

    if numericValue == 0 then
        return 0
    end

    local normalized = math.floor(numericValue)
    if normalized < 1 then
        return math.max(1, math.floor(tonumber(fallback) or 1))
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

local function normalizeDefenceStatRef(value)
    local reference = ensureString(value)
    return reference ~= "" and reference or nil
end

local function normalizeDamageSchoolRef(value)
    return normalizeRef(value)
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
            amountMode = normalizeAmountMode(value.amountMode),
            statScaling = normalizeStatScaling(value.statScaling),
            scaleWithRank = value.scaleWithRank ~= false,
        }
    end

    if effectType == "stat" then
        return {
            type = "stat",
            statRef = normalizeRef(value.statRef),
            operation = normalizeStatOperation(value.operation),
            baseAmount = tonumber(value.baseAmount) or 0,
            statScaling = normalizeStatScaling(value.statScaling),
            scaleWithRank = value.scaleWithRank ~= false,
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
            duration = normalizeAuraDuration(value.duration ~= nil and value.duration or value.turns, 12),
            basePower = tonumber(value.basePower) or tonumber(value.powerLevel) or 0,
        }
    end

    if effectType == "resource" then
        return {
            type = "resource",
            resourceRef = normalizeRef(value.resourceRef),
            amount = tonumber(value.amount) or tonumber(value.baseAmount) or 0,
            amountMode = normalizeAmountMode(value.amountMode),
            scaleWithRank = value.scaleWithRank ~= false,
            statScaling = normalizeStatScaling(value.statScaling),
        }
    end

    if effectType == "absorb" then
        return {
            type = "absorb",
            baseAbsorption = normalizeNonNegativeNumber(value.baseAbsorption),
            amountMode = normalizeAmountMode(value.amountMode),
            statScaling = normalizeStatScaling(value.statScaling),
            damageSchoolRefs = normalizeDamageSchoolRefs(value.damageSchoolRefs),
            scaleWithRank = value.scaleWithRank ~= false,
        }
    end

    return {
        type = "damage",
        baseDamage = tonumber(value.baseDamage) or 0,
        amountMode = normalizeAmountMode(value.amountMode),
        statScaling = normalizeStatScaling(value.statScaling),
        damageSchoolRefs = normalizeDamageSchoolRefs(value.damageSchoolRefs),
        threatCoefficient = value.threatCoefficient ~= nil and tonumber(value.threatCoefficient) or nil,
        scaleWithRank = value.scaleWithRank ~= false,
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
            amountMode = normalizeAmountMode(value.amountMode),
            statScaling = normalizeStatScaling(value.statScaling),
            scaleWithRank = value.scaleWithRank ~= false,
        }
    end

    if effectType == "apply_aura" then
        return {
            type = "apply_aura",
            auraRef = normalizeRef(value.auraRef),
            stacks = math.max(1, math.floor(tonumber(value.stacks) or tonumber(value.auraStacks) or 1)),
            duration = normalizeAuraDuration(value.duration ~= nil and value.duration or value.turns, 12),
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
            amountMode = normalizeAmountMode(value.amountMode),
            scaleWithRank = value.scaleWithRank ~= false,
            statScaling = normalizeStatScaling(value.statScaling),
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
            amountMode = normalizeAmountMode(value.amountMode),
            statScaling = normalizeStatScaling(value.statScaling),
            damageSchoolRefs = normalizeDamageSchoolRefs(value.damageSchoolRefs),
            scaleWithRank = value.scaleWithRank ~= false,
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
        defenceStatRef = combatEventId == "on_defence" and normalizeDefenceStatRef(value.defenceStatRef) or nil,
        damageSchoolRef = combatEventId == "on_damage_type" and normalizeDamageSchoolRef(value.damageSchoolRef) or nil,
        triggerTarget = triggerTarget,
        chance = normalizeChancePercent(value.chance),
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
        tooltipTemplate = false,
        tooltipTemplateData = nil,
        icon = nil,
        effects = {},
        events = {},
        duration = 1,
        stackBehavior = "refresh_duration",
        maxStacks = 1,
        tags = {},
        disposition = "auto",
        polarity = nil,
        tickTargetMode = "single",
        tickRadiusYards = nil,
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
    self.tooltipTemplate = normalizeBool(self.tooltipTemplate, false)
    self.tooltipTemplateData = normalizeAuraTooltipTemplateData(self.tooltipTemplateData)
    self.icon = ensureString(self.icon)
    self.duration = normalizeAuraDuration(self.duration, 1)
    self.stackBehavior = normalizeStackBehavior(self.stackBehavior)
    local hasDisposition = data.disposition ~= nil
    if hasDisposition then
        self.disposition = normalizeDisposition(data.disposition)
        self.polarity = self.disposition ~= "auto" and self.disposition or nil
    else
        self.polarity = normalizePolarity(self.polarity)
        self.disposition = self.polarity or normalizeDisposition(self.disposition)
    end
    self.tickTargetMode = normalizeTickTargetMode(self.tickTargetMode)
    self.tickRadiusYards = normalizeTickRadius(self.tickRadiusYards)
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
        tooltipTemplate = self.tooltipTemplate == true,
        tooltipTemplateData = normalizeAuraTooltipTemplateData(self.tooltipTemplateData),
        icon = self.icon,
        effects = normalizeEffects(self.effects),
        events = normalizeEvents(self.events),
        duration = self.duration,
        stackBehavior = self.stackBehavior,
        maxStacks = self.maxStacks,
        tags = normalizeTags(self.tags),
        disposition = normalizeDisposition(self.disposition),
        polarity = self.polarity,
        tickTargetMode = self.tickTargetMode,
        tickRadiusYards = self.tickRadiusYards,
    }
end

local function addSignedSignal(signals, value)
    local numericValue = tonumber(value)
    if numericValue == nil or numericValue == 0 then
        return
    end

    if numericValue < 0 then
        signals.harmful = true
    else
        signals.helpful = true
    end
end

local function addEffectSignals(signals, effect, visitAura, targetIsRecipient)
    if type(effect) ~= "table" or targetIsRecipient ~= true then
        return
    end

    local effectType = string.lower(ensureString(effect.type))
    if effectType == "damage" or effectType == "interrupt" then
        signals.harmful = true
        return
    end
    if effectType == "heal" or effectType == "absorb" then
        signals.helpful = true
        return
    end
    if effectType == "stat" then
        addSignedSignal(signals, effect.baseAmount)
        for index = 1, #(effect.statScaling or {}) do
            addSignedSignal(signals, effect.statScaling[index] and effect.statScaling[index].coefficient)
        end
        return
    end
    if effectType == "resource" or effectType == "skill" then
        addSignedSignal(signals, effect.amount or effect.baseAmount)
        for index = 1, #(effect.statScaling or {}) do
            addSignedSignal(signals, effect.statScaling[index] and effect.statScaling[index].coefficient)
        end
        return
    end
    if effectType == "control" then
        local movementRangeOverride = tonumber(effect.movementRangeOverride)
        if effect.preventCasting == true
            or effect.forceAutoHitAgainstTarget == true
            or (movementRangeOverride ~= nil and movementRangeOverride <= 0)
        then
            signals.harmful = true
        end
        return
    end
    if effectType == "apply_aura" and type(visitAura) == "function" then
        visitAura(effect.auraRef)
    end
end

local function resolveNestedAuraDefinition(auraRef, options)
    if type(options) == "table" and type(options.resolveAura) == "function" then
        local resolved = options.resolveAura(auraRef)
        if type(resolved) == "table" then
            return resolved
        end
    end

    local reference = normalizeRef(auraRef)
    local datasetId, auraId
    if reference then
        datasetId, auraId = reference:match("^([^:]+):(.+)$")
    end
    if not datasetId then
        return nil
    end
    local database = Addon.Internal and Addon.Internal.Database or nil
    local dataset = database and type(database.GetDatasetByID) == "function" and database.GetDatasetByID(datasetId) or nil
    for index = 1, #(dataset and dataset.auras or {}) do
        local aura = dataset.auras[index]
        if type(aura) == "table" and tostring(aura.id or "") == auraId then
            return aura
        end
    end

    return nil
end

local function resolveAuraDisposition(auraDefinition, options)
    local signals = {
        helpful = false,
        harmful = false,
    }
    local visitedDefinitions = {}
    local visitedRefs = {}

    local visitAura
    visitAura = function(definition, reference)
        if type(definition) ~= "table" then
            return
        end
        if reference and visitedRefs[reference] then
            return
        end
        if visitedDefinitions[definition] then
            return
        end

        local explicit = normalizeDisposition(definition.disposition)
        if definition.disposition == nil then
            explicit = normalizePolarity(definition.polarity) or "auto"
        end
        if explicit == "helpful" then
            signals.helpful = true
            return
        elseif explicit == "harmful" then
            signals.harmful = true
            return
        end

        visitedDefinitions[definition] = true
        if reference then
            visitedRefs[reference] = true
        end

        local targetIsRecipient = true
        local auraCasterEventId = tonumber(options and options.auraCasterEventId) or 0
        local auraTargetEventId = tonumber(options and options.auraTargetEventId) or 0
        local effectKeys = sortedNumericKeys(definition.effects)
        for index = 1, #effectKeys do
            addEffectSignals(signals, definition.effects[effectKeys[index].key], function(nestedRef)
                local nested = resolveNestedAuraDefinition(nestedRef, options)
                local nestedReference = normalizeRef(nestedRef)
                visitAura(nested, nestedReference)
            end, targetIsRecipient)
        end

        local eventKeys = sortedNumericKeys(definition.events)
        for eventIndex = 1, #eventKeys do
            local auraEvent = definition.events[eventKeys[eventIndex].key]
            if type(auraEvent) == "table" then
                local triggerTarget = string.lower(ensureString(auraEvent.triggerTarget))
                -- Static definitions cannot identify which event_source or
                -- event_other unit is the recipient, so those effects are not
                -- used for recipient polarity. Include aura_caster only for a
                -- self-targeted aura.
                local eventTargetsRecipient = triggerTarget == "aura_target"
                    or (triggerTarget == "aura_caster"
                        and auraCasterEventId > 0
                        and auraCasterEventId == auraTargetEventId)
                local eventEffectKeys = sortedNumericKeys(auraEvent.effects)
                for effectIndex = 1, #eventEffectKeys do
                    addEffectSignals(
                        signals,
                        auraEvent.effects[eventEffectKeys[effectIndex].key],
                        function(nestedRef)
                            local nested = resolveNestedAuraDefinition(nestedRef, options)
                            visitAura(nested, normalizeRef(nestedRef))
                        end,
                        eventTargetsRecipient
                    )
                end
            end
        end

        visitedDefinitions[definition] = nil
        if reference then
            visitedRefs[reference] = nil
        end
    end

    visitAura(auraDefinition)

    -- Mixed effects resolve deterministically as harmful. Authors can select
    -- helpful/harmful explicitly when the authored intent is not represented
    -- by the static effect semantics.
    return signals.harmful and "harmful" or "helpful"
end

function Aura.ResolveDisposition(auraDefinition, options)
    return resolveAuraDisposition(auraDefinition, options)
end

function Aura:ResolveDisposition(options)
    return resolveAuraDisposition(self, options)
end

function Aura.FromTable(data)
    return Aura:New(data)
end

function Aura:HasAbsorbEffect()
    for index = 1, #(self.effects or {}) do
        local effect = self.effects[index]
        if type(effect) == "table" and effect.type == "absorb" then
            return true
        end
    end

    return false
end

function Aura:Validate()
    local errors = {}
    if self.disposition ~= "auto" and self.disposition ~= "helpful" and self.disposition ~= "harmful" then
        errors[#errors + 1] = "Aura disposition must be Auto, Helpful or Harmful."
    end
    if self:HasAbsorbEffect() then
        if (tonumber(self.maxStacks) or 1) > 1 then
            errors[#errors + 1] = "Absorb effects require Max Stacks to be 1 in V1."
        end
        if self.stackBehavior == "independent_duration" then
            errors[#errors + 1] = "Absorb effects do not support Independent Duration stacking in V1."
        end
    end
    if self.tickTargetMode == "nearby_players" and self.tickRadiusYards == nil then
        errors[#errors + 1] = "Nearby Players tick targeting requires a positive finite tick radius."
    end

    return {
        valid = #errors == 0,
        errors = errors,
        reason = errors[1] or "",
    }
end

Addon.Internal.Database.Classes.Aura = Aura
