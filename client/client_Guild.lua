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
            -- Treat officer-chat and guild-management permissions as the WoW
            -- officer capability. Sender-provided fields are never consulted.
            return permissions[3] == true
                or permissions[4] == true
                or permissions[5] == true
                or permissions[6] == true
                or permissions[7] == true
                or permissions[8] == true
                or permissions[9] == true
                or permissions[11] == true
                or permissions[12] == true
                or permissions[13] == true
        end
    end

    -- Compatibility fallback for clients that cannot expose rank flags. The
    -- guild master and first officer rank are the stable roster-only fallback.
    return rankIndex <= 1
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
    if event ~= "PLAYER_GUILD_UPDATE" and event ~= "GUILD_ROSTER_UPDATE" then
        return nil
    end

    return self:RefreshWindow()
end

return Guild
