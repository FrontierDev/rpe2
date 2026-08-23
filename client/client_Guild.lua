local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Guild = Addon.Client.Guild or {}

local Client = Addon.Client
local Guild = Addon.Client.Guild
local Registry = Addon.Internal and Addon.Internal.Registry or {}

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
        datasetId = datasetId,
        settingId = settingId,
        ref = datasetId ~= "" and settingId ~= "" and (datasetId .. ":" .. settingId) or "",
        datasetName = getDatasetLabel(dataset),
        settingName = getSettingLabel(setting),
        guildName = trimText(setting and setting.guildName),
        matchType = matchType,
    }
end

local function hasOfficerPermission()
    local identity = getGuildIdentity()
    if not identity.inGuild then
        return false
    end

    local guildInfo = _G and _G.C_GuildInfo or nil
    if guildInfo and type(guildInfo.IsGuildLeader) == "function" then
        local ok, isLeader = pcall(guildInfo.IsGuildLeader)
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

function Guild:ResolveActiveGuildSetting()
    local identity = getGuildIdentity()
    local result = {
        inGuild = identity.inGuild,
        guildName = identity.guildName,
        guildRankName = identity.guildRankName,
        guildRankIndex = identity.guildRankIndex,
        setting = nil,
        dataset = nil,
        matches = {},
        conflict = false,
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
    result.matches = candidates

    if #candidates == 0 then
        result.reason = "no-setting"
        return result
    end

    if #candidates > 1 then
        result.conflict = true
        result.reason = "conflict"
        return result
    end

    result.setting = candidates[1].setting
    result.dataset = candidates[1].dataset
    result.match = candidates[1]
    result.reason = candidates[1].matchType
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
