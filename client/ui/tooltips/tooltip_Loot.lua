local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Tooltips = Addon.Client.UI.Tooltips or {}

local Tooltips = Addon.Client.UI.Tooltips
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}

local LootTooltip = Tooltips.Loot or {}
Tooltips.Loot = LootTooltip

local HIGH_CHANCE_THRESHOLD = 0.50
local MODERATE_CHANCE_THRESHOLD = 0.20

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function positiveNumber(value)
    local number = tonumber(value)
    if not number or number ~= number or number == math.huge or number == -math.huge or number <= 0 then return nil end
    return number
end

local function positiveInteger(value, defaultValue)
    local number = positiveNumber(value)
    if not number then return defaultValue end
    return math.max(1, math.floor(number))
end

local function resolveLoot(detail)
    local context = type(detail) == "table" and detail or {}
    local loot = context.loot or context.lootTable
    local reference = trim(context.lootRef or context.ref)
    if type(loot) ~= "table" and reference ~= "" and type(Registry.ResolveLootReference) == "function" then
        local ok, _, resolved = pcall(Registry.ResolveLootReference, Registry, reference)
        if ok then loot = resolved end
    end
    return type(loot) == "table" and loot or nil, reference
end

local function resolveRewardName(entry)
    local rewardType = string.lower(trim(entry and entry.type))
    local reference = trim(entry and entry.ref)
    if rewardType == "item" then
        if type(Registry.ResolveItemReference) == "function" then
            local ok, _, item = pcall(Registry.ResolveItemReference, Registry, reference)
            local name = ok and trim(item and item.name) or ""
            if name ~= "" then return name end
        end
        return reference ~= "" and reference or "Unknown item"
    end
    if rewardType == "currency" then
        if type(Profile.ResolveCurrencyDefinition) == "function" then
            local ok, definition = pcall(Profile.ResolveCurrencyDefinition, reference)
            local name = ok and trim(definition and definition.name) or ""
            if name ~= "" then return name end
        end
        return reference ~= "" and reference or "Unknown currency"
    end
    return nil
end

local function buildRewardGroups(loot)
    local rows, totalWeight = {}, 0
    for index, entry in pairs(type(loot and loot.entries) == "table" and loot.entries or {}) do
        if type(index) == "number" and type(entry) == "table" then
            local weight = positiveNumber(entry.weight)
            rows[#rows + 1] = { index = index, entry = entry, weight = weight }
            totalWeight = totalWeight + (weight or 0)
        end
    end
    table.sort(rows, function(left, right) return left.index < right.index end)

    local groups, seen = { high = {}, moderate = {}, low = {} }, { high = {}, moderate = {}, low = {} }
    if totalWeight <= 0 then return groups end
    for index = 1, #rows do
        local row = rows[index]
        local name = resolveRewardName(row.entry)
        if name and row.weight then
            local chance = row.weight / totalWeight
            local group = chance >= HIGH_CHANCE_THRESHOLD and "high"
                or (chance >= MODERATE_CHANCE_THRESHOLD and "moderate" or "low")
            if not seen[group][name] then
                seen[group][name] = true
                groups[group][#groups[group] + 1] = name
            end
        end
    end
    return groups
end

function LootTooltip:Build(detail)
    local loot, reference = resolveLoot(detail)
    if not loot then
        return {
            type = "game", title = "Missing Loot Table",
            titleColor = { r = 0.95, g = 0.35, b = 0.35 },
            lines = { { text = ("Missing loot table reference: %s"):format(reference ~= "" and reference or "-"), r = 0.95, g = 0.35, b = 0.35, wrap = true } },
        }
    end

    local title = trim(loot.name)
    if title == "" then title = "Loot Table" end
    local lines = {}
    local description = trim(loot.description)
    if description ~= "" then lines[#lines + 1] = { text = description, r = 0.82, g = 0.84, b = 0.88, wrap = true } end
    lines[#lines + 1] = { text = ("Rolls: %d"):format(positiveInteger(loot.drawCount, 1)), r = 0.50, g = 0.82, b = 1.00, wrap = false }

    local groups = buildRewardGroups(loot)
    for _, definition in ipairs({
        { key = "high", label = "High Chance:", r = 0.30, g = 0.95, b = 0.45 },
        { key = "moderate", label = "Moderate Chance:", r = 1.00, g = 0.82, b = 0.20 },
        { key = "low", label = "Low Chance:", r = 1.00, g = 0.45, b = 0.30 },
    }) do
        local rewards = groups[definition.key]
        if #rewards > 0 then
            lines[#lines + 1] = { text = " ", wrap = false }
            lines[#lines + 1] = { text = definition.label, r = definition.r, g = definition.g, b = definition.b, wrap = false }
            lines[#lines + 1] = { text = table.concat(rewards, ", "), r = 0.82, g = 0.84, b = 0.88, wrap = true }
        end
    end
    return { type = "game", title = title, titleColor = { r = 1.00, g = 0.82, b = 0.20 }, lines = lines }
end

return LootTooltip
