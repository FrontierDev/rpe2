local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Server = Addon.Server
local Classes = Addon.Internal.Database.Classes
local Unit = Classes.Unit
local Registry = Addon.Internal.Registry or {}

if type(Server) ~= "table" or type(Unit) ~= "table" or Server._spellEquipmentVariantIntegrationInstalled == true then
    return
end

local EQUIPMENT_FIELDS = {
    "mainHandWeapon",
    "offHandWeapon",
    "rangedWeapon",
    "shield",
}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = deepCopy(nestedValue)
    end
    return copy
end

local function resolveActivatedUnitDefinition(registryId)
    if type(Registry.ResolveUnitDefinition) ~= "function" then
        return nil
    end
    local _, unit = Registry:ResolveUnitDefinition(registryId)
    return unit
end

local function applyEquipment(target, equipment)
    if type(target) ~= "table" then
        return target
    end
    local source = type(equipment) == "table" and equipment or {}
    for index = 1, #EQUIPMENT_FIELDS do
        local key = EQUIPMENT_FIELDS[index]
        target[key] = source[key]
    end
    return target
end

local function resolveVariantEquipment(registryId, presetIndex)
    local baseUnit = resolveActivatedUnitDefinition(registryId)
    if not baseUnit or type(Unit.ResolveEffectiveEquipment) ~= "function" then
        return {}, baseUnit
    end
    return Unit.ResolveEffectiveEquipment(baseUnit, presetIndex), baseUnit
end

local baseBuildResolvedNpcVariant = Server.BuildResolvedNpcVariant
function Server:BuildResolvedNpcVariant(registryId, options)
    local variant = type(baseBuildResolvedNpcVariant) == "function"
        and baseBuildResolvedNpcVariant(self, registryId, options)
        or nil
    if type(variant) ~= "table" or type(variant.baseUnit) ~= "table" then
        return variant
    end

    local presetIndex = variant.presetIndex
    if type(Unit.ResolveEffectiveSpells) == "function" then
        variant.spells = Unit.ResolveEffectiveSpells(variant.baseUnit, presetIndex)
    end
    if type(Unit.ResolveEffectiveEquipment) == "function" then
        local equipment = Unit.ResolveEffectiveEquipment(variant.baseUnit, presetIndex)
        variant.equipment = deepCopy(equipment)
        applyEquipment(variant, equipment)
    end
    return variant
end

local baseBuildEventNpcUnitDataFromDefinition = Server.BuildEventNpcUnitDataFromDefinition
function Server:BuildEventNpcUnitDataFromDefinition(registryId, options)
    local data = type(baseBuildEventNpcUnitDataFromDefinition) == "function"
        and baseBuildEventNpcUnitDataFromDefinition(self, registryId, options)
        or nil
    if type(data) ~= "table" then
        return data
    end

    local equipment = resolveVariantEquipment(data.registryID or registryId, data.presetIndex)
    applyEquipment(data, equipment)

    -- Summon-specific equipment is deliberately applied after Base+Preset and
    -- before EventUnit construction/network broadcast.
    local summonOverride = self.PendingNpcSummonSpellEquipmentOverride
    if type(summonOverride) == "table"
        and tostring(summonOverride.registryID or "") == tostring(data.registryID or registryId or "")
    then
        if type(summonOverride.equipment) == "table" then
            applyEquipment(data, summonOverride.equipment)
        end
        for index = 1, #EQUIPMENT_FIELDS do
            local key = EQUIPMENT_FIELDS[index]
            if summonOverride[key] ~= nil then
                data[key] = summonOverride[key]
            end
        end
    end

    return data
end

local baseSummonEventPetUnit = Server.SummonEventPetUnit
function Server:SummonEventPetUnit(casterUnit, registryId, options)
    if type(baseSummonEventPetUnit) ~= "function" then
        return nil
    end

    local callOptions = type(options) == "table" and deepCopy(options) or {}
    local baseUnit = resolveActivatedUnitDefinition(registryId)
    local presetIndex = baseUnit and Unit.NormalizePresetIndex(baseUnit, callOptions.presetIndex) or 0

    -- The underlying summon path treats nil spells as compact Base inheritance.
    -- Supply the already-resolved variant list when the caller did not provide
    -- an explicit summon override, including an intentional empty Preset list.
    if callOptions.spells == nil and baseUnit and presetIndex > 0 and type(Unit.ResolveEffectiveSpells) == "function" then
        callOptions.spells = Unit.ResolveEffectiveSpells(baseUnit, presetIndex)
    end

    local previousOverride = self.PendingNpcSummonSpellEquipmentOverride
    self.PendingNpcSummonSpellEquipmentOverride = {
        registryID = tostring(registryId or ""),
        equipment = type(callOptions.equipment) == "table" and deepCopy(callOptions.equipment) or nil,
        mainHandWeapon = callOptions.mainHandWeapon,
        offHandWeapon = callOptions.offHandWeapon,
        rangedWeapon = callOptions.rangedWeapon,
        shield = callOptions.shield,
    }

    local unit = baseSummonEventPetUnit(self, casterUnit, registryId, callOptions)
    self.PendingNpcSummonSpellEquipmentOverride = previousOverride
    return unit
end

Server._spellEquipmentVariantIntegrationInstalled = true
