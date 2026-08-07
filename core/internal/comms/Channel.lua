local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

-- Forward Declarations
local Comms = Addon.Internal.Comms
local Diagnostics = Addon.Internal.Comms.Diagnostics or {}

local function findChannelIdInList(channelName)
    if type(channelName) ~= "string" or channelName == "" or not GetChannelList then
        return nil
    end

    local channels = { GetChannelList() }
    for index = 1, #channels, 2 do
        local listedChannelId = tonumber(channels[index])
        local listedChannelName = tostring(channels[index + 1] or "")
        if listedChannelId and listedChannelId > 0 and listedChannelName == channelName then
            return listedChannelId
        end
    end

    return nil
end

-- returns the channelId if the channel is joined, otherwise nil
function Comms:ResolveChannelId(channelName)
    if type(channelName) ~= "string" or channelName == "" or not GetChannelName then
        return findChannelIdInList(channelName)
    end

    local resolvedChannelId = GetChannelName(channelName)
    local channelId = tonumber(resolvedChannelId)
    if channelId and channelId > 0 then
        return channelId
    end

    return findChannelIdInList(channelName)
end

-- joins the specified channel and returns the channelId if successful, otherwise nil
function Comms:JoinChannel(channelName)
    if type(channelName) ~= "string" or channelName == "" then
        return nil
    end

    if JoinChannelByName then
        JoinChannelByName(channelName, nil, nil, true)
    elseif ChatFrame1EditBox and ChatEdit_SendText then
        ChatFrame1EditBox:SetText("/join " .. channelName)
        ChatEdit_SendText(ChatFrame1EditBox, 0)
    end

    local channelId = self:ResolveChannelId(channelName)
    if Diagnostics.RecordChannelJoin then
        Diagnostics:RecordChannelJoin(channelName, channelId)
    end
    return channelId
end

-- leaves the specified channel and returns true if successful, otherwise false
function Comms:LeaveChannel(channelName)
    if type(channelName) ~= "string" or channelName == "" then
        return false
    end

    if LeaveChannelByName then
        LeaveChannelByName(channelName)
    elseif ChatFrame1EditBox and ChatEdit_SendText then
        ChatFrame1EditBox:SetText("/leave " .. channelName)
        ChatEdit_SendText(ChatFrame1EditBox, 0)
    else
        return false
    end

    if Diagnostics.RecordChannelLeave then
        Diagnostics:RecordChannelLeave(channelName)
    end
    return true
end
