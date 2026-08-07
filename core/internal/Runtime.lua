local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Events = Addon.Internal.Events or {}

local Events = Addon.Internal.Events
local Tasks = Addon.Internal.Tasks or {}
local Comms = Addon.Internal.Comms or {}

local function safeCall(handler, ...)
    if type(handler) ~= "function" then
        return nil
    end

    local args = { ... }
    local argCount = select("#", ...)

    local ok, result = xpcall(function()
        return handler(unpack(args, 1, argCount))
    end, function(err)
        if debugstack then
            return ("%s\n%s"):format(tostring(err), debugstack(2))
        end

        return tostring(err)
    end)

    if ok then
        return result
    end

    if Addon.Debug and Addon.Debug.Error then
        Addon.Debug.Error("%s", result)
    end

    return nil
end

function Addon.Internal.DispatchEvent(event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName ~= Addon.Name then
            return
        end

        if Tasks and Tasks.Initialize then
            safeCall(Tasks.Initialize, Tasks)
        end

        if Comms and Comms.RegisterPrefix then
            safeCall(Comms.RegisterPrefix, Comms)
        end
        return
    end

    if event == "CHAT_MSG_ADDON" then
        local prefix, message, distribution, sender, target = ...
        if not Comms or not Comms.ReceiveMessage then
            return
        end

        safeCall(Comms.ReceiveMessage, Comms, prefix, message, distribution, sender, target)
        return
    end

    if event == "CHANNEL_UI_UPDATE"
        or event == "CHAT_MSG_CHANNEL_JOIN"
        or event == "CHAT_MSG_CHANNEL_NOTICE"
        or event == "CHAT_MSG_CHANNEL_NOTICE_USER"
        or event == "GROUP_ROSTER_UPDATE"
        or event == "PLAYER_ENTERING_WORLD"
    then
        local Client = Addon.Client or nil
        if Client and Client.HandleSessionRuntimeEvent then
            safeCall(Client.HandleSessionRuntimeEvent, Client, event, ...)
        elseif Client and Client.HandleChannelRuntimeEvent then
            safeCall(Client.HandleChannelRuntimeEvent, Client, event, ...)
        end
        return
    end

end

Events.Frame = Events.Frame or (CreateFrame and CreateFrame("Frame"))

if Events.Frame then
    Events.Frame:RegisterEvent("ADDON_LOADED")
    Events.Frame:RegisterEvent("CHAT_MSG_ADDON")
    Events.Frame:RegisterEvent("CHANNEL_UI_UPDATE")
    Events.Frame:RegisterEvent("CHAT_MSG_CHANNEL_JOIN")
    Events.Frame:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
    Events.Frame:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE_USER")
    Events.Frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    Events.Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    Events.Frame:SetScript("OnEvent", function(_, event, ...)
        Addon.Internal.DispatchEvent(event, ...)
    end)
end
