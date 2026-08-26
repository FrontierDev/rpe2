local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Profile = Addon.Internal.Profile or {}

local Profile = Addon.Internal.Profile

local Database = Addon.Internal and Addon.Internal.Database or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Runtime = Addon.Internal and Addon.Internal.Runtime or {}
local Common = Addon.Utils and Addon.Utils.Common or {}

local BUILTIN_ORDER = {
    "copper",
    "valor",
    "justice",
    "honor",
    "conquest",
}

local BUILTIN_DEFINITIONS = {
    copper = {
        id = "copper",
        key = "copper",
        name = "Copper",
        description = "The common currency used all around Azeroth.",
        icon = "Interface\\Icons\\INV_Misc_Coin_01",
        max = 2147483647,
        builtin = true,
        readOnly = true,
    },
    valor = {
        id = "valor",
        key = "valor",
        name = "Valor",
        description = "Valor points earned through difficult PvE challenges.",
        icon = 463447,
        max = 4000,
        builtin = true,
        readOnly = true,
    },
    justice = {
        id = "justice",
        key = "justice",
        name = "Justice",
        description = "Justice points earned through PvE combat.",
        icon = 463446,
        max = 4000,
        builtin = true,
        readOnly = true,
    },
    honor = {
        id = "honor",
        key = "honor",
        name = "Honor",
        description = "Honor points earned through PvP combat.",
        icon = 1455894,
        max = 4000,
        builtin = true,
        readOnly = true,
    },
    conquest = {
        id = "conquest",
        key = "conquest",
        name = "Conquest",
        description = "Conquest points earned through PvP triumphs.",
        icon = 1523630,
        max = 4000,
        builtin = true,
        readOnly = true,
    },
}

local BUILTIN_LOOKUP = {}
for _, currencyId in ipairs(BUILTIN_ORDER) do
    BUILTIN_LOOKUP[currencyId] = true
end

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function normalizeCurrencyAmount(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

local function splitCurrencyReference(reference)
    local normalizedReference = ensureString(reference)
    if normalizedReference == "" then
        return nil, nil
    end

    local separatorIndex = string.find(normalizedReference, ":", 1, true)
    if not separatorIndex then
        return nil, nil
    end

    local datasetId = string.sub(normalizedReference, 1, separatorIndex - 1)
    local currencyId = string.sub(normalizedReference, separatorIndex + 1)
    if datasetId == "" or currencyId == "" then
        return nil, nil
    end

    return datasetId, currencyId
end

local function isBuiltinCurrencyKey(currencyKey)
    return BUILTIN_LOOKUP[ensureString(currencyKey)] == true
end

local function cloneCurrencyDefinition(definition)
    if type(definition) ~= "table" then
        return nil
    end

    local copy = {}
    for key, value in pairs(definition) do
        copy[key] = value
    end

    return copy
end

local function buildCustomCurrencyDefinition(dataset, currency, isActive)
    if type(dataset) ~= "table" or type(currency) ~= "table" or ensureString(dataset.id) == "" or ensureString(currency.id) == "" then
        return nil
    end

    local datasetName = Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or ensureString(dataset.name)
    return {
        id = ensureString(currency.id),
        key = ("%s:%s"):format(ensureString(dataset.id), ensureString(currency.id)),
        ref = ("%s:%s"):format(ensureString(dataset.id), ensureString(currency.id)),
        name = ensureString(currency.name),
        description = ensureString(currency.description),
        icon = currency.icon ~= nil and currency.icon or "",
        max = math.max(0, math.floor(tonumber(currency.max) or 0)),
        builtin = false,
        readOnly = false,
        datasetId = ensureString(dataset.id),
        datasetName = datasetName,
        isActive = isActive == true,
        isMissing = false,
        source = currency,
    }
end

local function buildMissingCurrencyDefinition(datasetId, currencyId, datasetName)
    local normalizedDatasetId = ensureString(datasetId)
    local normalizedCurrencyId = ensureString(currencyId)
    if normalizedDatasetId == "" or normalizedCurrencyId == "" then
        return nil
    end

    local resolvedDatasetName = ensureString(datasetName)
    if resolvedDatasetName == "" then
        resolvedDatasetName = normalizedDatasetId
    end

    local ref = ("%s:%s"):format(normalizedDatasetId, normalizedCurrencyId)
    return {
        id = normalizedCurrencyId,
        key = ref,
        ref = ref,
        name = normalizedCurrencyId,
        description = "",
        icon = "",
        max = nil,
        builtin = false,
        readOnly = false,
        datasetId = normalizedDatasetId,
        datasetName = resolvedDatasetName,
        isActive = false,
        isMissing = true,
        source = nil,
    }
end

local function findCustomCurrencyByRef(currencyRef)
    local datasetId, currencyId = splitCurrencyReference(currencyRef)
    if not datasetId or not currencyId then
        return nil
    end

    local dataset = Database.GetDatasetByID and Database.GetDatasetByID(datasetId) or nil
    if not dataset then
        return buildMissingCurrencyDefinition(datasetId, currencyId)
    end

    local isActive = Registry.IsDatasetActivated and Registry:IsDatasetActivated(datasetId) or false
    for index = 1, #(dataset.currencies or {}) do
        local currency = dataset.currencies[index]
        if currency and ensureString(currency.id) == currencyId then
            return buildCustomCurrencyDefinition(dataset, currency, isActive)
        end
    end

    return buildMissingCurrencyDefinition(
        datasetId,
        currencyId,
        Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or ensureString(dataset.name)
    )
end

function Profile.GetBuiltinCurrencyDefinitions()
    local definitions = {}
    for index = 1, #BUILTIN_ORDER do
        definitions[#definitions + 1] = cloneCurrencyDefinition(BUILTIN_DEFINITIONS[BUILTIN_ORDER[index]])
    end

    return definitions
end

function Profile.NormalizeCurrencyKey(currencyRefOrId)
    local normalized = string.lower(ensureString(currencyRefOrId))
    if normalized == "" then
        return ""
    end

    if isBuiltinCurrencyKey(normalized) then
        return normalized
    end

    local datasetId, currencyId = splitCurrencyReference(normalized)
    if datasetId and currencyId then
        return ("%s:%s"):format(datasetId, currencyId)
    end

    return normalized
end

function Profile.IsBuiltinCurrencyKey(currencyKey)
    return isBuiltinCurrencyKey(currencyKey)
end

function Profile.ResolveCurrencyDefinition(currencyRefOrId)
    local normalizedKey = Profile.NormalizeCurrencyKey(currencyRefOrId)
    if normalizedKey == "" then
        return nil
    end

    if isBuiltinCurrencyKey(normalizedKey) then
        return cloneCurrencyDefinition(BUILTIN_DEFINITIONS[normalizedKey])
    end

    return findCustomCurrencyByRef(normalizedKey)
end

function Profile.ListCurrencyDefinitions(options)
    local definitions = {}
    local includeBuiltins = not (type(options) == "table" and options.includeBuiltins == false)
    local includeCustom = not (type(options) == "table" and options.includeCustom == false)
    local includeInactive = type(options) ~= "table" or options.includeInactive ~= false
    local includeMissingBalances = type(options) ~= "table" or options.includeMissingBalances ~= false
    local storedAmounts = Database.ListProfileCurrencies and Database.ListProfileCurrencies() or {}
    local seen = {}

    if includeBuiltins then
        for index = 1, #BUILTIN_ORDER do
            local key = BUILTIN_ORDER[index]
            local definition = cloneCurrencyDefinition(BUILTIN_DEFINITIONS[key])
            if definition then
                definitions[#definitions + 1] = definition
                seen[definition.key] = true
            end
        end
    end

    if includeCustom then
        local datasets = Registry.GetActivatedDatasets and Registry:GetActivatedDatasets() or {}
        for datasetIndex = 1, #datasets do
            local dataset = datasets[datasetIndex]
            for currencyIndex = 1, #(dataset and dataset.currencies or {}) do
                local definition = buildCustomCurrencyDefinition(dataset, dataset.currencies[currencyIndex], true)
                if definition and not seen[definition.key] then
                    definitions[#definitions + 1] = definition
                    seen[definition.key] = true
                end
            end
        end

        if includeInactive or includeMissingBalances then
            for currencyKey, amount in pairs(storedAmounts) do
                local normalizedKey = Profile.NormalizeCurrencyKey(currencyKey)
                if normalizedKey ~= "" and not isBuiltinCurrencyKey(normalizedKey) and not seen[normalizedKey] then
                    local definition = findCustomCurrencyByRef(normalizedKey)
                    if definition and ((definition.isActive == false and includeInactive) or (definition.isMissing == true and includeMissingBalances) or amount > 0) then
                        definitions[#definitions + 1] = definition
                        seen[normalizedKey] = true
                    end
                end
            end
        end
    end

    table.sort(definitions, function(left, right)
        local leftBuiltin = left and left.builtin == true
        local rightBuiltin = right and right.builtin == true
        if leftBuiltin ~= rightBuiltin then
            return leftBuiltin
        end

        if leftBuiltin and rightBuiltin then
            local leftIndex = 999
            local rightIndex = 999
            for index = 1, #BUILTIN_ORDER do
                if BUILTIN_ORDER[index] == left.key then
                    leftIndex = index
                end
                if BUILTIN_ORDER[index] == right.key then
                    rightIndex = index
                end
            end
            return leftIndex < rightIndex
        end

        local leftDataset = string.lower(ensureString(left and left.datasetName))
        local rightDataset = string.lower(ensureString(right and right.datasetName))
        if leftDataset ~= rightDataset then
            return leftDataset < rightDataset
        end

        return string.lower(ensureString(left and left.name)) < string.lower(ensureString(right and right.name))
    end)

    return definitions
end

function Profile.GetCurrencyAmount(currencyRefOrId)
    local normalizedKey = Profile.NormalizeCurrencyKey(currencyRefOrId)
    if normalizedKey == "" or not Database.GetProfileCurrencyAmount then
        return 0
    end

    return normalizeCurrencyAmount(Database.GetProfileCurrencyAmount(normalizedKey))
end

function Profile.SetCurrencyAmount(currencyRefOrId, amount)
    local normalizedKey = Profile.NormalizeCurrencyKey(currencyRefOrId)
    if normalizedKey == "" then
        return nil
    end

    local definition = Profile.ResolveCurrencyDefinition(normalizedKey)
    local normalizedAmount = normalizeCurrencyAmount(amount)
    if definition and definition.max ~= nil then
        normalizedAmount = math.min(normalizedAmount, normalizeCurrencyAmount(definition.max))
    end

    if Database.SetProfileCurrencyAmount then
        return Database.SetProfileCurrencyAmount(normalizedKey, normalizedAmount)
    end

    return normalizedAmount
end

function Profile.AddCurrencyAmount(currencyRefOrId, amount)
    local normalizedKey = Profile.NormalizeCurrencyKey(currencyRefOrId)
    if normalizedKey == "" then
        return nil
    end

    local function add()
        local currentAmount = Profile.GetCurrencyAmount(normalizedKey)
        local persistedAmount = Profile.SetCurrencyAmount(normalizedKey, currentAmount + normalizeCurrencyAmount(amount))
        local updatedAmount = Profile.GetCurrencyAmount(normalizedKey)
        local actualGain = updatedAmount - currentAmount
        if actualGain > 0 then
            local achievements = Addon.Client and Addon.Client.Achievements or nil
            if achievements and type(achievements.ProcessTrigger) == "function" then
                pcall(
                    achievements.ProcessTrigger,
                    achievements,
                    "currency_gain",
                    {
                        currencyRef = normalizedKey,
                        previousAmount = currentAmount,
                        updatedAmount = updatedAmount,
                        amount = actualGain,
                        source = "currency-add",
                    }
                )
            end
        end

        return persistedAmount
    end

    if type(Runtime) == "table" and type(Runtime.RunTransaction) == "function" then
        return Runtime:RunTransaction("currency-add:" .. normalizedKey, add)
    end

    return add()
end

function Profile.SpendCurrencyAmount(currencyRefOrId, amount)
    local normalizedKey = Profile.NormalizeCurrencyKey(currencyRefOrId)
    if normalizedKey == "" then
        return false, 0
    end

    local spendAmount = normalizeCurrencyAmount(amount)
    local currentAmount = Profile.GetCurrencyAmount(normalizedKey)
    if spendAmount <= 0 then
        return true, currentAmount
    end
    if currentAmount < spendAmount then
        return false, currentAmount
    end

    local updatedAmount = Profile.SetCurrencyAmount(normalizedKey, currentAmount - spendAmount)
    return true, updatedAmount
end

function Profile.FormatCurrencyAmount(currencyDefinition, amount)
    local definition = currencyDefinition
    if type(currencyDefinition) ~= "table" then
        definition = Profile.ResolveCurrencyDefinition(currencyDefinition)
    end

    local normalizedAmount = normalizeCurrencyAmount(amount)
    if definition and definition.key == "copper" and Common.FormatCopper then
        return Common:FormatCopper(normalizedAmount)
    end

    return tostring(normalizedAmount)
end
