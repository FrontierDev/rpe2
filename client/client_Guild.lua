local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Guild = Addon.Client.Guild or {}

local Client = Addon.Client
local Guild = Addon.Client.Guild
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Comms = Addon.Internal and Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}
local Common = Addon.Utils and Addon.Utils.Common or {}

local GUILD_ADMIN_PROTOCOL_VERSION = "1"
local GUILD_ADMIN_REQUEST_TIMEOUT = 8
local GUILD_ADMIN_QUERY_OPCODE = Operations.GetOpcode and Operations:GetOpcode("GUILD_ADMIN_QUERY") or nil
local GUILD_ADMIN_QUERY_RESPONSE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("GUILD_ADMIN_QUERY_RESPONSE") or nil
local GUILD_ADMIN_MUTATION_OPCODE = Operations.GetOpcode and Operations:GetOpcode("GUILD_ADMIN_MUTATION") or nil
local GUILD_ADMIN_MUTATION_RESPONSE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("GUILD_ADMIN_MUTATION_RESPONSE") or nil

Guild._guildAdminPending = Guild._guildAdminPending or {}
Guild._guildAdminRequestSequence = tonumber(Guild._guildAdminRequestSequence) or 0

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function trimText(value)
    return ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizePlayerName(value)
    local name = trimText(value)
    if name == "" then
        return ""
    end

    if type(Common.NormalizeName) == "function" then
        return trimText(Common.NormalizeName(name))
    end

    return name
end

local function getLocalPlayerName()
    if type(Common.GetPlayerName) == "function" then
        return normalizePlayerName(Common.GetPlayerName())
    end

    if type(GetUnitName) == "function" then
        return normalizePlayerName(GetUnitName("player", true) or GetUnitName("player"))
    end

    if type(UnitName) == "function" then
        return normalizePlayerName(UnitName("player"))
    end

    return ""
end

local function callGlobal(name, ...)
    local handler = _G and _G[name] or nil
    if type(handler) ~= "function" then
        return false
    end

    local ok, result = pcall(handler, ...)
    return ok and result or false
end

local function getGuildIdentity()
    local inGuild = type(IsInGuild) == "function" and IsInGuild() == true or false
    local guildName = ""
    local guildRankName = ""
    local guildRankIndex = nil

    if type(GetGuildInfo) == "function" then
        local ok, name, rankName, rankIndex = pcall(GetGuildInfo, "player")
        if ok then
            guildName = ensureString(name)
            guildRankName = ensureString(rankName)
            guildRankIndex = tonumber(rankIndex)
        end
    end

    return {
        inGuild = inGuild,
        guildName = guildName,
        guildRankName = guildRankName,
        guildRankIndex = guildRankIndex,
    }
end

local function getSettingLabel(setting)
    if not setting then
        return ""
    end

    local name = trimText(setting.name)
    if name ~= "" then
        return name
    end

    return trimText(setting.id)
end

local function getDatasetLabel(dataset)
    if not dataset then
        return ""
    end

    local name = trimText(dataset.name)
    if name ~= "" then
        return name
    end

    return trimText(dataset.id)
end

local function makeMatch(dataset, setting, matchType)
    local datasetId = trimText(dataset and dataset.id)
    local settingId = trimText(setting and setting.id)

    return {
        dataset = dataset,
        setting = setting,
        rank = setting,
        datasetId = datasetId,
        settingId = settingId,
        ref = datasetId ~= "" and settingId ~= "" and (datasetId .. ":" .. settingId) or "",
        datasetName = getDatasetLabel(dataset),
        settingName = getSettingLabel(setting),
        guildName = trimText(setting and setting.guildName),
        matchType = matchType,
    }
end

local function normalizeWowGuildRankIndex(value)
    local numeric = tonumber(value)
    if numeric == nil or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return nil
    end

    local integer = math.floor(numeric)
    if numeric ~= integer or integer < 0 then
        return nil
    end

    return integer
end

local function getGuildKey(identity)
    return trimText(identity and identity.guildName)
end

local function getAssignedGuildRankRef(identity)
    if type(Profile.GetAssignedGuildRank) ~= "function" then
        return nil
    end

    local guildKey = getGuildKey(identity)
    if guildKey == "" then
        return nil
    end

    local ok, assignedRankRef = pcall(Profile.GetAssignedGuildRank, guildKey)
    if not ok then
        return nil
    end

    local normalizedRef = trimText(assignedRankRef)
    return normalizedRef ~= "" and normalizedRef or nil
end

local function findMatchByRef(matches, assignedRankRef)
    local normalizedRef = trimText(assignedRankRef)
    if normalizedRef == "" then
        return nil
    end

    for index = 1, #(matches or {}) do
        local match = matches[index]
        if trimText(match and match.ref) == normalizedRef then
            return match
        end
    end

    return nil
end

local function isGuildRankEligibleForWowRank(setting, wowRankIndex)
    local mappedWowRanks = setting and setting.wowGuildRankIndices
    if type(mappedWowRanks) ~= "table" or #mappedWowRanks == 0 then
        return true
    end

    local normalizedTarget = normalizeWowGuildRankIndex(wowRankIndex)
    if normalizedTarget == nil then
        return false
    end

    for index = 1, #mappedWowRanks do
        if normalizeWowGuildRankIndex(mappedWowRanks[index]) == normalizedTarget then
            return true
        end
    end

    return false
end

local function getArgument(arguments, index)
    return trimText(arguments and arguments[index])
end

local function isSuccessfulArgument(value)
    local normalized = string.lower(trimText(value))
    return normalized == "1" or normalized == "true" or normalized == "success"
end

local function getGuildAdminRequestId()
    Guild._guildAdminRequestSequence = (tonumber(Guild._guildAdminRequestSequence) or 0) + 1
    local now = type(Common.GetNow) == "function" and tonumber(Common.GetNow()) or 0
    return ("guild-admin-%d-%d"):format(math.floor(now), Guild._guildAdminRequestSequence)
end

local function findRosterMember(self, targetName)
    local normalizedTarget = normalizePlayerName(targetName)
    if normalizedTarget == "" or type(self.GetRoster) ~= "function" then
        return nil
    end

    local roster = self:GetRoster()
    for index = 1, #(roster or {}) do
        local member = roster[index]
        if normalizePlayerName(member and member.name) == normalizedTarget then
            return member
        end
    end

    return nil
end

local function sendGuildAdminMessage(opcode, targetName, arguments)
    local normalizedTarget = trimText(targetName)
    if not opcode or normalizedTarget == "" or type(Comms.SendMessage) ~= "function" then
        return false
    end

    return Comms:SendMessage("WHISPER", opcode, arguments, normalizedTarget, {
        opcode = opcode,
        scope = "client",
    }) == true
end

local function hasGuildOfficerCapability(member)
    local rankIndex = normalizeWowGuildRankIndex(member and member.rankIndex)
    if rankIndex == nil then
        return false
    end

    local guildInfo = _G and _G.C_GuildInfo or nil
    local getRankFlags = guildInfo and guildInfo.GuildControlGetRankFlags or nil
    if type(getRankFlags) == "function" then
        -- GetGuildRosterInfo uses a zero-based rankIndex; GuildInfo uses a
        -- one-based rankOrder for permission flags.
        local ok, permissions = pcall(getRankFlags, rankIndex + 1)
        if ok and type(permissions) == "table" then
            -- Mirror the established local fallback: only management
            -- capabilities authorize Guild Admin. Officer-chat listen/speak
            -- and view-only note permissions are deliberately insufficient.
            return permissions[5] == true -- promote
                or permissions[6] == true -- demote
                or permissions[8] == true -- remove member
                or permissions[12] == true -- edit officer note
                or permissions[13] == true -- modify guild info
        end
    end

    -- Do not infer authority from rank order when capability inspection is
    -- unavailable. A passive rank or rank 1 must not authorize mutations.
    return false
end

local function invokeGuildAdminCallback(pending, response)
    if type(pending and pending.callback) == "function" then
        pending.callback(response)
    end
end

local function completeGuildAdminPending(self, requestId, response)
    local pending = self._guildAdminPending and self._guildAdminPending[requestId] or nil
    if not pending then
        return false
    end

    self._guildAdminPending[requestId] = nil
    invokeGuildAdminCallback(pending, response)
    return true
end

local function failGuildAdminPending(self, requestId, reason)
    return completeGuildAdminPending(self, requestId, {
        requestId = requestId,
        protocolVersion = GUILD_ADMIN_PROTOCOL_VERSION,
        success = false,
        reason = reason or "no-response",
    })
end

local function registerGuildAdminPending(self, requestId, pending)
    self._guildAdminPending[requestId] = pending
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(GUILD_ADMIN_REQUEST_TIMEOUT, function()
            if self._guildAdminPending[requestId] == pending then
                failGuildAdminPending(self, requestId, "no-response")
            end
        end)
    end
end

local function validateGuildAdminRequest(self, arguments, sender, distribution, targetIndex)
    local requestId = getArgument(arguments, 1)
    local protocolVersion = getArgument(arguments, 2)
    if requestId == "" or protocolVersion ~= GUILD_ADMIN_PROTOCOL_VERSION or distribution ~= "WHISPER" then
        return requestId ~= "" and requestId or nil, "incompatible-protocol", nil
    end

    local identity = getGuildIdentity()
    if not identity.inGuild then
        return requestId, "sender-not-in-guild", nil
    end

    local senderMember = findRosterMember(self, sender)
    if not senderMember then
        return requestId, "sender-not-in-guild", nil
    end

    if not hasGuildOfficerCapability(senderMember) then
        return requestId, "sender-not-officer", nil
    end

    local requestedTarget = normalizePlayerName(getArgument(arguments, targetIndex))
    local localPlayerName = getLocalPlayerName()
    if requestedTarget == "" or localPlayerName == "" or requestedTarget ~= localPlayerName then
        return requestId, "wrong-target", nil
    end

    return requestId, nil, identity
end

local function getResolvedGuildRankReference(guildRankRef)
    if type(Registry.ResolveGuildSettingReference) ~= "function" then
        return nil, nil
    end

    return Registry:ResolveGuildSettingReference(guildRankRef)
end

local function buildQueryResponseArguments(requestId, success, reason, identity, assignedRankRef)
    return {
        requestId,
        GUILD_ADMIN_PROTOCOL_VERSION,
        success and "1" or "0",
        reason or (success and "ok" or "unknown-error"),
        assignedRankRef or "",
        identity and identity.guildRankIndex or "",
        identity and identity.guildRankName or "",
        identity and identity.guildName or "",
    }
end

local function buildMutationResponseArguments(requestId, operation, success, reason, assignedRankRef)
    return {
        requestId,
        GUILD_ADMIN_PROTOCOL_VERSION,
        operation or "",
        success and "1" or "0",
        reason or (success and "ok" or "unknown-error"),
        assignedRankRef or "",
    }
end

local function hasOfficerPermission()
    local identity = getGuildIdentity()
    if not identity.inGuild then
        return false
    end

    local guildInfo = _G and _G.C_GuildInfo or nil
    if guildInfo and type(guildInfo.IsGuildOfficer) == "function" then
        local ok, isOfficer = pcall(guildInfo.IsGuildOfficer)
        if ok then
            return isOfficer == true
        end
    end

    -- Compatibility fallback for interfaces without C_GuildInfo.IsGuildOfficer.
    if type(IsGuildLeader) == "function" then
        local ok, isLeader = pcall(IsGuildLeader)
        if ok and isLeader == true then
            return true
        end
    end

    local permissionAPIs = {
        "CanGuildRemove",
        "CanGuildPromote",
        "CanGuildDemote",
        "CanEditGuildInfo",
        "CanEditOfficerNote",
    }
    for index = 1, #permissionAPIs do
        if callGlobal(permissionAPIs[index]) == true then
            return true
        end
    end

    return false
end

function Guild:GetLocalGuildIdentity()
    return getGuildIdentity()
end

function Guild:GetCurrentGuildName()
    return getGuildIdentity().guildName
end

local function buildApplicableGuildRankCatalogue()
    local identity = getGuildIdentity()
    local result = {
        inGuild = identity.inGuild,
        guildName = identity.guildName,
        guildRankName = identity.guildRankName,
        guildRankIndex = identity.guildRankIndex,
        guildKey = getGuildKey(identity),
        ranks = {},
        matches = {},
        conflict = false,
        exactMatches = {},
        genericMatches = {},
        matchType = nil,
        reason = nil,
    }

    if not identity.inGuild then
        result.reason = "not-in-guild"
        return result
    end

    local guildName = trimText(identity.guildName)
    if guildName == "" then
        result.reason = "guild-loading"
        return result
    end

    local exactMatches = {}
    local genericMatches = {}
    local datasets = Registry.GetActivatedDatasets and Registry:GetActivatedDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local guildSettings = dataset and dataset.guildSettings or {}
        for settingIndex = 1, #guildSettings do
            local setting = guildSettings[settingIndex]
            local configuredGuildName = trimText(setting and setting.guildName)
            if configuredGuildName == guildName then
                exactMatches[#exactMatches + 1] = makeMatch(dataset, setting, "exact")
            elseif configuredGuildName == "" then
                genericMatches[#genericMatches + 1] = makeMatch(dataset, setting, "generic")
            end
        end
    end

    local candidates = #exactMatches > 0 and exactMatches or genericMatches
    result.exactMatches = exactMatches
    result.genericMatches = genericMatches
    result.matchType = #exactMatches > 0 and "exact" or (#genericMatches > 0 and "generic" or nil)
    result.ranks = candidates
    result.matches = candidates

    if #candidates == 0 then
        result.reason = "no-setting"
        return result
    end

    result.reason = result.matchType
    return result
end

function Guild:GetApplicableGuildRanks()
    local catalogue = buildApplicableGuildRankCatalogue()
    return catalogue.ranks, catalogue
end

function Guild:GetEligibleGuildRanksForWoWRank(wowRankIndex)
    local catalogue = buildApplicableGuildRankCatalogue()
    local eligibleRanks = {}

    for index = 1, #catalogue.ranks do
        local match = catalogue.ranks[index]
        if isGuildRankEligibleForWowRank(match and match.setting, wowRankIndex) then
            eligibleRanks[#eligibleRanks + 1] = match
        end
    end

    local result = {
        inGuild = catalogue.inGuild,
        guildName = catalogue.guildName,
        guildRankName = catalogue.guildRankName,
        guildRankIndex = catalogue.guildRankIndex,
        guildKey = catalogue.guildKey,
        wowRankIndex = normalizeWowGuildRankIndex(wowRankIndex),
        ranks = eligibleRanks,
        matches = eligibleRanks,
        conflict = false,
        applicableRanks = catalogue.ranks,
        reason = catalogue.reason,
        matchType = catalogue.matchType,
    }

    return eligibleRanks, result
end

function Guild:GetAssignedGuildRankRef()
    local identity = getGuildIdentity()
    return getAssignedGuildRankRef(identity)
end

local function buildAssignedGuildRankStatus()
    local identity = getGuildIdentity()
    local result = {
        status = nil,
        reason = nil,
        inGuild = identity.inGuild,
        guildName = identity.guildName,
        guildRankName = identity.guildRankName,
        guildRankIndex = identity.guildRankIndex,
        guildKey = getGuildKey(identity),
        assignedRankRef = nil,
        rank = nil,
        setting = nil,
        dataset = nil,
        match = nil,
        catalogue = nil,
    }

    if not identity.inGuild then
        result.status = "not-in-guild"
        result.reason = result.status
        return result
    end

    if trimText(identity.guildName) == "" then
        result.status = "guild-loading"
        result.reason = result.status
        return result
    end

    local assignedRankRef = getAssignedGuildRankRef(identity)
    result.assignedRankRef = assignedRankRef
    if not assignedRankRef then
        result.status = "unassigned"
        result.reason = result.status
        return result
    end

    local catalogue = buildApplicableGuildRankCatalogue()
    result.catalogue = catalogue
    local match = findMatchByRef(catalogue.ranks, assignedRankRef)
    if not match then
        local dataset, rank
        if type(Registry.ResolveGuildSettingReference) == "function" then
            dataset, rank = Registry:ResolveGuildSettingReference(assignedRankRef)
        end

        if not rank then
            result.status = "unknown-rank"
            result.reason = result.status
            return result
        end

        result.dataset = dataset
        result.rank = rank
        result.setting = rank
        result.status = "not-applicable"
        result.reason = result.status
        return result
    end

    result.match = match
    result.dataset = match.dataset
    result.rank = match.setting
    result.setting = match.setting

    if normalizeWowGuildRankIndex(identity.guildRankIndex) == nil then
        result.status = "guild-loading"
        result.reason = result.status
        return result
    end

    if not isGuildRankEligibleForWowRank(match.setting, identity.guildRankIndex) then
        result.status = "not-eligible-for-current-wow-rank"
        result.reason = result.status
        return result
    end

    result.status = "valid"
    result.reason = result.status
    return result
end

function Guild:GetAssignedGuildRankStatus()
    return buildAssignedGuildRankStatus()
end

function Guild:GetAssignedGuildRank()
    local result = buildAssignedGuildRankStatus()
    if result.status ~= "valid" then
        return nil, result
    end

    return result.rank, result
end

local function getInventoryService()
    return Client.Inventory or {}
end

local function findRequisition(rank, requisitionId)
    local normalizedId = trimText(requisitionId)
    if normalizedId == "" or type(rank and rank.requisitions) ~= "table" then
        return nil
    end

    for index = 1, #rank.requisitions do
        local requisition = rank.requisitions[index]
        if trimText(requisition and requisition.id) == normalizedId then
            return requisition
        end
    end

    return nil
end

local function parseItemReference(itemRef)
    local reference = trimText(itemRef)
    local separatorIndex = string.find(reference, ":", 1, true)
    if not separatorIndex then
        return nil, nil
    end

    local datasetId = trimText(string.sub(reference, 1, separatorIndex - 1))
    local itemId = trimText(string.sub(reference, separatorIndex + 1))
    if datasetId == "" or itemId == "" then
        return nil, nil
    end

    return datasetId, itemId
end

local function getCurrencyCosts(costs)
    if type(Profile.NormalizeCurrencyKey) ~= "function"
        or type(Profile.ResolveCurrencyDefinition) ~= "function" then
        return nil, "currency-api-unavailable"
    end

    local normalizedCosts = {}
    local byCurrency = {}
    local costList = type(costs) == "table" and costs or {}
    for index = 1, #costList do
        local cost = costList[index]
        local currencyRef = Profile.NormalizeCurrencyKey(cost and cost.currencyRef)
        if currencyRef == "" then
            return nil, "currency-unavailable", {
                costIndex = index,
            }
        end

        local resolved, definition = pcall(Profile.ResolveCurrencyDefinition, currencyRef)
        if not resolved or type(definition) ~= "table" or definition.isMissing == true then
            return nil, "currency-unavailable", {
                currencyRef = currencyRef,
                costIndex = index,
            }
        end

        local amount = tonumber(cost and cost.amount)
        if not amount or amount ~= amount or amount == math.huge or amount == -math.huge or amount < 0 then
            return nil, "invalid-currency-cost", {
                currencyRef = currencyRef,
                costIndex = index,
            }
        end
        amount = math.floor(amount)

        local entry = byCurrency[currencyRef]
        if not entry then
            entry = {
                currencyRef = currencyRef,
                amount = 0,
                definition = definition,
            }
            byCurrency[currencyRef] = entry
            normalizedCosts[#normalizedCosts + 1] = entry
        end
        entry.amount = entry.amount + amount
    end

    return normalizedCosts
end

local function getInventoryItemQuantity(inventory, datasetId, itemId)
    if type(inventory.GetItems) ~= "function" then
        return nil
    end

    local ok, items = pcall(inventory.GetItems)
    if not ok or type(items) ~= "table" then
        return nil
    end

    local quantity = 0
    for index = 1, #items do
        local item = items[index]
        if tostring(item and item.dataset or "") == datasetId
            and tostring(item and item.id or "") == itemId then
            quantity = quantity + math.max(0, math.floor(tonumber(item.quantity or item.count) or 0))
        end
    end

    return quantity
end

local function removeInventoryItemQuantity(inventory, datasetId, itemId, quantity)
    local remaining = math.max(0, math.floor(tonumber(quantity) or 0))
    if remaining == 0 then
        return true
    end
    if type(inventory.GetItems) ~= "function" or type(inventory.RemoveItem) ~= "function" then
        return false
    end

    local ok, items = pcall(inventory.GetItems)
    if not ok or type(items) ~= "table" then
        return false
    end

    for index = #items, 1, -1 do
        local item = items[index]
        if tostring(item and item.dataset or "") == datasetId
            and tostring(item and item.id or "") == itemId then
            local itemQuantity = math.max(1, math.floor(tonumber(item.quantity or item.count) or 1))
            local removeQuantity = math.min(itemQuantity, remaining)
            local removed, result = pcall(inventory.RemoveItem, index, removeQuantity)
            if not removed or not result then
                return false
            end

            remaining = remaining - removeQuantity
            if remaining <= 0 then
                return true
            end
        end
    end

    return false
end

local function restoreCurrencySnapshots(snapshots)
    local restored = true
    if type(Profile.SetCurrencyAmount) ~= "function" or type(Profile.GetCurrencyAmount) ~= "function" then
        return false
    end

    for index = #snapshots, 1, -1 do
        local snapshot = snapshots[index]
        local ok, result = pcall(Profile.SetCurrencyAmount, snapshot.currencyRef, snapshot.amount)
        local gotAmount, actual = pcall(Profile.GetCurrencyAmount, snapshot.currencyRef)
        actual = gotAmount and (tonumber(actual) or 0) or nil
        if not ok or result == nil or not gotAmount or actual ~= snapshot.amount then
            restored = false
        end
    end

    return restored
end

local function buildRequisitionFailure(reason, detail)
    return false, reason, detail
end

function Guild:GetRequisitionEligibility(guildRankRef, requisitionId)
    local identity = getGuildIdentity()
    if not identity.inGuild then
        return buildRequisitionFailure("not-in-guild")
    end

    local guildKey = getGuildKey(identity)
    if guildKey == "" then
        return buildRequisitionFailure("guild-loading")
    end

    local ok, assignment = pcall(self.GetAssignedGuildRankStatus, self)
    if not ok or type(assignment) ~= "table" then
        return buildRequisitionFailure("invalid-assigned-rank")
    end

    if assignment.status == "not-in-guild" or assignment.status == "guild-loading" then
        return buildRequisitionFailure(assignment.status)
    end
    if assignment.status == "unassigned" then
        return buildRequisitionFailure("no-assigned-rank")
    end
    if assignment.status ~= "valid" or type(assignment.rank) ~= "table" then
        return buildRequisitionFailure("invalid-assigned-rank", assignment)
    end

    local assignedRankRef = trimText(assignment.assignedRankRef)
    local requestedRankRef = trimText(guildRankRef)
    if requestedRankRef == "" or requestedRankRef ~= assignedRankRef then
        return buildRequisitionFailure("rank-mismatch", {
            assignedRankRef = assignedRankRef,
            requestedRankRef = requestedRankRef,
        })
    end

    local general = type(assignment.rank.general) == "table" and assignment.rank.general or {}
    if general.enableRequisitions ~= true then
        return buildRequisitionFailure("requisitions-disabled", assignment)
    end

    local normalizedRequisitionId = trimText(requisitionId)
    local requisition = findRequisition(assignment.rank, normalizedRequisitionId)
    if not requisition then
        return buildRequisitionFailure("requisition-unavailable")
    end

    local itemRef = trimText(requisition.itemRef)
    local itemDataset, item = nil, nil
    if type(Registry.ResolveItemReference) == "function" then
        local resolved
        resolved, itemDataset, item = pcall(Registry.ResolveItemReference, Registry, itemRef)
        if not resolved then
            itemDataset, item = nil, nil
        end
    end
    if type(itemDataset) ~= "table" or type(item) ~= "table" then
        return buildRequisitionFailure("item-unavailable", {
            itemRef = itemRef,
        })
    end

    local datasetId, itemId = parseItemReference(itemRef)
    if not datasetId or not itemId then
        return buildRequisitionFailure("item-unavailable", {
            itemRef = itemRef,
        })
    end

    if type(Profile.GetGuildRequisitionUsage) ~= "function" then
        return buildRequisitionFailure("ledger-unavailable")
    end
    local usage = Profile.GetGuildRequisitionUsage(guildKey, assignedRankRef, normalizedRequisitionId)
    usage = math.max(0, math.floor(tonumber(usage) or 0))
    local characterLimit = tonumber(requisition.characterLimit)
    if not characterLimit or characterLimit ~= characterLimit or characterLimit == math.huge or characterLimit == -math.huge then
        characterLimit = 1
    end
    characterLimit = math.max(1, math.floor(characterLimit))
    if usage >= characterLimit then
        return buildRequisitionFailure("character-limit-reached", {
            usage = usage,
            characterLimit = characterLimit,
            requisitionId = normalizedRequisitionId,
        })
    end

    local normalizedCosts, costReason, costDetail = getCurrencyCosts(requisition.costs)
    if not normalizedCosts then
        return buildRequisitionFailure(costReason, costDetail)
    end

    if type(Profile.GetCurrencyAmount) ~= "function" then
        return buildRequisitionFailure("currency-api-unavailable")
    end
    for index = 1, #normalizedCosts do
        local cost = normalizedCosts[index]
        local balance = tonumber(Profile.GetCurrencyAmount(cost.currencyRef)) or 0
        if balance < cost.amount then
            return buildRequisitionFailure("insufficient-currency", {
                currencyRef = cost.currencyRef,
                balance = balance,
                amount = cost.amount,
            })
        end
    end

    local inventory = getInventoryService()
    if type(inventory.AddItem) ~= "function" then
        return buildRequisitionFailure("inventory-unavailable")
    end

    return true, nil, {
        identity = identity,
        guildKey = guildKey,
        assignment = assignment,
        assignedRankRef = assignedRankRef,
        requisitionId = normalizedRequisitionId,
        requisition = requisition,
        itemRef = itemRef,
        itemDataset = itemDataset,
        item = item,
        datasetId = datasetId,
        itemId = itemId,
        quantity = math.max(1, math.floor(tonumber(requisition.quantity) or 1)),
        costs = normalizedCosts,
        usage = usage,
        characterLimit = characterLimit,
    }
end

function Guild:TryRequisition(guildRankRef, requisitionId)
    local eligible, reason, detail = self:GetRequisitionEligibility(guildRankRef, requisitionId)
    if not eligible then
        return false, reason, detail
    end

    local snapshots = {}
    for index = 1, #detail.costs do
        local cost = detail.costs[index]
        local balance = tonumber(Profile.GetCurrencyAmount(cost.currencyRef)) or 0
        snapshots[#snapshots + 1] = {
            currencyRef = cost.currencyRef,
            amount = balance,
        }
    end

    local function rollbackCurrencies()
        return restoreCurrencySnapshots(snapshots)
    end

    if type(Profile.SpendCurrencyAmount) ~= "function" then
        return false, "currency-api-unavailable", detail
    end

    for index = 1, #detail.costs do
        local cost = detail.costs[index]
        local before = snapshots[index].amount
        local expected = before - cost.amount
        local callOk, spendOk, updated = pcall(Profile.SpendCurrencyAmount, cost.currencyRef, cost.amount)
        local gotAfter, after = pcall(Profile.GetCurrencyAmount, cost.currencyRef)
        after = gotAfter and (tonumber(after) or 0) or nil
        if not callOk or spendOk ~= true or not gotAfter or updated ~= expected or after ~= expected then
            local restored = rollbackCurrencies()
            return false, restored and "currency-transaction-failed" or "rollback-failed", detail
        end
    end

    local inventory = getInventoryService()
    local quantityBefore = getInventoryItemQuantity(inventory, detail.datasetId, detail.itemId)
    local added, addedRecord = pcall(inventory.AddItem, {
        dataset = detail.datasetId,
        id = detail.itemId,
        quantity = detail.quantity,
    })
    if not added or not addedRecord then
        local restored = rollbackCurrencies()
        return false, restored and "inventory-award-failed" or "rollback-failed", detail
    end

    local quantityAfter = getInventoryItemQuantity(inventory, detail.datasetId, detail.itemId)
    local awardedQuantity = detail.quantity
    if quantityBefore ~= nil and quantityAfter ~= nil then
        awardedQuantity = math.max(0, quantityAfter - quantityBefore)
    end

    local expectedUsage = detail.usage + 1
    local updatedUsage = nil
    if type(Profile.IncrementGuildRequisitionUsage) == "function" then
        local incremented
        incremented, updatedUsage = pcall(Profile.IncrementGuildRequisitionUsage,
            detail.guildKey,
            detail.assignedRankRef,
            detail.requisitionId
        )
        if not incremented then
            updatedUsage = nil
        end
    end

    if updatedUsage ~= expectedUsage then
        local itemRestored = removeInventoryItemQuantity(
            inventory,
            detail.datasetId,
            detail.itemId,
            awardedQuantity
        )
        local ledgerRestored = false
        if itemRestored and type(Profile.SetGuildRequisitionUsage) == "function" then
            local restored, restoredUsage = pcall(Profile.SetGuildRequisitionUsage,
                detail.guildKey,
                detail.assignedRankRef,
                detail.requisitionId,
                detail.usage
            )
            ledgerRestored = restored and restoredUsage == detail.usage
        end
        local currenciesRestored = rollbackCurrencies()
        if itemRestored and ledgerRestored and currenciesRestored then
            return false, "ledger-update-failed", detail
        end

        -- If the item cannot be removed, leave a successful ledger increment
        -- intact when possible so a granted item cannot be claimed a second time.
        return false, "rollback-failed", detail
    end

    pcall(self.RefreshWindow, self)
    return true, "ok", {
        guildRankRef = detail.assignedRankRef,
        requisitionId = detail.requisitionId,
        itemRef = detail.itemRef,
        quantity = detail.quantity,
        usage = updatedUsage,
        characterLimit = detail.characterLimit,
    }
end

local function getDailyRewardDayKey()
    if type(Common.GetNow) ~= "function" or type(date) ~= "function" then
        return nil
    end

    local timestamp = tonumber(Common.GetNow())
    if not timestamp then
        return nil
    end

    local ok, dayKey = pcall(date, "%Y-%m-%d", timestamp)
    if not ok or type(dayKey) ~= "string" or dayKey == "" then
        return nil
    end

    return dayKey
end

local function buildDailyRewardPlan(rank)
    local rewards = type(rank and rank.dailyRewards) == "table" and rank.dailyRewards or {}
    local plan = {}
    local needsItemAward = false
    local needsCurrencyAward = false

    for index = 1, #rewards do
        local reward = rewards[index]
        local rewardId = trimText(reward and reward.id)
        local rewardType = string.lower(trimText(reward and reward.type))
        local rewardRef = trimText(reward and reward.ref)
        local amount = tonumber(reward and reward.amount)
        if rewardId == ""
            or (rewardType ~= "item" and rewardType ~= "currency")
            or rewardRef == ""
            or not amount
            or amount ~= amount
            or amount == math.huge
            or amount == -math.huge
            or amount < 1
            or amount ~= math.floor(amount) then
            return nil, "invalid-reward-definition", {
                rewardIndex = index,
                rewardId = rewardId,
            }
        end
        amount = math.floor(amount)

        if rewardType == "item" then
            if type(Registry.ResolveItemReference) ~= "function" then
                return nil, "item-api-unavailable", {
                    rewardIndex = index,
                    rewardId = rewardId,
                }
            end

            local callOk, dataset, item = pcall(Registry.ResolveItemReference, Registry, rewardRef)
            local datasetId, itemId = parseItemReference(rewardRef)
            if not callOk or type(dataset) ~= "table" or type(item) ~= "table" or not datasetId or not itemId then
                return nil, "item-unavailable", {
                    rewardIndex = index,
                    rewardId = rewardId,
                    ref = rewardRef,
                }
            end

            plan[#plan + 1] = {
                id = rewardId,
                type = rewardType,
                ref = rewardRef,
                amount = amount,
                datasetId = datasetId,
                itemId = itemId,
            }
            needsItemAward = true
        else
            if type(Profile.NormalizeCurrencyKey) ~= "function"
                or type(Profile.ResolveCurrencyDefinition) ~= "function" then
                return nil, "currency-api-unavailable", {
                    rewardIndex = index,
                    rewardId = rewardId,
                }
            end

            local currencyRef = Profile.NormalizeCurrencyKey(rewardRef)
            local callOk, definition = pcall(Profile.ResolveCurrencyDefinition, currencyRef)
            if currencyRef == ""
                or not callOk
                or type(definition) ~= "table"
                or definition.isMissing == true then
                return nil, "currency-unavailable", {
                    rewardIndex = index,
                    rewardId = rewardId,
                    ref = rewardRef,
                }
            end

            plan[#plan + 1] = {
                id = rewardId,
                type = rewardType,
                ref = rewardRef,
                currencyRef = currencyRef,
                amount = amount,
                definition = definition,
            }
            needsCurrencyAward = true
        end
    end

    return plan, nil, {
        needsItemAward = needsItemAward,
        needsCurrencyAward = needsCurrencyAward,
    }
end

local function getDailyRewardStatus(self)
    local identity = getGuildIdentity()
    local result = {
        status = nil,
        reason = nil,
        inGuild = identity.inGuild,
        guildName = identity.guildName,
        guildRankName = identity.guildRankName,
        guildRankIndex = identity.guildRankIndex,
        guildKey = getGuildKey(identity),
        assignedRankRef = nil,
        rank = nil,
        rewards = {},
        dayKey = nil,
        claimDate = nil,
        claimRankRef = nil,
        plan = nil,
    }

    if not identity.inGuild then
        result.status = "not-in-guild"
        result.reason = result.status
        return result
    end

    if result.guildKey == "" then
        result.status = "guild-loading"
        result.reason = result.status
        return result
    end

    local assignmentOk, assignment = pcall(self.GetAssignedGuildRankStatus, self)
    if not assignmentOk or type(assignment) ~= "table" then
        result.status = "invalid-assigned-rank"
        result.reason = result.status
        return result
    end

    result.assignment = assignment
    result.assignedRankRef = trimText(assignment.assignedRankRef)
    result.rank = assignment.rank
    result.rewards = type(assignment.rank and assignment.rank.dailyRewards) == "table"
        and assignment.rank.dailyRewards
        or {}

    if assignment.status == "not-in-guild" or assignment.status == "guild-loading" then
        result.status = assignment.status
        result.reason = result.status
        return result
    end
    if assignment.status == "unassigned" then
        result.status = "no-assigned-rank"
        result.reason = result.status
        return result
    end
    if assignment.status ~= "valid" or type(assignment.rank) ~= "table" then
        result.status = "invalid-assigned-rank"
        result.reason = result.status
        return result
    end

    local general = type(assignment.rank.general) == "table" and assignment.rank.general or {}
    if general.enableDailyRewards ~= true then
        result.status = "daily-rewards-disabled"
        result.reason = result.status
        return result
    end

    local dayKey = getDailyRewardDayKey()
    if not dayKey then
        result.status = "calendar-unavailable"
        result.reason = result.status
        return result
    end
    result.dayKey = dayKey

    if type(Profile.GetDailyRewardClaim) ~= "function" then
        result.status = "profile-api-unavailable"
        result.reason = result.status
        return result
    end

    local claimCallOk, claimDate, claimRankRef = pcall(Profile.GetDailyRewardClaim, result.guildKey)
    if not claimCallOk then
        result.status = "profile-api-unavailable"
        result.reason = result.status
        return result
    end
    result.claimDate = claimDate
    result.claimRankRef = claimRankRef
    if claimDate == dayKey then
        result.status = "received-today"
        result.reason = result.status
        return result
    end

    local plan, planReason, planDetail = buildDailyRewardPlan(assignment.rank)
    if not plan then
        result.status = planReason or "invalid-reward-definition"
        result.reason = result.status
        result.detail = planDetail
        return result
    end

    local planFlags = planDetail or {}
    local inventory = getInventoryService()
    if planFlags.needsItemAward and type(inventory.AddItem) ~= "function" then
        result.status = "inventory-api-unavailable"
        result.reason = result.status
        return result
    end
    if planFlags.needsCurrencyAward
        and (type(Profile.GetCurrencyAmount) ~= "function"
            or type(Profile.AddCurrencyAmount) ~= "function"
            or type(Profile.SetCurrencyAmount) ~= "function") then
        result.status = "currency-api-unavailable"
        result.reason = result.status
        return result
    end

    result.status = "available-today"
    result.reason = result.status
    result.plan = plan
    return result
end

function Guild:GetDailyRewardStatus()
    return getDailyRewardStatus(self)
end

local function createDailyRewardTransaction()
    local transaction = {
        itemAwards = {},
        currencySnapshots = {},
    }

    function transaction:Rollback()
        local restored = true
        local inventory = getInventoryService()
        for index = #self.itemAwards, 1, -1 do
            local award = self.itemAwards[index]
            if not removeInventoryItemQuantity(
                inventory,
                award.datasetId,
                award.itemId,
                award.amount
            ) then
                restored = false
            end
        end

        if not restoreCurrencySnapshots(self.currencySnapshots) then
            restored = false
        end

        return restored
    end

    return transaction
end

local function awardDailyRewardPlan(plan)
    local transaction = createDailyRewardTransaction()
    local inventory = getInventoryService()
    local currencySnapshotsByRef = {}

    for index = 1, #plan do
        local reward = plan[index]
        if reward.type == "currency" and not currencySnapshotsByRef[reward.currencyRef] then
            local gotAmount, amount = pcall(Profile.GetCurrencyAmount, reward.currencyRef)
            if not gotAmount then
                transaction:Rollback()
                return false, "currency-read-failed", transaction
            end

            local snapshot = {
                currencyRef = reward.currencyRef,
                amount = tonumber(amount) or 0,
            }
            currencySnapshotsByRef[reward.currencyRef] = snapshot
            transaction.currencySnapshots[#transaction.currencySnapshots + 1] = snapshot
        end
    end

    for index = 1, #plan do
        local reward = plan[index]
        if reward.type == "item" then
            local quantityBefore = getInventoryItemQuantity(inventory, reward.datasetId, reward.itemId)
            local callOk, addedRecord = pcall(inventory.AddItem, {
                dataset = reward.datasetId,
                id = reward.itemId,
                quantity = reward.amount,
            })
            local quantityAfter = getInventoryItemQuantity(inventory, reward.datasetId, reward.itemId)
            local awardedAmount = reward.amount
            local measuredAward = quantityBefore ~= nil and quantityAfter ~= nil
            if measuredAward then
                awardedAmount = math.max(0, quantityAfter - quantityBefore)
            end

            if awardedAmount > 0 and (measuredAward or (callOk and addedRecord)) then
                transaction.itemAwards[#transaction.itemAwards + 1] = {
                    datasetId = reward.datasetId,
                    itemId = reward.itemId,
                    amount = awardedAmount,
                }
            end

            if not callOk or not addedRecord or awardedAmount < reward.amount then
                local rolledBack = transaction:Rollback()
                return false, rolledBack and "item-award-failed" or "rollback-failed", transaction
            end
        else
            local snapshot = currencySnapshotsByRef[reward.currencyRef]
            local callOk, addedAmount = pcall(Profile.AddCurrencyAmount, reward.currencyRef, reward.amount)
            local gotAfter, after = pcall(Profile.GetCurrencyAmount, reward.currencyRef)
            after = gotAfter and (tonumber(after) or 0) or nil
            if not callOk
                or addedAmount == nil
                or not gotAfter
                or after < snapshot.amount then
                local rolledBack = transaction:Rollback()
                return false, rolledBack and "currency-award-failed" or "rollback-failed", transaction
            end
        end
    end

    return true, "ok", transaction
end

function Guild:ProcessDailyRewards()
    if self._dailyRewardProcessing == true then
        return false, "processing"
    end

    self._dailyRewardProcessing = true
    local callOk, success, reason, result = xpcall(function()
        local status = self:GetDailyRewardStatus()
        if status.status ~= "available-today" then
            return false, status.status, status
        end

        local awarded, awardReason, transaction = awardDailyRewardPlan(status.plan or {})
        if not awarded then
            return false, awardReason, status
        end

        if type(Profile.SetDailyRewardClaim) ~= "function" then
            local rolledBack = transaction:Rollback()
            return false, rolledBack and "claim-persistence-unavailable" or "rollback-failed", status
        end

        local claimCallOk, persistedBucket = pcall(
            Profile.SetDailyRewardClaim,
            status.guildKey,
            status.dayKey,
            status.assignedRankRef
        )
        local storedCallOk, storedDate, storedRankRef = pcall(Profile.GetDailyRewardClaim, status.guildKey)
        if not claimCallOk
            or type(persistedBucket) ~= "table"
            or not storedCallOk
            or storedDate ~= status.dayKey
            or storedRankRef ~= status.assignedRankRef then
            local rolledBack = transaction:Rollback()
            return false, rolledBack and "claim-persistence-failed" or "rollback-failed", status
        end

        pcall(self.RefreshWindow, self)
        return true, "claimed", {
            dayKey = status.dayKey,
            guildRankRef = status.assignedRankRef,
            rewardCount = #(status.plan or {}),
        }
    end, function(errorMessage)
        return tostring(errorMessage)
    end)
    self._dailyRewardProcessing = false

    if not callOk then
        return false, "processing-failed", {
            error = reason,
        }
    end

    return success, reason, result
end

function Guild:IsGuildAdminTargetAvailable(targetName)
    local identity = getGuildIdentity()
    if not identity.inGuild then
        return false, "sender-not-in-guild"
    end

    if self:IsLocalPlayerOfficer() ~= true then
        return false, "sender-not-officer"
    end

    local member = findRosterMember(self, targetName)
    if not member then
        return false, "target-not-in-guild"
    end

    if member.online ~= true then
        return false, "target-offline"
    end

    return true, nil, member
end

local function sendGuildAdminRequest(self, opcode, targetName, arguments, pending)
    local requestId = pending.requestId
    registerGuildAdminPending(self, requestId, pending)
    if sendGuildAdminMessage(opcode, targetName, arguments) then
        return true, requestId
    end

    self._guildAdminPending[requestId] = nil
    invokeGuildAdminCallback(pending, {
        requestId = requestId,
        protocolVersion = GUILD_ADMIN_PROTOCOL_VERSION,
        success = false,
        reason = "send-failed",
    })
    return false, "send-failed"
end

function Guild:QueryGuildAdminMember(targetName, callback)
    local available, reason, member = self:IsGuildAdminTargetAvailable(targetName)
    if not available then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            reason = reason,
        })
        return false, reason
    end

    local requestId = getGuildAdminRequestId()
    return sendGuildAdminRequest(self, GUILD_ADMIN_QUERY_OPCODE, member.name, {
        requestId,
        GUILD_ADMIN_PROTOCOL_VERSION,
        member.name,
    }, {
        requestId = requestId,
        kind = "query",
        targetName = member.name,
        callback = callback,
    })
end

function Guild:SetGuildRankForMember(targetName, guildRankRef, callback)
    local available, reason, member = self:IsGuildAdminTargetAvailable(targetName)
    local normalizedRef = trimText(guildRankRef)
    if not available then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            reason = reason,
        })
        return false, reason
    end

    if normalizedRef == "" then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            reason = "unknown-guild-rank",
        })
        return false, "unknown-guild-rank"
    end

    local requestId = getGuildAdminRequestId()
    return sendGuildAdminRequest(self, GUILD_ADMIN_MUTATION_OPCODE, member.name, {
        requestId,
        GUILD_ADMIN_PROTOCOL_VERSION,
        "set_guild_rank",
        member.name,
        normalizedRef,
    }, {
        requestId = requestId,
        kind = "mutation",
        operation = "set_guild_rank",
        targetName = member.name,
        callback = callback,
    })
end

function Guild:ClearGuildRankForMember(targetName, callback)
    local available, reason, member = self:IsGuildAdminTargetAvailable(targetName)
    if not available then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            reason = reason,
        })
        return false, reason
    end

    local requestId = getGuildAdminRequestId()
    return sendGuildAdminRequest(self, GUILD_ADMIN_MUTATION_OPCODE, member.name, {
        requestId,
        GUILD_ADMIN_PROTOCOL_VERSION,
        "clear_guild_rank",
        member.name,
        "",
    }, {
        requestId = requestId,
        kind = "mutation",
        operation = "clear_guild_rank",
        targetName = member.name,
        callback = callback,
    })
end

local function getPendingResponse(self, arguments, sender, distribution)
    local requestId = getArgument(arguments, 1)
    local pending = self._guildAdminPending and self._guildAdminPending[requestId] or nil
    if not pending or distribution ~= "WHISPER" then
        return nil, nil
    end

    if normalizePlayerName(sender) ~= normalizePlayerName(pending.targetName) then
        return nil, nil
    end

    return requestId, pending
end

function Guild:HandleGuildAdminQueryResponse(arguments, sender, distribution, target, message)
    local requestId, pending = getPendingResponse(self, arguments, sender, distribution)
    if not requestId or not pending or pending.kind ~= "query" then
        return false
    end

    local protocolVersion = getArgument(arguments, 2)
    if protocolVersion ~= GUILD_ADMIN_PROTOCOL_VERSION then
        return completeGuildAdminPending(self, requestId, {
            requestId = requestId,
            protocolVersion = protocolVersion,
            success = false,
            reason = "incompatible-protocol",
            sender = sender,
        })
    end

    return completeGuildAdminPending(self, requestId, {
        requestId = requestId,
        protocolVersion = protocolVersion,
        success = isSuccessfulArgument(getArgument(arguments, 3)),
        reason = getArgument(arguments, 4),
        assignedRankRef = getArgument(arguments, 5),
        guildRankIndex = tonumber(getArgument(arguments, 6)),
        guildRankName = getArgument(arguments, 7),
        guildName = getArgument(arguments, 8),
        sender = sender,
    })
end

function Guild:HandleGuildAdminMutationResponse(arguments, sender, distribution, target, message)
    local requestId, pending = getPendingResponse(self, arguments, sender, distribution)
    if not requestId or not pending or pending.kind ~= "mutation" then
        return false
    end

    local protocolVersion = getArgument(arguments, 2)
    local operation = getArgument(arguments, 3)
    if protocolVersion ~= GUILD_ADMIN_PROTOCOL_VERSION or operation ~= pending.operation then
        return completeGuildAdminPending(self, requestId, {
            requestId = requestId,
            protocolVersion = protocolVersion,
            operation = operation,
            success = false,
            reason = "incompatible-protocol",
            sender = sender,
        })
    end

    return completeGuildAdminPending(self, requestId, {
        requestId = requestId,
        protocolVersion = protocolVersion,
        operation = operation,
        success = isSuccessfulArgument(getArgument(arguments, 4)),
        reason = getArgument(arguments, 5),
        assignedRankRef = getArgument(arguments, 6),
        sender = sender,
    })
end

function Guild:HandleGuildAdminQuery(arguments, sender, distribution, target, message)
    local requestId, reason, identity = validateGuildAdminRequest(self, arguments, sender, distribution, 3)
    if not requestId then
        return false
    end

    if reason then
        return sendGuildAdminMessage(
            GUILD_ADMIN_QUERY_RESPONSE_OPCODE,
            sender,
            buildQueryResponseArguments(requestId, false, reason)
        )
    end

    return sendGuildAdminMessage(
        GUILD_ADMIN_QUERY_RESPONSE_OPCODE,
        sender,
        buildQueryResponseArguments(requestId, true, "ok", identity, getAssignedGuildRankRef(identity))
    )
end

function Guild:HandleGuildAdminMutation(arguments, sender, distribution, target, message)
    local operation = getArgument(arguments, 3)
    local requestId, reason, identity = validateGuildAdminRequest(self, arguments, sender, distribution, 4)
    if not requestId then
        return false
    end

    if reason then
        return sendGuildAdminMessage(
            GUILD_ADMIN_MUTATION_RESPONSE_OPCODE,
            sender,
            buildMutationResponseArguments(requestId, operation, false, reason)
        )
    end

    if operation == "set_guild_rank" then
        local guildRankRef = getArgument(arguments, 5)
        local applicableRanks = self:GetApplicableGuildRanks()
        local applicableMatch = findMatchByRef(applicableRanks, guildRankRef)
        if not applicableMatch then
            local _, rank = getResolvedGuildRankReference(guildRankRef)
            reason = rank and "rank-not-applicable" or "unknown-guild-rank"
        elseif normalizeWowGuildRankIndex(identity.guildRankIndex) == nil then
            reason = "rank-not-eligible"
        else
            local eligibleRanks = self:GetEligibleGuildRanksForWoWRank(identity.guildRankIndex)
            if not findMatchByRef(eligibleRanks, guildRankRef) then
                reason = "rank-not-eligible"
            elseif type(Profile.SetAssignedGuildRank) ~= "function" then
                reason = "persistence-failed"
            else
                local assignment = Profile.SetAssignedGuildRank(getGuildKey(identity), guildRankRef, {
                    assignedRankAt = type(Common.GetNow) == "function" and Common.GetNow() or nil,
                    assignedRankBy = tostring(sender or ""),
                })
                if not assignment then
                    reason = "persistence-failed"
                else
                    self:RefreshWindow()
                    return sendGuildAdminMessage(
                        GUILD_ADMIN_MUTATION_RESPONSE_OPCODE,
                        sender,
                        buildMutationResponseArguments(requestId, operation, true, "ok", guildRankRef)
                    )
                end
            end
        end

        return sendGuildAdminMessage(
            GUILD_ADMIN_MUTATION_RESPONSE_OPCODE,
            sender,
            buildMutationResponseArguments(requestId, operation, false, reason)
        )
    end

    if operation == "clear_guild_rank" then
        if type(Profile.ClearAssignedGuildRank) ~= "function" then
            reason = "persistence-failed"
        else
            local existingRankRef = getAssignedGuildRankRef(identity)
            local cleared = Profile.ClearAssignedGuildRank(getGuildKey(identity))
            if not cleared and existingRankRef then
                reason = "persistence-failed"
            else
                self:RefreshWindow()
                return sendGuildAdminMessage(
                    GUILD_ADMIN_MUTATION_RESPONSE_OPCODE,
                    sender,
                    buildMutationResponseArguments(requestId, operation, true, "ok")
                )
            end
        end

        return sendGuildAdminMessage(
            GUILD_ADMIN_MUTATION_RESPONSE_OPCODE,
            sender,
            buildMutationResponseArguments(requestId, operation, false, reason)
        )
    end

    return sendGuildAdminMessage(
        GUILD_ADMIN_MUTATION_RESPONSE_OPCODE,
        sender,
        buildMutationResponseArguments(requestId, operation, false, "unsupported-operation")
    )
end

-- Compatibility facade for the existing Guild pages. The complete catalogue is
-- available through GetApplicableGuildRanks; this wrapper never reports a
-- multi-rank catalogue as a conflict or selects one rank as authoritative.
function Guild:ResolveActiveGuildSetting()
    local catalogue = buildApplicableGuildRankCatalogue()
    local result = {
        inGuild = catalogue.inGuild,
        guildName = catalogue.guildName,
        guildRankName = catalogue.guildRankName,
        guildRankIndex = catalogue.guildRankIndex,
        setting = nil,
        dataset = nil,
        matches = catalogue.ranks,
        conflict = false,
        reason = catalogue.reason,
        catalogue = catalogue,
    }

    if #catalogue.ranks == 1 then
        result.setting = catalogue.ranks[1].setting
        result.dataset = catalogue.ranks[1].dataset
        result.match = catalogue.ranks[1]
    elseif #catalogue.ranks > 1 then
        result.reason = "multiple"
    end

    return result
end

function Guild:GetActiveGuildSetting()
    local resolution = self:ResolveActiveGuildSetting()
    return resolution.setting, resolution
end

function Guild:IsLocalPlayerOfficer()
    return hasOfficerPermission()
end

function Guild:RequestRosterUpdate()
    local now = type(GetTime) == "function" and GetTime() or 0
    if self._lastRosterRequest and now - self._lastRosterRequest < 2 then
        return false
    end

    local guildInfo = _G and _G.C_GuildInfo or nil
    local request = guildInfo and guildInfo.GuildRoster or _G and _G.GuildRoster or nil
    if type(request) ~= "function" then
        return false
    end

    local ok = pcall(request)
    if ok then
        self._lastRosterRequest = now
    end
    return ok
end

function Guild:GetRoster()
    local identity = getGuildIdentity()
    if not identity.inGuild then
        return {}
    end

    self:RequestRosterUpdate()

    local count = type(GetNumGuildMembers) == "function" and (GetNumGuildMembers() or 0) or 0
    local roster = {}
    for index = 1, count do
        if type(GetGuildRosterInfo) == "function" then
            local ok, name, rankName, rankIndex, level, className, zone, note, _, online = pcall(GetGuildRosterInfo, index)
            if ok and name then
                roster[#roster + 1] = {
                    name = ensureString(name),
                    rankName = ensureString(rankName),
                    rankIndex = tonumber(rankIndex),
                    level = tonumber(level) or 0,
                    className = ensureString(className),
                    zone = ensureString(zone),
                    note = ensureString(note),
                    online = online == true,
                }
            end
        end
    end

    return roster
end

function Guild:RefreshWindow()
    local guildUI = Client.UI and Client.UI.Guild or nil
    local windowController = guildUI and guildUI.Window or nil
    local window = windowController and windowController.Get and windowController:Get() or nil
    if not window or not window.IsVisible or not window:IsVisible() then
        return nil
    end

    return window.Refresh and window:Refresh() or nil
end

function Guild:HandleRuntimeEvent(event)
    if event ~= "PLAYER_ENTERING_WORLD"
        and event ~= "PLAYER_GUILD_UPDATE"
        and event ~= "GUILD_ROSTER_UPDATE" then
        return nil
    end

    local dailyResult = self:ProcessDailyRewards()
    self:RefreshWindow()
    return dailyResult
end

return Guild
