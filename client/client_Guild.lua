local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Guild = Addon.Client.Guild or {}

local Client = Addon.Client
local Guild = Addon.Client.Guild
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function trimText(value)
    return ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
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
