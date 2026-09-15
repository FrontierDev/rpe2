local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Spellcasting = Client.Spellcasting
local Registry = Addon.Internal.Registry or {}
local Ruleset = Addon.Internal.Ruleset or {}
local Event = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil

local BASIC_ATTACK_RULE_KEY = "basic_attacks_do_not_consume_gcd"
local BASIC_ATTACK_TYPE_FAILURE_TEXT = "A basic attack of another damage type was already used this turn."

local baseBuildSpellActivationSnapshot = Spellcasting.BuildSpellActivationSnapshot
local baseApplyLocalSpellCooldown = Spellcasting.ApplyLocalSpellCooldown
local baseResolveSpellActivationState = Spellcasting.ResolveSpellActivationState

if type(baseBuildSpellActivationSnapshot) ~= "function"
    or type(Client.ResolveSpellActivation) ~= "function"
then
    return
end

local function registerBasicAttackRule()
    local definitions = Addon.Internal
        and Addon.Internal.Ruleset
        and Addon.Internal.Ruleset.Rules
        and Addon.Internal.Ruleset.Rules.Definitions
        or nil
    if type(definitions) ~= "table" then
        return false
    end

    for categoryIndex = 1, #definitions do
        local category = definitions[categoryIndex]
        if type(category) == "table" and category.key == "combat" then
            category.rules = type(category.rules) == "table" and category.rules or {}
            for ruleIndex = 1, #category.rules do
                if category.rules[ruleIndex] and category.rules[ruleIndex].key == BASIC_ATTACK_RULE_KEY then
                    return true
                end
            end

            category.rules[#category.rules + 1] = {
                key = BASIC_ATTACK_RULE_KEY,
                label = "Basic Attacks Do Not Consume Global Cooldown",
                type = "checkbox",
                default = true,
                description = "Basic attacks (auto hit type) do not consume the global cooldown. Each basic attack may still be used only once per turn, and after using one basic attack only other basic attacks of the same damage type (melee, ranged, or spell) may be used that turn.",
            }
            return true
        end
    end

    return false
end

registerBasicAttackRule()

local function isBasicAttackRuleEnabled()
    if type(Ruleset.GetRulesetRuleValueByKey) ~= "function" then
        return true
    end

    local activeRuleset = type(Ruleset.GetActiveRuleset) == "function" and Ruleset.GetActiveRuleset() or nil
    return Ruleset.GetRulesetRuleValueByKey(activeRuleset, "combat", BASIC_ATTACK_RULE_KEY, true) == true
end

local function normalizeDamageType(value)
    local damageType = string.lower(tostring(value or ""))
    if damageType == "melee" or damageType == "ranged" or damageType == "spell" then
        return damageType
    end
    return damageType ~= "" and damageType or nil
end

local function resolveBasicAttackDamageType(spell)
    if type(spell) ~= "table" then
        return nil
    end

    for index = 1, #(spell.components or {}) do
        local component = spell.components[index]
        local effect = type(component) == "table" and component.effect or nil
        if type(effect) == "table"
            and tostring(effect.type or "") == "damage"
            and string.lower(tostring(effect.hitType or "")) == "auto"
        then
            return normalizeDamageType(effect.damageType)
        end
    end

    return nil
end

local function resolveSpell(spellRef)
    if type(Registry.ResolveSpellReference) ~= "function" then
        return nil
    end

    local _, spell = Registry:ResolveSpellReference(spellRef)
    return type(spell) == "table" and spell or nil
end

local function normalizeEventUnitId(value)
    local eventId = math.floor(tonumber(value) or 0)
    return eventId > 0 and eventId or nil
end

local function normalizeTurnNumber(eventState)
    return math.max(1, math.floor(tonumber(eventState and eventState.turnNumber) or 1))
end

local function getBasicAttackUsageState(client, eventState, casterUnit)
    local eventId = tostring(eventState and eventState.id or "")
    local casterEventId = normalizeEventUnitId(casterUnit and casterUnit.eventID)
    if eventId == "" or not casterEventId then
        return nil
    end

    local eventBucket = type(client and client.CooldownsByEventId) == "table" and client.CooldownsByEventId[eventId] or nil
    local unitState = type(eventBucket) == "table" and eventBucket[casterEventId] or nil
    if type(unitState) ~= "table" then
        return nil
    end

    if math.max(0, math.floor(tonumber(unitState.basicAttackTurnNumber) or 0)) ~= normalizeTurnNumber(eventState) then
        return nil
    end

    local damageType = normalizeDamageType(unitState.basicAttackDamageType)
    if not damageType then
        return nil
    end

    return {
        turnNumber = normalizeTurnNumber(eventState),
        damageType = damageType,
    }
end

local function recordBasicAttackUsage(client, eventState, casterUnit, damageType)
    local eventId = tostring(eventState and eventState.id or "")
    local casterEventId = normalizeEventUnitId(casterUnit and casterUnit.eventID)
    local normalizedDamageType = normalizeDamageType(damageType)
    if eventId == "" or not casterEventId or not normalizedDamageType then
        return false
    end

    local eventBucket = type(client and client.CooldownsByEventId) == "table" and client.CooldownsByEventId[eventId] or nil
    local unitState = type(eventBucket) == "table" and eventBucket[casterEventId] or nil
    if type(unitState) ~= "table" then
        return false
    end

    unitState.basicAttackTurnNumber = normalizeTurnNumber(eventState)
    unitState.basicAttackDamageType = normalizedDamageType
    return true
end

local function cloneSpellForBasicAttackCooldown(spell)
    local clone = {}
    for key, value in pairs(spell or {}) do
        clone[key] = value
    end

    clone.triggersGCD = false
    clone.cooldown = math.max(1, math.floor(tonumber(spell and spell.cooldown) or 0))
    return clone
end

local function callWithoutBasicAttackGcd(spellRef, fn)
    if not isBasicAttackRuleEnabled() then
        return fn()
    end

    local spell = resolveSpell(spellRef)
    if not spell or not resolveBasicAttackDamageType(spell) then
        return fn()
    end

    local originalTriggersGCD = spell.triggersGCD
    spell.triggersGCD = false
    local results = { pcall(fn) }
    spell.triggersGCD = originalTriggersGCD

    if results[1] ~= true then
        error(results[2], 0)
    end

    return unpack(results, 2)
end

local function findEventUnitById(units, eventId)
    local numericEventId = normalizeEventUnitId(eventId)
    if not numericEventId then
        return nil
    end

    for index = 1, #(units or {}) do
        local unit = units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit
        end
    end

    return nil
end

local function isActiveNpcUnit(unit)
    if type(unit) ~= "table" or unit.isPlayer == true then
        return false
    end

    if type(Event) == "table" and type(Event.IsUnitActive) == "function" then
        return Event.IsUnitActive(unit) == true
    end

    return unit.active ~= false
end

local function normalizeSpellRef(value)
    if type(value) == "string" then
        return value ~= "" and value or nil
    end
    if type(value) ~= "table" then
        return nil
    end

    local spellRef = value.spellRef or value.spellID or value.id or value.name
    if type(spellRef) ~= "string" or spellRef == "" then
        return nil
    end
    return spellRef
end

local function listResolvedSpellRefs(casterUnit)
    if type(casterUnit) ~= "table" then
        return {}
    end

    local values = casterUnit.spells or {}
    if type(casterUnit.GetResolvedValue) == "function" then
        local ok, resolved = pcall(casterUnit.GetResolvedValue, casterUnit, "spells", values)
        if ok and resolved ~= nil then
            values = resolved
        end
    end

    if type(values) == "string" then
        return values ~= "" and { values } or {}
    end
    if type(values) ~= "table" then
        return {}
    end

    local refs = {}
    local seen = {}
    for index = 1, #values do
        local spellRef = normalizeSpellRef(values[index])
        if spellRef and seen[spellRef] ~= true then
            seen[spellRef] = true
            refs[#refs + 1] = spellRef
        end
    end
    return refs
end

local function hasResolvedSpellRef(casterUnit, spellRef)
    local normalizedSpellRef = normalizeSpellRef(spellRef)
    if not normalizedSpellRef then
        return false
    end

    local refs = listResolvedSpellRefs(casterUnit)
    for index = 1, #refs do
        if refs[index] == normalizedSpellRef then
            return true
        end
    end
    return false
end

function Spellcasting.ListEventUnitResolvedSpellRefs(self, eventState, casterEventId)
    if type(eventState) ~= "table" or eventState.active ~= true then
        return {}
    end

    local casterUnit = findEventUnitById(eventState.units, casterEventId)
    if not isActiveNpcUnit(casterUnit) then
        return {}
    end

    return listResolvedSpellRefs(casterUnit)
end

function Client:ListEventUnitResolvedSpellRefs(casterEventId, eventStateOverride)
    local eventState = eventStateOverride or (self.GetEventState and self:GetEventState() or nil)
    return Spellcasting.ListEventUnitResolvedSpellRefs(self, eventState, casterEventId)
end

local function buildExplicitCasterProxy(client, eventState, casterUnit)
    local proxy = {
        ResolveActiveSpellcasterUnit = function(_, requestedEventState)
            if requestedEventState ~= eventState then
                return nil
            end
            return casterUnit
        end,
        GetActionBarControlContext = function(_, requestedEventState)
            if requestedEventState ~= eventState then
                return nil
            end
            return {
                isControlled = true,
                controlledUnit = casterUnit,
                controlledEventId = tonumber(casterUnit.eventID),
            }
        end,
    }

    return setmetatable(proxy, {
        __index = client,
    })
end

local function resolveExplicitCasterContext(client, options)
    local casterEventId = normalizeEventUnitId(type(options) == "table" and options.casterEventId or nil)
    if not casterEventId then
        return nil, nil
    end

    local eventState = client.GetEventState and client:GetEventState() or nil
    if type(eventState) ~= "table" or eventState.active ~= true then
        return nil, nil
    end

    local casterUnit = findEventUnitById(eventState.units, casterEventId)
    if not isActiveNpcUnit(casterUnit) then
        return eventState, nil
    end

    return eventState, casterUnit
end

local function buildActivationSnapshot(self, spellRef, options)
    local resolvedOptions = type(options) == "table" and options or nil
    local hasExplicitCaster = resolvedOptions ~= nil and resolvedOptions.casterEventId ~= nil
    if not hasExplicitCaster then
        return baseBuildSpellActivationSnapshot(self, spellRef, options)
    end

    if normalizeEventUnitId(resolvedOptions.casterEventId) == nil then
        return nil
    end

    local eventState, casterUnit = resolveExplicitCasterContext(self, resolvedOptions)
    if type(eventState) ~= "table" or type(casterUnit) ~= "table" then
        return nil
    end
    if not hasResolvedSpellRef(casterUnit, spellRef) then
        return nil
    end

    local proxy = buildExplicitCasterProxy(self, eventState, casterUnit)
    return baseBuildSpellActivationSnapshot(proxy, spellRef, resolvedOptions)
end

local function applyBasicAttackTypeRestriction(self, snapshot)
    if not isBasicAttackRuleEnabled() or type(snapshot) ~= "table" or snapshot.canCast ~= true then
        return snapshot
    end

    local damageType = resolveBasicAttackDamageType(snapshot.spell)
    if not damageType then
        return snapshot
    end

    local usage = getBasicAttackUsageState(self, snapshot.eventState, snapshot.casterUnit)
    if usage and usage.damageType ~= damageType then
        snapshot.canCast = false
        snapshot.reason = "basic-attack-type"
    end

    return snapshot
end

function Spellcasting.BuildSpellActivationSnapshot(self, spellRef, options)
    local snapshot = callWithoutBasicAttackGcd(spellRef, function()
        return buildActivationSnapshot(self, spellRef, options)
    end)

    snapshot = applyBasicAttackTypeRestriction(self, snapshot)
    if self ~= Client and type(snapshot) == "table" and snapshot.canCast ~= true then
        return nil
    end
    return snapshot
end

if type(baseApplyLocalSpellCooldown) == "function" then
    function Spellcasting.ApplyLocalSpellCooldown(self, eventState, casterUnit, spellRef, spell)
        if not isBasicAttackRuleEnabled() then
            return baseApplyLocalSpellCooldown(self, eventState, casterUnit, spellRef, spell)
        end

        local damageType = resolveBasicAttackDamageType(spell)
        if not damageType then
            return baseApplyLocalSpellCooldown(self, eventState, casterUnit, spellRef, spell)
        end

        local changed = baseApplyLocalSpellCooldown(
            self,
            eventState,
            casterUnit,
            spellRef,
            cloneSpellForBasicAttackCooldown(spell)
        )
        recordBasicAttackUsage(self, eventState, casterUnit, damageType)
        return changed
    end
end

if type(baseResolveSpellActivationState) == "function" then
    function Spellcasting.ResolveSpellActivationState(self, spellRef, options)
        local state = baseResolveSpellActivationState(self, spellRef, options)
        local includeText = type(options) ~= "table" or options.includeText ~= false
        if type(state) == "table" and state.reason == "basic-attack-type" and includeText then
            state.failureText = BASIC_ATTACK_TYPE_FAILURE_TEXT
        end
        return state
    end
end

return Spellcasting