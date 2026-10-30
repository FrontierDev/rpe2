local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Market = {}
Market.__index = Market

local MARKET_TYPES = {
    exchange = true,
    tracker = true,
}

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function trimText(value)
    return ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function isFiniteNumber(value)
    return value ~= nil
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function normalizeNumber(value, fallback)
    local numeric = tonumber(value)
    if not isFiniteNumber(numeric) then
        return fallback
    end

    return numeric
end

local function normalizeNonNegativeNumber(value, fallback)
    return math.max(0, normalizeNumber(value, fallback))
end

local function normalizeTariff(value)
    return math.min(99.999999, math.max(0, normalizeNumber(value, 0)))
end

local function normalizeStringList(value)
    if type(value) ~= "table" then
        return {}
    end

    local normalized = {}
    local seen = {}
    for index = 1, #value do
        local item = trimText(value[index])
        if item ~= "" and not seen[item] then
            normalized[#normalized + 1] = item
            seen[item] = true
        end
    end

    return normalized
end

local function normalizeSellRules(value)
    local source = type(value) == "table" and value or {}
    return {
        itemRefs = normalizeStringList(source.itemRefs),
        itemTypes = normalizeStringList(source.itemTypes),
        armorWeights = normalizeStringList(source.armorWeights),
        weaponTypeRefs = normalizeStringList(source.weaponTypeRefs),
        slotRefs = normalizeStringList(source.slotRefs),
        consumableTypes = normalizeStringList(source.consumableTypes),
        consumableElixirTypes = normalizeStringList(source.consumableElixirTypes),
        modificationKinds = normalizeStringList(source.modificationKinds),
        targetSlotRefs = normalizeStringList(source.targetSlotRefs),
        targetWeaponTypeRefs = normalizeStringList(source.targetWeaponTypeRefs),
        targetArmorWeights = normalizeStringList(source.targetArmorWeights),
    }
end

local function normalizeMarketType(value)
    local marketType = string.lower(trimText(value))
    return MARKET_TYPES[marketType] and marketType or "exchange"
end

function Market:New(data)
    return setmetatable({
        id = nil,
        name = "",
        index = "",
        marketType = "exchange",
        baseCoefficientPercent = 0,
        dailyVariationPercent = 10,
        trackerMarketRef = "",
        trackerInfluencePercent = 100,
        tariffPercent = 5,
        buyItemRefs = {},
        sellRules = {
            itemRefs = {},
            itemTypes = {},
            armorWeights = {},
            weaponTypeRefs = {},
            slotRefs = {},
            consumableTypes = {},
            consumableElixirTypes = {},
            modificationKinds = {},
            targetSlotRefs = {},
            targetWeaponTypeRefs = {},
            targetArmorWeights = {},
        },
    }, Market):Merge(data)
end

function Market:Merge(data)
    if type(data) == "table" then
        self.id = data.id ~= nil and trimText(data.id) or self.id
        self.name = data.name ~= nil and trimText(data.name) or self.name
        self.index = data.index ~= nil and string.upper(trimText(data.index)) or self.index
        self.marketType = data.marketType ~= nil and normalizeMarketType(data.marketType) or self.marketType
        self.baseCoefficientPercent = data.baseCoefficientPercent ~= nil
            and normalizeNumber(data.baseCoefficientPercent, 0)
            or normalizeNumber(self.baseCoefficientPercent, 0)
        self.dailyVariationPercent = data.dailyVariationPercent ~= nil
            and normalizeNonNegativeNumber(data.dailyVariationPercent, 10)
            or normalizeNonNegativeNumber(self.dailyVariationPercent, 10)
        self.trackerMarketRef = data.trackerMarketRef ~= nil
            and trimText(data.trackerMarketRef)
            or trimText(self.trackerMarketRef)
        self.trackerInfluencePercent = data.trackerInfluencePercent ~= nil
            and normalizeNumber(data.trackerInfluencePercent, 100)
            or normalizeNumber(self.trackerInfluencePercent, 100)
        self.tariffPercent = data.tariffPercent ~= nil
            and normalizeTariff(data.tariffPercent)
            or normalizeTariff(self.tariffPercent)
        self.buyItemRefs = data.buyItemRefs ~= nil
            and normalizeStringList(data.buyItemRefs)
            or normalizeStringList(self.buyItemRefs)
        self.sellRules = data.sellRules ~= nil
            and normalizeSellRules(data.sellRules)
            or normalizeSellRules(self.sellRules)
    else
        self.id = self.id ~= nil and trimText(self.id) or nil
        self.name = trimText(self.name)
        self.index = string.upper(trimText(self.index))
        self.marketType = normalizeMarketType(self.marketType)
        self.baseCoefficientPercent = normalizeNumber(self.baseCoefficientPercent, 0)
        self.dailyVariationPercent = normalizeNonNegativeNumber(self.dailyVariationPercent, 10)
        self.trackerMarketRef = trimText(self.trackerMarketRef)
        self.trackerInfluencePercent = normalizeNumber(self.trackerInfluencePercent, 100)
        self.tariffPercent = normalizeTariff(self.tariffPercent)
        self.buyItemRefs = normalizeStringList(self.buyItemRefs)
        self.sellRules = normalizeSellRules(self.sellRules)
    end

    if self.marketType == "tracker" then
        self.trackerMarketRef = ""
        self.tariffPercent = 0
        self.buyItemRefs = {}
        self.sellRules = {
            itemRefs = {},
            itemTypes = {},
            armorWeights = {},
            weaponTypeRefs = {},
            slotRefs = {},
            consumableTypes = {},
            consumableElixirTypes = {},
            modificationKinds = {},
            targetSlotRefs = {},
            targetWeaponTypeRefs = {},
            targetArmorWeights = {},
        }
    end

    return self
end

function Market:ToTable()
    local sellRules = normalizeSellRules(self.sellRules)
    local normalized = {
        id = self.id,
        name = trimText(self.name),
        index = string.upper(trimText(self.index)),
        marketType = normalizeMarketType(self.marketType),
        baseCoefficientPercent = normalizeNumber(self.baseCoefficientPercent, 0),
        dailyVariationPercent = normalizeNonNegativeNumber(self.dailyVariationPercent, 10),
        trackerMarketRef = trimText(self.trackerMarketRef),
        trackerInfluencePercent = normalizeNumber(self.trackerInfluencePercent, 100),
        tariffPercent = normalizeTariff(self.tariffPercent),
        buyItemRefs = normalizeStringList(self.buyItemRefs),
        sellRules = sellRules,
    }

    if normalized.marketType == "tracker" then
        normalized.trackerMarketRef = ""
        normalized.tariffPercent = 0
        normalized.buyItemRefs = {}
        normalized.sellRules = {
            itemRefs = {},
            itemTypes = {},
            armorWeights = {},
            weaponTypeRefs = {},
            slotRefs = {},
            consumableTypes = {},
            consumableElixirTypes = {},
            modificationKinds = {},
            targetSlotRefs = {},
            targetWeaponTypeRefs = {},
            targetArmorWeights = {},
        }
    end

    return normalized
end

function Market.FromTable(data)
    return Market:New(data)
end

function Market.Validate(value)
    local diagnostics = {}
    local market = type(value) == "table" and value or {}

    if trimText(market.id) == "" then
        diagnostics[#diagnostics + 1] = "Market id must be non-empty."
    end
    if trimText(market.name) == "" then
        diagnostics[#diagnostics + 1] = "Market name must be non-empty."
    end
    if trimText(market.index) == "" then
        diagnostics[#diagnostics + 1] = "Market index must be non-empty."
    end
    local marketType = string.lower(trimText(market.marketType))
    if not MARKET_TYPES[marketType] then
        diagnostics[#diagnostics + 1] = "Market marketType must be 'exchange' or 'tracker'."
    end

    local numericFields = {
        "baseCoefficientPercent",
        "dailyVariationPercent",
        "trackerInfluencePercent",
        "tariffPercent",
    }
    for index = 1, #numericFields do
        local fieldName = numericFields[index]
        if not isFiniteNumber(tonumber(market[fieldName])) then
            diagnostics[#diagnostics + 1] = ("Market %s must be finite."):format(fieldName)
        end
    end
    if tonumber(market.dailyVariationPercent) and tonumber(market.dailyVariationPercent) < 0 then
        diagnostics[#diagnostics + 1] = "Market dailyVariationPercent must be non-negative."
    end
    if tonumber(market.tariffPercent)
        and (tonumber(market.tariffPercent) < 0 or tonumber(market.tariffPercent) >= 100)
    then
        diagnostics[#diagnostics + 1] = "Market tariffPercent must be at least 0 and less than 100."
    end

    return #diagnostics == 0, diagnostics
end

Addon.Internal.Database.Classes.Market = Market
