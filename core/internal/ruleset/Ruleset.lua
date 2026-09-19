local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Ruleset = Addon.Internal.Ruleset or {}

local Ruleset = Addon.Internal.Ruleset

local function refreshVisibleProfileWindow()
    local profileWindow = Addon.Client and Addon.Client.UI and Addon.Client.UI.Profile and Addon.Client.UI.Profile.Window or nil
    if not (profileWindow and profileWindow.Get) then
        return false
    end

    local instance = profileWindow:Get()
    if instance and instance.RefreshVisible then
        instance:RefreshVisible()
        return true
    end

    return false
end

local function refreshVisibleDataEditor()
    local dataEditor = Addon.Client and Addon.Client.UI and Addon.Client.UI.Editor or nil
    if not (dataEditor and dataEditor.IsWindowVisible and dataEditor:IsWindowVisible()) then
        return false
    end

    if dataEditor.RefreshSpellInspectorPage then
        dataEditor:RefreshSpellInspectorPage()
        return true
    end

    return false
end
local Rules = Addon.Internal.Ruleset.Rules or {}
local Database = Addon.Internal.Database or {}
local RULESET_CATEGORY_DEFINITIONS = Rules.Definitions or {}
local COOLDOWN_CHANNEL_MIN_ID = 1
local COOLDOWN_CHANNEL_MAX_ID = 10

local function normalizeCooldownChannelId(channelId)
    if type(channelId) ~= "number"
        or channelId % 1 ~= 0
        or channelId < COOLDOWN_CHANNEL_MIN_ID
        or channelId > COOLDOWN_CHANNEL_MAX_ID
    then
        return nil
    end

    return channelId
end

local function trimText(value)
    if type(value) ~= "string" then
        return ""
    end

    local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
    return trimmed
end

local function getCooldownChannelRuleKey(channelId, suffix)
    return ("cooldown_channel_%d_%s"):format(channelId, suffix)
end

local function findCategoryDefinition(categoryKey)
    for index = 1, #RULESET_CATEGORY_DEFINITIONS do
        if RULESET_CATEGORY_DEFINITIONS[index].key == categoryKey then
            return RULESET_CATEGORY_DEFINITIONS[index], index
        end
    end

    return RULESET_CATEGORY_DEFINITIONS[1], 1
end

local function findRuleDefinition(categoryDefinition, ruleKey)
    local rules = categoryDefinition and categoryDefinition.rules or nil
    for index = 1, #(rules or {}) do
        local rule = rules and rules[index]
        if rule and rule.key == ruleKey then
            return rule, index
        end
    end

    return nil, nil
end

local function normalizeCheckboxValue(value, defaultValue)
    if value == nil then
        return defaultValue == true
    end

    if value == true or value == false then
        return value
    end

    if type(value) == "number" then
        return value ~= 0
    end

    if type(value) == "string" then
        local normalized = string.lower(value:gsub("^%s+", ""):gsub("%s+$", ""))
        if normalized == "" or normalized == "0" or normalized == "false" or normalized == "off" or normalized == "no" then
            return false
        end
        if normalized == "1" or normalized == "true" or normalized == "on" or normalized == "yes" then
            return true
        end
    end

    return value and true or false
end

local function normalizeSpellRankEffectGainPercent(value, fallback)
    local numeric = tonumber(value)
    if numeric == nil or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        numeric = tonumber(fallback)
    end
    if numeric == nil or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        numeric = 10
    end

    numeric = math.max(0, numeric)

    return tostring(numeric)
end

local function normalizeRulesetRuleValue(ruleDefinition, value)
    if type(ruleDefinition) == "table" and ruleDefinition.key == "spell_rank_effect_gain_percent" then
        return normalizeSpellRankEffectGainPercent(value, ruleDefinition.default)
    end

    return value
end

local function buildDatasetEntryReferenceItems(collectionKey, options)
    local items = {}
    local settings = type(options) == "table" and options or {}
    if settings.includeNone == true then
        items[#items + 1] = {
            label = settings.noneLabel or "None",
            value = "",
        }
    end

    local datasets = Database and Database.ListDatasets and Database.ListDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetId = tostring(dataset and dataset.id or "")
        local datasetLabel = Database and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or tostring(dataset and dataset.name or datasetId)
        local entries = dataset and dataset[collectionKey] or {}
        for entryIndex = 1, #entries do
            local entry = entries[entryIndex]
            local entryId = tostring(entry and entry.id or "")
            if datasetId ~= "" and entryId ~= "" then
                local entryLabel = tostring(entry and entry.name or entryId)
                items[#items + 1] = {
                    label = ("%s / %s"):format(datasetLabel, entryLabel),
                    value = ("%s:%s"):format(datasetId, entryId),
                }
            end
        end
    end

    return items
end

function Ruleset.GetRulesets()
    return Database.ListRulesets and Database.ListRulesets() or {}
end

function Ruleset.GetRulesetByID(rulesetId)
    if not (Database and Database.GetRulesetByID) then
        return nil
    end

    return Database.GetRulesetByID(rulesetId)
end

function Ruleset.GetRulesetDisplayName(ruleset)
    if Database and Database.GetRulesetDisplayName then
        return Database.GetRulesetDisplayName(ruleset)
    end

    local name = ruleset and ruleset.name or nil
    if name == nil or name == "" then
        return "Unnamed Ruleset"
    end

    return tostring(name)
end

function Ruleset.GetActiveRulesetId()
    return Database and Database.GetActiveRulesetId and Database.GetActiveRulesetId() or nil
end

function Ruleset.GetActiveRuleset()
    return Database and Database.GetActiveRuleset and Database.GetActiveRuleset() or nil
end

function Ruleset.IsRulesetActive(rulesetId)
    local activeRulesetId = Ruleset.GetActiveRulesetId()
    return activeRulesetId ~= nil and activeRulesetId == rulesetId
end

function Ruleset.SetActiveRulesetId(rulesetId)
    if not (Database and Database.SetActiveRulesetId) then
        return nil
    end

    local activeId = Database.SetActiveRulesetId(rulesetId)
    refreshVisibleProfileWindow()
    refreshVisibleDataEditor()
    return activeId
end

function Ruleset.CreateRuleset(name)
    if not (Database and Database.CreateRuleset) then
        return nil
    end

    return Database.CreateRuleset(name or "New Ruleset")
end

function Ruleset.DeleteRuleset(rulesetId)
    if not rulesetId or not (Database and Database.DeleteRuleset) then
        return false
    end

    return Database.DeleteRuleset(rulesetId)
end

function Ruleset.ExportRuleset(rulesetId)
    if not rulesetId or not (Database and Database.ExportRuleset) then
        return nil
    end

    return Database.ExportRuleset(rulesetId)
end

function Ruleset.ImportRuleset(text)
    if not (Database and Database.ImportRuleset) then
        return nil, "Ruleset import is unavailable."
    end

    return Database.ImportRuleset(text)
end

function Ruleset.GetRulesetCategoryDefinitions()
    return RULESET_CATEGORY_DEFINITIONS
end

function Ruleset.GetRulesetCategoryIndexByKey(categoryKey)
    local _, index = findCategoryDefinition(categoryKey)
    return index or 1
end

function Ruleset.GetRulesetCategoryDefinition(categoryKey)
    return findCategoryDefinition(categoryKey)
end

function Ruleset.GetRulesetRuleDefinition(categoryKey, ruleKey)
    local categoryDefinition = Ruleset.GetRulesetCategoryDefinition(categoryKey)
    return findRuleDefinition(categoryDefinition, ruleKey)
end

function Ruleset.GetDefaultRulesetCategoryKey()
    local categoryDefinition = RULESET_CATEGORY_DEFINITIONS[1]
    return categoryDefinition and categoryDefinition.key or nil
end

function Ruleset.GetDefaultRulesetRuleKey(categoryKey)
    local categoryDefinition = Ruleset.GetRulesetCategoryDefinition(categoryKey)
    local firstRule = categoryDefinition and categoryDefinition.rules and categoryDefinition.rules[1] or nil
    return firstRule and firstRule.key or nil
end

function Ruleset.GetRulesetRuleValue(ruleset, categoryKey, ruleDefinition)
    if not ruleDefinition then
        return nil
    end

    local rules = ruleset and type(ruleset.rules) == "table" and ruleset.rules or nil
    local categoryRules = rules and type(rules[categoryKey]) == "table" and rules[categoryKey] or nil
    local value = nil
    if categoryRules ~= nil then
        value = categoryRules[ruleDefinition.key]
    end
    if value == nil then
        value = ruleDefinition.default
    end

    if ruleDefinition.type == "checkbox" then
        return normalizeCheckboxValue(value, ruleDefinition.default)
    end

    return normalizeRulesetRuleValue(ruleDefinition, value)
end

function Ruleset.GetRulesetRuleValueByKey(ruleset, categoryKey, ruleKey, defaultValue)
    local normalizedCategoryKey = tostring(categoryKey or "")
    local normalizedRuleKey = tostring(ruleKey or "")
    if normalizedCategoryKey == "" or normalizedRuleKey == "" then
        return defaultValue
    end

    local rules = ruleset and type(ruleset.rules) == "table" and ruleset.rules or nil
    local categoryRules = rules and type(rules[normalizedCategoryKey]) == "table" and rules[normalizedCategoryKey] or nil
    local ruleDefinition = Ruleset.GetRulesetRuleDefinition(normalizedCategoryKey, normalizedRuleKey)
    local fallbackValue = defaultValue
    if fallbackValue == nil and ruleDefinition ~= nil then
        fallbackValue = ruleDefinition.default
    end

    local value = categoryRules ~= nil and categoryRules[normalizedRuleKey] or nil
    if value == nil then
        value = fallbackValue
    end

    if (ruleDefinition and ruleDefinition.type == "checkbox") or type(fallbackValue) == "boolean" then
        return normalizeCheckboxValue(value, fallbackValue)
    end

    return normalizeRulesetRuleValue(ruleDefinition, value)
end

function Ruleset.GetCooldownChannel(channelId, rulesetOverride)
    local normalizedChannelId = normalizeCooldownChannelId(channelId)
    if not normalizedChannelId then
        return nil
    end

    local ruleset = rulesetOverride
    if ruleset == nil then
        ruleset = Ruleset.GetActiveRuleset()
    end

    local name = Ruleset.GetRulesetRuleValueByKey(
        ruleset,
        "action_economy",
        getCooldownChannelRuleKey(normalizedChannelId, "name"),
        ""
    )
    local triggersGCD = Ruleset.GetRulesetRuleValueByKey(
        ruleset,
        "action_economy",
        getCooldownChannelRuleKey(normalizedChannelId, "triggers_gcd"),
        false
    ) == true
    local canUseOffTurn = Ruleset.GetRulesetRuleValueByKey(
        ruleset,
        "action_economy",
        getCooldownChannelRuleKey(normalizedChannelId, "can_use_off_turn"),
        false
    ) == true
    local normalizedName = trimText(name)
    local enabled = normalizedName ~= ""

    return {
        id = normalizedChannelId,
        name = normalizedName,
        triggersGCD = triggersGCD,
        canUseOffTurn = enabled and canUseOffTurn or false,
        enabled = enabled,
    }
end

function Ruleset.GetCooldownChannels(rulesetOverride)
    local channels = {}
    for channelId = COOLDOWN_CHANNEL_MIN_ID, COOLDOWN_CHANNEL_MAX_ID do
        channels[#channels + 1] = Ruleset.GetCooldownChannel(channelId, rulesetOverride)
    end

    return channels
end

function Ruleset.IsCooldownChannelEnabled(channelId, rulesetOverride)
    local channel = Ruleset.GetCooldownChannel(channelId, rulesetOverride)
    return channel ~= nil and channel.enabled == true
end

function Ruleset.DoesCooldownChannelTriggerGCD(channelId, rulesetOverride)
    local channel = Ruleset.GetCooldownChannel(channelId, rulesetOverride)
    return channel ~= nil and channel.triggersGCD == true
end

function Ruleset.CanCooldownChannelBeUsedOffTurn(channelId, rulesetOverride)
    local channel = Ruleset.GetCooldownChannel(channelId, rulesetOverride)
    return channel ~= nil and channel.enabled == true and channel.canUseOffTurn == true
end

function Ruleset.GetCooldownChannelName(channelId, rulesetOverride)
    local channel = Ruleset.GetCooldownChannel(channelId, rulesetOverride)
    return channel and channel.name or nil
end

function Ruleset.SetRulesetRuleValue(rulesetId, categoryKey, ruleDefinition, value)
    local ruleset = Ruleset.GetRulesetByID(rulesetId)
    if not ruleset or not ruleDefinition then
        return nil
    end

    ruleset.rules = type(ruleset.rules) == "table" and ruleset.rules or {}
    ruleset.rules[categoryKey] = type(ruleset.rules[categoryKey]) == "table" and ruleset.rules[categoryKey] or {}
    ruleset.rules[categoryKey][ruleDefinition.key] = normalizeRulesetRuleValue(ruleDefinition, value)

    if Database and Database.UpdateRulesetMetadata then
        local updated = Database.UpdateRulesetMetadata(ruleset.id, { rules = ruleset.rules })
        refreshVisibleProfileWindow()
        refreshVisibleDataEditor()
        return updated
    end

    refreshVisibleProfileWindow()
    refreshVisibleDataEditor()
    return ruleset
end

function Ruleset.BuildRulesetStatReferenceItems()
    local items = {
        { label = "None", value = "" },
    }

    local datasets = Database and Database.ListDatasets and Database.ListDatasets() or {}
    local dependencies = Database and Database.Dependecies or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local stats = dataset and dataset.stats or {}
        for statIndex = 1, #stats do
            local stat = stats[statIndex]
            if stat and stat.id then
                local value = dependencies.ComposeSourceStatRef and dependencies.ComposeSourceStatRef(dataset.id, stat.id) or ("%s:%s"):format(dataset.id, stat.id)
                local statLabel = tostring(stat.name or stat.id)
                local datasetLabel = Database and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or tostring(dataset.name or dataset.id)
                items[#items + 1] = {
                    label = ("%s / %s"):format(datasetLabel, statLabel),
                    value = value,
                }
            end
        end
    end

    return items
end

function Ruleset.BuildRulesetResourceReferenceItems()
    local items = {
        { label = "None", value = "" },
    }

    local datasets = Database and Database.ListDatasets and Database.ListDatasets() or {}
    local dependencies = Database and Database.Dependecies or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local resources = dataset and dataset.resources or {}
        for resourceIndex = 1, #resources do
            local resource = resources[resourceIndex]
            if resource and resource.id then
                local value = dependencies.ComposeSourceStatRef and dependencies.ComposeSourceStatRef(dataset.id, resource.id) or ("%s:%s"):format(dataset.id, resource.id)
                local resourceLabel = tostring(resource.name or resource.id)
                local datasetLabel = Database and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or tostring(dataset.name or dataset.id)
                items[#items + 1] = {
                    label = ("%s / %s"):format(datasetLabel, resourceLabel),
                    value = value,
                }
            end
        end
    end

    return items
end

function Ruleset.BuildRulesetItemSlotReferenceItems()
    local items = {
        { label = "None", value = "" },
    }

    local datasets = Database and Database.ListDatasets and Database.ListDatasets() or {}
    local dependencies = Database and Database.Dependecies or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local itemSlots = dataset and dataset.itemSlots or {}
        for itemSlotIndex = 1, #itemSlots do
            local itemSlot = itemSlots[itemSlotIndex]
            if itemSlot and itemSlot.id then
                local value = dependencies.ComposeSourceStatRef and dependencies.ComposeSourceStatRef(dataset.id, itemSlot.id) or ("%s:%s"):format(dataset.id, itemSlot.id)
                local itemSlotLabel = tostring(itemSlot.name or itemSlot.id)
                local datasetLabel = Database and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or tostring(dataset.name or dataset.id)
                items[#items + 1] = {
                    label = ("%s / %s"):format(datasetLabel, itemSlotLabel),
                    value = value,
                }
            end
        end
    end

    return items
end

function Ruleset.BuildRulesetDatasetIdItems()
    local items = {}
    local datasets = Database and Database.ListDatasets and Database.ListDatasets() or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetId = tostring(dataset and dataset.id or "")
        if datasetId ~= "" then
            items[#items + 1] = {
                label = Database and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or tostring(dataset and dataset.name or datasetId),
                value = datasetId,
            }
        end
    end

    return items
end

function Ruleset.BuildRulesetRaceReferenceItems()
    return buildDatasetEntryReferenceItems("races")
end

function Ruleset.BuildRulesetClassReferenceItems()
    return buildDatasetEntryReferenceItems("classes")
end

function Ruleset.GetRulesetRuleOptions(ruleDefinition)
    if not ruleDefinition or ruleDefinition.type ~= "dropdown" then
        return {}
    end

    if ruleDefinition.optionsSource == "statReference" then
        return Ruleset.BuildRulesetStatReferenceItems()
    end
    if ruleDefinition.optionsSource == "resourceReference" then
        return Ruleset.BuildRulesetResourceReferenceItems()
    end
    if ruleDefinition.optionsSource == "itemSlotReference" then
        return Ruleset.BuildRulesetItemSlotReferenceItems()
    end
    if ruleDefinition.optionsSource == "datasetId" then
        return Ruleset.BuildRulesetDatasetIdItems()
    end
    if ruleDefinition.optionsSource == "raceReference" then
        return Ruleset.BuildRulesetRaceReferenceItems()
    end
    if ruleDefinition.optionsSource == "classReference" then
        return Ruleset.BuildRulesetClassReferenceItems()
    end

    return ruleDefinition.options or {}
end
