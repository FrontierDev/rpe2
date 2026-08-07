local _, Addon = ...

Addon.Core = Addon.Core or {}

local Sound = Addon.Core.Sound or {}
Addon.Core.Sound = Sound

local DEFAULT_CHANNEL_ORDER = {
    "Master",
    "SFX",
    nil,
}

local function tryPlaySound(soundKitId, channel)
    if type(PlaySound) ~= "function" then
        return false
    end

    local ok, result
    if channel ~= nil then
        ok, result = pcall(PlaySound, soundKitId, channel)
    else
        ok, result = pcall(PlaySound, soundKitId)
    end

    if not ok then
        return false
    end

    if result == nil then
        return true
    end

    return result == true
end

local function tryPlaySoundFile(fileId, channel)
    if type(PlaySoundFile) ~= "function" then
        return false
    end

    local ok, result
    if channel ~= nil then
        ok, result = pcall(PlaySoundFile, fileId, channel)
    else
        ok, result = pcall(PlaySoundFile, fileId)
    end

    if not ok then
        return false
    end

    if result == nil then
        return true
    end

    return result == true
end

function Sound:Play(soundKitId, channel)
    local resolvedSoundKitId = tonumber(soundKitId)
    if not resolvedSoundKitId or resolvedSoundKitId <= 0 then
        return false
    end

    if channel ~= nil then
        return tryPlaySound(resolvedSoundKitId, channel) or tryPlaySoundFile(resolvedSoundKitId, channel)
    end

    for index = 1, #DEFAULT_CHANNEL_ORDER do
        local targetChannel = DEFAULT_CHANNEL_ORDER[index]
        if tryPlaySound(resolvedSoundKitId, targetChannel) or tryPlaySoundFile(resolvedSoundKitId, targetChannel) then
            return true
        end
    end

    return false
end

function Sound:GetRaidWarningSoundKitId()
    if type(SOUNDKIT) == "table" and tonumber(SOUNDKIT.RAID_WARNING) then
        return tonumber(SOUNDKIT.RAID_WARNING)
    end

    return 12889
end

function Sound:PlayRaidWarning(channel)
    return self:Play(self:GetRaidWarningSoundKitId(), channel)
end

function Sound:PlayEventStartCue(channel)
    return self:Play(25478, channel)
end

function Sound:PlayLocalTurnStartCue(channel)
    return self:Play(3175, channel)
end

return Sound
