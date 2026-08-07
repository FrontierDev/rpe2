local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Item = {}
Item.__index = Item

local TraitClass = Addon.Internal.Database.Classes.Trait or {}
local ConditionClass = Addon.Internal.Database.Classes.Condition or {}
local Registry = Addon.Internal.Registry or {}

local AUTO_PRICE_QUALITY_MULTIPLIERS = {
    poor = 0.8,
    common = 1.0,
    uncommon = 1.2,
    rare = 1.5,
    epic = 2.0,
    legendary = 3.0,
}

local AUTO_PRICE_BASE_UNITS = {
    none = 25,
    weapon = 90,
    armor = 75,
    consumable = 35,
}

local BINDING_FLAGS = {
    bind_on_pickup = true,
    bind_on_equip = true,
    bind_on_use = true,
}

local CONSUMABLE_TYPES = {
    potion = true,
    flask = true,
    elixir = true,
    scroll = true,
    rune = true,
    enhancement = true,
}

local CONSUMABLE_ELIXIR_TYPES = {
    generic = true,
    battle = true,
    guardian = true,
}

local MODIFICATION_KINDS = {
    generic = true,
    gem = true,
    enchant = true,
}

local SOCKET_TYPE_FLAGS = {
    red = true,
    blue = true,
    yellow = true,
    green = true,
    meta = true,
    cogwheel = true,
    prismatic = true,
}

local SOCKET_COUNT_FIELDS = {
    "redSockets",
    "blueSockets",
    "yellowSockets",
    "greenSockets",
    "metaSockets",
    "cogSockets",
    "prismaticSockets",
}

local function ensureTable(value)
    if type(value) == "table" then
        return value
    end

    return {}
end

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function normalizeRef(value)
    local reference = ensureString(value)
    if reference == "" then
        return nil
    end

    return reference
end

local function filterAllowedSlotRefs(validSlotRefs, allowedSlotRefs)
    local allowedLookup = {}
    for index = 1, #(allowedSlotRefs or {}) do
        local slotRef = ensureString(allowedSlotRefs[index])
        if slotRef ~= "" then
            allowedLookup[slotRef] = true
        end
    end

    if next(allowedLookup) == nil then
        return {}
    end

    local filtered = {}
    for index = 1, #(validSlotRefs or {}) do
        local slotRef = ensureString(validSlotRefs[index])
        if slotRef ~= "" and allowedLookup[slotRef] == true then
            filtered[#filtered + 1] = slotRef
        end
    end

    return filtered
end

local function normalizeItemLevel(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

local function normalizeConsumableType(value)
    local normalized = string.lower(ensureString(value))
    if CONSUMABLE_TYPES[normalized] == true then
        return normalized
    end

    return ""
end

local function normalizeConsumableElixirType(value)
    local normalized = string.lower(ensureString(value))
    if CONSUMABLE_ELIXIR_TYPES[normalized] == true then
        return normalized
    end

    return "generic"
end

local function normalizeItemStats(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local entry = values[index]
        local sourceStatRef = type(entry) == "table" and ensureString(entry.sourceStatRef) or ""
        if sourceStatRef ~= "" then
            normalized[#normalized + 1] = {
                sourceStatRef = sourceStatRef,
                value = tonumber(entry.value) or 0,
            }
        end
    end

    return normalized
end

local function normalizeItemSkillBonuses(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local entry = values[index]
        local skillRef = type(entry) == "table" and ensureString(entry.skillRef) or ""
        if skillRef ~= "" then
            normalized[#normalized + 1] = {
                skillRef = skillRef,
                value = tonumber(entry.value) or 0,
            }
        end
    end

    return normalized
end

local function normalizeStringList(values)
    local normalized = {}

    for index = 1, #(values or {}) do
        local entry = ensureString(values[index])
        if entry ~= "" then
            normalized[#normalized + 1] = entry
        end
    end

    return normalized
end

local function normalizeSocketTypeList(values)
    local normalized = {}
    local seen = {}

    for index = 1, #(values or {}) do
        local entry = string.lower(ensureString(values[index]))
        if SOCKET_TYPE_FLAGS[entry] == true and not seen[entry] then
            normalized[#normalized + 1] = entry
            seen[entry] = true
        end
    end

    return normalized
end

local function normalizeModificationKind(value)
    local normalized = string.lower(ensureString(value))
    if MODIFICATION_KINDS[normalized] == true then
        return normalized
    end

    return "generic"
end

local function normalizeSocketCount(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

local function normalizeGenericModificationCountMap(values)
    local normalized = {}

    for key, value in pairs(type(values) == "table" and values or {}) do
        local normalizedKey = string.lower(ensureString(key))
        if normalizedKey ~= "" then
            normalized[normalizedKey] = math.max(0, math.floor(tonumber(value) or 0))
        end
    end

    return normalized
end

local function appendSocketRows(output, color, count)
    local normalizedColor = string.lower(ensureString(color))
    if SOCKET_TYPE_FLAGS[normalizedColor] ~= true then
        return
    end

    for index = 1, math.max(0, math.floor(tonumber(count) or 0)) do
        output[#output + 1] = {
            color = normalizedColor,
        }
    end
end

local function buildLegacySocketRows(source)
    local rows = {}
    if type(source) ~= "table" then
        return rows
    end

    appendSocketRows(rows, "red", source.redSockets)
    appendSocketRows(rows, "blue", source.blueSockets)
    appendSocketRows(rows, "yellow", source.yellowSockets)
    appendSocketRows(rows, "green", source.greenSockets)
    appendSocketRows(rows, "meta", source.metaSockets)
    appendSocketRows(rows, "cogwheel", source.cogSockets)
    appendSocketRows(rows, "prismatic", source.prismaticSockets)
    return rows
end

local function normalizeSockets(values, legacySource)
    local normalized = {}

    if type(values) == "table" and #values > 0 then
        for index = 1, #values do
            local entry = values[index]
            local color = string.lower(ensureString(type(entry) == "table" and entry.color or entry))
            if SOCKET_TYPE_FLAGS[color] == true then
                normalized[#normalized + 1] = {
                    color = color,
                }
            end
        end
    else
        normalized = buildLegacySocketRows(legacySource)
    end

    return normalized
end

local function countSocketsByColor(sockets)
    local counts = {
        red = 0,
        blue = 0,
        yellow = 0,
        green = 0,
        meta = 0,
        cogwheel = 0,
        prismatic = 0,
    }

    for index = 1, #(sockets or {}) do
        local color = string.lower(ensureString(type(sockets[index]) == "table" and sockets[index].color or nil))
        if counts[color] ~= nil then
            counts[color] = counts[color] + 1
        end
    end

    return counts
end

local function normalizeConsumableTraitPhase(value)
    local phase = string.lower(ensureString(value))
    if phase == "event_end" then
        return "event_end"
    end

    return "event_start"
end

local function normalizeItemTrait(value, includePhase)
    if type(value) ~= "table" then
        return nil
    end

    local payload = TraitClass.NormalizeRuntimePayload and TraitClass.NormalizeRuntimePayload(value) or {
        name = ensureString(value.name),
        description = ensureString(value.description),
        icon = ensureString(value.icon),
        statBonuses = {},
        skillBonuses = {},
        automaticAuras = {},
        events = {},
    }

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

    if includePhase == true then
        payload.phase = normalizeConsumableTraitPhase(value.phase)
    else
        payload.phase = nil
    end
    return payload
end

local function normalizeConsumableTrait(value)
    return normalizeItemTrait(value, true)
end

local function normalizeEquipmentTrait(value)
    return normalizeItemTrait(value, false)
end

local function getAverageDamagePerTurn(item)
    local damageMode = ensureString(item and item.damageMode)
    if damageMode == "range" then
        local minimum = math.max(0, tonumber(item and item.minDamagePerTurn) or 0)
        local maximum = math.max(minimum, tonumber(item and item.maxDamagePerTurn) or 0)
        return (minimum + maximum) * 0.5
    end

    local fixedDamage = math.max(0, tonumber(item and item.damagePerTurn) or 0)
    if fixedDamage > 0 then
        return fixedDamage
    end

    local minimum = math.max(0, tonumber(item and item.minDamagePerTurn) or 0)
    local maximum = math.max(minimum, tonumber(item and item.maxDamagePerTurn) or 0)
    if maximum > 0 then
        return (minimum + maximum) * 0.5
    end

    return 0
end

local function getStatBudget(item)
    local total = 0

    for index = 1, #(item and item.stats or {}) do
        local stat = item.stats[index]
        total = total + math.abs(tonumber(stat and stat.value) or 0)
    end

    return total
end

local function getAutoSellPrice(item)
    if type(item) ~= "table" or item.canSell == false then
        return 0
    end

    local qualityMultiplier = AUTO_PRICE_QUALITY_MULTIPLIERS[ensureString(item.quality)] or 1.0
    local baseUnits = AUTO_PRICE_BASE_UNITS[ensureString(item.itemType)] or AUTO_PRICE_BASE_UNITS.none
    local statBudget = getStatBudget(item)
    local damageBudget = getAverageDamagePerTurn(item)
    local slotBudget = math.max(0, #(item.validSlotRefs or {}) - 1) * 6
    local traitUnits = 0

    if type(item.consumableTrait) == "table" then
        traitUnits = traitUnits + 18
    end

    if type(item.equipmentTrait) == "table" then
        traitUnits = traitUnits + 24
    end

    local priceUnits = baseUnits
        + (statBudget * 8)
        + (damageBudget * 10)
        + slotBudget
        + traitUnits

    if item.isTwoHanded == true then
        priceUnits = priceUnits * 1.2
    end

    local priceCopper = priceUnits * 4 * qualityMultiplier
    return math.max(1, math.floor(priceCopper))
end

local function getBindingFlag(item)
    local bindingFlag = ensureString(type(item) == "table" and item.bindingFlag or nil)
    if bindingFlag == "" then
        return "none"
    end

    return string.lower(bindingFlag)
end

local function getItemLevelCalculator()
    return Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.ItemLevel or nil
end

function Item:New(data)
    return setmetatable({
        id = nil,
        name = "",
        description = "",
        icon = "",
        quality = "common",
        itemSetKey = "",
        uniqueFlag = "none",
        bindingFlag = "none",
        canStack = true,
        maxStackSize = 99,
        canTrade = true,
        canSell = true,
        sellPrice = 0,
        itemLevel = 0,
        canDisenchant = true,
        itemType = "none",
        modificationKind = "generic",
        gemColor = "none",
        genericModificationKey = "",
        targetSlotRefs = {},
        targetWeaponTypeRef = nil,
        targetArmorWeight = "none",
        sockets = {},
        maxGenericModificationCounts = {},
        socketTypes = {},
        redSockets = 0,
        blueSockets = 0,
        yellowSockets = 0,
        greenSockets = 0,
        metaSockets = 0,
        cogSockets = 0,
        prismaticSockets = 0,
        maxModificationCounts = {},
        consumableType = "",
        consumableElixirType = "",
        weaponTypeRef = nil,
        armorWeight = "cosmetic",
        isTwoHanded = false,
        damageMode = "fixed",
        damagePerTurn = 0,
        minDamagePerTurn = 0,
        maxDamagePerTurn = 0,
        damageSchoolRef = nil,
        validSlotRefs = {},
        stats = {},
        skillBonuses = {},
        conditions = {},
        tags = {},
        consumableTrait = nil,
        equipmentTrait = nil,
    }, Item):Merge(data)
end

function Item:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    local previousItemType = ensureString(self.itemType)

    for key, value in pairs(data) do
        if key ~= "stats"
            and key ~= "skillBonuses"
            and key ~= "validSlotRefs"
            and key ~= "targetSlotRefs"
            and key ~= "sockets"
            and key ~= "socketTypes"
            and key ~= "maxGenericModificationCounts"
            and key ~= "maxModificationCounts"
            and key ~= "conditions"
            and key ~= "tags"
            and key ~= "consumableTrait"
            and key ~= "equipmentTrait" then
            self[key] = value
        end
    end

    self.name = ensureString(self.name)
    self.description = ensureString(self.description)
    self.icon = ensureString(self.icon)
    self.quality = ensureString(self.quality)
    self.itemSetKey = ensureString(self.itemSetKey)
    self.uniqueFlag = ensureString(self.uniqueFlag)
    self.bindingFlag = ensureString(self.bindingFlag)
    self.itemLevel = normalizeItemLevel(self.itemLevel)
    self.itemType = ensureString(self.itemType)
    self.modificationKind = normalizeModificationKind(self.modificationKind)
    local requestedGemColor = string.lower(ensureString(data.gemColor ~= nil and data.gemColor or self.gemColor))
    self.gemColor = SOCKET_TYPE_FLAGS[requestedGemColor] == true and requestedGemColor or "none"
    self.genericModificationKey = string.lower(ensureString(self.genericModificationKey)):gsub("^%s+", ""):gsub("%s+$", "")
    self.targetWeaponTypeRef = normalizeRef(self.targetWeaponTypeRef)
    self.targetArmorWeight = ensureString(self.targetArmorWeight)
    local nextConsumableType = self.consumableType
    if data.consumableType ~= nil then
        nextConsumableType = data.consumableType
    end
    self.consumableType = normalizeConsumableType(nextConsumableType)
    local nextConsumableElixirType = self.consumableElixirType
    if data.consumableElixirType ~= nil then
        nextConsumableElixirType = data.consumableElixirType
    end
    if self.consumableType == "elixir" then
        self.consumableElixirType = normalizeConsumableElixirType(nextConsumableElixirType)
    else
        self.consumableElixirType = ""
    end
    self.weaponTypeRef = normalizeRef(self.weaponTypeRef)
    self.armorWeight = ensureString(self.armorWeight)
    self.damageMode = ensureString(self.damageMode)
    self.damageSchoolRef = ensureString(self.damageSchoolRef)
    if self.damageSchoolRef == "" then
        self.damageSchoolRef = nil
    end
    self.validSlotRefs = normalizeStringList(data.validSlotRefs or self.validSlotRefs)
    self.targetSlotRefs = normalizeStringList(data.targetSlotRefs or self.targetSlotRefs)
    self.sockets = normalizeSockets(data.sockets or self.sockets, data)
    self.socketTypes = normalizeSocketTypeList(data.socketTypes or self.socketTypes)
    self.stats = normalizeItemStats(data.stats or self.stats)
    self.skillBonuses = normalizeItemSkillBonuses(data.skillBonuses or self.skillBonuses)
    self.maxGenericModificationCounts = normalizeGenericModificationCountMap(data.maxGenericModificationCounts or data.maxModificationCounts or self.maxGenericModificationCounts or self.maxModificationCounts)
    self.maxModificationCounts = normalizeGenericModificationCountMap(self.maxGenericModificationCounts)
    self.conditions = ConditionClass.NormalizeList and ConditionClass.NormalizeList(data.conditions or self.conditions) or {}
    self.tags = normalizeStringList(data.tags or self.tags)
    self.consumableTrait = normalizeConsumableTrait(data.consumableTrait or self.consumableTrait)
    self.equipmentTrait = normalizeEquipmentTrait(data.equipmentTrait or self.equipmentTrait)
    local socketCounts = countSocketsByColor(self.sockets)
    self.redSockets = socketCounts.red
    self.blueSockets = socketCounts.blue
    self.yellowSockets = socketCounts.yellow
    self.greenSockets = socketCounts.green
    self.metaSockets = socketCounts.meta
    self.cogSockets = socketCounts.cogwheel
    self.prismaticSockets = socketCounts.prismatic
    if self.itemType ~= "consumable" then
        self.consumableType = ""
        self.consumableElixirType = ""
        self.consumableTrait = nil
    end
    if self.itemType ~= "weapon" and self.itemType ~= "armor" then
        self.equipmentTrait = nil
    end
    if self.weaponTypeRef ~= nil and type(Registry.ResolveWeaponTypeReference) == "function" then
        local _, weaponType = Registry:ResolveWeaponTypeReference(self.weaponTypeRef)
        if weaponType ~= nil and self.itemType == "weapon" then
            self.validSlotRefs = filterAllowedSlotRefs(self.validSlotRefs, weaponType.allowedSlotRefs)
        end
    end
    if self.itemType == "modification" then
        if previousItemType ~= "modification" and data.canStack == nil and data.maxStackSize == nil then
            self.canStack = false
            self.maxStackSize = 1
        end
        self.validSlotRefs = {}
        self.sockets = {}
        self.maxGenericModificationCounts = {}
        self.maxModificationCounts = {}
        self.consumableType = ""
        self.consumableElixirType = ""
        self.consumableTrait = nil
        self.equipmentTrait = nil
        if self.modificationKind == "gem" then
            if self.gemColor == "none" and #self.socketTypes > 0 then
                local fallbackColor = string.lower(ensureString(self.socketTypes[1]))
                self.gemColor = SOCKET_TYPE_FLAGS[fallbackColor] == true and fallbackColor or "none"
            end
            self.genericModificationKey = ""
            self.targetSlotRefs = {}
            self.targetWeaponTypeRef = nil
            self.targetArmorWeight = "none"
        elseif self.modificationKind == "enchant" then
            self.gemColor = "none"
            self.genericModificationKey = ""
            self.socketTypes = {}
        else
            self.modificationKind = "generic"
            self.gemColor = "none"
            self.socketTypes = {}
        end
    else
        self.modificationKind = "generic"
        self.gemColor = "none"
        self.genericModificationKey = ""
        self.targetSlotRefs = {}
        self.targetWeaponTypeRef = nil
        self.targetArmorWeight = "none"
        self.socketTypes = {}
        if self.itemType ~= "weapon" and self.itemType ~= "armor" then
            self.sockets = {}
            self.maxGenericModificationCounts = {}
            self.maxModificationCounts = {}
        end
    end

    return self
end

function Item:ToTable()
    return {
        id = self.id,
        name = self.name,
        description = self.description,
        icon = self.icon,
        quality = self.quality,
        itemSetKey = self.itemSetKey,
        uniqueFlag = self.uniqueFlag,
        bindingFlag = self.bindingFlag,
        canStack = self.canStack,
        maxStackSize = self.maxStackSize,
        canTrade = self.canTrade,
        canSell = self.canSell,
        sellPrice = self.sellPrice,
        itemLevel = normalizeItemLevel(self.itemLevel),
        canDisenchant = self.canDisenchant,
        itemType = self.itemType,
        modificationKind = self.itemType == "modification" and self.modificationKind or "generic",
        gemColor = self.itemType == "modification" and self.modificationKind == "gem" and self.gemColor or "none",
        genericModificationKey = self.itemType == "modification" and self.modificationKind == "generic" and self.genericModificationKey or "",
        targetSlotRefs = normalizeStringList(self.targetSlotRefs),
        targetWeaponTypeRef = normalizeRef(self.targetWeaponTypeRef),
        targetArmorWeight = self.targetArmorWeight,
        sockets = normalizeSockets(self.sockets, self),
        socketTypes = self.itemType == "modification" and self.modificationKind == "gem" and self.gemColor ~= "none" and { self.gemColor } or {},
        redSockets = countSocketsByColor(self.sockets).red,
        blueSockets = countSocketsByColor(self.sockets).blue,
        yellowSockets = countSocketsByColor(self.sockets).yellow,
        greenSockets = countSocketsByColor(self.sockets).green,
        metaSockets = countSocketsByColor(self.sockets).meta,
        cogSockets = countSocketsByColor(self.sockets).cogwheel,
        prismaticSockets = countSocketsByColor(self.sockets).prismatic,
        maxGenericModificationCounts = normalizeGenericModificationCountMap(self.maxGenericModificationCounts),
        maxModificationCounts = normalizeGenericModificationCountMap(self.maxGenericModificationCounts),
        consumableType = normalizeConsumableType(self.consumableType),
        consumableElixirType = self.consumableType == "elixir" and normalizeConsumableElixirType(self.consumableElixirType) or "",
        weaponTypeRef = normalizeRef(self.weaponTypeRef),
        armorWeight = self.armorWeight,
        isTwoHanded = self.isTwoHanded,
        damageMode = self.damageMode,
        damagePerTurn = self.damagePerTurn,
        minDamagePerTurn = self.minDamagePerTurn,
        maxDamagePerTurn = self.maxDamagePerTurn,
        damageSchoolRef = self.damageSchoolRef,
        validSlotRefs = normalizeStringList(self.validSlotRefs),
        stats = normalizeItemStats(self.stats),
        skillBonuses = normalizeItemSkillBonuses(self.skillBonuses),
        conditions = ConditionClass.NormalizeList and ConditionClass.NormalizeList(self.conditions) or {},
        tags = normalizeStringList(self.tags),
        consumableTrait = normalizeConsumableTrait(self.consumableTrait),
        equipmentTrait = normalizeEquipmentTrait(self.equipmentTrait),
    }
end

function Item.FromTable(data)
    return Item:New(data)
end

function Item.GetBindingFlag(item)
    return getBindingFlag(item)
end

function Item.IsBindingFlag(item, flag)
    local normalizedFlag = string.lower(ensureString(flag))
    return normalizedFlag ~= "" and getBindingFlag(item) == normalizedFlag
end

function Item.IsBindOnPickup(item)
    return getBindingFlag(item) == "bind_on_pickup"
end

function Item.IsBindOnEquip(item)
    return getBindingFlag(item) == "bind_on_equip"
end

function Item.IsBindOnUse(item)
    return getBindingFlag(item) == "bind_on_use"
end

function Item.HasBindingBehavior(item)
    return BINDING_FLAGS[getBindingFlag(item)] == true
end

function Item.IsItemLevelEligible(item)
    local itemType = ensureString(type(item) == "table" and item.itemType or nil)
    return itemType == "weapon" or itemType == "armor"
end

function Item.CalculateItemLevel(item)
    if not Item.IsItemLevelEligible(item) then
        return 0
    end

    local calculator = getItemLevelCalculator()
    if type(calculator) == "table" and type(calculator.CalculateForItem) == "function" then
        return math.max(0, math.floor(tonumber(calculator.CalculateForItem(item)) or 0))
    end

    return 0
end

function Item.ResolveItemLevel(item)
    if not Item.IsItemLevelEligible(item) then
        return 0
    end

    local manualOverride = normalizeItemLevel(type(item) == "table" and item.itemLevel or 0)
    if manualOverride > 0 then
        return manualOverride
    end

    return Item.CalculateItemLevel(item)
end

function Item.ResolveSellPrice(item)
    local explicitSellPrice = tonumber(type(item) == "table" and item.sellPrice or nil) or 0
    if explicitSellPrice > 0 then
        return math.floor(explicitSellPrice)
    end

    return getAutoSellPrice(item)
end

function Item:GetSellPrice()
    return Item.ResolveSellPrice(self)
end

Addon.Internal.Database.Classes.Item = Item
