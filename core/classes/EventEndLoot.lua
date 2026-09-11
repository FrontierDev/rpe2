local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}
Addon.Utils = Addon.Utils or {}

local Event = Addon.Internal.Database.Classes.Event
local Common = Addon.Utils.Common or {}

if type(Event) ~= "table" or Event._endLootExtensionInstalled == true then
    return
end

local END_LOOT_RECORD_SEPARATOR = string.char(16)
local END_LOOT_FIELD_SEPARATOR = string.char(15)
local NETWORK_FIELD_INDEX = 19
local NETWORK_TURN_MODE_FIELD_INDEX = 18

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeToken(value)
    return string.lower(trim(value))
end

local function splitPreservingEmpty(value, separator)
    if type(Common.SplitPreservingEmpty) == "function" then
        return Common.SplitPreservingEmpty(tostring(value or ""), separator)
    end

    local result = {}
    local text = tostring(value or "")
    local startIndex = 1
    while true do
        local separatorIndex = string.find(text, separator, startIndex, true)
        if not separatorIndex then
            result[#result + 1] = string.sub(text, startIndex)
            break
        end
        result[#result + 1] = string.sub(text, startIndex, separatorIndex - 1)
        startIndex = separatorIndex + #separator
    end
    return result
end

local function encodeField(value)
    local text = tostring(value == nil and "" or value)
    local parts = {}
    for index = 1, #text do
        local byte = string.byte(text, index)
        local character = string.char(byte)
        if (byte >= 48 and byte <= 57)
            or (byte >= 65 and byte <= 90)
            or (byte >= 97 and byte <= 122)
            or character == "."
            or character == "_"
            or character == ":"
            or character == "-"
        then
            parts[#parts + 1] = character
        else
            parts[#parts + 1] = ("%%%02X"):format(byte)
        end
    end
    return table.concat(parts)
end

local function decodeField(value)
    local text = tostring(value or "")
    local parts = {}
    local index = 1
    while index <= #text do
        local character = string.sub(text, index, index)
        if character ~= "%" then
            parts[#parts + 1] = character
            index = index + 1
        else
            local hex = string.sub(text, index + 1, index + 2)
            if #hex ~= 2 or not hex:match("^%x%x$") then
                return nil
            end
            parts[#parts + 1] = string.char(tonumber(hex, 16))
            index = index + 3
        end
    end
    return table.concat(parts)
end

local function cloneReward(reward)
    if type(reward) ~= "table" then
        return nil
    end
    return {
        type = normalizeToken(reward.type),
        ref = reward.ref == nil and "" or tostring(reward.ref),
        amount = reward.amount,
    }
end

local function cloneEndLootGrant(grant)
    if type(grant) ~= "table" then
        return {
            sourceType = "",
            distribution = "",
            _invalidValue = grant,
        }
    end

    local copy = {
        sourceType = normalizeToken(grant.sourceType),
        distribution = normalizeToken(grant.distribution),
    }

    if grant.lootRef ~= nil then
        copy.lootRef = tostring(grant.lootRef)
    end
    if grant.reward ~= nil then
        copy.reward = cloneReward(grant.reward)
    end
    if grant._invalidValue ~= nil then
        copy._invalidValue = grant._invalidValue
    end
    return copy
end

local function cloneEndLootGrants(values)
    local cloned = {}
    if type(values) ~= "table" then
        return cloned
    end

    for index = 1, #values do
        cloned[#cloned + 1] = cloneEndLootGrant(values[index])
    end
    return cloned
end

local function buildEndLootGrantsFromLegacyRefs(values)
    local grants = {}
    local seen = {}
    for index = 1, #(type(values) == "table" and values or {}) do
        local lootRef = trim(values[index])
        if lootRef ~= "" and not seen[lootRef] then
            seen[lootRef] = true
            grants[#grants + 1] = {
                sourceType = "loot_table",
                lootRef = lootRef,
                distribution = "group",
            }
        end
    end
    return grants
end

local function buildLegacyLootRefsFromEndLootGrants(values)
    local refs = {}
    local seen = {}
    for index = 1, #(type(values) == "table" and values or {}) do
        local grant = values[index]
        if type(grant) == "table" and normalizeToken(grant.sourceType) == "loot_table" then
            local lootRef = trim(grant.lootRef)
            if lootRef ~= "" and not seen[lootRef] then
                seen[lootRef] = true
                refs[#refs + 1] = lootRef
            end
        end
    end
    return refs
end

local function serializeEndLootGrants(values)
    local records = {}
    local grants = cloneEndLootGrants(values)
    for index = 1, #grants do
        local grant = grants[index]
        local reward = type(grant.reward) == "table" and grant.reward or nil
        records[#records + 1] = table.concat({
            encodeField(grant.sourceType),
            encodeField(grant.distribution),
            encodeField(reward and reward.type or ""),
            encodeField(reward and reward.ref or ""),
            encodeField(reward and reward.amount or ""),
            encodeField(grant.lootRef or ""),
        }, END_LOOT_FIELD_SEPARATOR)
    end
    return table.concat(records, END_LOOT_RECORD_SEPARATOR)
end

local function deserializeEndLootGrants(text)
    if type(text) ~= "string" or text == "" then
        return {}
    end

    local records = splitPreservingEmpty(text, END_LOOT_RECORD_SEPARATOR)
    local grants = {}
    for index = 1, #records do
        local fields = splitPreservingEmpty(records[index], END_LOOT_FIELD_SEPARATOR)
        if #fields >= 6 then
            local decoded = {}
            local valid = true
            for fieldIndex = 1, 6 do
                decoded[fieldIndex] = decodeField(fields[fieldIndex])
                if decoded[fieldIndex] == nil then
                    valid = false
                    break
                end
            end
            if valid then
                local sourceType = normalizeToken(decoded[1])
                local distribution = normalizeToken(decoded[2])
                local rewardType = normalizeToken(decoded[3])
                local rewardRef = decoded[4] or ""
                local rewardAmountText = decoded[5] or ""
                local lootRef = decoded[6] or ""
                local grant = {
                    sourceType = sourceType,
                    distribution = distribution,
                }
                if lootRef ~= "" or sourceType == "loot_table" then
                    grant.lootRef = lootRef
                end
                if rewardType ~= "" or rewardRef ~= "" or rewardAmountText ~= "" or sourceType == "direct" then
                    local amount = tonumber(rewardAmountText)
                    grant.reward = {
                        type = rewardType,
                        ref = rewardRef,
                        amount = amount ~= nil and amount or rewardAmountText,
                    }
                end
                grants[#grants + 1] = grant
            else
                grants[#grants + 1] = {
                    sourceType = "",
                    distribution = "",
                    _invalidValue = records[index],
                }
            end
        else
            grants[#grants + 1] = {
                sourceType = "",
                distribution = "",
                _invalidValue = records[index],
            }
        end
    end
    return cloneEndLootGrants(grants)
end

Event._endLootConstructionContext = Event._endLootConstructionContext or nil

function Event.PushEndLootConstructionContext(grants)
    local previous = Event._endLootConstructionContext
    Event._endLootConstructionContext = cloneEndLootGrants(grants)
    return previous
end

function Event.PopEndLootConstructionContext(previous)
    Event._endLootConstructionContext = previous
end

local baseMerge = Event.Merge
function Event:Merge(data)
    local existingCanonical = cloneEndLootGrants(self.endLootGrants)
    local canonicalAlreadyEstablished = self._endLootCanonicalPresent == true
    local hasCanonicalInput = type(data) == "table" and data.endLootGrants ~= nil
    local hasLegacyInput = type(data) == "table" and data.lootRefs ~= nil
    local constructionContext = Event._endLootConstructionContext

    local result = type(baseMerge) == "function" and baseMerge(self, data) or self

    if hasCanonicalInput then
        self.endLootGrants = cloneEndLootGrants(data.endLootGrants)
        self._endLootCanonicalPresent = true
    elseif type(constructionContext) == "table" and hasLegacyInput then
        self.endLootGrants = cloneEndLootGrants(constructionContext)
        self._endLootCanonicalPresent = true
    elseif canonicalAlreadyEstablished then
        self.endLootGrants = existingCanonical
        self._endLootCanonicalPresent = true
    elseif hasLegacyInput and type(self.lootRefs) == "table" and #self.lootRefs > 0 then
        self.endLootGrants = buildEndLootGrantsFromLegacyRefs(self.lootRefs)
        self._endLootCanonicalPresent = true
    else
        self.endLootGrants = cloneEndLootGrants(self.endLootGrants)
    end

    self.lootRefs = buildLegacyLootRefsFromEndLootGrants(self.endLootGrants)
    return result
end

local baseToTable = Event.ToTable
function Event:ToTable()
    local values = type(baseToTable) == "function" and baseToTable(self) or {}
    values.endLootGrants = cloneEndLootGrants(self.endLootGrants)
    values.lootRefs = buildLegacyLootRefsFromEndLootGrants(values.endLootGrants)
    return values
end

local baseToStartArguments = Event.ToStartArguments
function Event:ToStartArguments(includeUnits)
    local arguments = type(baseToStartArguments) == "function" and baseToStartArguments(self, includeUnits) or {}
    while #arguments < NETWORK_TURN_MODE_FIELD_INDEX do
        arguments[#arguments + 1] = ""
    end
    arguments[NETWORK_FIELD_INDEX] = serializeEndLootGrants(self.endLootGrants)
    return arguments
end

local baseFromStartArguments = Event.FromStartArguments
function Event.FromStartArguments(arguments)
    local eventState = type(baseFromStartArguments) == "function"
        and baseFromStartArguments(arguments)
        or Event:New({})
    if type(eventState) == "table" and type(arguments) == "table" and #arguments >= NETWORK_FIELD_INDEX then
        eventState:Merge({
            endLootGrants = deserializeEndLootGrants(arguments[NETWORK_FIELD_INDEX] or ""),
        })
    end
    return eventState
end

Event.CloneEndLootGrant = cloneEndLootGrant
Event.CloneEndLootGrants = cloneEndLootGrants
Event.NormalizeEndLootGrants = cloneEndLootGrants
Event.BuildEndLootGrantsFromLegacyRefs = buildEndLootGrantsFromLegacyRefs
Event.BuildLegacyLootRefsFromEndLootGrants = buildLegacyLootRefsFromEndLootGrants
Event.SerializeEndLootGrantsForNetwork = serializeEndLootGrants
Event.DeserializeEndLootGrantsFromNetwork = deserializeEndLootGrants
Event.EndLootNetworkFieldIndex = NETWORK_FIELD_INDEX
Event._endLootExtensionInstalled = true
