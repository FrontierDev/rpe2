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
local DAILY_REWARD_CLAIM_SEMANTICS_RESET_CYCLE = "reset-cycle"

Guild._guildAdminPending = Guild._guildAdminPending or {}
Guild._guildAdminRequestSequence = tonumber(Guild._guildAdminRequestSequence) or 0

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function trimText(value)
    local text = ensureString(value)
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
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
    local realmName = ""
    local legacyRealmName = ""
    local guildClubId = ""

    local club = _G and _G.C_Club or nil
    if club and type(club.GetGuildClubId) == "function" then
        local ok, value = pcall(club.GetGuildClubId)
        if ok then
            guildClubId = trimText(value)
        end
    end

    if type(GetGuildInfo) == "function" then
        local ok, name, rankName, rankIndex, guildRealmName = pcall(GetGuildInfo, "player")
        if ok then
            guildName = ensureString(name)
            guildRankName = ensureString(rankName)
            guildRankIndex = tonumber(rankIndex)
            realmName = trimText(guildRealmName)
        end
    end

    -- Keep the local realm only as migration context. It must not become the
    -- current fallback key when the guild realm is unavailable: same-realm
    -- guilds intentionally use the name-only fallback until a Club ID exists.
    if type(GetRealmName) == "function" then
        local ok, currentRealm = pcall(GetRealmName)
        if ok then
            legacyRealmName = trimText(currentRealm)
        end
    end

    return {
        inGuild = inGuild,
        guildName = guildName,
        guildRankName = guildRankName,
        guildRankIndex = guildRankIndex,
        realmName = realmName,
        legacyRealmName = legacyRealmName,
        guildClubId = guildClubId,
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

local function normalizeProgressionSlotCount(value)
    local slotCount = tonumber(value)
    if not slotCount or slotCount ~= slotCount or slotCount == math.huge or slotCount == -math.huge then
        return 0
    end

    return math.max(0, math.floor(slotCount))
end

local function getGuildKey(identity)
    if type(Profile.GetGuildKey) ~= "function" then
        return ""
    end

    return trimText(Profile.GetGuildKey(identity))
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

local function getSortedStringKeys(values, predicate)
    local keys = {}
    for key, value in pairs(type(values) == "table" and values or {}) do
        local normalizedKey = trimText(key)
        if normalizedKey ~= "" and (type(predicate) ~= "function" or predicate(value)) then
            keys[#keys + 1] = normalizedKey
        end
    end

    table.sort(keys)
    return keys
end

local function appendQueryProfileStateArguments(arguments)
    local achievementStates = {}
    if type(Profile.ListAchievementStates) == "function" then
        local ok, states = pcall(Profile.ListAchievementStates)
        if ok and type(states) == "table" then
            achievementStates = states
        end
    end

    local completedAchievementRefs = getSortedStringKeys(achievementStates, function(state)
        return type(state) == "table" and state.completedAt ~= nil
    end)
    arguments[#arguments + 1] = tostring(#completedAchievementRefs)
    for index = 1, #completedAchievementRefs do
        local achievementRef = completedAchievementRefs[index]
        local state = achievementStates[achievementRef] or {}
        arguments[#arguments + 1] = achievementRef
        arguments[#arguments + 1] = state.completedAt
    end

    local skillLevels = {}
    if type(Profile.ListSkillLevels) == "function" then
        local ok, levels = pcall(Profile.ListSkillLevels)
        if ok and type(levels) == "table" then
            skillLevels = levels
        end
    end

    local skillRefs = getSortedStringKeys(skillLevels)
    arguments[#arguments + 1] = tostring(#skillRefs)
    for index = 1, #skillRefs do
        local skillRef = skillRefs[index]
        arguments[#arguments + 1] = skillRef
        arguments[#arguments + 1] = tonumber(skillLevels[skillRef]) or 0
    end

    return arguments
end

local function appendQueryProgressionStateArguments(arguments, snapshot)
    if type(snapshot) ~= "table" then
        arguments[#arguments + 1] = "0"
        return arguments
    end

    arguments[#arguments + 1] = "1"
    arguments[#arguments + 1] = trimText(snapshot.rankRef)
    arguments[#arguments + 1] = normalizeProgressionSlotCount(snapshot.slotCount)

    local slots = type(snapshot.slots) == "table" and snapshot.slots or {}
    local slotKeys = {}
    for slot, entryId in pairs(slots) do
        local numericSlot = tonumber(slot)
        local normalizedSlot = numericSlot and numericSlot == math.floor(numericSlot)
            and numericSlot >= 1 and math.floor(numericSlot) or nil
        if normalizedSlot and trimText(entryId) ~= "" then
            slotKeys[#slotKeys + 1] = normalizedSlot
        end
    end
    table.sort(slotKeys)
    arguments[#arguments + 1] = #slotKeys
    for index = 1, #slotKeys do
        local slot = slotKeys[index]
        arguments[#arguments + 1] = slot
        arguments[#arguments + 1] = trimText(slots[slot])
    end

    local unlockedKeys = getSortedStringKeys(snapshot.unlocked, function(value)
        return value == true
    end)
    arguments[#arguments + 1] = #unlockedKeys
    for index = 1, #unlockedKeys do
        arguments[#arguments + 1] = unlockedKeys[index]
    end

    local selectedSpells = type(snapshot.selectedSpells) == "table" and snapshot.selectedSpells or {}
    local selectedKeys = getSortedStringKeys(selectedSpells, function(value)
        return trimText(value) ~= ""
    end)
    arguments[#arguments + 1] = #selectedKeys
    for index = 1, #selectedKeys do
        local entryId = selectedKeys[index]
        arguments[#arguments + 1] = entryId
        arguments[#arguments + 1] = trimText(selectedSpells[entryId])
    end

    return arguments
end

local function buildQueryResponseArguments(requestId, success, reason, identity, assignedRankRef, progressionSnapshot)
    local arguments = {
        requestId,
        GUILD_ADMIN_PROTOCOL_VERSION,
        success and "1" or "0",
        reason or (success and "ok" or "unknown-error"),
        assignedRankRef or "",
        identity and identity.guildRankIndex or "",
        identity and identity.guildRankName or "",
        identity and identity.guildName or "",
    }
    if success then
        appendQueryProfileStateArguments(arguments)
        return appendQueryProgressionStateArguments(arguments, progressionSnapshot)
    end

    arguments[#arguments + 1] = ""
    arguments[#arguments + 1] = ""
    arguments[#arguments + 1] = "0"
    return arguments
end

local function buildMutationResponseArguments(requestId, operation, success, reason, assignedRankRef, detail, value)
    return {
        requestId,
        GUILD_ADMIN_PROTOCOL_VERSION,
        operation or "",
        success and "1" or "0",
        reason or (success and "ok" or "unknown-error"),
        assignedRankRef or "",
        detail or "",
        value or "",
    }
end

local function normalizeIntegerArgument(value, minimum, maximum)
    local numeric = tonumber(trimText(value))
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return nil
    end

    local integer = math.floor(numeric)
    if numeric ~= integer then
        return nil
    end
    if minimum ~= nil and integer < minimum then
        return nil
    end
    if maximum ~= nil and integer > maximum then
        return nil
    end

    return integer
end

local function normalizeCharacterLimit(value)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return 1
    end

    if numeric == 0 then
        return 0
    end

    return math.max(1, math.floor(numeric))
end

local function resolveAchievementReference(achievementRef)
    if type(Registry.ResolveAchievementReference) ~= "function" then
        return nil, nil
    end

    local ok, dataset, achievement = pcall(Registry.ResolveAchievementReference, Registry, achievementRef)
    if not ok or type(dataset) ~= "table" or type(achievement) ~= "table" then
        return nil, nil
    end

    return dataset, achievement
end

local function resolveSkillReference(skillRef)
    if type(Registry.ResolveSkillReference) ~= "function" then
        return nil, nil
    end

    local ok, dataset, skill = pcall(Registry.ResolveSkillReference, Registry, skillRef)
    if not ok or type(dataset) ~= "table" or type(skill) ~= "table" then
        return nil, nil
    end

    return dataset, skill
end

local function resolveItemReference(itemRef)
    if type(Registry.ResolveItemReference) ~= "function" then
        return nil, nil
    end

    local ok, dataset, item = pcall(Registry.ResolveItemReference, Registry, itemRef)
    if not ok or type(dataset) ~= "table" or type(item) ~= "table" then
        return nil, nil
    end

    return dataset, item
end

local function getSkillLevelBounds(skillRef, skill)
    local minimum = string.lower(trimText(skill and skill.skillType)) == "crafting" and 1 or 0
    local maximum = nil
    local hasResolvedRow = false
    if type(Profile.GetResolvedSkillRow) == "function" then
        hasResolvedRow = true
        local ok, row = pcall(Profile.GetResolvedSkillRow, skillRef)
        if ok and type(row) == "table" then
            maximum = normalizeIntegerArgument(row.maxValue, minimum)
        else
            return nil, nil, false
        end
    end

    if maximum ~= nil and maximum < minimum then
        return nil, nil, hasResolvedRow
    end

    return minimum, maximum, hasResolvedRow
end

local function parseQueryProfileStateArguments(arguments)
    local result = {
        achievements = {},
        skills = {},
        progression = nil,
    }
    local cursor = 9
    local achievementCount = normalizeIntegerArgument(getArgument(arguments, cursor), 0, 10000) or 0
    cursor = cursor + 1
    for index = 1, achievementCount do
        local achievementRef = getArgument(arguments, cursor)
        local completedAt = getArgument(arguments, cursor + 1)
        cursor = cursor + 2
        if achievementRef ~= "" and completedAt ~= "" then
            result.achievements[achievementRef] = {
                completedAt = completedAt,
            }
        end
    end

    local skillCount = normalizeIntegerArgument(getArgument(arguments, cursor), 0, 10000) or 0
    cursor = cursor + 1
    for index = 1, skillCount do
        local skillRef = getArgument(arguments, cursor)
        local level = normalizeIntegerArgument(getArgument(arguments, cursor + 1), 0)
        cursor = cursor + 2
        if skillRef ~= "" and level ~= nil then
            result.skills[skillRef] = level
        end
    end

    local progressionActive = getArgument(arguments, cursor)
    cursor = cursor + 1
    if isSuccessfulArgument(progressionActive) then
        local progression = {
            rankRef = getArgument(arguments, cursor),
            slotCount = normalizeIntegerArgument(getArgument(arguments, cursor + 1), 0) or 0,
            slots = {},
            unlocked = {},
            selectedSpells = {},
        }
        cursor = cursor + 2

        local slotCount = normalizeIntegerArgument(getArgument(arguments, cursor), 0, 10000) or 0
        cursor = cursor + 1
        for index = 1, slotCount do
            local slot = normalizeIntegerArgument(getArgument(arguments, cursor), 1)
            local entryId = getArgument(arguments, cursor + 1)
            cursor = cursor + 2
            if slot and entryId ~= "" then
                progression.slots[slot] = entryId
            end
        end

        local unlockedCount = normalizeIntegerArgument(getArgument(arguments, cursor), 0, 10000) or 0
        cursor = cursor + 1
        for index = 1, unlockedCount do
            local entryId = getArgument(arguments, cursor)
            cursor = cursor + 1
            if entryId ~= "" then
                progression.unlocked[entryId] = true
            end
        end

        local selectedCount = normalizeIntegerArgument(getArgument(arguments, cursor), 0, 10000) or 0
        cursor = cursor + 1
        for index = 1, selectedCount do
            local entryId = getArgument(arguments, cursor)
            local spellRef = getArgument(arguments, cursor + 1)
            cursor = cursor + 2
            if entryId ~= "" and spellRef ~= "" then
                progression.selectedSpells[entryId] = spellRef
            end
        end

        result.progression = progression
    end

    return result
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

local function getProgressionEntryMap(progression)
    local entries = type(progression and progression.entries) == "table" and progression.entries or {}
    local byId = {}
    for index = 1, #entries do
        local entry = entries[index]
        local entryId = trimText(entry and entry.id)
        if entryId ~= "" then
            byId[entryId] = entry
        end
    end

    return entries, byId
end

local function isConfiguredSpell(entry, spellRef)
    local normalizedRef = trimText(spellRef)
    if normalizedRef == "" then
        return false
    end

    local spellRefs = type(entry and entry.spellRefs) == "table" and entry.spellRefs or {}
    for index = 1, #spellRefs do
        if trimText(spellRefs[index]) == normalizedRef then
            return true
        end
    end

    return false
end

local function buildActiveGuildProgression(self)
    local result = {
        status = "unavailable",
        reason = "no-active-progression",
        guildKey = "",
        rankRef = nil,
        rank = nil,
        progression = nil,
        state = { slots = {}, unlocked = {}, selectedSpells = {} },
        activeSlots = {},
        activeUnlocked = {},
        activeSelectedSpells = {},
        entries = {},
        entryById = {},
        slotCount = 0,
    }

    local assignment = self:GetAssignedGuildRankStatus()
    result.assignment = assignment
    result.guildKey = trimText(assignment and assignment.guildKey)
    result.rankRef = trimText(assignment and assignment.assignedRankRef)
    result.rank = assignment and assignment.rank or nil
    if not assignment or assignment.status ~= "valid" or type(assignment.rank) ~= "table" then
        result.status = assignment and assignment.status or "unavailable"
        result.reason = assignment and assignment.reason or "no-active-progression"
        return result
    end

    local general = type(assignment.rank.general) == "table" and assignment.rank.general or {}
    if general.enableProgression ~= true then
        result.status = "progression-disabled"
        result.reason = result.status
        return result
    end

    local progression = type(assignment.rank.progression) == "table" and assignment.rank.progression or nil
    if not progression then
        result.status = "progression-unavailable"
        result.reason = result.status
        return result
    end

    result.status = "valid"
    result.reason = result.status
    result.progression = progression
    result.slotCount = normalizeProgressionSlotCount(progression.slotCount)
    result.entries, result.entryById = getProgressionEntryMap(progression)

    if type(Profile.GetGuildProgression) == "function" and result.guildKey ~= "" and result.rankRef ~= "" then
        local stateOk, state = pcall(Profile.GetGuildProgression, result.guildKey, result.rankRef)
        if stateOk and type(state) == "table" then
            result.state = state
        end
    end

    local rawState = result.state
    for slot = 1, result.slotCount do
        local entryId = trimText(rawState.slots and rawState.slots[slot])
        local entry = result.entryById[entryId]
        if entry and rawState.unlocked and rawState.unlocked[entryId] == true then
            result.activeSlots[slot] = entryId
        end
    end

    for index = 1, #result.entries do
        local entry = result.entries[index]
        local entryId = trimText(entry and entry.id)
        if entryId ~= "" and rawState.unlocked and rawState.unlocked[entryId] == true then
            result.activeUnlocked[entryId] = true
            local spellRef = trimText(rawState.selectedSpells and rawState.selectedSpells[entryId])
            if isConfiguredSpell(entry, spellRef) then
                result.activeSelectedSpells[entryId] = spellRef
            end
        end
    end

    return result
end

function Guild:GetActiveGuildProgression()
    return buildActiveGuildProgression(self)
end

local function getProgressionQuerySnapshot(self)
    if type(self.GetActiveGuildProgression) ~= "function" then
        return nil
    end

    local ok, active = pcall(self.GetActiveGuildProgression, self)
    if not ok or type(active) ~= "table" or active.status ~= "valid" then
        return nil
    end

    return {
        rankRef = active.rankRef,
        slotCount = active.slotCount,
        slots = active.state and active.state.slots or {},
        unlocked = active.state and active.state.unlocked or {},
        selectedSpells = active.state and active.state.selectedSpells or {},
    }
end

local function getProgressionMutationContext(self)
    local active = self:GetActiveGuildProgression()
    if active.status ~= "valid" then
        return nil, active.reason or "no-active-progression"
    end
    if type(Profile.SetGuildProgression) ~= "function" then
        return nil, "profile-api-unavailable"
    end

    return active, nil
end

local function persistProgressionMutation(active, state)
    local ok, persisted = pcall(
        Profile.SetGuildProgression,
        active.guildKey,
        active.rankRef,
        state
    )
    if not ok or type(persisted) ~= "table" then
        return false, "persistence-failed"
    end

    return true, "ok"
end

function Guild:AssignProgressionEntryToSlot(slotIndex, entryId)
    local active, reason = getProgressionMutationContext(self)
    local normalizedSlot = normalizeIntegerArgument(slotIndex, 1, active and active.slotCount or 0)
    local normalizedEntryId = trimText(entryId)
    if not active then
        return false, reason
    end
    if normalizedSlot == nil then
        return false, "invalid-progression-slot"
    end
    if normalizedEntryId == "" or not active.entryById[normalizedEntryId] then
        return false, "unknown-progression-entry"
    end
    if active.state.unlocked[normalizedEntryId] ~= true then
        return false, "progression-entry-locked"
    end

    active.state.slots[normalizedSlot] = normalizedEntryId
    return persistProgressionMutation(active, active.state)
end

function Guild:SetProgressionEntryUnlocked(entryId, unlocked)
    local active, reason = getProgressionMutationContext(self)
    local normalizedEntryId = trimText(entryId)
    if not active then
        return false, reason
    end
    if normalizedEntryId == "" or not active.entryById[normalizedEntryId] then
        return false, "unknown-progression-entry"
    end

    if unlocked == true then
        active.state.unlocked[normalizedEntryId] = true
    else
        active.state.unlocked[normalizedEntryId] = nil
        for slot = 1, active.slotCount do
            if trimText(active.state.slots[slot]) == normalizedEntryId then
                active.state.slots[slot] = nil
            end
        end
        active.state.selectedSpells[normalizedEntryId] = nil
    end

    return persistProgressionMutation(active, active.state)
end

function Guild:SelectProgressionSpell(entryId, spellRef)
    local active, reason = getProgressionMutationContext(self)
    local normalizedEntryId = trimText(entryId)
    local normalizedSpellRef = trimText(spellRef)
    if not active then
        return false, reason
    end
    local entry = active.entryById[normalizedEntryId]
    if not entry then
        return false, "unknown-progression-entry"
    end
    if active.state.unlocked[normalizedEntryId] ~= true then
        return false, "progression-entry-locked"
    end
    if not isConfiguredSpell(entry, normalizedSpellRef) then
        return false, "invalid-progression-spell"
    end

    active.state.selectedSpells[normalizedEntryId] = normalizedSpellRef
    return persistProgressionMutation(active, active.state)
end

function Guild:ClearProgressionSpell(entryId)
    local active, reason = getProgressionMutationContext(self)
    local normalizedEntryId = trimText(entryId)
    if not active then
        return false, reason
    end
    if normalizedEntryId == "" or not active.entryById[normalizedEntryId] then
        return false, "unknown-progression-entry"
    end

    active.state.selectedSpells[normalizedEntryId] = nil
    return persistProgressionMutation(active, active.state)
end

-- Explicit aliases keep the API readable to callers without introducing a
-- second progression state or mutation path.
Guild.SetProgressionSlot = Guild.AssignProgressionEntryToSlot
Guild.UnlockProgressionEntry = function(self, entryId)
    return self:SetProgressionEntryUnlocked(entryId, true)
end
Guild.LockProgressionEntry = function(self, entryId)
    return self:SetProgressionEntryUnlocked(entryId, false)
end
Guild.SelectGuildProgressionSpell = Guild.SelectProgressionSpell
Guild.ClearGuildProgressionSpell = Guild.ClearProgressionSpell

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

    local characterLimit = normalizeCharacterLimit(requisition.characterLimit)
    local isUnlimited = characterLimit == 0
    local usage = 0
    if not isUnlimited then
        if type(Profile.GetGuildRequisitionUsage) ~= "function" then
            return buildRequisitionFailure("ledger-unavailable")
        end

        usage = Profile.GetGuildRequisitionUsage(guildKey, assignedRankRef, normalizedRequisitionId)
        usage = math.max(0, math.floor(tonumber(usage) or 0))
        if usage >= characterLimit then
            return buildRequisitionFailure("character-limit-reached", {
                usage = usage,
                characterLimit = characterLimit,
                requisitionId = normalizedRequisitionId,
            })
        end
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
        isUnlimited = isUnlimited,
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
    local quantityAfter = getInventoryItemQuantity(inventory, detail.datasetId, detail.itemId)
    local awardedQuantity = detail.quantity
    if quantityBefore ~= nil and quantityAfter ~= nil then
        awardedQuantity = math.max(0, quantityAfter - quantityBefore)
    end

    local measuredAward = quantityBefore ~= nil and quantityAfter ~= nil
    if not added or not addedRecord or (measuredAward and awardedQuantity < detail.quantity) then
        local itemRestored = true
        if measuredAward and awardedQuantity > 0 then
            itemRestored = removeInventoryItemQuantity(
                inventory,
                detail.datasetId,
                detail.itemId,
                awardedQuantity
            )
        end

        local currenciesRestored = rollbackCurrencies()
        if itemRestored and currenciesRestored then
            return false, "inventory-award-failed", detail
        end

        return false, "rollback-failed", detail
    end

    local expectedUsage = detail.usage + 1
    local updatedUsage = detail.usage
    if detail.characterLimit > 0 and type(Profile.IncrementGuildRequisitionUsage) == "function" then
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

    if detail.characterLimit > 0 and updatedUsage ~= expectedUsage then
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

local function isFiniteNumber(value)
    return value ~= nil
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

function Guild:GetDailyRewardResetState()
    if type(Common.GetNow) ~= "function" or type(date) ~= "function" then
        return nil, "calendar-unavailable"
    end

    local dateAndTime = _G and _G.C_DateAndTime or nil
    local getSecondsUntilDailyReset = dateAndTime and dateAndTime.GetSecondsUntilDailyReset or nil
    if type(getSecondsUntilDailyReset) ~= "function" then
        return nil, "calendar-unavailable"
    end

    local nowCallOk, now = pcall(Common.GetNow)
    now = tonumber(now)
    local resetCallOk, secondsRemaining = pcall(getSecondsUntilDailyReset)
    secondsRemaining = tonumber(secondsRemaining)
    if not nowCallOk
        or not isFiniteNumber(now)
        or not resetCallOk
        or not isFiniteNumber(secondsRemaining)
        or secondsRemaining < 0 then
        return nil, "calendar-unavailable"
    end

    secondsRemaining = math.floor(secondsRemaining)
    local nextResetTimestamp = now + secondsRemaining
    if not isFiniteNumber(nextResetTimestamp) then
        return nil, "calendar-unavailable"
    end

    local dateCallOk, cycleKey = pcall(date, "%Y-%m-%d", nextResetTimestamp)
    if not dateCallOk
        or type(cycleKey) ~= "string"
        or not cycleKey:match("^%d%d%d%d%-%d%d%-%d%d$") then
        return nil, "calendar-unavailable"
    end

    local currentDateCallOk, currentDayKey = pcall(date, "%Y-%m-%d", now)
    local previousResetDateCallOk, previousCycleKey = pcall(
        date,
        "%Y-%m-%d",
        nextResetTimestamp - (24 * 60 * 60)
    )
    if not currentDateCallOk
        or type(currentDayKey) ~= "string"
        or not currentDayKey:match("^%d%d%d%d%-%d%d%-%d%d$")
        or not previousResetDateCallOk
        or type(previousCycleKey) ~= "string"
        or not previousCycleKey:match("^%d%d%d%d%-%d%d%-%d%d$") then
        return nil, "calendar-unavailable"
    end

    return {
        secondsRemaining = secondsRemaining,
        cycleKey = cycleKey,
        currentDayKey = currentDayKey,
        previousCycleKey = previousCycleKey,
    }
end

local function legacyDailyRewardClaimBelongsToCurrentResetCycle(claimDate, resetState)
    if type(claimDate) ~= "string" or type(resetState) ~= "table" then
        return false
    end

    if claimDate == resetState.currentDayKey then
        return true
    end

    -- Before the reset, the current reset cycle can include the previous
    -- calendar day. Legacy storage has no claim timestamp, so retain that
    -- claim conservatively rather than risking a duplicate award.
    return resetState.cycleKey == resetState.currentDayKey
        and claimDate == resetState.previousCycleKey
end

local function migrateLegacyDailyRewardClaim(guildKey, claimDate, claimRankRef, assignedRankRef, resetState)
    if type(Profile.SetDailyRewardClaim) ~= "function"
        or type(Profile.GetDailyRewardClaim) ~= "function" then
        return nil, nil, nil, "profile-api-unavailable"
    end

    local normalizedRankRef = claimRankRef or assignedRankRef
    if type(normalizedRankRef) ~= "string" or normalizedRankRef == "" then
        return nil, nil, nil, "profile-api-unavailable"
    end

    local migratedDate = legacyDailyRewardClaimBelongsToCurrentResetCycle(claimDate, resetState)
        and resetState.cycleKey
        or claimDate
    local setCallOk = pcall(
        Profile.SetDailyRewardClaim,
        guildKey,
        migratedDate,
        normalizedRankRef,
        DAILY_REWARD_CLAIM_SEMANTICS_RESET_CYCLE
    )
    if not setCallOk then
        return nil, nil, nil, "profile-api-unavailable"
    end

    local storedCallOk, storedDate, storedRankRef, storedSemantics = pcall(
        Profile.GetDailyRewardClaim,
        guildKey
    )
    if not storedCallOk
        or storedDate ~= migratedDate
        or storedRankRef ~= normalizedRankRef
        or storedSemantics ~= DAILY_REWARD_CLAIM_SEMANTICS_RESET_CYCLE then
        return nil, nil, nil, "profile-api-unavailable"
    end

    return storedDate, storedRankRef, storedSemantics
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
        resetState = nil,
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

    local resetState, resetReason = self:GetDailyRewardResetState()
    if type(resetState) ~= "table" then
        result.status = resetReason or "calendar-unavailable"
        result.reason = result.status
        return result
    end
    result.resetState = resetState
    result.dayKey = resetState.cycleKey

    if type(Profile.GetDailyRewardClaim) ~= "function" then
        result.status = "profile-api-unavailable"
        result.reason = result.status
        return result
    end

    local claimCallOk, claimDate, claimRankRef, claimSemantics = pcall(
        Profile.GetDailyRewardClaim,
        result.guildKey
    )
    if not claimCallOk then
        result.status = "profile-api-unavailable"
        result.reason = result.status
        return result
    end

    if claimDate and claimSemantics ~= DAILY_REWARD_CLAIM_SEMANTICS_RESET_CYCLE then
        local migratedDate, migratedRankRef, migratedSemantics, migrationReason = migrateLegacyDailyRewardClaim(
            result.guildKey,
            claimDate,
            claimRankRef,
            result.assignedRankRef,
            resetState
        )
        if not migratedDate then
            result.status = migrationReason or "profile-api-unavailable"
            result.reason = result.status
            return result
        end

        claimDate = migratedDate
        claimRankRef = migratedRankRef
        claimSemantics = migratedSemantics
    end
    result.claimDate = claimDate
    result.claimRankRef = claimRankRef
    result.claimSemantics = claimSemantics
    if claimDate == result.dayKey then
        result.status = "received-today"
        result.reason = result.status
        return result
    end

    if type(Profile.GetDailyRewardTransaction) ~= "function" then
        result.status = "profile-api-unavailable"
        result.reason = result.status
        return result
    end

    local transactionCallOk, transaction = pcall(Profile.GetDailyRewardTransaction, result.guildKey)
    if not transactionCallOk then
        result.status = "profile-api-unavailable"
        result.reason = result.status
        return result
    end
    if type(transaction) == "table" then
        result.status = "transaction-recovery-required"
        result.reason = result.status
        result.transaction = transaction
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
                local rolledBack = transaction:Rollback()
                return false, rolledBack and "currency-read-failed" or "rollback-failed", transaction
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

local function persistDailyRewardTransactionState(context, state, reason)
    if type(context) ~= "table"
        or type(Profile.SetDailyRewardTransaction) ~= "function" then
        return false
    end

    local callOk, persisted = pcall(
        Profile.SetDailyRewardTransaction,
        context.guildKey,
        context.dayKey,
        context.guildRankRef,
        state,
        reason
    )
    return callOk
        and type(persisted) == "table"
        and persisted.status == state
        and persisted.date == context.dayKey
        and persisted.rankRef == context.guildRankRef
end

local function clearDailyRewardTransactionState(guildKey)
    if type(Profile.ClearDailyRewardTransaction) ~= "function" then
        return false
    end

    local callOk, cleared = pcall(Profile.ClearDailyRewardTransaction, guildKey)
    return callOk and cleared == true
end

function Guild:ProcessDailyRewards()
    if self._dailyRewardProcessing == true then
        return false, "processing"
    end

    self._dailyRewardProcessing = true
    local transactionContext = nil
    local callOk, success, reason, result = xpcall(function()
        local status = self:GetDailyRewardStatus()
        if status.status ~= "available-today" then
            return false, status.status, status
        end

        transactionContext = {
            guildKey = status.guildKey,
            dayKey = status.dayKey,
            guildRankRef = status.assignedRankRef,
        }
        if not persistDailyRewardTransactionState(transactionContext, "in-progress", "award-started") then
            return false, "transaction-state-persistence-failed", status
        end

        local awarded, awardReason, transaction = awardDailyRewardPlan(status.plan or {})
        if not awarded then
            if not persistDailyRewardTransactionState(transactionContext, "failed", awardReason) then
                return false, "transaction-state-persistence-failed", status
            end
            return false, awardReason, status
        end

        if type(Profile.SetDailyRewardClaim) ~= "function" then
            pcall(transaction.Rollback, transaction)
            if not persistDailyRewardTransactionState(
                transactionContext,
                "failed",
                "claim-persistence-unavailable"
            ) then
                return false, "transaction-state-persistence-failed", status
            end
            return false, "claim-persistence-unavailable", status
        end

        local claimCallOk, persistedBucket = pcall(
            Profile.SetDailyRewardClaim,
            status.guildKey,
            status.dayKey,
            status.assignedRankRef,
            DAILY_REWARD_CLAIM_SEMANTICS_RESET_CYCLE
        )
        local storedCallOk, storedDate, storedRankRef, storedSemantics = pcall(
            Profile.GetDailyRewardClaim,
            status.guildKey
        )
        if not claimCallOk
            or type(persistedBucket) ~= "table"
            or not storedCallOk
            or storedDate ~= status.dayKey
            or storedRankRef ~= status.assignedRankRef
            or storedSemantics ~= DAILY_REWARD_CLAIM_SEMANTICS_RESET_CYCLE then
            pcall(transaction.Rollback, transaction)
            if not persistDailyRewardTransactionState(
                transactionContext,
                "failed",
                "claim-persistence-failed"
            ) then
                return false, "transaction-state-persistence-failed", status
            end
            return false, "claim-persistence-failed", status
        end

        -- The claim is authoritative once verified. If marker cleanup fails,
        -- the completed claim still wins over the stale marker on future runs.
        clearDailyRewardTransactionState(status.guildKey)
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
        if transactionContext then
            persistDailyRewardTransactionState(transactionContext, "failed", "processing-failed")
        end
        return false, "processing-failed", {
            error = reason,
        }
    end

    return success, reason, result
end

function Guild:TryClaimDailyReward()
    return self:ProcessDailyRewards()
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

function Guild:GrantAchievementForMember(targetName, achievementRef, callback)
    local available, reason, member = self:IsGuildAdminTargetAvailable(targetName)
    local normalizedRef = trimText(achievementRef)
    if not available then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            operation = "grant_achievement",
            reason = reason,
        })
        return false, reason
    end

    if normalizedRef == "" then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            operation = "grant_achievement",
            reason = "unknown-achievement",
        })
        return false, "unknown-achievement"
    end

    local requestId = getGuildAdminRequestId()
    return sendGuildAdminRequest(self, GUILD_ADMIN_MUTATION_OPCODE, member.name, {
        requestId,
        GUILD_ADMIN_PROTOCOL_VERSION,
        "grant_achievement",
        member.name,
        normalizedRef,
    }, {
        requestId = requestId,
        kind = "mutation",
        operation = "grant_achievement",
        targetName = member.name,
        callback = callback,
    })
end

function Guild:AdjustSkillForMember(targetName, skillRef, delta, callback)
    local available, reason, member = self:IsGuildAdminTargetAvailable(targetName)
    local normalizedRef = trimText(skillRef)
    local normalizedDelta = normalizeIntegerArgument(delta)
    if not available then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            operation = "adjust_skill",
            reason = reason,
        })
        return false, reason
    end

    if normalizedRef == "" then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            operation = "adjust_skill",
            reason = "unknown-skill",
        })
        return false, "unknown-skill"
    end
    if normalizedDelta == nil or normalizedDelta == 0 then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            operation = "adjust_skill",
            reason = "invalid-delta",
        })
        return false, "invalid-delta"
    end

    local requestId = getGuildAdminRequestId()
    return sendGuildAdminRequest(self, GUILD_ADMIN_MUTATION_OPCODE, member.name, {
        requestId,
        GUILD_ADMIN_PROTOCOL_VERSION,
        "adjust_skill",
        member.name,
        normalizedRef,
        normalizedDelta,
    }, {
        requestId = requestId,
        kind = "mutation",
        operation = "adjust_skill",
        targetName = member.name,
        callback = callback,
    })
end

function Guild:GiveItemToMember(targetName, itemRef, quantity, callback)
    local available, reason, member = self:IsGuildAdminTargetAvailable(targetName)
    local normalizedRef = trimText(itemRef)
    local normalizedQuantity = normalizeIntegerArgument(quantity, 1)
    if not available then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            operation = "give_item",
            reason = reason,
        })
        return false, reason
    end

    if normalizedRef == "" then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            operation = "give_item",
            reason = "unknown-item",
        })
        return false, "unknown-item"
    end
    if normalizedQuantity == nil then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            operation = "give_item",
            reason = "invalid-quantity",
        })
        return false, "invalid-quantity"
    end

    local requestId = getGuildAdminRequestId()
    return sendGuildAdminRequest(self, GUILD_ADMIN_MUTATION_OPCODE, member.name, {
        requestId,
        GUILD_ADMIN_PROTOCOL_VERSION,
        "give_item",
        member.name,
        normalizedRef,
        normalizedQuantity,
    }, {
        requestId = requestId,
        kind = "mutation",
        operation = "give_item",
        targetName = member.name,
        callback = callback,
    })
end

function Guild:AssignProgressionEntryForMember(targetName, slotIndex, entryId, callback)
    local available, reason, member = self:IsGuildAdminTargetAvailable(targetName)
    local normalizedSlot = normalizeIntegerArgument(slotIndex, 1)
    local normalizedEntryId = trimText(entryId)
    if not available then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            operation = "assign_progression_entry",
            reason = reason,
        })
        return false, reason
    end
    if normalizedSlot == nil then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            operation = "assign_progression_entry",
            reason = "invalid-progression-slot",
        })
        return false, "invalid-progression-slot"
    end
    if normalizedEntryId == "" then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            operation = "assign_progression_entry",
            reason = "unknown-progression-entry",
        })
        return false, "unknown-progression-entry"
    end

    local requestId = getGuildAdminRequestId()
    return sendGuildAdminRequest(self, GUILD_ADMIN_MUTATION_OPCODE, member.name, {
        requestId,
        GUILD_ADMIN_PROTOCOL_VERSION,
        "assign_progression_entry",
        member.name,
        normalizedSlot,
        normalizedEntryId,
    }, {
        requestId = requestId,
        kind = "mutation",
        operation = "assign_progression_entry",
        targetName = member.name,
        callback = callback,
    })
end

function Guild:SetProgressionEntryLockForMember(targetName, entryId, unlocked, callback)
    local available, reason, member = self:IsGuildAdminTargetAvailable(targetName)
    local normalizedEntryId = trimText(entryId)
    local operation = unlocked == true and "unlock_progression_entry" or "lock_progression_entry"
    if not available then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            operation = operation,
            reason = reason,
        })
        return false, reason
    end
    if normalizedEntryId == "" then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            operation = operation,
            reason = "unknown-progression-entry",
        })
        return false, "unknown-progression-entry"
    end

    local requestId = getGuildAdminRequestId()
    return sendGuildAdminRequest(self, GUILD_ADMIN_MUTATION_OPCODE, member.name, {
        requestId,
        GUILD_ADMIN_PROTOCOL_VERSION,
        operation,
        member.name,
        normalizedEntryId,
    }, {
        requestId = requestId,
        kind = "mutation",
        operation = operation,
        targetName = member.name,
        callback = callback,
    })
end

function Guild:ClearProgressionSpellForMember(targetName, entryId, spellRef, callback)
    local available, reason, member = self:IsGuildAdminTargetAvailable(targetName)
    local normalizedEntryId = trimText(entryId)
    local normalizedSpellRef = trimText(spellRef)
    if not available then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            operation = "clear_progression_spell",
            reason = reason,
        })
        return false, reason
    end
    if normalizedEntryId == "" then
        invokeGuildAdminCallback({ callback = callback }, {
            success = false,
            operation = "clear_progression_spell",
            reason = "unknown-progression-entry",
        })
        return false, "unknown-progression-entry"
    end

    local requestId = getGuildAdminRequestId()
    return sendGuildAdminRequest(self, GUILD_ADMIN_MUTATION_OPCODE, member.name, {
        requestId,
        GUILD_ADMIN_PROTOCOL_VERSION,
        "clear_progression_spell",
        member.name,
        normalizedEntryId,
        normalizedSpellRef,
    }, {
        requestId = requestId,
        kind = "mutation",
        operation = "clear_progression_spell",
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

    local profileState = parseQueryProfileStateArguments(arguments)
    return completeGuildAdminPending(self, requestId, {
        requestId = requestId,
        protocolVersion = protocolVersion,
        success = isSuccessfulArgument(getArgument(arguments, 3)),
        reason = getArgument(arguments, 4),
        assignedRankRef = getArgument(arguments, 5),
        guildRankIndex = tonumber(getArgument(arguments, 6)),
        guildRankName = getArgument(arguments, 7),
        guildName = getArgument(arguments, 8),
        profileState = profileState,
        achievements = profileState.achievements,
        skills = profileState.skills,
        progression = profileState.progression,
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
        detail = getArgument(arguments, 7),
        value = getArgument(arguments, 8),
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
        buildQueryResponseArguments(
            requestId,
            true,
            "ok",
            identity,
            getAssignedGuildRankRef(identity),
            getProgressionQuerySnapshot(self)
        )
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

    if operation == "assign_progression_entry"
        or operation == "lock_progression_entry"
        or operation == "unlock_progression_entry"
        or operation == "clear_progression_spell" then
        local active = type(self.GetActiveGuildProgression) == "function"
            and self:GetActiveGuildProgression()
            or nil
        if type(active) ~= "table" or active.status ~= "valid" then
            reason = active and active.reason or "no-active-progression"
        else
            local entryId
            local entry
            if operation == "assign_progression_entry" then
                local slotIndex = normalizeIntegerArgument(getArgument(arguments, 5), 1, active.slotCount)
                entryId = getArgument(arguments, 6)
                entry = active.entryById and active.entryById[entryId] or nil
                if slotIndex == nil then
                    reason = "invalid-progression-slot"
                elseif not entry then
                    reason = "unknown-progression-entry"
                elseif active.state.unlocked[entryId] ~= true then
                    reason = "progression-entry-locked"
                else
                    local changed, changeReason = self:AssignProgressionEntryToSlot(slotIndex, entryId)
                    if changed then
                        self:RefreshWindow()
                        return sendGuildAdminMessage(
                            GUILD_ADMIN_MUTATION_RESPONSE_OPCODE,
                            sender,
                            buildMutationResponseArguments(
                                requestId,
                                operation,
                                true,
                                "ok",
                                active.rankRef,
                                "progression-slot-assigned",
                                slotIndex
                            )
                        )
                    end
                    reason = changeReason or "persistence-failed"
                end
            else
                entryId = getArgument(arguments, 5)
                entry = active.entryById and active.entryById[entryId] or nil
                if not entry then
                    reason = "unknown-progression-entry"
                elseif operation == "lock_progression_entry" or operation == "unlock_progression_entry" then
                    local shouldUnlock = operation == "unlock_progression_entry"
                    local changed, changeReason = self:SetProgressionEntryUnlocked(entryId, shouldUnlock)
                    if changed then
                        self:RefreshWindow()
                        return sendGuildAdminMessage(
                            GUILD_ADMIN_MUTATION_RESPONSE_OPCODE,
                            sender,
                            buildMutationResponseArguments(
                                requestId,
                                operation,
                                true,
                                "ok",
                                active.rankRef,
                                shouldUnlock and "progression-entry-unlocked" or "progression-entry-locked",
                                entryId
                            )
                        )
                    end
                    reason = changeReason or "persistence-failed"
                else
                    local expectedSpellRef = getArgument(arguments, 6)
                    local currentSpellRef = trimText(active.state.selectedSpells and active.state.selectedSpells[entryId])
                    -- An expected value makes this cleanup mutation safe against
                    -- concurrent edits. A matching stale value may still be
                    -- cleared so administrators can repair obsolete definitions.
                    if expectedSpellRef ~= "" and currentSpellRef ~= expectedSpellRef then
                        reason = "selected-spell-changed"
                    else
                        local changed, changeReason = self:ClearProgressionSpell(entryId)
                        if changed then
                            self:RefreshWindow()
                            return sendGuildAdminMessage(
                                GUILD_ADMIN_MUTATION_RESPONSE_OPCODE,
                                sender,
                                buildMutationResponseArguments(
                                    requestId,
                                    operation,
                                    true,
                                    "ok",
                                    active.rankRef,
                                    "progression-spell-cleared",
                                    entryId
                                )
                            )
                        end
                        reason = changeReason or "persistence-failed"
                    end
                end
            end
        end

        return sendGuildAdminMessage(
            GUILD_ADMIN_MUTATION_RESPONSE_OPCODE,
            sender,
            buildMutationResponseArguments(requestId, operation, false, reason)
        )
    end

    if operation == "grant_achievement" then
        local achievementRef = getArgument(arguments, 5)
        local _, achievement = resolveAchievementReference(achievementRef)
        if not achievement then
            reason = "unknown-achievement"
        else
            local achievements = Client.Achievements or {}
            if type(achievements.Grant) ~= "function" then
                reason = "achievement-api-unavailable"
            else
                local callOk, granted, grantReason = pcall(
                    achievements.Grant,
                    achievements,
                    achievementRef,
                    {
                        source = "guild_admin",
                        actor = tostring(sender or ""),
                    }
                )
                if not callOk or granted ~= true then
                    reason = callOk and trimText(grantReason) or "achievement-grant-failed"
                    if reason == "" then
                        reason = "achievement-grant-failed"
                    end
                else
                    self:RefreshWindow()
                    return sendGuildAdminMessage(
                        GUILD_ADMIN_MUTATION_RESPONSE_OPCODE,
                        sender,
                        buildMutationResponseArguments(
                            requestId,
                            operation,
                            true,
                            "ok",
                            nil,
                            "achievement-granted",
                            achievementRef
                        )
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

    if operation == "adjust_skill" then
        local skillRef = getArgument(arguments, 5)
        local delta = normalizeIntegerArgument(getArgument(arguments, 6))
        local _, skill = resolveSkillReference(skillRef)
        if not skill then
            reason = "unknown-skill"
        elseif delta == nil or delta == 0 then
            reason = "invalid-delta"
        elseif type(Profile.GetSkillLevel) ~= "function" or type(Profile.SetSkillLevel) ~= "function" then
            reason = "skill-api-unavailable"
        else
            local minimum, maximum, hasResolvedRow = getSkillLevelBounds(skillRef, skill)
            if type(Profile.GetResolvedSkillRow) == "function" and hasResolvedRow == false then
                reason = "skill-unavailable"
            elseif minimum == nil then
                reason = "invalid-skill-bounds"
            else
                local currentCallOk, current = pcall(Profile.GetSkillLevel, skillRef)
                current = currentCallOk and normalizeIntegerArgument(current, 0) or nil
                local nextLevel = current and (current + delta) or nil
                if not nextLevel or nextLevel ~= nextLevel or nextLevel == math.huge or nextLevel == -math.huge then
                    reason = "invalid-skill-level"
                elseif nextLevel < minimum or (maximum ~= nil and nextLevel > maximum) then
                    reason = "skill-level-out-of-range"
                else
                    local setCallOk, storedLevel = pcall(Profile.SetSkillLevel, skillRef, nextLevel)
                    local getCallOk, verifiedLevel = pcall(Profile.GetSkillLevel, skillRef)
                    verifiedLevel = getCallOk and normalizeIntegerArgument(verifiedLevel, 0) or nil
                    if not setCallOk or storedLevel == nil or not getCallOk or verifiedLevel ~= nextLevel then
                        reason = "skill-persistence-failed"
                    else
                        self:RefreshWindow()
                        return sendGuildAdminMessage(
                            GUILD_ADMIN_MUTATION_RESPONSE_OPCODE,
                            sender,
                            buildMutationResponseArguments(
                                requestId,
                                operation,
                                true,
                                "ok",
                                nil,
                                "skill-adjusted",
                                verifiedLevel
                            )
                        )
                    end
                end
            end
        end

        return sendGuildAdminMessage(
            GUILD_ADMIN_MUTATION_RESPONSE_OPCODE,
            sender,
            buildMutationResponseArguments(requestId, operation, false, reason)
        )
    end

    if operation == "give_item" then
        local itemRef = getArgument(arguments, 5)
        local quantity = normalizeIntegerArgument(getArgument(arguments, 6), 1)
        local itemDataset, item = resolveItemReference(itemRef)
        local datasetId, itemId = parseItemReference(itemRef)
        if not itemDataset or not item or not datasetId or not itemId then
            reason = "unknown-item"
        elseif quantity == nil then
            reason = "invalid-quantity"
        else
            local inventory = getInventoryService()
            if type(inventory.AddItem) ~= "function" then
                reason = "inventory-api-unavailable"
            else
                local callOk, addedRecord = pcall(inventory.AddItem, {
                    dataset = datasetId,
                    id = itemId,
                    quantity = quantity,
                })
                if not callOk or not addedRecord then
                    reason = "item-award-failed"
                else
                    self:RefreshWindow()
                    return sendGuildAdminMessage(
                        GUILD_ADMIN_MUTATION_RESPONSE_OPCODE,
                        sender,
                        buildMutationResponseArguments(
                            requestId,
                            operation,
                            true,
                            "ok",
                            nil,
                            "item-awarded",
                            quantity
                        )
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

    local status = nil
    if type(self.GetAssignedGuildRankStatus) == "function" then
        local statusCallOk, assignedStatus = pcall(self.GetAssignedGuildRankStatus, self)
        if statusCallOk then
            status = assignedStatus
        end
    end

    self:RefreshWindow()
    return status
end

return Guild
