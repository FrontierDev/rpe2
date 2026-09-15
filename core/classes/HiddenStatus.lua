local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Classes = Addon.Internal.Database.Classes
local Condition = Classes.Condition
local Spell = Classes.Spell
local Aura = Classes.Aura

local function normalizeConditionUnit(value)
    return string.lower(tostring(value or "")) == "target" and "target" or "caster"
end

if type(Condition) == "table" and Condition._hiddenStatusSchemaExtended ~= true then
    local originalCreateDefaults = Condition.CreateDefaults
    local originalGetKnownTypes = Condition.GetKnownTypes
    local originalIsKnownType = Condition.IsKnownType
    local originalNormalize = Condition.Normalize

    function Condition.CreateDefaults(conditionType)
        if string.lower(tostring(conditionType or "")) == "hidden" then
            return {
                type = "hidden",
                showOnTooltip = false,
                tooltipTextOverride = "",
                invert = false,
                unit = "caster",
            }
        end
        return originalCreateDefaults(conditionType)
    end

    function Condition.GetKnownTypes()
        local types = originalGetKnownTypes() or {}
        local found = false
        for index = 1, #types do
            if types[index] == "hidden" then
                found = true
                break
            end
        end
        if not found then
            types[#types + 1] = "hidden"
            table.sort(types)
        end
        return types
    end

    function Condition.IsKnownType(conditionType)
        if string.lower(tostring(conditionType or "")) == "hidden" then
            return true
        end
        return originalIsKnownType(conditionType)
    end

    function Condition.Normalize(value)
        if type(value) == "table" and string.lower(tostring(value.type or "")) == "hidden" then
            return {
                type = "hidden",
                showOnTooltip = value.showOnTooltip == true,
                tooltipTextOverride = tostring(value.tooltipTextOverride or ""),
                invert = value.invert == true,
                unit = normalizeConditionUnit(value.unit),
            }
        end
        return originalNormalize(value)
    end

    Condition._hiddenStatusSchemaExtended = true
end

local VALID_COMBAT_EVENTS = {
    on_auto_attack_hit = true,
    on_auto_attack_taken = true,
    on_melee_hit = true,
    on_melee_taken = true,
    on_ranged_hit = true,
    on_ranged_taken = true,
    on_spell_hit = true,
    on_spell_taken = true,
    on_heal = true,
    on_heal_taken = true,
    on_critical_hit = true,
    on_critical_hit_taken = true,
    on_critical_heal = true,
    on_critical_heal_taken = true,
}

local function normalizeEventList(values)
    local normalized = {}
    for index = 1, #(values or {}) do
        local eventId = tostring(values[index] or "")
        if VALID_COMBAT_EVENTS[eventId] then
            normalized[#normalized + 1] = eventId
        end
    end
    return normalized
end

local function collectHiddenSpellEffects(components)
    local hidden = {}
    for index = 1, #(components or {}) do
        local component = components[index]
        local effect = type(component) == "table" and component.effect or nil
        if type(effect) == "table" and string.lower(tostring(effect.type or "")) == "hide" then
            hidden[index] = {
                type = "hide",
                targetEvents = normalizeEventList(effect.targetEvents),
            }
        end
    end
    return hidden
end

local function restoreHiddenSpellEffects(components, hidden)
    for index, effect in pairs(hidden or {}) do
        if type(components) == "table" and type(components[index]) == "table" then
            components[index].effect = effect
        end
    end
end

if type(Spell) == "table" and type(Spell.Merge) == "function" and type(Spell.ToTable) == "function" and Spell._hiddenStatusSchemaExtended ~= true then
    local originalMerge = Spell.Merge
    local originalToTable = Spell.ToTable

    function Spell:Merge(data)
        local sourceComponents = type(data) == "table" and (data.components or data.effects) or nil
        local hidden = collectHiddenSpellEffects(sourceComponents)
        local result = originalMerge(self, data)
        restoreHiddenSpellEffects(self.components, hidden)
        return result
    end

    function Spell:ToTable()
        local hidden = collectHiddenSpellEffects(self.components)
        local data = originalToTable(self)
        restoreHiddenSpellEffects(data and data.components, hidden)
        return data
    end

    Spell._hiddenStatusSchemaExtended = true
end

local function collectRemoveHiddenEventEffects(events)
    local preserved = {}
    for eventIndex = 1, #(events or {}) do
        local auraEvent = events[eventIndex]
        for effectIndex = 1, #(type(auraEvent) == "table" and auraEvent.effects or {}) do
            local effect = auraEvent.effects[effectIndex]
            if type(effect) == "table" and string.lower(tostring(effect.type or "")) == "remove_hidden" then
                preserved[eventIndex] = preserved[eventIndex] or {}
                preserved[eventIndex][effectIndex] = {
                    type = "remove_hidden",
                }
            end
        end
    end
    return preserved
end

local function restoreRemoveHiddenEventEffects(events, preserved)
    for eventIndex, effects in pairs(preserved or {}) do
        local auraEvent = type(events) == "table" and events[eventIndex] or nil
        if type(auraEvent) == "table" and type(auraEvent.effects) == "table" then
            local highestEffectIndex = 0
            for effectIndex in pairs(effects) do
                highestEffectIndex = math.max(highestEffectIndex, tonumber(effectIndex) or 0)
            end

            for effectIndex = 1, highestEffectIndex do
                local effect = effects[effectIndex]
                if effect then
                    table.insert(auraEvent.effects, math.min(effectIndex, #auraEvent.effects + 1), effect)
                end
            end
        end
    end
end

if type(Aura) == "table" and type(Aura.Merge) == "function" and type(Aura.ToTable) == "function" and Aura._hiddenStatusSchemaExtended ~= true then
    local originalMerge = Aura.Merge
    local originalToTable = Aura.ToTable

    function Aura:Merge(data)
        local preserved = collectRemoveHiddenEventEffects(type(data) == "table" and data.events or nil)
        local result = originalMerge(self, data)
        restoreRemoveHiddenEventEffects(self.events, preserved)
        return result
    end

    function Aura:ToTable()
        local preserved = collectRemoveHiddenEventEffects(self.events)
        local data = originalToTable(self)
        restoreRemoveHiddenEventEffects(data and data.events, preserved)
        return data
    end

    Aura._hiddenStatusSchemaExtended = true
end
