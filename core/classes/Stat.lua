local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Stat = {}
Stat.__index = Stat

local function normalizeDisplayMode(value)
    local mode = tostring(value or "signed_value")
    if mode == "value" or mode == "signed_percent" then
        return mode
    end

    return "signed_value"
end

local function normalizePriority(value)
    return math.floor(tonumber(value) or 0)
end

local function normalizeDefenceLabel(value)
    local text = tostring(value or "")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

local function normalizeColor(value)
    if type(value) ~= "table" then
        return {
            r = 1,
            g = 1,
            b = 1,
            a = 1,
        }
    end

    return {
        r = math.max(0, math.min(1, tonumber(value.r) or 1)),
        g = math.max(0, math.min(1, tonumber(value.g) or 1)),
        b = math.max(0, math.min(1, tonumber(value.b) or 1)),
        a = math.max(0, math.min(1, tonumber(value.a) or 1)),
    }
end

local function normalizeDerivedSources(sources, legacySourceStatRef)
    local normalized = {}

    if type(sources) == "table" then
        for index = 1, #sources do
            local source = sources[index]
            if type(source) == "table" then
                local sourceStatRef = source.sourceStatRef
                if type(sourceStatRef) == "string" and sourceStatRef ~= "" then
                    normalized[#normalized + 1] = {
                        sourceStatRef = sourceStatRef,
                        coefficient = tonumber(source.coefficient) or 1,
                    }
                end
            end
        end
    end

    if #normalized == 0 and type(legacySourceStatRef) == "string" and legacySourceStatRef ~= "" then
        normalized[1] = {
            sourceStatRef = legacySourceStatRef,
            coefficient = 1,
        }
    end

    return normalized
end

function Stat:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
        icon = "",
        category = "Primary",
        visibility = false,
        valueMode = "manual",
        baseValue = 0,
        displayMode = "signed_value",
        defenceLabel = "",
        priority = 0,
        color = { r = 1, g = 1, b = 1, a = 1 },
        itemLevelWeight = 0,
        seedNPCStat = false,
        derivedSources = {},
        tags = {},
    }, Stat):Merge(data)
end

function Stat:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        if key ~= "sourceStatRef" and key ~= "derivedSources" then
            self[key] = value
        end
    end

    self.displayMode = normalizeDisplayMode(self.displayMode)
    self.defenceLabel = normalizeDefenceLabel(self.defenceLabel)
    self.priority = normalizePriority(self.priority)
    self.color = normalizeColor(self.color)
    self.itemLevelWeight = tonumber(self.itemLevelWeight) or 0
    self.seedNPCStat = self.seedNPCStat == true
    self.derivedSources = normalizeDerivedSources(data.derivedSources, data.sourceStatRef)
    return self
end

function Stat:ToTable()
    return {
        id = self.id,
        name = self.name,
        description = self.description,
        icon = self.icon,
        category = self.category,
        visibility = self.visibility == true,
        valueMode = self.valueMode,
        baseValue = self.baseValue,
        displayMode = self.displayMode,
        defenceLabel = self.defenceLabel,
        priority = self.priority,
        color = normalizeColor(self.color),
        itemLevelWeight = tonumber(self.itemLevelWeight) or 0,
        seedNPCStat = self.seedNPCStat == true,
        derivedSources = self.derivedSources,
        tags = self.tags,
    }
end

function Stat.FromTable(data)
    return Stat:New(data)
end

Addon.Internal.Database.Classes.Stat = Stat
