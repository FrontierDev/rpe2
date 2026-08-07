local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Resource = {}
Resource.__index = Resource

local DEFAULT_COLOR = {
    r = 0.18,
    g = 0.68,
    b = 0.2,
    a = 1,
}

local function normalizeColor(value)
    if type(value) ~= "table" then
        return {
            r = DEFAULT_COLOR.r,
            g = DEFAULT_COLOR.g,
            b = DEFAULT_COLOR.b,
            a = DEFAULT_COLOR.a,
        }
    end

    return {
        r = math.max(0, math.min(1, tonumber(value.r) or DEFAULT_COLOR.r)),
        g = math.max(0, math.min(1, tonumber(value.g) or DEFAULT_COLOR.g)),
        b = math.max(0, math.min(1, tonumber(value.b) or DEFAULT_COLOR.b)),
        a = math.max(0, math.min(1, tonumber(value.a) or DEFAULT_COLOR.a)),
    }
end

local function readLegacyDerivedSource(data)
    if type(data) ~= "table" then
        return nil, 0
    end

    local sources = data.derivedSources
    if type(sources) ~= "table" or #sources == 0 then
        return nil, 0
    end

    local first = sources[1]
    if type(first) ~= "table" then
        return nil, 0
    end

    local sourceRef = type(first.sourceResourceRef) == "string" and first.sourceResourceRef
        or type(first.sourceStatRef) == "string" and first.sourceStatRef
        or nil

    return sourceRef, tonumber(first.coefficient) or 0
end

function Resource:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
        icon = "",
        color = normalizeColor(nil),
        valueMode = "manual",
        baseValue = 0,
        sourceStatRef = nil,
        multiplier = 0,
        startsAtZero = false,
        special = false,
        seedNPCResource = false,
        regenMode = "manual",
        regenPerSecond = 0,
        regenSourceStatRef = nil,
        regenMultiplier = 0,
        tags = {},
    }, Resource):Merge(data)
end

function Resource:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        if key ~= "derivedSources" and key ~= "startAtMax" then
            self[key] = value
        end
    end

    if data.startsAtZero == nil and data.startAtMax ~= nil then
        self.startsAtZero = data.startAtMax ~= true
    end

    if (self.sourceStatRef == nil or self.sourceStatRef == "") and data.derivedSources ~= nil then
        local sourceRef, coefficient = readLegacyDerivedSource(data)
        self.sourceStatRef = sourceRef
        self.multiplier = coefficient
    end

    self.valueMode = self.valueMode == "derived" and "derived" or "manual"
    self.color = normalizeColor(self.color)
    self.baseValue = tonumber(self.baseValue) or 0
    self.multiplier = tonumber(self.multiplier) or 0
    self.startsAtZero = self.startsAtZero == true
    self.special = self.special == true
    self.seedNPCResource = self.seedNPCResource == true
    self.regenMode = self.regenMode == "derived" and "derived" or "manual"
    self.regenPerSecond = tonumber(self.regenPerSecond) or 0
    self.regenMultiplier = tonumber(self.regenMultiplier) or 0
    self.tags = type(self.tags) == "table" and self.tags or {}

    if type(self.sourceStatRef) ~= "string" or self.sourceStatRef == "" then
        self.sourceStatRef = nil
    end
    if type(self.regenSourceStatRef) ~= "string" or self.regenSourceStatRef == "" then
        self.regenSourceStatRef = nil
    end

    return self
end

function Resource:ToTable()
    return {
        id = self.id,
        name = self.name,
        description = self.description,
        icon = self.icon,
        color = normalizeColor(self.color),
        valueMode = self.valueMode,
        baseValue = self.baseValue,
        sourceStatRef = self.sourceStatRef,
        multiplier = self.multiplier,
        startsAtZero = self.startsAtZero,
        special = self.special == true,
        seedNPCResource = self.seedNPCResource == true,
        regenMode = self.regenMode,
        regenPerSecond = self.regenPerSecond,
        regenSourceStatRef = self.regenSourceStatRef,
        regenMultiplier = self.regenMultiplier,
        tags = self.tags,
    }
end

function Resource.FromTable(data)
    return Resource:New(data)
end

Addon.Internal.Database.Classes.Resource = Resource
