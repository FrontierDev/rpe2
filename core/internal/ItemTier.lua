local _, Addon = ...

Addon.Internal = Addon.Internal or {}

local ItemTier = Addon.Internal.ItemTier or {}
Addon.Internal.ItemTier = ItemTier

ItemTier.NORMAL = "normal"
ItemTier.HEROIC = "heroic"
ItemTier.MYTHIC = "mythic"

local VALID_TIERS = {
    normal = true,
    heroic = true,
    mythic = true,
}

local DISPLAY_NAMES = {
    normal = "Normal",
    heroic = "Heroic",
    mythic = "Mythic",
}

local QUALITY_UPGRADES = {
    poor = "common",
    common = "uncommon",
    uncommon = "rare",
    rare = "epic",
    epic = "epic",
    legendary = "legendary",
}

local function normalizeToken(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
end

function ItemTier.IsValid(value)
    return VALID_TIERS[normalizeToken(value)] == true
end

function ItemTier.Normalize(value)
    local normalized = normalizeToken(value)
    if normalized == "" then
        return ItemTier.NORMAL
    end
    return VALID_TIERS[normalized] and normalized or nil
end

function ItemTier.Validate(value)
    if value ~= nil and normalizeToken(value) == "" then
        return nil, "invalid-item-tier"
    end
    local normalized = ItemTier.Normalize(value)
    if not normalized then
        return nil, "invalid-item-tier"
    end
    return normalized
end

function ItemTier.DisplayName(value)
    local normalized = ItemTier.Normalize(value) or ItemTier.NORMAL
    return DISPLAY_NAMES[normalized]
end

function ItemTier.GetOptions()
    return {
        { label = DISPLAY_NAMES.normal, value = ItemTier.NORMAL },
        { label = DISPLAY_NAMES.heroic, value = ItemTier.HEROIC },
        { label = DISPLAY_NAMES.mythic, value = ItemTier.MYTHIC },
    }
end

function ItemTier.GetEffectiveQuality(quality, value)
    local normalizedQuality = string.lower(tostring(quality or "common"))
    if ItemTier.Normalize(value) ~= ItemTier.MYTHIC then
        return normalizedQuality
    end
    return QUALITY_UPGRADES[normalizedQuality] or normalizedQuality
end

local function finiteNumber(value)
    local numeric = tonumber(value)
    if numeric == nil or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return nil
    end
    return numeric
end

function ItemTier.NormalizeBonusPercent(value, fallback)
    local numeric = finiteNumber(value)
    if numeric == nil or numeric < 0 or numeric > 10000 then
        numeric = finiteNumber(fallback) or 0
    end
    return numeric
end

function ItemTier.GetStatBonusPercent(value, options)
    local normalized = ItemTier.Normalize(value) or ItemTier.NORMAL
    local settings = type(options) == "table" and options or {}
    if normalized == ItemTier.HEROIC then
        return ItemTier.NormalizeBonusPercent(settings.heroicBonusPercent, 10)
    end
    if normalized == ItemTier.MYTHIC then
        return ItemTier.NormalizeBonusPercent(settings.mythicBonusPercent, 20)
    end
    return 0
end

function ItemTier.GetStatMultiplier(value, options)
    return 1 + (ItemTier.GetStatBonusPercent(value, options) / 100)
end

function ItemTier.IsPercentageStat(statEntry, statDefinition)
    local source = type(statEntry) == "table" and statEntry or {}
    local definition = type(statDefinition) == "table" and statDefinition or {}
    local displayMode = string.lower(tostring(definition.displayMode or source.displayMode or source.operation or ""))
    return source.isPercent == true
        or displayMode == "percent"
        or displayMode == "percentage"
        or string.find(displayMode, "percent", 1, true) ~= nil
end

function ItemTier.ResolveAuthoredStatValue(statEntry, value, options, statDefinition)
    local source = type(statEntry) == "table" and statEntry or {}
    local authoredValue = tonumber(source.value) or 0
    local resolvedValue = authoredValue * ItemTier.GetStatMultiplier(value, options)
    local normalizedTier = ItemTier.Normalize(value) or ItemTier.NORMAL
    if normalizedTier ~= ItemTier.NORMAL and not ItemTier.IsPercentageStat(source, statDefinition) then
        resolvedValue = math.ceil(resolvedValue)
    end
    return resolvedValue
end

return ItemTier
