local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local EventUnit = {}
EventUnit.__index = EventUnit
local RESOURCE_RECORD_SEPARATOR = string.char(27)
local RESOURCE_FIELD_SEPARATOR = string.char(26)
local SPELL_RECORD_SEPARATOR = string.char(21)
local STAT_RECORD_SEPARATOR = string.char(20)
local STAT_FIELD_SEPARATOR = string.char(19)
local THREAT_RECORD_SEPARATOR = string.char(18)
local THREAT_FIELD_SEPARATOR = string.char(17)

local function coerceBoolean(value, defaultValue)
    if value == nil then
        return defaultValue == true
    end

    if value == true or value == false then
        return value
    end

    local numericValue = tonumber(value)
    if numericValue ~= nil then
        return numericValue ~= 0
    end

    if type(value) == "string" then
        local normalized = string.lower(value)
        if normalized == "true" or normalized == "yes" or normalized == "on" then
            return true
        end
        if normalized == "false" or normalized == "no" or normalized == "off" then
            return false
        end
    end

    return defaultValue == true
end

local function normalizeTeam(value)
    local team = tonumber(value) or 1
    if team <= 0 then
        return 1
    end

    return math.floor(team)
end

local function normalizeInitiative(value)
    local initiative = tonumber(value)
    if initiative == nil then
        return nil
    end

    initiative = math.floor(initiative)
    if initiative < 0 then
        initiative = 0
    end

    return initiative
end

local function normalizeString(value, fallback)
    local text = value == nil and "" or tostring(value)
    if text == "" then
        return fallback or ""
    end

    return text
end

local function normalizeRef(value)
    local text = value == nil and "" or tostring(value)
    if text == "" then
        return nil
    end

    return text
end

local function resolveUnitDefinition(registryId)
    local normalizedRegistryId = type(registryId) == "string" and registryId or ""
    if normalizedRegistryId == "" then
        return nil, nil
    end

    local separatorIndex = string.find(normalizedRegistryId, ":", 1, true)
    if not separatorIndex then
        return nil, nil
    end

    local datasetId = string.sub(normalizedRegistryId, 1, separatorIndex - 1)
    local unitId = string.sub(normalizedRegistryId, separatorIndex + 1)
    if datasetId == "" or unitId == "" then
        return nil, nil
    end

    local registry = Addon.Internal and Addon.Internal.Registry or nil
    local datasets = registry and registry.GetActivatedDatasets and registry:GetActivatedDatasets() or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        if dataset and dataset.id == datasetId then
            for unitIndex = 1, #(dataset.units or {}) do
                local unit = dataset.units[unitIndex]
                if unit and unit.id == unitId then
                    return dataset, unit
                end
            end
        end
    end

    return nil, nil
end

local function resolvePetDefinition(petRef)
    local normalizedPetRef = type(petRef) == "string" and petRef or ""
    if normalizedPetRef == "" then
        return nil, nil
    end

    local separatorIndex = string.find(normalizedPetRef, ":", 1, true)
    if not separatorIndex then
        return nil, nil
    end

    local datasetId = string.sub(normalizedPetRef, 1, separatorIndex - 1)
    local petId = string.sub(normalizedPetRef, separatorIndex + 1)
    if datasetId == "" or petId == "" then
        return nil, nil
    end

    local registry = Addon.Internal and Addon.Internal.Registry or nil
    local datasets = registry and registry.GetActivatedDatasets and registry:GetActivatedDatasets() or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        if dataset and dataset.id == datasetId then
            for petIndex = 1, #(dataset.pets or {}) do
                local pet = dataset.pets[petIndex]
                if pet and pet.id == petId then
                    return dataset, pet
                end
            end
        end
    end

    return nil, nil
end

local function normalizeResourceEntry(entry)
    if type(entry) ~= "table" then
        return nil
    end

    local resourceRef = normalizeString(entry.resourceRef or entry.resourceID or entry.id, "")
    if resourceRef == "" then
        return nil
    end

    return {
        resourceRef = resourceRef,
        currentValue = tonumber(entry.currentValue ~= nil and entry.currentValue or entry.current or entry.value) or 0,
        maxValue = tonumber(entry.maxValue ~= nil and entry.maxValue or entry.max or entry.maximum) or 0,
    }
end

local function normalizeResources(entries)
    local normalized = {}

    for index = 1, #(entries or {}) do
        local entry = normalizeResourceEntry(entries[index])
        if entry then
            normalized[#normalized + 1] = entry
        end
    end

    return normalized
end

local function normalizeSpellRefs(entries)
    local normalized = {}

    for index = 1, #(entries or {}) do
        local spellRef = normalizeRef(entries[index])
        if spellRef then
            normalized[#normalized + 1] = spellRef
        end
    end

    return normalized
end

local function normalizeStatEntry(entry)
    if type(entry) ~= "table" then
        return nil
    end

    local statRef = normalizeRef(entry.statRef or entry.sourceStatRef)
    if not statRef then
        return nil
    end

    local value = tonumber(entry.value)
    local currentValue = tonumber(entry.currentValue ~= nil and entry.currentValue or entry.current)
    if value == nil and currentValue == nil then
        value = 0
        currentValue = 0
    elseif value == nil then
        value = currentValue
    elseif currentValue == nil then
        currentValue = value
    end

    return {
        statRef = statRef,
        value = value,
        currentValue = currentValue,
    }
end

local function normalizeStats(entries)
    local normalized = {}

    for index = 1, #(entries or {}) do
        local entry = normalizeStatEntry(entries[index])
        if entry then
            normalized[#normalized + 1] = entry
        end
    end

    return normalized
end

local function cloneResources(resources)
    return normalizeResources(resources)
end

local function cloneSpellRefs(spellRefs)
    return normalizeSpellRefs(spellRefs)
end

local function cloneStats(stats)
    return normalizeStats(stats)
end

local function normalizeThreatTable(value)
    local normalized = {}
    if type(value) ~= "table" then
        return normalized
    end

    for key, threatValue in pairs(value) do
        local eventId = math.floor(tonumber(key) or 0)
        if eventId > 0 then
            normalized[eventId] = tonumber(threatValue) or 0
        end
    end

    return normalized
end

local function cloneThreatTable(threatTable)
    return normalizeThreatTable(threatTable)
end

local resolveSpellValue

local function buildResolvedResources(eventUnit, playerCount)
    local localResources = type(eventUnit) == "table" and eventUnit.resources or nil
    if type(localResources) == "table" and #localResources > 0 then
        return cloneResources(localResources)
    end

    local resolvedUnit = type(eventUnit) == "table" and eventUnit.GetResolvedUnit and eventUnit:GetResolvedUnit() or nil
    local resolvedResources = {}
    for index = 1, #((resolvedUnit and resolvedUnit.resources) or {}) do
        local entry = resolvedUnit.resources[index]
        local resourceRef = normalizeString(entry and (entry.resourceRef or entry.resourceID or entry.id), "")
        if resourceRef ~= "" then
            local currentValue = entry and entry.currentValue or nil
            local maxValue = entry and entry.maxValue or nil
            if currentValue ~= nil or maxValue ~= nil then
                resolvedResources[#resolvedResources + 1] = {
                    resourceRef = resourceRef,
                    currentValue = tonumber(currentValue ~= nil and currentValue or maxValue) or 0,
                    maxValue = tonumber(maxValue ~= nil and maxValue or currentValue) or 0,
                }
            else
                local baseValue = tonumber(entry and entry.value) or 0
                resolvedResources[#resolvedResources + 1] = {
                    resourceRef = resourceRef,
                    currentValue = baseValue,
                    maxValue = baseValue,
                }
            end
        end
    end

    return resolvedResources
end

local function buildResolvedSpellRefs(eventUnit, fallback)
    local resolvedUnit = type(eventUnit) == "table" and eventUnit.GetResolvedUnit and eventUnit:GetResolvedUnit() or nil
    return cloneSpellRefs(resolveSpellValue(eventUnit, resolvedUnit, fallback) or {})
end

local function buildResolvedStats(eventUnit, fallback)
    local resolvedUnit = type(eventUnit) == "table" and eventUnit.GetResolvedUnit and eventUnit:GetResolvedUnit() or nil
    local baseStats = cloneStats((resolvedUnit and resolvedUnit.stats) or fallback or {})
    local localStats = type(eventUnit) == "table" and eventUnit.stats or nil
    if type(localStats) ~= "table" or #localStats == 0 then
        return baseStats
    end

    local statMode = tostring(type(eventUnit) == "table" and eventUnit._networkStatMode or "")
    local merged = {}
    local indexByRef = {}
    for index = 1, #baseStats do
        local entry = baseStats[index]
        local statRef = normalizeRef(entry and entry.statRef)
        if statRef then
            local copy = {
                statRef = statRef,
                value = tonumber(entry.value) or 0,
                currentValue = tonumber(entry.currentValue ~= nil and entry.currentValue or entry.value) or 0,
            }
            merged[#merged + 1] = copy
            indexByRef[statRef] = #merged
        end
    end

    local overrideStats = cloneStats(localStats)
    for index = 1, #overrideStats do
        local entry = overrideStats[index]
        local statRef = normalizeRef(entry and entry.statRef)
        if statRef then
            local existingIndex = indexByRef[statRef]
            if statMode == "bonus" then
                local bonusValue = tonumber(entry.value) or 0
                local bonusCurrent = tonumber(entry.currentValue ~= nil and entry.currentValue or entry.value) or 0
                if existingIndex then
                    local existing = merged[existingIndex]
                    existing.value = (tonumber(existing.value) or 0) + bonusValue
                    existing.currentValue = (tonumber(existing.currentValue) or 0) + bonusCurrent
                else
                    merged[#merged + 1] = {
                        statRef = statRef,
                        value = bonusValue,
                        currentValue = bonusCurrent,
                    }
                    indexByRef[statRef] = #merged
                end
            else
                local copy = {
                    statRef = statRef,
                    value = tonumber(entry.value) or 0,
                    currentValue = tonumber(entry.currentValue ~= nil and entry.currentValue or entry.value) or 0,
                }
                if existingIndex then
                    merged[existingIndex] = copy
                else
                    merged[#merged + 1] = copy
                    indexByRef[statRef] = #merged
                end
            end
        end
    end

    return merged
end

local function serializeResources(resources)
    local records = {}
    local normalized = normalizeResources(resources)

    for index = 1, #normalized do
        local resource = normalized[index]
        records[#records + 1] = table.concat({
            tostring(resource.resourceRef or ""),
            tostring(resource.currentValue or 0),
            tostring(resource.maxValue or 0),
        }, RESOURCE_FIELD_SEPARATOR)
    end

    return table.concat(records, RESOURCE_RECORD_SEPARATOR)
end

local function serializeSpellRefs(spellRefs)
    return table.concat(normalizeSpellRefs(spellRefs), SPELL_RECORD_SEPARATOR)
end

local function serializeStats(stats)
    local records = {}
    local normalized = normalizeStats(stats)

    for index = 1, #normalized do
        local stat = normalized[index]
        records[#records + 1] = table.concat({
            tostring(stat.statRef or ""),
            tostring(stat.value or 0),
            tostring(stat.currentValue or 0),
        }, STAT_FIELD_SEPARATOR)
    end

    return table.concat(records, STAT_RECORD_SEPARATOR)
end

local function serializeThreatTable(threatTable)
    local records = {}
    local normalized = normalizeThreatTable(threatTable)
    for eventId, value in pairs(normalized) do
        records[#records + 1] = table.concat({
            tostring(eventId),
            tostring(value or 0),
        }, THREAT_FIELD_SEPARATOR)
    end

    table.sort(records)
    return table.concat(records, THREAT_RECORD_SEPARATOR)
end

local function splitPreservingEmpty(text, separator)
    if Addon.Utils and Addon.Utils.Common and Addon.Utils.Common.SplitPreservingEmpty then
        return Addon.Utils.Common.SplitPreservingEmpty(text, separator)
    end

    local values = {}
    local pattern = "([^" .. separator .. "]*)"
    local startIndex = 1

    while true do
        local separatorIndex = string.find(text, separator, startIndex, true)
        if not separatorIndex then
            values[#values + 1] = string.sub(text, startIndex)
            break
        end

        values[#values + 1] = string.sub(text, startIndex, separatorIndex - 1)
        startIndex = separatorIndex + #separator
    end

    return values
end

local function deserializeResources(text)
    local normalized = {}
    if type(text) ~= "string" or text == "" then
        return normalized
    end

    local records = splitPreservingEmpty(text, RESOURCE_RECORD_SEPARATOR)
    for index = 1, #records do
        local values = splitPreservingEmpty(records[index], RESOURCE_FIELD_SEPARATOR)
        local entry = normalizeResourceEntry({
            resourceRef = values[1],
            currentValue = values[2],
            maxValue = values[3],
        })
        if entry then
            normalized[#normalized + 1] = entry
        end
    end

    return normalized
end

local function deserializeSpellRefs(text)
    if type(text) ~= "string" or text == "" then
        return {}
    end

    return normalizeSpellRefs(splitPreservingEmpty(text, SPELL_RECORD_SEPARATOR))
end

local function deserializeStats(text)
    local normalized = {}
    if type(text) ~= "string" or text == "" then
        return normalized
    end

    local records = splitPreservingEmpty(text, STAT_RECORD_SEPARATOR)
    for index = 1, #records do
        local values = splitPreservingEmpty(records[index], STAT_FIELD_SEPARATOR)
        local entry = normalizeStatEntry({
            statRef = values[1],
            value = values[2],
            currentValue = values[3],
        })
        if entry then
            normalized[#normalized + 1] = entry
        end
    end

    return normalized
end

local function deserializeThreatTable(text)
    local normalized = {}
    if type(text) ~= "string" or text == "" then
        return normalized
    end

    local records = splitPreservingEmpty(text, THREAT_RECORD_SEPARATOR)
    for index = 1, #records do
        local values = splitPreservingEmpty(records[index], THREAT_FIELD_SEPARATOR)
        local eventId = math.floor(tonumber(values[1]) or 0)
        if eventId > 0 then
            normalized[eventId] = tonumber(values[2]) or 0
        end
    end

    return normalized
end

local function normalizeHidden(value)
    return coerceBoolean(value, false)
end

local function normalizeBoss(value)
    return coerceBoolean(value, false)
end

local function normalizeActive(isPlayer, value)
    if isPlayer == true then
        return true
    end

    return coerceBoolean(value, true)
end

function EventUnit:New(data)
    return setmetatable({
        name = "",
        description = "",
        isPlayer = false,
        eventID = nil,
        registryID = nil,
        raidMarker = 0,
        team = 1,
        ownerID = nil,
        controllerID = nil,
        initiative = nil,
        resources = {},
        spells = {},
        stats = {},
        threatTable = {},
        active = true,
        hidden = false,
        boss = false,
        petRef = nil,
        summonedByEventID = nil,
        mainHandWeapon = nil,
        offHandWeapon = nil,
        rangedWeapon = nil,
        shield = nil,
    }, EventUnit):Merge(data)
end

function EventUnit:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        if key == "team" then
            self.team = normalizeTeam(value)
        elseif key == "initiative" then
            self.initiative = normalizeInitiative(value)
        elseif key == "resources" then
            self.resources = normalizeResources(value)
        elseif key == "spells" then
            self.spells = normalizeSpellRefs(value)
        elseif key == "stats" then
            self.stats = normalizeStats(value)
        elseif key == "threatTable" then
            self.threatTable = normalizeThreatTable(value)
        else
            self[key] = value
        end
    end

    self.team = normalizeTeam(self.team)
    self.initiative = normalizeInitiative(self.initiative)
    self.name = normalizeString(self.name, "")
    self.description = normalizeString(self.description, "")
    self.resources = normalizeResources(self.resources)
    self.spells = normalizeSpellRefs(self.spells)
    self.stats = normalizeStats(self.stats)
    self.threatTable = normalizeThreatTable(self.threatTable)
    self.active = normalizeActive(self.isPlayer, self.active)
    self.hidden = normalizeHidden(self.hidden)
    self.boss = normalizeBoss(self.boss)
    self.petRef = normalizeRef(self.petRef)
    self.summonedByEventID = tonumber(self.summonedByEventID) or nil
    self.mainHandWeapon = normalizeRef(self.mainHandWeapon)
    self.offHandWeapon = normalizeRef(self.offHandWeapon)
    self.rangedWeapon = normalizeRef(self.rangedWeapon)
    self.shield = normalizeRef(self.shield)

    return self
end

function EventUnit:ResolveUnitDefinition()
    return resolveUnitDefinition(self.registryID)
end

function EventUnit:GetResolvedUnit()
    local _, unit = self:ResolveUnitDefinition()
    return unit
end

function EventUnit:ResolvePetDefinition()
    return resolvePetDefinition(self.petRef)
end

function EventUnit:GetResolvedPet()
    local _, pet = self:ResolvePetDefinition()
    return pet
end

resolveSpellValue = function(eventUnit, resolvedUnit, fallback)
    local localSpells = type(eventUnit) == "table" and eventUnit.spells or nil
    if type(localSpells) == "string" and localSpells ~= "" then
        return localSpells
    end
    if type(localSpells) == "table" and next(localSpells) ~= nil then
        return localSpells
    end

    local resolvedPet = type(eventUnit) == "table" and eventUnit.GetResolvedPet and eventUnit:GetResolvedPet() or nil
    local petSpells = resolvedPet and resolvedPet.spells or nil
    if type(petSpells) == "string" and petSpells ~= "" then
        return petSpells
    end
    if type(petSpells) == "table" and next(petSpells) ~= nil then
        return petSpells
    end

    local unitSpells = resolvedUnit and resolvedUnit.spells or nil
    if type(unitSpells) == "string" and unitSpells ~= "" then
        return unitSpells
    end
    if type(unitSpells) == "table" and next(unitSpells) ~= nil then
        return unitSpells
    end

    return fallback
end

function EventUnit:GetResolvedValue(key, fallback)
    if key == "spells" then
        return buildResolvedSpellRefs(self, fallback)
    end
    if key == "stats" then
        return buildResolvedStats(self, fallback)
    end
    if key == "resources" then
        return buildResolvedResources(self)
    end

    local resolvedUnit = self:GetResolvedUnit()
    local value = self[key]
    if value == nil then
        value = resolvedUnit and resolvedUnit[key] or nil
    end
    if value == nil then
        value = fallback
    end
    return value
end

function EventUnit:ToTable()
    return {
        name = self.name,
        description = self.description,
        isPlayer = self.isPlayer,
        eventID = self.eventID,
        registryID = self.registryID,
        raidMarker = self.raidMarker,
        team = self.team,
        ownerID = self.ownerID,
        controllerID = self.controllerID,
        initiative = normalizeInitiative(self.initiative),
        resources = normalizeResources(self.resources),
        spells = normalizeSpellRefs(self.spells),
        stats = normalizeStats(self.stats),
        threatTable = normalizeThreatTable(self.threatTable),
        active = normalizeActive(self.isPlayer, self.active),
        hidden = normalizeHidden(self.hidden),
        boss = normalizeBoss(self.boss),
        petRef = self.petRef,
        summonedByEventID = tonumber(self.summonedByEventID) or nil,
        mainHandWeapon = self.mainHandWeapon,
        offHandWeapon = self.offHandWeapon,
        rangedWeapon = self.rangedWeapon,
        shield = self.shield,
    }
end

function EventUnit.IsActive(unit)
    if type(unit) ~= "table" then
        return false
    end

    return normalizeActive(unit.isPlayer, unit.active)
end

function EventUnit.IsHidden(unit)
    return type(unit) == "table" and normalizeHidden(unit.hidden)
end

function EventUnit.IsBoss(unit)
    return type(unit) == "table" and normalizeBoss(unit.boss)
end

EventUnit.CoerceBoolean = coerceBoolean

function EventUnit.BuildResolvedResources(eventUnit, playerCount)
    return buildResolvedResources(eventUnit, playerCount)
end

function EventUnit.BuildResolvedSpellRefs(eventUnit, fallback)
    return buildResolvedSpellRefs(eventUnit, fallback)
end

function EventUnit.BuildResolvedStats(eventUnit, fallback)
    return buildResolvedStats(eventUnit, fallback)
end

function EventUnit.HydrateNetworkUnit(unit, options)
    if type(unit) ~= "table" then
        return unit
    end

    local resourceMode = tostring(unit._networkResourceMode or "")
    local spellMode = tostring(unit._networkSpellMode or "")
    local statMode = tostring(unit._networkStatMode or "")
    if resourceMode == "" and spellMode == "" and statMode == "" then
        return unit
    end

    local hydrated = EventUnit.FromTable and EventUnit.FromTable(unit) or unit
    local playerCount = math.max(0, tonumber(type(options) == "table" and options.playerCount or 0) or 0)

    if resourceMode == "inherit" then
        hydrated.resources = buildResolvedResources(hydrated, playerCount)
    end
    if spellMode == "inherit" then
        hydrated.spells = buildResolvedSpellRefs(hydrated)
    end
    if statMode == "inherit" or statMode == "merge" or statMode == "bonus" then
        hydrated.stats = buildResolvedStats(hydrated)
    end

    hydrated._networkResourceMode = nil
    hydrated._networkSpellMode = nil
    hydrated._networkStatMode = nil
    return hydrated
end

function EventUnit.SerializeResourcesForNetwork(resources)
    return serializeResources(resources)
end

function EventUnit.DeserializeResourcesFromNetwork(text)
    return deserializeResources(text)
end

function EventUnit.SerializeSpellRefsForNetwork(spellRefs)
    return serializeSpellRefs(spellRefs)
end

function EventUnit.DeserializeSpellRefsFromNetwork(text)
    return deserializeSpellRefs(text)
end

function EventUnit.SerializeStatsForNetwork(stats)
    return serializeStats(stats)
end

function EventUnit.DeserializeStatsFromNetwork(text)
    return deserializeStats(text)
end

function EventUnit.SerializeThreatTableForNetwork(threatTable)
    return serializeThreatTable(threatTable)
end

function EventUnit.DeserializeThreatTableFromNetwork(text)
    return deserializeThreatTable(text)
end

function EventUnit.FromTable(data)
    return EventUnit:New(data)
end

Addon.Internal.Database.Classes.EventUnit = EventUnit
