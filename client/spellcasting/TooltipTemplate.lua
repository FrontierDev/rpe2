local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}

local Spellcasting = Addon.Client.Spellcasting or {}
local TooltipTemplate = Spellcasting.TooltipTemplate or {}
Spellcasting.TooltipTemplate = TooltipTemplate

local TEMPLATE_VERSION = 1

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

local function normalizeTargetContext(value)
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

local function normalizeToken(token)
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

local function normalizeTokens(values)
    local normalized = {}
    for index = 1, #(values or {}) do
        local token = normalizeToken(values[index])
        if token then
            normalized[#normalized + 1] = token
        end
    end

    return normalized
end

local function normalizeAuraSection(section)
    if type(section) ~= "table" then
        return nil
    end

    local nameText = trimText(section.nameText)
    local descriptionText = trimText(section.descriptionText)
    local normalized = {
        auraRef = ensureString(section.auraRef),
        datasetId = ensureString(section.datasetId),
        spellDatasetId = ensureString(section.spellDatasetId),
        nameText = nameText,
        icon = ensureString(section.icon),
        descriptionText = descriptionText,
        tokens = normalizeTokens(section.tokens),
        powerLevel = tonumber(section.powerLevel) or 0,
        stacks = math.max(1, math.floor(tonumber(section.stacks) or 1)),
    }
    if section.duration ~= nil then
        normalized.duration = math.max(0, math.floor(tonumber(section.duration) or 0))
    end
    normalized.targetContext = normalizeTargetContext(section.targetContext)
    if normalized.nameText == "" and normalized.descriptionText == "" then
        return nil
    end

    return normalized
end

function TooltipTemplate.NormalizeSpellPayload(payload)
    if type(payload) ~= "table" then
        return nil
    end

    local normalized = {
        version = TEMPLATE_VERSION,
        mainText = trimText(payload.mainText),
        tokens = normalizeTokens(payload.tokens),
        auraSections = {},
    }
    for index = 1, #(payload.auraSections or {}) do
        local section = normalizeAuraSection(payload.auraSections[index])
        if section then
            normalized.auraSections[#normalized.auraSections + 1] = section
        end
    end

    if normalized.mainText == "" and #normalized.auraSections == 0 then
        return nil
    end

    return normalized
end

function TooltipTemplate.NormalizeAuraPayload(payload)
    if type(payload) ~= "table" then
        return nil
    end

    local normalized = {
        version = TEMPLATE_VERSION,
        bodyText = trimText(payload.bodyText),
        bodyTokens = normalizeTokens(payload.bodyTokens),
        stackingText = trimText(payload.stackingText),
        stackingTokens = normalizeTokens(payload.stackingTokens),
    }
    if normalized.bodyText == "" and normalized.stackingText == "" then
        return nil
    end

    return normalized
end

function TooltipTemplate.CreateBuildState()
    return {
        counters = {},
        tokens = {},
    }
end

function TooltipTemplate.AddToken(state, baseKey, tokenType, metadata)
    if type(state) ~= "table" then
        return ""
    end

    local normalizedBaseKey = trimText(baseKey):upper()
    if normalizedBaseKey == "" then
        normalizedBaseKey = "TOKEN"
    end

    local nextIndex = math.max(0, math.floor(tonumber(state.counters[normalizedBaseKey]) or 0)) + 1
    state.counters[normalizedBaseKey] = nextIndex

    local key = ("%s_%d"):format(normalizedBaseKey, nextIndex)
    local token = {
        key = key,
        tokenType = ensureString(tokenType),
    }
    if type(metadata) == "table" then
        for metadataKey, metadataValue in pairs(metadata) do
            if type(metadataValue) == "string" or type(metadataValue) == "number" or type(metadataValue) == "boolean" then
                token[metadataKey] = metadataValue
            end
        end
    end
    state.tokens[#state.tokens + 1] = token
    return ("{%s}"):format(key)
end

function TooltipTemplate.CombineText(left, right)
    local leftText = trimText(left)
    local rightText = trimText(right)
    if leftText == "" then
        return rightText
    end
    if rightText == "" then
        return leftText
    end

    return ("%s %s"):format(leftText, rightText)
end

function TooltipTemplate.MergeTokens(...)
    local merged = {}
    local sourceLists = { ... }
    for listIndex = 1, #sourceLists do
        local sourceList = sourceLists[listIndex]
        for tokenIndex = 1, #(sourceList or {}) do
            local token = normalizeToken(sourceList[tokenIndex])
            if token then
                merged[#merged + 1] = token
            end
        end
    end

    return merged
end

function TooltipTemplate.ResolveText(text, tokens, resolveToken)
    local templateText = ensureString(text)
    local tokenList = normalizeTokens(tokens)
    local tokenMap = {}
    for index = 1, #tokenList do
        local token = tokenList[index]
        tokenMap[token.key] = token
    end

    local missingKey = nil
    local failureMessage = nil
    local rendered = templateText:gsub("{([A-Z0-9_]+)}", function(key)
        local token = tokenMap[key]
        if type(token) ~= "table" then
            missingKey = key
            return ""
        end

        local resolvedValue, resolveError = resolveToken(token)
        local normalizedValue = trimText(resolvedValue)
        if normalizedValue == "" then
            missingKey = key
            failureMessage = trimText(resolveError)
            return ""
        end

        return normalizedValue
    end)

    if missingKey ~= nil then
        if failureMessage ~= "" and failureMessage ~= nil then
            return nil, failureMessage
        end
        return nil, ("Could not resolve template token '%s'."):format(missingKey)
    end

    return trimText(rendered), nil
end

return TooltipTemplate
