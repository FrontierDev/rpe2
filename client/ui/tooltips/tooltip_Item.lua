local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Tooltips = Addon.Client.UI.Tooltips or {}
Addon.Client.Traits = Addon.Client.Traits or {}

local Tooltips = Addon.Client.UI.Tooltips
local Traits = Addon.Client.Traits or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Dependencies = Database and Database.Dependecies or {}
local Runtime = Addon.Internal and Addon.Internal.Runtime or {}
local Ruleset = Addon.Internal and Addon.Internal.Ruleset or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local ItemClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Item or nil
local ModificationService = Profile and Profile.Modifications or {}
local Common = Addon.Utils and Addon.Utils.Common or nil
local TraitClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Trait or nil
local Conditions = Addon.Client and Addon.Client.Conditions or {}
local DescriptionBuilder = Addon.Client
    and Addon.Client.Spellcasting
    and Addon.Client.Spellcasting.DescriptionBuilder
    or {}

local ItemTooltip = Tooltips.Item or {}
Tooltips.Item = ItemTooltip
local ensureString

ensureString = function(value, fallback)
    if value == nil or value == "" then
        return fallback or ""
    end

    return tostring(value)
end

local TOOLTIP_CACHE_VERSION = "item-tooltip-v2"
ItemTooltip.BuildCache = ItemTooltip.BuildCache or {}
ItemTooltip.StaticBuildCache = ItemTooltip.StaticBuildCache or {}
ItemTooltip.DatasetIndexCache = ItemTooltip.DatasetIndexCache or {}
ItemTooltip.BuildCacheHits = math.max(0, math.floor(tonumber(ItemTooltip.BuildCacheHits) or 0))
ItemTooltip.BuildCacheMisses = math.max(0, math.floor(tonumber(ItemTooltip.BuildCacheMisses) or 0))
ItemTooltip.DatasetIndexBuilds = math.max(0, math.floor(tonumber(ItemTooltip.DatasetIndexBuilds) or 0))

local function startTiming(label, thresholdMs, context)
    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Start) == "function" then
        if type(timings.IsEnabled) == "function" and not timings:IsEnabled() then
            return nil
        end
        return timings:Start(label, {
            thresholdMs = thresholdMs,
            context = context,
        })
    end
    return nil
end

local function stopTiming(timer, cardinality)
    if not timer then
        return 0
    end

    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Stop) == "function" then
        local elapsedMs = timings:Stop(timer, { cardinality = cardinality })
        return math.max(0, tonumber(elapsedMs) or 0)
    end

    return 0
end

local function logTooltipBuildHardFailure(elapsedMs, item, cacheHit)
    if tonumber(elapsedMs) == nil or elapsedMs <= 16 then
        return
    end

    local debug = Addon.Debug
    if type(debug) ~= "table" or type(debug.Internal) ~= "function" then
        return
    end

    if type(debug.EnsureInternalLevelEnabled) == "function" then
        debug.EnsureInternalLevelEnabled()
    end

    debug.Internal(
        "HARD FAILURE ItemTooltip:Build took %.2fms [cacheHit=%s,item=%s]",
        elapsedMs,
        cacheHit == true and "true" or "false",
        tostring(item and item.id or "unknown")
    )
end

local function getConfigurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
end

local function getRuntimeRevision(domain, key)
    if type(Runtime) == "table" and type(Runtime.GetRevision) == "function" then
        return math.max(0, math.floor(tonumber(Runtime:GetRevision(domain, key)) or 0))
    end

    return 0
end

local function sortedTableKeys(value)
    local keys = {}
    for key in pairs(value or {}) do
        keys[#keys + 1] = key
    end

    table.sort(keys, function(left, right)
        return tostring(left) < tostring(right)
    end)
    return keys
end

local function stableSerialize(value, seen, nextId)
    local valueType = type(value)
    if valueType == "nil" then
        return "nil"
    end
    if valueType == "boolean" then
        return value and "boolean:true" or "boolean:false"
    end
    if valueType == "number" then
        if value ~= value then
            return "number:nan"
        end
        if value == math.huge then
            return "number:infinity"
        end
        if value == -math.huge then
            return "number:-infinity"
        end
        return "number:" .. tostring(value)
    end
    if valueType == "string" then
        return "string:" .. string.format("%q", value)
    end
    if valueType ~= "table" then
        return valueType .. ":" .. tostring(value)
    end

    seen = seen or {}
    nextId = nextId or { value = 0 }
    if seen[value] then
        return "table-ref:" .. tostring(seen[value])
    end

    nextId.value = nextId.value + 1
    seen[value] = nextId.value
    local parts = {}
    local keys = sortedTableKeys(value)
    for index = 1, #keys do
        local key = keys[index]
        parts[#parts + 1] = stableSerialize(key, seen, nextId)
            .. "="
            .. stableSerialize(value[key], seen, nextId)
    end

    return "table:{" .. table.concat(parts, ";") .. "}"
end

local function getDatasetIndex(datasetId)
    local normalizedDatasetId = ensureString(datasetId)
    if normalizedDatasetId == "" or type(Database.GetDatasetByID) ~= "function" then
        return nil
    end

    local revision = getConfigurationRevision()
    local cached = ItemTooltip.DatasetIndexCache[normalizedDatasetId]
    if type(cached) == "table" and cached.revision == revision then
        return cached
    end

    local dataset = Database.GetDatasetByID(normalizedDatasetId)
    if type(dataset) ~= "table" then
        ItemTooltip.DatasetIndexCache[normalizedDatasetId] = {
            revision = revision,
            dataset = nil,
            itemSlotsById = {},
            statsById = {},
        }
        return ItemTooltip.DatasetIndexCache[normalizedDatasetId]
    end

    local itemSlotsById = {}
    for index = 1, #(dataset.itemSlots or {}) do
        local slot = dataset.itemSlots[index]
        local slotId = ensureString(slot and slot.id)
        if slotId ~= "" then
            itemSlotsById[slotId] = slot
        end
    end

    local statsById = {}
    for index = 1, #(dataset.stats or {}) do
        local stat = dataset.stats[index]
        local statId = ensureString(stat and stat.id)
        if statId ~= "" then
            statsById[statId] = stat
        end
    end

    local index = {
        revision = revision,
        dataset = dataset,
        itemSlotsById = itemSlotsById,
        statsById = statsById,
    }
    ItemTooltip.DatasetIndexCache[normalizedDatasetId] = index
    ItemTooltip.DatasetIndexBuilds = ItemTooltip.DatasetIndexBuilds + 1
    return index
end

local function getDatasetByIdCached(datasetId)
    local datasetIndex = getDatasetIndex(datasetId)
    return datasetIndex and datasetIndex.dataset or nil
end

local function getEventTooltipRevision()
    local client = Addon.Client or {}
    local eventState = type(client.GetEventState) == "function" and client:GetEventState() or nil
    local eventId = math.max(0, math.floor(tonumber(eventState and eventState.id) or 0))
    if eventId <= 0 then
        return "0:0:0"
    end

    local descriptionBucket = type(DescriptionBuilder.EventTooltipContextRevisions) == "table"
        and DescriptionBuilder.EventTooltipContextRevisions[eventId]
        or nil
    local descriptionRevision = math.max(1, math.floor(tonumber(descriptionBucket and descriptionBucket.global) or 1))
    local auraRevision = getRuntimeRevision("AuraRevisionByEventId", eventId)
    local cooldownRevision = getRuntimeRevision("CooldownRevisionByEventId", eventId)
    local spellcastRevision = getRuntimeRevision("SpellcastRevisionByEventId", eventId)

    return table.concat({
        tostring(eventId),
        tostring(descriptionRevision),
        tostring(auraRevision),
        tostring(cooldownRevision),
        tostring(spellcastRevision),
    }, ":")
end

local function getTooltipRuntimeRevisionKey()
    return table.concat({
        tostring(getConfigurationRevision()),
        tostring(getRuntimeRevision("InventoryRevision")),
        tostring(getRuntimeRevision("ProfileStateRevision")),
        tostring(getRuntimeRevision("EquipmentRevision")),
        tostring(getRuntimeRevision("SkillRevision")),
        tostring(getRuntimeRevision("ResolvedProfileRevision")),
        tostring(getRuntimeRevision("EventRuntimeRevision")),
        tostring(math.max(1, math.floor(tonumber(DescriptionBuilder.ProfileTooltipContextRevision) or 1))),
        getEventTooltipRevision(),
    }, "\31")
end

local function getTooltipVariantKey(item, values, runtimeRevisionKey)
    local modifications = values.modifications
    if modifications == nil then
        modifications = item.modifications
    end

    return table.concat({
        TOOLTIP_CACHE_VERSION,
        runtimeRevisionKey or getTooltipRuntimeRevisionKey(),
        tostring(values.datasetId or values.dataset and values.dataset.id or item.datasetId or ""),
        tostring(values.itemId or item.id or ""),
        tostring(values.datasetName or ""),
        tostring(values.itemRef or ""),
        tostring(values.equipmentScope or ""),
        tostring(values.isActive == false),
        tostring(values.isMissing == true),
        tostring(values.soulbound == true),
        tostring(values.quantity or values.stackCount or item.quantity or item.stackCount or ""),
        tostring(values.stackIdentity or item.stackIdentity or ""),
        tostring(item),
        stableSerialize(modifications or {}),
    }, "\31")
end

local function getStaticTooltipVariantKey(item, values)
    local modifications = values.modifications
    if modifications == nil then
        modifications = item.modifications
    end

    return table.concat({
        TOOLTIP_CACHE_VERSION,
        "static",
        tostring(getConfigurationRevision()),
        tostring(values.datasetId or values.dataset and values.dataset.id or item.datasetId or ""),
        tostring(values.itemId or item.id or ""),
        tostring(values.datasetName or ""),
        tostring(values.itemRef or ""),
        tostring(values.equipmentScope or ""),
        tostring(values.isActive == false),
        tostring(values.isMissing == true),
        tostring(values.soulbound == true),
        tostring(values.quantity or values.stackCount or item.quantity or item.stackCount or ""),
        tostring(values.stackIdentity or item.stackIdentity or ""),
        tostring(item),
        stableSerialize(modifications or {}),
    }, "\31")
end

local function finishTooltipBuild(timer, result, item, cacheHit)
    local elapsedMs = stopTiming(timer, {
        cacheHit = cacheHit == true,
        lineCount = math.max(0, math.floor(tonumber(result and result.lines and #result.lines) or 0)),
    })
    logTooltipBuildHardFailure(elapsedMs, item, cacheHit)
    return result
end

local QUALITY_COLORS = {
    poor = { r = 0.62, g = 0.62, b = 0.62 },
    common = { r = 1.0, g = 1.0, b = 1.0 },
    uncommon = { r = 0.12, g = 1.0, b = 0.0 },
    rare = { r = 0.0, g = 0.44, b = 0.87 },
    epic = { r = 0.64, g = 0.21, b = 0.93 },
    legendary = { r = 1.0, g = 0.5, b = 0.0 },
}

local ARMOR_WEIGHT_LABELS = {
    cosmetic = "Cosmetic",
    cloth = "Cloth",
    leather = "Leather",
    mail = "Mail",
    plate = "Plate",
    shield = "Shield",
    light = "Cloth",
    medium = "Leather",
    heavy = "Plate",
}

local ITEM_TYPE_LABELS = {
    consumable = "Consumable",
    tool = "Tool",
    material = "Crafting Reagent",
    modification = "Modification",
    none = "Item",
}

local SOCKET_TYPE_ORDER = {
    "meta",
    "red",
    "blue",
    "yellow",
    "green",
    "cogwheel",
    "prismatic",
}

local SOCKET_TYPE_LABELS = {
    meta = "Meta",
    red = "Red",
    blue = "Blue",
    yellow = "Yellow",
    green = "Green",
    cogwheel = "Cogwheel",
    prismatic = "Prismatic",
}

local SOCKET_LINE_COLORS = {
    meta = { r = 0.64, g = 0.82, b = 1.0 },
    red = { r = 1.0, g = 0.32, b = 0.32 },
    blue = { r = 0.42, g = 0.72, b = 1.0 },
    yellow = { r = 1.0, g = 0.92, b = 0.32 },
    green = { r = 0.38, g = 0.92, b = 0.38 },
    cogwheel = { r = 0.9, g = 0.9, b = 0.9 },
    prismatic = { r = 1.0, g = 1.0, b = 1.0 },
}

local SOCKET_TEXTURES = {
    meta = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Meta",
    red = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Red",
    blue = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Blue",
    yellow = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Yellow",
    green = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Yellow",
    cogwheel = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Cogwheel",
    prismatic = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Meta",
}

local ENCHANT_INLINE_ICON = "|TInterface\\Icons\\Trade_Engraving:12:12|t"
local APPLIED_MOD_GREEN = { r = 0.12, g = 1.0, b = 0.0 }
local EMPTY_SOCKET_TEXT_COLOR = { r = 0.65, g = 0.65, b = 0.65 }

local UNIQUE_FLAG_LABELS = {
    unique_equipped = "Unique-Equipped",
    unique_owned = "Unique",
}

local BINDING_FLAG_LABELS = {
    bind_on_pickup = "Binds when picked up",
    bind_on_equip = "Binds when equipped",
    bind_on_use = "Binds when used",
}

local QUEST_ITEM_TEXT = "Quest Item"

local function getWhiteLineColor()
    return 1, 1, 1
end

local function getQualityColor(quality)
    return QUALITY_COLORS[tostring(quality or "common")] or QUALITY_COLORS.common
end

local function getWeaponTypeLabel(weaponType)
    if type(Registry.ResolveWeaponTypeName) == "function" then
        local resolvedName = Registry:ResolveWeaponTypeName(weaponType)
        if type(resolvedName) == "string" and resolvedName ~= "" and resolvedName ~= "unknown-weapon-type" then
            return resolvedName
        end
    end

    return ensureString(weaponType, "Weapon")
end

local function hasWeaponType(item)
    local weaponTypeRef = ensureString(item and item.weaponTypeRef)
    return weaponTypeRef ~= ""
end

local function getArmorWeightLabel(armorWeight)
    return ARMOR_WEIGHT_LABELS[tostring(armorWeight or "cosmetic")] or ensureString(armorWeight, "Armor")
end

local function getItemTypeLabel(itemType)
    return ITEM_TYPE_LABELS[tostring(itemType or "none")] or ensureString(itemType, "Item")
end

local function appendSpacerLine(lines)
    if type(lines) ~= "table" or #lines == 0 then
        return
    end

    local previousLine = lines[#lines]
    if type(previousLine) == "table" and previousLine.text == " " then
        return
    end

    lines[#lines + 1] = {
        text = " ",
        wrap = false,
    }
end

local function getSocketInlineIcon(socketType)
    local texturePath = SOCKET_TEXTURES[tostring(socketType or "")]
    if type(texturePath) ~= "string" or texturePath == "" then
        return ""
    end

    return ("|T%s:12:12|t"):format(texturePath)
end

local function getItemInlineIcon(item)
    local texturePath = type(item) == "table" and ensureString(item.icon) or ""
    if texturePath == "" then
        return ""
    end

    return ("|T%s:12:12|t"):format(texturePath)
end

local function buildSocketDisplayRows(item, modifications)
    if type(ModificationService.BuildSocketRows) ~= "function"
        or type(ModificationService.ListAppliedModifications) ~= "function"
    then
        return {}, {}, {}
    end

    local socketSlots = type(ModificationService.BuildEffectiveSocketRows) == "function"
        and ModificationService.BuildEffectiveSocketRows(item, modifications)
        or ModificationService.BuildSocketRows(item)
    local applied = ModificationService.ListAppliedModifications(modifications)
    local gemEntries = {}
    local visibleMods = {}
    for index = 1, #applied do
        local entry = applied[index]
        if entry and entry.isGem == true and entry.item then
            gemEntries[#gemEntries + 1] = entry
        elseif entry and entry.isHidden ~= true then
            visibleMods[#visibleMods + 1] = entry
        end
    end

    local assignments = {}
    if type(ModificationService.BuildGemSocketAssignments) == "function" then
        socketSlots, assignments = ModificationService.BuildGemSocketAssignments(item, modifications)
    else
        for index = 1, #gemEntries do
            assignments[index] = gemEntries[index]
        end
    end

    return socketSlots, assignments, visibleMods
end

local function getEquipmentRuleValue(ruleKey, fallback)
    if type(Ruleset.GetActiveRuleset) ~= "function"
        or type(Ruleset.GetRulesetRuleDefinition) ~= "function"
        or type(Ruleset.GetRulesetRuleValue) ~= "function"
    then
        return fallback
    end

    local activeRuleset = Ruleset.GetActiveRuleset()
    local ruleDefinition = Ruleset.GetRulesetRuleDefinition("interface", ruleKey)
    local value = Ruleset.GetRulesetRuleValue(activeRuleset, "interface", ruleDefinition)
    if value == nil or value == "" then
        return fallback
    end

    return value
end

local function resolveSlotName(slotRef)
    if type(slotRef) ~= "string" or slotRef == "" then
        return nil
    end

    local datasetId, slotId = nil, nil
    if Dependencies and Dependencies.ParseSourceStatRef then
        datasetId, slotId = Dependencies.ParseSourceStatRef(slotRef)
    end

    local datasetIndex = getDatasetIndex(datasetId)
    if type(datasetIndex) ~= "table" then
        return nil
    end

    local slot = datasetIndex.itemSlotsById and datasetIndex.itemSlotsById[tostring(slotId)] or nil
    if slot then
        return ensureString(slot.name, slot.id)
    end

    return nil
end

local function resolvePrimarySlotName(item)
    local slotRefs = item and item.validSlotRefs or nil
    if type(slotRefs) ~= "table" then
        return nil
    end

    for index = 1, #slotRefs do
        local slotName = resolveSlotName(slotRefs[index])
        if slotName and slotName ~= "" then
            return slotName
        end
    end

    return nil
end

local function resolvePrimarySlotKey(item)
    local slotRefs = item and item.validSlotRefs or nil
    if type(slotRefs) ~= "table" then
        return nil
    end

    for index = 1, #slotRefs do
        local slotRef = slotRefs[index]
        local slotName = resolveSlotName(slotRef)
        if slotName and slotName ~= "" then
            local normalized = string.lower(slotName):gsub("[_%-%s]", "")
            if normalized ~= "" then
                return normalized
            end
        end
    end

    return nil
end

local function isRangedWeapon(item)
    return resolvePrimarySlotKey(item) == "ranged"
end

local function getWeaponHandlingLabel(item)
    if isRangedWeapon(item) then
        return "Ranged"
    end

    if item and item.isTwoHanded then
        return "Two Hand"
    end

    return "One Hand"
end

local function buildWeaponCategoryLine(item)
    local colorR, colorG, colorB = getWhiteLineColor()
    if not hasWeaponType(item) then
        return {
            text = ("Held in %s"):format(resolvePrimarySlotName(item) or "Hand"),
            r = colorR,
            g = colorG,
            b = colorB,
            wrap = false,
        }
    end

    return {
        left = getWeaponHandlingLabel(item),
        right = getWeaponTypeLabel(item.weaponTypeRef),
        r = colorR,
        g = colorG,
        b = colorB,
        wrap = false,
    }
end

local function buildArmorCategoryLine(item)
    local colorR, colorG, colorB = getWhiteLineColor()
    local armorWeight = tostring(item and item.armorWeight or "cosmetic")
    local slotName = resolvePrimarySlotName(item) or "Armor"
    if armorWeight == "cosmetic" then
        return {
            text = slotName,
            r = colorR,
            g = colorG,
            b = colorB,
            wrap = false,
        }
    end

    return {
        left = slotName,
        right = getArmorWeightLabel(armorWeight),
        r = colorR,
        g = colorG,
        b = colorB,
        wrap = false,
    }
end

local function buildDamageLine(item)
    if not hasWeaponType(item) then
        return nil
    end

    local mode = tostring(item and item.damageMode or "fixed")
    if mode == "none" then
        return nil
    end

    if mode == "range" then
        local minDamage = math.floor(tonumber(item and item.minDamagePerTurn) or 0)
        local maxDamage = math.floor(tonumber(item and item.maxDamagePerTurn) or 0)
        local colorR, colorG, colorB = getWhiteLineColor()
        return {
            left = ("%d - %d damage"):format(minDamage, maxDamage),
            right = "",
            r = colorR,
            g = colorG,
            b = colorB,
            wrap = false,
        }
    end

    local damage = math.floor(tonumber(item and item.damagePerTurn) or 0)
    local colorR, colorG, colorB = getWhiteLineColor()
    return {
        left = ("%d damage"):format(damage),
        right = "",
        r = colorR,
        g = colorG,
        b = colorB,
        wrap = false,
    }
end

local function appendItemLevelLine(lines, item)
    if type(item) ~= "table"
        or type(ItemClass) ~= "table"
        or type(ItemClass.IsItemLevelEligible) ~= "function"
        or type(ItemClass.ResolveItemLevel) ~= "function"
    then
        return
    end

    if getEquipmentRuleValue("use_item_level", true) ~= true or not ItemClass.IsItemLevelEligible(item) then
        return
    end

    local resolvedItemLevel = math.max(0, math.floor(tonumber(ItemClass.ResolveItemLevel(item)) or 0))
    if resolvedItemLevel <= 0 then
        return
    end

    lines[#lines + 1] = {
        text = ("Item Level %d"):format(resolvedItemLevel),
        r = 1,
        g = 1,
        b = 0,
        wrap = false,
    }
end

local function resolveStatDefinition(sourceStatRef)
    if type(sourceStatRef) ~= "string" or sourceStatRef == "" then
        return nil, nil
    end

    local datasetId, statId = nil, nil
    if Dependencies and Dependencies.ParseSourceStatRef then
        datasetId, statId = Dependencies.ParseSourceStatRef(sourceStatRef)
    end

    if not datasetId or not statId then
        return nil, statId or sourceStatRef
    end

    local datasetIndex = getDatasetIndex(datasetId)
    if type(datasetIndex) ~= "table" then
        return nil, statId
    end

    return datasetIndex.statsById and datasetIndex.statsById[tostring(statId)] or nil, statId
end

local function resolveStatLabel(sourceStatRef)
    local stat, fallback = resolveStatDefinition(sourceStatRef)
    if stat then
        return ensureString(stat.name, "Unnamed Stat")
    end

    return fallback
end

local function resolveEquipStatLabel(sourceStatRef)
    local label = resolveStatLabel(sourceStatRef)
    if type(label) ~= "string" then
        return label
    end

    return string.lower(label)
end

local function resolveSkillLabel(skillRef)
    if type(skillRef) ~= "string" or skillRef == "" then
        return "Unnamed Skill"
    end

    if type(Registry.ResolveSkillName) == "function" then
        local resolvedName = Registry:ResolveSkillName(skillRef)
        if type(resolvedName) == "string" and resolvedName ~= "" then
            return resolvedName
        end
    end

    local _, skillId = nil, nil
    if Dependencies and Dependencies.ParseSourceStatRef then
        _, skillId = Dependencies.ParseSourceStatRef(skillRef)
    end

    return ensureString(skillId or skillRef, "Unnamed Skill")
end

local function normalizeEquipmentTrait(value)
    if type(value) ~= "table" then
        return nil
    end

    local payload = TraitClass and TraitClass.NormalizeRuntimePayload and TraitClass.NormalizeRuntimePayload(value) or value
    local hasContent = ensureString(payload and payload.name) ~= ""
        or ensureString(payload and payload.description) ~= ""
        or ensureString(payload and payload.icon) ~= ""
        or #((payload and payload.statBonuses) or {}) > 0
        or #((payload and payload.skillBonuses) or {}) > 0
        or #((payload and payload.automaticAuras) or {}) > 0
        or #((payload and payload.events) or {}) > 0
    if not hasContent then
        return nil
    end

    payload.phase = nil
    return payload
end

local function normalizeConsumableTrait(value)
    if type(value) ~= "table" then
        return nil
    end

    local payload = TraitClass and TraitClass.NormalizeRuntimePayload and TraitClass.NormalizeRuntimePayload(value) or value
    local hasContent = ensureString(payload and payload.description) ~= ""
        or #((payload and payload.statBonuses) or {}) > 0
        or #((payload and payload.skillBonuses) or {}) > 0
        or #((payload and payload.automaticAuras) or {}) > 0
        or #((payload and payload.events) or {}) > 0
    if not hasContent then
        return nil
    end

    return payload
end

local function formatSummaryCount(count, singular)
    local numericCount = math.max(0, math.floor(tonumber(count) or 0))
    return ("%d %s%s"):format(numericCount, singular, numericCount == 1 and "" or "s")
end

local function getTraitSummaryText(payload)
    if type(payload) ~= "table" then
        return "No effects"
    end

    local parts = {}
    local statBonusCount = #(payload.statBonuses or {})
    local skillBonusCount = #(payload.skillBonuses or {})
    local automaticAuraCount = #(payload.automaticAuras or {})
    local eventCount = #(payload.events or {})

    if statBonusCount > 0 then
        parts[#parts + 1] = formatSummaryCount(statBonusCount, "stat bonus")
    end
    if skillBonusCount > 0 then
        parts[#parts + 1] = formatSummaryCount(skillBonusCount, "skill bonus")
    end
    if automaticAuraCount > 0 then
        parts[#parts + 1] = formatSummaryCount(automaticAuraCount, "aura")
    end
    if eventCount > 0 then
        parts[#parts + 1] = formatSummaryCount(eventCount, "event")
    end

    return #parts > 0 and table.concat(parts, ", ") or "No effects"
end

local function getEquipmentTraitDescription(item, payload, options)
    if type(payload) ~= "table" then
        return ""
    end

    local authoredDescription = ensureString(payload.description)
    if authoredDescription ~= "" then
        return authoredDescription
    end

    local descriptionBuilder = Traits and Traits.DescriptionBuilder or nil
    if type(descriptionBuilder) == "table" and type(descriptionBuilder.BuildDescription) == "function" then
        local tooltipOptions = options or {}
        local dataset = tooltipOptions.dataset
        local detailName = ensureString(payload.name)
        if detailName == "" then
            detailName = ensureString(item and item.name) ~= "" and ensureString(item and item.name) or "Equipment Trait"
        end
        if not dataset and ensureString(tooltipOptions.datasetId) ~= "" then
            dataset = getDatasetByIdCached(tooltipOptions.datasetId)
        end

        local descriptionText = descriptionBuilder:BuildDescription({
            sourceType = "equipment",
            category = "equipment",
            name = detailName,
            item = item,
            itemName = ensureString(item and item.name, ""),
            payload = payload,
            traitPayload = payload,
            authoredDescriptionText = "",
            summaryText = getTraitSummaryText(payload),
            dataset = dataset,
            datasetId = tooltipOptions.datasetId or (dataset and dataset.id) or nil,
        }, {
            deferGeneration = false,
        })
        descriptionText = ensureString(descriptionText)
        if descriptionText ~= "" then
            return descriptionText
        end
    end

    return getTraitSummaryText(payload)
end

local function buildFormattedStatText(value, label, statDefinition)
    local displayMode = statDefinition and tostring(statDefinition.displayMode or "signed_value") or "signed_value"
    if displayMode == "value" then
        return ("%g %s"):format(value, label)
    end

    if displayMode == "signed_percent" or displayMode == "equip_percent" then
        return ("%+g%% %s"):format(value, label)
    end

    return ("%+g %s"):format(value, label)
end

local function appendEquipLine(lines, item, options)
    local itemType = tostring(item and item.itemType or "none")
    if itemType ~= "weapon" and itemType ~= "armor" and itemType ~= "modification" then
        return
    end

    local equipmentTrait = normalizeEquipmentTrait(item and item.equipmentTrait)
    if not equipmentTrait then
        return
    end

    local description = getEquipmentTraitDescription(item, equipmentTrait, options)
    if description == "" then
        return
    end

    lines[#lines + 1] = {
        text = ("Equip: %s"):format(description),
        r = 0.12,
        g = 1.0,
        b = 0.0,
        wrap = true,
    }
end

local function getConsumableTraitDescription(item, payload, options)
    if type(payload) ~= "table" then
        return ""
    end

    local authoredDescription = ensureString(payload.description)
    if authoredDescription ~= "" then
        return authoredDescription
    end

    local descriptionBuilder = Traits and Traits.DescriptionBuilder or nil
    if type(descriptionBuilder) == "table" and type(descriptionBuilder.BuildDescription) == "function" then
        local tooltipOptions = options or {}
        local dataset = tooltipOptions.dataset
        if not dataset and ensureString(tooltipOptions.datasetId) ~= "" then
            dataset = getDatasetByIdCached(tooltipOptions.datasetId)
        end

        local descriptionText = descriptionBuilder:BuildDescription({
            sourceType = "consumable",
            category = "consumable",
            name = ensureString(item and item.name, "Consumable"),
            item = item,
            itemName = ensureString(item and item.name, ""),
            payload = payload,
            consumableTrait = payload,
            authoredDescriptionText = "",
            summaryText = getTraitSummaryText(payload),
            dataset = dataset,
            datasetId = tooltipOptions.datasetId or (dataset and dataset.id) or nil,
        }, {
            deferGeneration = false,
        })
        descriptionText = ensureString(descriptionText)
        if descriptionText ~= "" then
            return descriptionText
        end
    end

    return getTraitSummaryText(payload)
end

local function appendUseLine(lines, item, options)
    if type(item) ~= "table" or tostring(item.itemType or "none") ~= "consumable" then
        return
    end

    local consumableTrait = normalizeConsumableTrait(item.consumableTrait)
    if not consumableTrait then
        return
    end

    local description = getConsumableTraitDescription(item, consumableTrait, options)
    if description == "" then
        return
    end

    lines[#lines + 1] = {
        text = ("Use: %s"):format(description),
        r = 0.12,
        g = 1.0,
        b = 0.0,
        wrap = true,
    }
end

local function getStatLineColor(statDefinition)
    local color = statDefinition and statDefinition.color or nil
    if type(color) ~= "table" then
        return 1, 1, 1
    end

    return color.r or 1, color.g or 1, color.b or 1
end

local function getStatPriority(statDefinition)
    return math.floor(tonumber(statDefinition and statDefinition.priority) or 0)
end

local function buildItemStatLines(item)
    if type(item) ~= "table" or type(item.stats) ~= "table" then
        return {}
    end

    local statLines = {}
    for index = 1, #item.stats do
        local entry = item.stats[index]
        if type(entry) == "table" then
            local value = tonumber(entry.value) or 0
            if value ~= 0 then
                local statDefinition = nil
                local fallbackLabel = nil
                statDefinition, fallbackLabel = resolveStatDefinition(entry.sourceStatRef)
                local displayMode = statDefinition and tostring(statDefinition.displayMode or "signed_value") or "signed_value"
                
                -- Skip equip display modes, they're rendered separately
                if displayMode ~= "equip" and displayMode ~= "equip_percent" then
                    local label = resolveStatLabel(entry.sourceStatRef) or fallbackLabel or "Stat"
                    local colorR, colorG, colorB = getStatLineColor(statDefinition)
                    statLines[#statLines + 1] = {
                        sortIndex = index,
                        priority = getStatPriority(statDefinition),
                        line = {
                            text = buildFormattedStatText(value, label, statDefinition),
                            r = colorR,
                            g = colorG,
                            b = colorB,
                            wrap = false,
                        },
                    }
                end
            end
        end
    end

    table.sort(statLines, function(left, right)
        if left.priority == right.priority then
            return left.sortIndex < right.sortIndex
        end

        return left.priority > right.priority
    end)

    local rows = {}
    for index = 1, #statLines do
        rows[#rows + 1] = statLines[index].line
    end

    return rows
end

local function buildWhiteItemStatLines(item)
    local rows = buildItemStatLines(item)
    for index = 1, #rows do
        rows[index] = {
            text = rows[index].text,
            r = 1,
            g = 1,
            b = 1,
            wrap = rows[index].wrap,
        }
    end
    return rows
end

local function buildModificationEquipValueText(value, statDefinition)
    local displayMode = statDefinition and tostring(statDefinition.displayMode or "signed_value") or "signed_value"
    local amount = math.abs(tonumber(value) or 0)
    if displayMode == "signed_percent" or displayMode == "equip_percent" then
        return (value > 0 and ("%+g%%"):format(value) or ("%g%%"):format(amount))
    end
    if displayMode == "value" or displayMode == "equip" then
        return ("%g"):format(amount)
    end
    return value > 0 and ("%+g"):format(value) or ("%g"):format(amount)
end

local function appendModificationEquipStatLines(lines, item)
    if type(item) ~= "table" or type(item.stats) ~= "table" then
        return
    end

    local equipStatLines = {}
    
    for index = 1, #item.stats do
        local entry = item.stats[index]
        local value = type(entry) == "table" and tonumber(entry.value) or 0
        if value and value ~= 0 then
            local statDefinition = nil
            local fallbackLabel = nil
            statDefinition, fallbackLabel = resolveStatDefinition(entry.sourceStatRef)
            local displayMode = statDefinition and tostring(statDefinition.displayMode or "signed_value") or "signed_value"
            local label = resolveEquipStatLabel(entry.sourceStatRef) or fallbackLabel or "stat"
            local colorR, colorG, colorB = getStatLineColor(statDefinition)
            local verb = value > 0 and "Increases" or "Reduces"
            local amount = math.abs(value)
            
            -- Format based on display mode
            local valueText = nil
            if displayMode == "signed_percent" or displayMode == "equip_percent" then
                valueText = ("%g%%"):format(amount)
            else
                valueText = ("%g"):format(amount)
            end
            
            equipStatLines[#equipStatLines + 1] = {
                sortIndex = index,
                priority = getStatPriority(statDefinition),
                line = {
                    text = ("Equip: %s %s by %s."):format(verb, label, valueText),
                    r = colorR,
                    g = colorG,
                    b = colorB,
                    wrap = true,
                },
            }
        end
    end

    table.sort(equipStatLines, function(left, right)
        if left.priority == right.priority then
            return left.sortIndex < right.sortIndex
        end
        return left.priority > right.priority
    end)

    for index = 1, #equipStatLines do
        lines[#lines + 1] = equipStatLines[index].line
    end
end

local function appendStatLines(lines, item)
    local statLines = buildItemStatLines(item)
    for index = 1, #statLines do
        lines[#lines + 1] = statLines[index]
    end
end

local function appendEquipStatLines(lines, item)
    if type(item) ~= "table" or type(item.stats) ~= "table" then
        return
    end

    local equipStatLines = {}
    for index = 1, #item.stats do
        local entry = item.stats[index]
        if type(entry) == "table" then
            local value = tonumber(entry.value) or 0
            if value ~= 0 then
                local statDefinition = nil
                local fallbackLabel = nil
                statDefinition, fallbackLabel = resolveStatDefinition(entry.sourceStatRef)
                local displayMode = statDefinition and tostring(statDefinition.displayMode or "signed_value") or "signed_value"
                
                if displayMode == "equip" or displayMode == "equip_percent" then
                    local label = resolveEquipStatLabel(entry.sourceStatRef) or fallbackLabel or "stat"
                    local verb = value > 0 and "Increases" or "Reduces"
                    local amount = math.abs(value)
                    local valueText = nil
                    
                    if displayMode == "equip_percent" then
                        valueText = ("%g%%"):format(amount)
                    else
                        valueText = ("%g"):format(amount)
                    end
                    
                    local colorR, colorG, colorB = getStatLineColor(statDefinition)
                    equipStatLines[#equipStatLines + 1] = {
                        sortIndex = index,
                        priority = getStatPriority(statDefinition),
                        line = {
                            text = ("Equip: %s %s by %s."):format(verb, label, valueText),
                            r = colorR,
                            g = colorG,
                            b = colorB,
                            wrap = true,
                        },
                    }
                end
            end
        end
    end

    table.sort(equipStatLines, function(left, right)
        if left.priority == right.priority then
            return left.sortIndex < right.sortIndex
        end

        return left.priority > right.priority
    end)

    for index = 1, #equipStatLines do
        lines[#lines + 1] = equipStatLines[index].line
    end
end

local function appendSkillBonusLines(lines, item)
    if type(item) ~= "table" or type(item.skillBonuses) ~= "table" then
        return
    end

    for index = 1, #item.skillBonuses do
        local entry = item.skillBonuses[index]
        local amount = type(entry) == "table" and tonumber(entry.value) or 0
        local skillName = type(entry) == "table" and resolveSkillLabel(entry.skillRef) or "Unnamed Skill"
        if amount and amount ~= 0 then
            local text = nil
            if amount > 0 then
                text = ("Equip: Increases your skill in %s by %d."):format(skillName, math.abs(amount))
            else
                text = ("Equip: Reduces your skill in %s by %d."):format(skillName, math.abs(amount))
            end

            lines[#lines + 1] = {
                text = text,
                r = 0.12,
                g = 1.0,
                b = 0.0,
                wrap = true,
            }
        end
    end
end

local function appendAppliedModificationLines(lines, item, options)
    if type(item) ~= "table" then
        return
    end

    local itemType = tostring(item.itemType or "none")
    if itemType ~= "weapon" and itemType ~= "armor" then
        return
    end

    local socketRows, assignments, visibleMods = buildSocketDisplayRows(item, options and options.modifications)
    local enchantMods = {}
    local genericMods = {}

    for index = 1, #visibleMods do
        local entry = visibleMods[index]
        if entry and entry.modificationKind == "enchant" then
            enchantMods[#enchantMods + 1] = entry
        else
            genericMods[#genericMods + 1] = entry
        end
    end

    if #socketRows > 0 then
        appendSpacerLine(lines)
        for index = 1, #socketRows do
            local socket = socketRows[index]
            local assigned = assignments[index]
            local socketColor = tostring(socket and socket.color or "prismatic")

            if assigned and assigned.item then
                local gemStatLines = buildItemStatLines(assigned.item)
                local gemIcon = getItemInlineIcon(assigned.item)
                if #gemStatLines > 0 then
                    for statIndex = 1, #gemStatLines do
                        local line = gemStatLines[statIndex]
                        if statIndex == 1 then
                            line = {
                                text = ("%s %s"):format(gemIcon, ensureString(line.text)),
                                r = line.r,
                                g = line.g,
                                b = line.b,
                                wrap = line.wrap,
                            }
                        end
                        line.r = 1
                        line.g = 1
                        line.b = 1
                        lines[#lines + 1] = line
                    end
                else
                    lines[#lines + 1] = {
                        text = ("%s %s"):format(gemIcon, ensureString(assigned.item.name, assigned.itemId or "Gem")),
                        r = 1,
                        g = 1,
                        b = 1,
                        wrap = false,
                    }
                end
            else
                local socketLabel = SOCKET_TYPE_LABELS[socketColor] or "Socket"
                lines[#lines + 1] = {
                    text = ("%s %s Socket"):format(getSocketInlineIcon(socketColor), socketLabel),
                    r = EMPTY_SOCKET_TEXT_COLOR.r,
                    g = EMPTY_SOCKET_TEXT_COLOR.g,
                    b = EMPTY_SOCKET_TEXT_COLOR.b,
                    wrap = false,
                }
            end
        end
    end

    if #enchantMods > 0 then
        appendSpacerLine(lines)
    end
    for index = 1, #enchantMods do
        local entry = enchantMods[index]
        local modItem = entry and entry.item or nil
        if modItem then
            local iconText = getItemInlineIcon(modItem)
            local qualityColor = getQualityColor(modItem.quality)
            if iconText == "" then
                iconText = ENCHANT_INLINE_ICON
            end
            lines[#lines + 1] = {
                text = ("%s %s"):format(iconText, ensureString(modItem.name, entry.itemId or "Modification")),
                r = qualityColor.r or 1,
                g = qualityColor.g or 1,
                b = qualityColor.b or 1,
                wrap = false,
            }
        end
    end

    if #genericMods > 0 then
        appendSpacerLine(lines)
    end
    local groupedGenericMods = {}
    local orderedGenericMods = {}
    for index = 1, #genericMods do
        local entry = genericMods[index]
        local groupKey = ensureString(entry and entry.itemRef, ensureString(entry and entry.itemId, tostring(index)))
        local bucket = groupedGenericMods[groupKey]
        if not bucket then
            bucket = {
                entry = entry,
                count = 0,
            }
            groupedGenericMods[groupKey] = bucket
            orderedGenericMods[#orderedGenericMods + 1] = bucket
        end
        bucket.count = bucket.count + 1
    end
    for index = 1, #orderedGenericMods do
        local bucket = orderedGenericMods[index]
        local entry = bucket.entry
        local modItem = entry and entry.item or nil
        if modItem then
            local qualityColor = getQualityColor(modItem.quality)
            local displayName = ensureString(modItem.name, entry.itemId or "Modification")
            if bucket.count > 1 then
                displayName = ("%s (%d)"):format(displayName, bucket.count)
            end
            lines[#lines + 1] = {
                text = ("%s %s"):format(ENCHANT_INLINE_ICON, displayName),
                r = qualityColor.r or 0.12,
                g = qualityColor.g or 1,
                b = qualityColor.b or 0.82,
                wrap = false,
            }
        end
    end
end

local function hasRenderedStatLines(item)
    if type(item) ~= "table" or type(item.stats) ~= "table" then
        return false
    end

    for index = 1, #item.stats do
        local entry = item.stats[index]
        if type(entry) == "table" and (tonumber(entry.value) or 0) ~= 0 then
            return true
        end
    end

    return false
end

local function hasRenderedSkillBonusLines(item)
    if type(item) ~= "table" or type(item.skillBonuses) ~= "table" then
        return false
    end

    for index = 1, #item.skillBonuses do
        local entry = item.skillBonuses[index]
        if type(entry) == "table" and (tonumber(entry.value) or 0) ~= 0 then
            return true
        end
    end

    return false
end

local function hasRenderedEquipText(item, options)
    local itemType = tostring(item and item.itemType or "none")
    if itemType ~= "weapon" and itemType ~= "armor" and itemType ~= "modification" then
        return false
    end

    local equipmentTrait = normalizeEquipmentTrait(item and item.equipmentTrait)
    if not equipmentTrait then
        return false
    end

    return getEquipmentTraitDescription(item, equipmentTrait, options) ~= ""
end

local function joinLabels(labels)
    if type(labels) ~= "table" or #labels == 0 then
        return ""
    end
    if #labels == 1 then
        return labels[1]
    end
    if #labels == 2 then
        return labels[1] .. " and " .. labels[2]
    end

    local buffer = {}
    for index = 1, #labels - 1 do
        buffer[#buffer + 1] = labels[index]
    end
    return table.concat(buffer, ", ") .. ", and " .. labels[#labels]
end

local function joinTargetLabels(labels, suffix)
    local joined = joinLabels(labels)
    if joined == "" then
        return ""
    end
    if suffix == nil or suffix == "" then
        return joined
    end
    return joined .. " " .. suffix
end

local function normalizeSlotTargetLabel(slotName)
    local normalized = string.lower(ensureString(slotName))
    if normalized == "" then
        return nil
    end

    local labels = {
        mainhand = "main-hand",
        offhand = "off-hand",
        onehand = "one-handed",
        twohand = "two-handed",
    }

    local key = normalized:gsub("[_%-%s]", "")
    return labels[key] or normalized
end

local function buildPluralTargetLabel(baseLabel, suffix)
    local normalizedBase = ensureString(baseLabel)
    if normalizedBase == "" then
        return ""
    end
    if suffix ~= nil and suffix ~= "" then
        return normalizedBase .. " " .. suffix
    end
    if string.sub(normalizedBase, -1) == "s" then
        return normalizedBase
    end
    return normalizedBase .. "s"
end

local function buildModificationApplicationDescription(item)
    if type(item) ~= "table" or tostring(item.itemType or "none") ~= "modification" then
        return nil
    end

    local modificationKind = type(ModificationService.GetModificationKind) == "function" and ModificationService.GetModificationKind(item) or "generic"
    if modificationKind == "gem" then
        local gemColor = type(ModificationService.GetGemColor) == "function" and ModificationService.GetGemColor(item) or "none"
        if gemColor ~= "none" then
            return ("Can be applied to a %s socket."):format(string.lower(gemColor))
        end
        return "Can be applied to a socket."
    end

    local slotTargets = {}
    local seen = {}
    for index = 1, #(item.targetSlotRefs or {}) do
        local slotName = resolveSlotName(item.targetSlotRefs[index])
        if slotName and slotName ~= "" then
            local label = normalizeSlotTargetLabel(slotName)
            local key = string.lower(label or "")
            if not seen[key] then
                seen[key] = true
                slotTargets[#slotTargets + 1] = label
            end
        end
    end

    local targetWeaponType = tostring(item.targetWeaponTypeRef or "")
    local targetArmorWeight = tostring(item.targetArmorWeight or "none")
    local targetTwoHandedOnly = item.targetTwoHandedOnly == true
    local weaponLabel = nil
    local armorLabel = nil

    if targetWeaponType ~= "" then
        weaponLabel = string.lower(getWeaponTypeLabel(targetWeaponType))
        if targetTwoHandedOnly then
            weaponLabel = "two-handed " .. weaponLabel
        end
    elseif targetTwoHandedOnly then
        weaponLabel = "two-handed weapon"
    end

    if targetArmorWeight ~= "" and targetArmorWeight ~= "none" then
        armorLabel = string.lower(getArmorWeightLabel(targetArmorWeight))
    end

    if armorLabel == "shield" then
        return "Can be applied to shields."
    end

    local targetPhrase = nil
    if weaponLabel then
        if #slotTargets > 0 then
            targetPhrase = joinTargetLabels(slotTargets, buildPluralTargetLabel(weaponLabel))
        else
            targetPhrase = buildPluralTargetLabel(weaponLabel)
        end
    elseif armorLabel then
        if #slotTargets > 0 then
            targetPhrase = joinTargetLabels(slotTargets, armorLabel .. " armor")
        else
            targetPhrase = armorLabel .. " armor"
        end
    elseif #slotTargets > 0 then
        targetPhrase = joinTargetLabels(slotTargets, "items")
    end

    if not targetPhrase or targetPhrase == "" then
        return "Can be applied to equipment."
    end
    return ("Can be applied to %s."):format(targetPhrase)
end

local function appendDescriptionLine(lines, item)
    local descriptionLines = {}
    local applicationDescription = buildModificationApplicationDescription(item)
    if type(applicationDescription) == "string" and applicationDescription ~= "" then
        descriptionLines[#descriptionLines + 1] = applicationDescription
    end

    local itemDescription = type(item) == "table" and ensureString(item.description) or ""
    if itemDescription ~= "" and #descriptionLines == 0 then
        descriptionLines[#descriptionLines + 1] = itemDescription
    end

    if #descriptionLines == 0 then
        return
    end

    appendSpacerLine(lines)
    for index = 1, #descriptionLines do
        lines[#lines + 1] = {
            text = ("*%s*"):format(descriptionLines[index]),
            r = 1,
            g = 0.82,
            b = 0,
            wrap = true,
        }
    end
end

local function appendSoulboundLine(lines, options)
    if type(options) ~= "table" or options.soulbound ~= true then
        return
    end

    lines[#lines + 1] = {
        text = "Soulbound",
        r = 1,
        g = 1,
        b = 1,
        wrap = false,
    }
end

local function appendBindingLine(lines, item, options)
    if type(item) ~= "table" then
        return
    end

    if type(options) == "table" and options.soulbound == true then
        return
    end

    local bindingText = BINDING_FLAG_LABELS[tostring(item.bindingFlag or "none")]
    if not bindingText or bindingText == "" then
        return
    end

    lines[#lines + 1] = {
        text = bindingText,
        r = 1,
        g = 1,
        b = 1,
        wrap = false,
    }
end

local function appendQuestItemLine(lines, item)
    if type(item) ~= "table" or tostring(item.bindingFlag or "none") ~= "quest_item" then
        return
    end

    lines[#lines + 1] = {
        text = QUEST_ITEM_TEXT,
        r = 1,
        g = 1,
        b = 1,
        wrap = false,
    }
end

local function appendUniqueLine(lines, item)
    if type(item) ~= "table" then
        return
    end

    local uniqueText = UNIQUE_FLAG_LABELS[tostring(item.uniqueFlag or "none")]
    if not uniqueText or uniqueText == "" then
        return
    end

    lines[#lines + 1] = {
        text = uniqueText,
        r = 1,
        g = 1,
        b = 1,
        wrap = false,
    }
end

local function appendEconomyLine(lines, item)
    if type(item) ~= "table" or item.canSell == false then
        return
    end

    local sellPrice = ItemClass and ItemClass.ResolveSellPrice and ItemClass.ResolveSellPrice(item) or (tonumber(item.sellPrice) or 0)
    if sellPrice <= 0 then
        return
    end

    local formattedSellPrice = Common and Common.FormatCopper and Common.FormatCopper(sellPrice) or ("%dc"):format(math.floor(sellPrice))
    appendSpacerLine(lines)

    lines[#lines + 1] = {
        text = ("Sell Price: %s"):format(formattedSellPrice),
        r = 1,
        g = 1,
        b = 1,
        wrap = false,
    }
end

local function appendConditionLines(lines, item, options, skipSpacer)
    if type(Conditions) ~= "table" or type(Conditions.BuildTooltipLines) ~= "function" or type(item) ~= "table" then
        return
    end

    local values = type(options) == "table" and options or {}
    local context = Conditions:BuildContext("item", item, {
        item = item,
        itemRef = values.itemRef,
        equipmentScope = values.equipmentScope,
    })
    local conditionLines = Conditions:BuildTooltipLines(item.conditions, context)
    if #conditionLines <= 0 then
        return
    end

    if skipSpacer ~= true then
        appendSpacerLine(lines)
    end
    for index = 1, #conditionLines do
        lines[#lines + 1] = conditionLines[index]
    end
end

local function buildInactiveTooltip(item, options)
    local values = options or {}
    local warningText = values.isMissing and "This item could not be resolved." or "This item is not part of your active data."

    return {
        type = "game",
        title = ensureString(item and item.name, values.itemId or "Unknown Item"),
        titleColor = { r = 0.7, g = 0.7, b = 0.7 },
        lines = {
            {
                text = warningText,
                r = 1,
                g = 0.25,
                b = 0.25,
                wrap = false,
            },
        },
    }
end

local function hasDynamicTooltipContent(item)
    if type(item) ~= "table" then
        return false
    end

    if type(item.conditions) == "table" and #item.conditions > 0 then
        return true
    end

    local itemType = tostring(item.itemType or "none")
    if itemType == "weapon" or itemType == "armor" or itemType == "modification" then
        local equipmentTrait = normalizeEquipmentTrait(item.equipmentTrait)
        if equipmentTrait and ensureString(equipmentTrait.description) == "" then
            return true
        end
    end

    if itemType == "consumable" then
        local consumableTrait = normalizeConsumableTrait(item.consumableTrait)
        if consumableTrait and ensureString(consumableTrait.description) == "" then
            return true
        end
    end

    return false
end

function ItemTooltip:Build(item, options)
    if type(item) ~= "table" then
        return nil
    end

    local values = options or {}
    local timer = startTiming(
        "ItemTooltip:Build",
        4,
        tostring(values.itemId or item.id or item.name or "unknown")
    )
    local runtimeRevisionKey = getTooltipRuntimeRevisionKey()
    local cacheRevision = TOOLTIP_CACHE_VERSION .. "\31" .. runtimeRevisionKey
    if ItemTooltip.BuildCacheRevision ~= cacheRevision then
        ItemTooltip.BuildCache = {}
        ItemTooltip.BuildCacheRevision = cacheRevision
    elseif type(ItemTooltip.BuildCache) ~= "table" then
        ItemTooltip.BuildCache = {}
    end

    local configurationRevision = getConfigurationRevision()
    if ItemTooltip.StaticBuildCacheRevision ~= configurationRevision then
        ItemTooltip.StaticBuildCache = {}
        ItemTooltip.StaticBuildCacheRevision = configurationRevision
    elseif type(ItemTooltip.StaticBuildCache) ~= "table" then
        ItemTooltip.StaticBuildCache = {}
    end

    local cacheKey = getTooltipVariantKey(item, values, runtimeRevisionKey)
    local cached = ItemTooltip.BuildCache[cacheKey]
    if cached then
        ItemTooltip.BuildCacheHits = ItemTooltip.BuildCacheHits + 1
        return finishTooltipBuild(timer, cached, item, true)
    end

    ItemTooltip.BuildCacheMisses = ItemTooltip.BuildCacheMisses + 1
    if values.isMissing or values.isActive == false then
        local inactiveTooltip = buildInactiveTooltip(item, values)
        ItemTooltip.BuildCache[cacheKey] = inactiveTooltip
        return finishTooltipBuild(timer, inactiveTooltip, item, false)
    end

    local isDynamic = hasDynamicTooltipContent(item)
    local staticCacheKey = not isDynamic and getStaticTooltipVariantKey(item, values) or nil
    if staticCacheKey then
        local staticCached = ItemTooltip.StaticBuildCache[staticCacheKey]
        if staticCached then
            ItemTooltip.BuildCache[cacheKey] = staticCached
            ItemTooltip.BuildCacheHits = ItemTooltip.BuildCacheHits + 1
            return finishTooltipBuild(timer, staticCached, item, true)
        end
    end

    local lines = {}
    local itemType = tostring(item.itemType or "none")
    local modificationKind = type(ModificationService.GetModificationKind) == "function" and ModificationService.GetModificationKind(item) or "generic"

    appendItemLevelLine(lines, item)
    appendSoulboundLine(lines, values)
    appendBindingLine(lines, item, values)
    appendQuestItemLine(lines, item)
    appendUniqueLine(lines, item)

    if itemType == "weapon" then
        lines[#lines + 1] = buildWeaponCategoryLine(item)
        local damageLine = buildDamageLine(item)
        if damageLine then
            lines[#lines + 1] = damageLine
        end
    elseif itemType == "armor" then
        lines[#lines + 1] = buildArmorCategoryLine(item)
    elseif itemType == "material" then
        local typeLabel = getItemTypeLabel(itemType)
        lines[#lines + 1] = {
            text = typeLabel,
            r = itemType == "material" and 0.0 or 0.12,
            g = itemType == "material" and 0.66 or 1.0,
            b = itemType == "material" and 0.66 or 0.82,
            wrap = false,
        }
    end

    local renderedPlainStats = false
    if itemType == "modification" and modificationKind == "gem" then
        local gemStatLines = buildWhiteItemStatLines(item)
        for index = 1, #gemStatLines do
            lines[#lines + 1] = gemStatLines[index]
        end
        renderedPlainStats = #gemStatLines > 0
    elseif itemType == "modification" and modificationKind ~= "gem" then
        appendModificationEquipStatLines(lines, item)
    else
        appendStatLines(lines, item)
        renderedPlainStats = hasRenderedStatLines(item)
    end

    if renderedPlainStats and (hasRenderedSkillBonusLines(item) or hasRenderedEquipText(item, values)) then
        appendSpacerLine(lines)
    end
    appendSkillBonusLines(lines, item)
    appendConditionLines(lines, item, values, true)
    appendEquipLine(lines, item, values)
    if itemType ~= "modification" or modificationKind == "gem" then
        appendEquipStatLines(lines, item)
    end
    appendUseLine(lines, item, values)
    appendAppliedModificationLines(lines, item, values)
    appendDescriptionLine(lines, item)
    appendEconomyLine(lines, item)

    local tooltip = {
        type = "game",
        title = ensureString(item.name, values.itemId or "Unnamed Item"),
        titleColor = getQualityColor(item.quality),
        lines = lines,
    }
    ItemTooltip.BuildCache[cacheKey] = tooltip
    if staticCacheKey then
        ItemTooltip.StaticBuildCache[staticCacheKey] = tooltip
    end
    return finishTooltipBuild(timer, tooltip, item, false)
end

return ItemTooltip
