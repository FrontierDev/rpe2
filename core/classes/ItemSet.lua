local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local ItemSet = {}
ItemSet.__index = ItemSet
local TraitClass = Addon.Internal.Database.Classes.Trait or {}

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function trimText(value)
    return ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeReference(value)
    return trimText(value)
end

local function listLength(value)
    return type(value) == "table" and #value or 0
end

local function normalizeBonusList(values, referenceKey, legacyReferenceKey)
    local normalized = {}

    for index = 1, listLength(values) do
        local source = values[index]
        local entry = type(source) == "table" and source or {}
        local reference = normalizeReference(entry[referenceKey])
        if reference == "" and legacyReferenceKey then
            reference = normalizeReference(entry[legacyReferenceKey])
        end

        -- Keep malformed rows in the normalized authored data. Validation can
        -- then report the exact row and resolution can refuse to apply it.
        normalized[#normalized + 1] = {
            [referenceKey] = reference,
            value = tonumber(entry.value) or 0,
        }
    end

    return normalized
end

local function normalizeEquipmentBonus(value)
    if type(value) ~= "table" then
        return nil
    end

    local payload
    if type(TraitClass.NormalizeRuntimePayload) == "function" then
        payload = TraitClass.NormalizeRuntimePayload(value)
    else
        payload = {
            name = ensureString(value.name),
            description = ensureString(value.description),
            icon = ensureString(value.icon),
            conditions = type(value.conditions) == "table" and value.conditions or {},
            statBonuses = normalizeBonusList(value.statBonuses, "statRef", "sourceStatRef"),
            skillBonuses = normalizeBonusList(value.skillBonuses, "skillRef"),
            automaticAuras = type(value.automaticAuras) == "table" and value.automaticAuras or {},
            events = type(value.events) == "table" and value.events or {},
        }
    end

    local hasContent = payload.name ~= ""
        or payload.description ~= ""
        or payload.icon ~= ""
        or #(payload.statBonuses or {}) > 0
        or #(payload.skillBonuses or {}) > 0
        or #(payload.automaticAuras or {}) > 0
        or #(payload.events or {}) > 0
    if not hasContent then
        return nil
    end

    return payload
end

local function normalizeEquipmentBonuses(values)
    local normalized = {}

    for index = 1, listLength(values) do
        local payload = normalizeEquipmentBonus(values[index])
        if payload then
            normalized[#normalized + 1] = payload
        end
    end

    return normalized
end

local function bonusSortKey(bonus)
    local statParts = {}
    for index = 1, listLength(bonus and bonus.statBonuses) do
        local entry = bonus.statBonuses[index]
        statParts[#statParts + 1] = ("%s:%s"):format(
            ensureString(entry and entry.statRef),
            tostring(tonumber(entry and entry.value) or 0)
        )
    end

    local skillParts = {}
    for index = 1, listLength(bonus and bonus.skillBonuses) do
        local entry = bonus.skillBonuses[index]
        skillParts[#skillParts + 1] = ("%s:%s"):format(
            ensureString(entry and entry.skillRef),
            tostring(tonumber(entry and entry.value) or 0)
        )
    end

    local equipmentParts = {}
    for index = 1, listLength(bonus and bonus.equipmentBonuses) do
        local payload = bonus.equipmentBonuses[index]
        equipmentParts[#equipmentParts + 1] = table.concat({
            ensureString(payload and payload.name),
            ensureString(payload and payload.description),
            ensureString(payload and payload.icon),
        }, ":")
    end

    return table.concat(statParts, ",")
        .. "|"
        .. table.concat(skillParts, ",")
        .. "|"
        .. table.concat(equipmentParts, ",")
end

local function normalizeBonuses(values)
    local normalized = {}

    for index = 1, listLength(values) do
        local source = values[index]
        local entry = type(source) == "table" and source or {}
        normalized[#normalized + 1] = {
            requiredPieces = tonumber(entry.requiredPieces) or 0,
            statBonuses = normalizeBonusList(entry.statBonuses, "statRef", "sourceStatRef"),
            skillBonuses = normalizeBonusList(entry.skillBonuses, "skillRef"),
            equipmentBonuses = normalizeEquipmentBonuses(entry.equipmentBonuses),
        }
    end

    table.sort(normalized, function(left, right)
        local leftRequired = tonumber(left and left.requiredPieces) or 0
        local rightRequired = tonumber(right and right.requiredPieces) or 0
        if leftRequired ~= rightRequired then
            return leftRequired < rightRequired
        end

        return bonusSortKey(left) < bonusSortKey(right)
    end)

    return normalized
end

function ItemSet:New(data)
    return setmetatable({
        id = nil,
        key = "",
        name = "",
        description = "",
        icon = "",
        bonuses = {},
    }, ItemSet):Merge(data)
end

function ItemSet:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        if key ~= "bonuses" then
            self[key] = value
        end
    end

    self.id = self.id ~= nil and ensureString(self.id) or nil
    self.key = trimText(self.key)
    self.name = ensureString(self.name)
    self.description = ensureString(self.description)
    self.icon = ensureString(self.icon)
    local bonusSource = data.bonuses ~= nil and data.bonuses or self.bonuses
    self.bonuses = type(bonusSource) == "table" and normalizeBonuses(bonusSource) or bonusSource
    return self
end

function ItemSet:ToTable()
    local bonuses = type(self.bonuses) == "table" and normalizeBonuses(self.bonuses) or self.bonuses
    local normalized = {
        id = self.id,
        key = trimText(self.key),
        name = ensureString(self.name),
        description = ensureString(self.description),
        icon = ensureString(self.icon),
        bonuses = type(bonuses) == "table" and {} or bonuses,
    }

    if type(bonuses) == "table" then
        for index = 1, #bonuses do
            local bonus = type(bonuses[index]) == "table" and bonuses[index] or {}
            normalized.bonuses[index] = {
                requiredPieces = tonumber(bonus.requiredPieces) or 0,
                statBonuses = normalizeBonusList(bonus.statBonuses, "statRef"),
                skillBonuses = normalizeBonusList(bonus.skillBonuses, "skillRef"),
                equipmentBonuses = normalizeEquipmentBonuses(bonus.equipmentBonuses),
            }
        end
    end

    return normalized
end

function ItemSet.FromTable(data)
    return ItemSet:New(data)
end

function ItemSet.Validate(value)
    local diagnostics = {}
    local itemSet = type(value) == "table" and value or {}
    local key = trimText(itemSet.key)

    if trimText(itemSet.id) == "" then
        diagnostics[#diagnostics + 1] = "Item Set id must be non-empty."
    end

    if key == "" then
        diagnostics[#diagnostics + 1] = "Item Set key must be non-empty."
    elseif string.find(key, ":", 1, true) then
        diagnostics[#diagnostics + 1] = "Item Set key must not contain ':'."
    end

    if itemSet.bonuses ~= nil and type(itemSet.bonuses) ~= "table" then
        diagnostics[#diagnostics + 1] = "Item Set bonuses must be a table."
    end

    local previousRequiredPieces = 0
    local seenThresholds = {}
    for index = 1, listLength(itemSet.bonuses) do
        local bonus = itemSet.bonuses[index]
        local bonusTable = type(bonus) == "table" and bonus or {}
        if type(bonus) ~= "table" then
            diagnostics[#diagnostics + 1] = ("Bonus tier %d must be a table."):format(index)
        end
        local requiredPieces = tonumber(bonusTable.requiredPieces)
        if requiredPieces == nil or requiredPieces <= 0 or requiredPieces ~= math.floor(requiredPieces) then
            diagnostics[#diagnostics + 1] = ("Bonus tier %d must have a positive integer requiredPieces."):format(index)
        elseif seenThresholds[requiredPieces] then
            diagnostics[#diagnostics + 1] = ("Bonus tier %d duplicates requiredPieces %d."):format(index, requiredPieces)
        else
            seenThresholds[requiredPieces] = true
            if requiredPieces < previousRequiredPieces then
                diagnostics[#diagnostics + 1] = "Bonus tiers must be sorted by requiredPieces."
            end
            previousRequiredPieces = requiredPieces
        end

        if bonusTable.statBonuses ~= nil and type(bonusTable.statBonuses) ~= "table" then
            diagnostics[#diagnostics + 1] = ("Bonus tier %d statBonuses must be a table."):format(index)
        end
        if bonusTable.skillBonuses ~= nil and type(bonusTable.skillBonuses) ~= "table" then
            diagnostics[#diagnostics + 1] = ("Bonus tier %d skillBonuses must be a table."):format(index)
        end
        if bonusTable.equipmentBonuses ~= nil and type(bonusTable.equipmentBonuses) ~= "table" then
            diagnostics[#diagnostics + 1] = ("Bonus tier %d equipmentBonuses must be a table."):format(index)
        end

        for equipmentIndex = 1, listLength(bonusTable.equipmentBonuses) do
            local equipmentBonus = bonusTable.equipmentBonuses[equipmentIndex]
            if type(equipmentBonus) ~= "table" then
                diagnostics[#diagnostics + 1] = ("Bonus tier %d equipment bonus %d must be a table."):format(index, equipmentIndex)
            else
                if equipmentBonus.statBonuses ~= nil and type(equipmentBonus.statBonuses) ~= "table" then
                    diagnostics[#diagnostics + 1] = ("Bonus tier %d equipment bonus %d statBonuses must be a table."):format(index, equipmentIndex)
                end
                if equipmentBonus.skillBonuses ~= nil and type(equipmentBonus.skillBonuses) ~= "table" then
                    diagnostics[#diagnostics + 1] = ("Bonus tier %d equipment bonus %d skillBonuses must be a table."):format(index, equipmentIndex)
                end
                for statIndex = 1, listLength(equipmentBonus.statBonuses) do
                    local statBonus = equipmentBonus.statBonuses[statIndex]
                    local statRef = type(statBonus) == "table" and (statBonus.statRef or statBonus.sourceStatRef) or nil
                    if trimText(statRef) == "" then
                        diagnostics[#diagnostics + 1] = ("Bonus tier %d equipment bonus %d stat bonus %d has no statRef."):format(index, equipmentIndex, statIndex)
                    end
                end
                for skillIndex = 1, listLength(equipmentBonus.skillBonuses) do
                    local skillBonus = equipmentBonus.skillBonuses[skillIndex]
                    local skillRef = type(skillBonus) == "table" and skillBonus.skillRef or nil
                    if trimText(skillRef) == "" then
                        diagnostics[#diagnostics + 1] = ("Bonus tier %d equipment bonus %d skill bonus %d has no skillRef."):format(index, equipmentIndex, skillIndex)
                    end
                end
            end
        end

        for statIndex = 1, listLength(bonusTable.statBonuses) do
            local statBonus = bonusTable.statBonuses[statIndex]
            local statRef = type(statBonus) == "table" and statBonus.statRef or nil
            if trimText(statRef) == "" then
                diagnostics[#diagnostics + 1] = ("Bonus tier %d stat bonus %d has no statRef."):format(index, statIndex)
            end
        end

        for skillIndex = 1, listLength(bonusTable.skillBonuses) do
            local skillBonus = bonusTable.skillBonuses[skillIndex]
            local skillRef = type(skillBonus) == "table" and skillBonus.skillRef or nil
            if trimText(skillRef) == "" then
                diagnostics[#diagnostics + 1] = ("Bonus tier %d skill bonus %d has no skillRef."):format(index, skillIndex)
            end
        end
    end

    return #diagnostics == 0, diagnostics
end

Addon.Internal.Database.Classes.ItemSet = ItemSet
