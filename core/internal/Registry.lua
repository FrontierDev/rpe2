local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Registry = Addon.Internal.Registry or {}

local Registry = Addon.Internal.Registry
local Database = Addon.Internal.Database or {}
local HASH_MODULUS = 4294967296
local HASH_MULTIPLIER = 33
local DATASET_HASH_SALTS = {
    "RPE_ACTIVATED_DATASETS_V1:A",
    "RPE_ACTIVATED_DATASETS_V1:B",
    "RPE_ACTIVATED_DATASETS_V1:C",
    "RPE_ACTIVATED_DATASETS_V1:D",
}
local RULESET_HASH_SALTS = {
    "RPE_ACTIVE_RULESET_V1:A",
    "RPE_ACTIVE_RULESET_V1:B",
    "RPE_ACTIVE_RULESET_V1:C",
    "RPE_ACTIVE_RULESET_V1:D",
}

Registry.DatasetHashCache = Registry.DatasetHashCache or nil
Registry.RulesetHashCache = Registry.RulesetHashCache or nil

local function getConfigurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
end

local function ensureDatasetEntryCache(dataset, collectionKey)
    if type(dataset) ~= "table" or type(collectionKey) ~= "string" or collectionKey == "" then
        return nil
    end

    local revision = getConfigurationRevision()
    local entries = dataset[collectionKey]
    local cacheByCollection = type(dataset.__entryCacheByCollection) == "table" and dataset.__entryCacheByCollection or {}
    dataset.__entryCacheByCollection = cacheByCollection

    local cached = cacheByCollection[collectionKey]
    if type(cached) == "table"
        and cached.revision == revision
        and cached.entries == entries
    then
        return cached.byId
    end

    local byId = {}
    for index = 1, #(entries or {}) do
        local entry = entries[index]
        local entryId = tostring(entry and entry.id or "")
        if entryId ~= "" then
            byId[entryId] = entry
        end
    end

    cacheByCollection[collectionKey] = {
        revision = revision,
        entries = entries,
        byId = byId,
    }
    return byId
end

local function sortIds(values)
    table.sort(values, function(left, right)
        return tostring(left or "") < tostring(right or "")
    end)
    return values
end

local function humanizeToken(value)
    local text = tostring(value or "")
    if text == "" then
        return ""
    end

    text = text:gsub("[-_]+", " ")
    text = text:gsub("(%w)([%w']*)", function(first, rest)
        return string.upper(first) .. string.lower(rest)
    end)
    return text
end

local function parseDatasetQualifiedRef(reference)
    local normalizedReference = type(reference) == "string" and reference or ""
    if normalizedReference == "" then
        return nil, nil
    end

    local separatorIndex = string.find(normalizedReference, ":", 1, true)
    if not separatorIndex then
        return nil, nil
    end

    local datasetId = string.sub(normalizedReference, 1, separatorIndex - 1)
    local entryId = string.sub(normalizedReference, separatorIndex + 1)
    if datasetId == "" or entryId == "" then
        return nil, nil
    end

    return datasetId, entryId
end

local function updateHash(hash, text)
    local value = tonumber(hash) or 5381
    local source = tostring(text or "")

    for index = 1, #source do
        value = ((value * HASH_MULTIPLIER) + string.byte(source, index)) % HASH_MODULUS
    end

    return value
end

local function generateHashFromSegments(salts, segments)
    local hashes = { 5381, 5381, 5381, 5381 }

    for index = 1, #hashes do
        hashes[index] = updateHash(hashes[index], salts[index] or "")
    end

    for segmentIndex = 1, #(segments or {}) do
        local segment = tostring(segments[segmentIndex] or "")
        for hashIndex = 1, #hashes do
            hashes[hashIndex] = updateHash(hashes[hashIndex], tostring(#segment))
            hashes[hashIndex] = updateHash(hashes[hashIndex], ":")
            hashes[hashIndex] = updateHash(hashes[hashIndex], segment)
            hashes[hashIndex] = updateHash(hashes[hashIndex], "|")
        end
    end

    return table.concat({
        ("%08x"):format(hashes[1]),
        ("%08x"):format(hashes[2]),
        ("%08x"):format(hashes[3]),
        ("%08x"):format(hashes[4]),
    })
end

function Registry:ListActivatedDatasetIds()
    if Database.ListActivatedDatasetIds then
        return Database.ListActivatedDatasetIds()
    end

    return {}
end

function Registry:IsDatasetActivated(datasetId)
    if Database.IsDatasetActivated then
        return Database.IsDatasetActivated(datasetId)
    end

    return false
end

function Registry:ActivateDataset(datasetId)
    if Database.SetDatasetActivated then
        return Database.SetDatasetActivated(datasetId, true)
    end

    return false
end

function Registry:DeactivateDataset(datasetId)
    if Database.SetDatasetActivated then
        return Database.SetDatasetActivated(datasetId, false)
    end

    return false
end

function Registry:ToggleDataset(datasetId)
    if Database.ToggleDatasetActivated then
        return Database.ToggleDatasetActivated(datasetId)
    end

    return nil
end

function Registry:GetActivatedDatasets()
    local ids = self:ListActivatedDatasetIds()
    local datasets = {}

    for index = 1, #ids do
        local dataset = Database.GetDatasetByID and Database.GetDatasetByID(ids[index]) or nil
        if dataset then
            datasets[#datasets + 1] = dataset
        end
    end

    return datasets
end

function Registry:GenerateActivatedDatasetsHash()
    local revision = getConfigurationRevision()
    local cached = self.DatasetHashCache
    if type(cached) == "table" and cached.revision == revision then
        return cached.value
    end

    local ids = self:ListActivatedDatasetIds() or {}
    local sortedIds = {}
    local segments = {}

    for index = 1, #ids do
        sortedIds[index] = ids[index]
    end
    sortIds(sortedIds)

    for index = 1, #sortedIds do
        local datasetId = tostring(sortedIds[index] or "")
        local exportText = Database.ExportDataset and Database.ExportDataset(datasetId) or nil
        if type(exportText) ~= "string" or exportText == "" then
            local dataset = Database.GetDatasetByID and Database.GetDatasetByID(datasetId) or nil
            exportText = tostring(dataset and dataset.name or "")
        end

        segments[#segments + 1] = datasetId
        segments[#segments + 1] = exportText
    end

    local hash = generateHashFromSegments(DATASET_HASH_SALTS, segments)
    self.DatasetHashCache = {
        revision = revision,
        value = hash,
    }
    return hash
end

function Registry:GenerateActiveRulesetHash()
    local revision = getConfigurationRevision()
    local cached = self.RulesetHashCache
    if type(cached) == "table" and cached.revision == revision then
        return cached.value
    end

    local rulesetId = Database.GetActiveRulesetId and Database.GetActiveRulesetId() or nil
    if rulesetId == nil or rulesetId == "" then
        self.RulesetHashCache = {
            revision = revision,
            value = nil,
        }
        return nil
    end

    local exportText = Database.ExportRuleset and Database.ExportRuleset(rulesetId) or nil
    if type(exportText) ~= "string" or exportText == "" then
        local ruleset = Database.GetRulesetByID and Database.GetRulesetByID(rulesetId) or nil
        exportText = tostring(ruleset and ruleset.name or "")
    end

    local hash = generateHashFromSegments(RULESET_HASH_SALTS, {
        tostring(rulesetId),
        exportText,
    })
    self.RulesetHashCache = {
        revision = revision,
        value = hash,
    }
    return hash
end

function Registry:ResolveSpellReference(spellRef)
    local datasetId, spellId = parseDatasetQualifiedRef(spellRef)
    if not datasetId or not spellId then
        return nil, nil
    end

    local dataset = Database.GetDatasetByID and Database.GetDatasetByID(datasetId) or nil
    if not dataset then
        return nil, nil
    end

    local byId = ensureDatasetEntryCache(dataset, "spells")
    return dataset, byId and byId[spellId] or nil
end

function Registry:ResolveSpellName(spellRef)
    local dataset, spell = self:ResolveSpellReference(spellRef)
    if spell and type(spell.name) == "string" and spell.name ~= "" then
        return spell.name
    end

    local _, spellId = parseDatasetQualifiedRef(spellRef)
    if spellId then
        return spellId
    end

    local normalizedRef = type(spellRef) == "string" and spellRef or ""
    if normalizedRef ~= "" then
        return normalizedRef
    end

    return "unknown-spell"
end

function Registry:ResolveTraitReference(traitRef)
    local datasetId, traitId = parseDatasetQualifiedRef(traitRef)
    if not datasetId or not traitId then
        return nil, nil
    end

    local dataset = Database.GetDatasetByID and Database.GetDatasetByID(datasetId) or nil
    if not dataset then
        return nil, nil
    end

    for index = 1, #(dataset.traits or {}) do
        local trait = dataset.traits[index]
        if trait and tostring(trait.id or "") == traitId then
            return dataset, trait
        end
    end

    return dataset, nil
end

function Registry:ResolveTraitName(traitRef)
    local dataset, trait = self:ResolveTraitReference(traitRef)
    if trait and type(trait.name) == "string" and trait.name ~= "" then
        return trait.name
    end

    local _, traitId = parseDatasetQualifiedRef(traitRef)
    if traitId then
        return traitId
    end

    local normalizedRef = type(traitRef) == "string" and traitRef or ""
    if normalizedRef ~= "" then
        return normalizedRef
    end

    return "unknown-trait"
end

local function resolveDatasetEntryByCollection(datasetId, entryId, collectionKey)
    local dataset = Database.GetDatasetByID and Database.GetDatasetByID(datasetId) or nil
    if not dataset then
        return nil, nil
    end

    local byId = ensureDatasetEntryCache(dataset, collectionKey)
    return dataset, byId and byId[entryId] or nil
end

function Registry:ResolveStatReference(statRef)
    local datasetId, statId = parseDatasetQualifiedRef(statRef)
    if not datasetId or not statId then
        return nil, nil
    end

    return resolveDatasetEntryByCollection(datasetId, statId, "stats")
end

function Registry:ResolveSkillReference(skillRef)
    local datasetId, skillId = parseDatasetQualifiedRef(skillRef)
    if not datasetId or not skillId then
        return nil, nil
    end

    return resolveDatasetEntryByCollection(datasetId, skillId, "skills")
end

function Registry:ResolveSkillName(skillRef)
    local _, skill = self:ResolveSkillReference(skillRef)
    if skill and type(skill.name) == "string" and skill.name ~= "" then
        return skill.name
    end

    local _, skillId = parseDatasetQualifiedRef(skillRef)
    if skillId then
        return skillId
    end

    local normalizedRef = type(skillRef) == "string" and skillRef or ""
    if normalizedRef ~= "" then
        return normalizedRef
    end

    return "unknown-skill"
end

function Registry:ResolveRaceReference(raceRef)
    local datasetId, raceId = parseDatasetQualifiedRef(raceRef)
    if not datasetId or not raceId then
        return nil, nil
    end

    return resolveDatasetEntryByCollection(datasetId, raceId, "races")
end

function Registry:ResolveRaceName(raceRef)
    local dataset, race = self:ResolveRaceReference(raceRef)
    if race and type(race.name) == "string" and race.name ~= "" then
        return race.name
    end

    local _, raceId = parseDatasetQualifiedRef(raceRef)
    if raceId then
        return raceId
    end

    local normalizedRef = type(raceRef) == "string" and raceRef or ""
    if normalizedRef ~= "" then
        return normalizedRef
    end

    return "unknown-race"
end

function Registry:ResolveClassReference(classRef)
    local datasetId, classId = parseDatasetQualifiedRef(classRef)
    if not datasetId or not classId then
        return nil, nil
    end

    return resolveDatasetEntryByCollection(datasetId, classId, "classes")
end

function Registry:ResolveClassName(classRef)
    local dataset, class = self:ResolveClassReference(classRef)
    if class and type(class.name) == "string" and class.name ~= "" then
        return class.name
    end

    local _, classId = parseDatasetQualifiedRef(classRef)
    if classId then
        return classId
    end

    local normalizedRef = type(classRef) == "string" and classRef or ""
    if normalizedRef ~= "" then
        return normalizedRef
    end

    return "unknown-class"
end

function Registry:ResolveWeaponTypeReference(weaponTypeRef)
    local datasetId, weaponTypeId = parseDatasetQualifiedRef(weaponTypeRef)
    if not datasetId or not weaponTypeId then
        return nil, nil
    end

    return resolveDatasetEntryByCollection(datasetId, weaponTypeId, "weaponTypes")
end

function Registry:ResolveWeaponTypeName(weaponTypeRef)
    local _, weaponType = self:ResolveWeaponTypeReference(weaponTypeRef)
    if weaponType and type(weaponType.name) == "string" and weaponType.name ~= "" then
        return weaponType.name
    end

    local _, weaponTypeId = parseDatasetQualifiedRef(weaponTypeRef)
    if weaponTypeId then
        return humanizeToken(weaponTypeId)
    end

    local normalizedRef = type(weaponTypeRef) == "string" and weaponTypeRef or ""
    if normalizedRef ~= "" then
        return humanizeToken(normalizedRef)
    end

    return "unknown-weapon-type"
end
