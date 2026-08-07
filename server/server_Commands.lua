local addonName, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.Commands = Addon.Server.Commands or {}

local ServerCommands = Addon.Server.Commands
local Commands = Addon.Commands or {}
local Server = Addon.Server

local function joinArgs(args, startIndex)
    local values = {}
    for index = startIndex or 1, #(args or {}) do
        values[#values + 1] = tostring(args[index] or "")
    end
    return table.concat(values, " ")
end

local function register(path, handler, description)
    if Commands and Commands.RegisterCommand then
        Commands:RegisterCommand(path, handler, {
            description = description,
        })
    end
end

function ServerCommands:RegisterSlashCommands()
    register({ "event" }, function(context)
        if not Server.ShowEventManageWindow then
            context.router:Print("Event management UI is not available.", "warn")
            return false
        end

        Server:ShowEventManageWindow()
        return true
    end, "Show the event management window.")

    register({ "server", "start" }, function(context)
        if not Server.StartServer then
            context.router:Print("Server start is not available.", "warn")
            return false
        end

        local state = Server:StartServer()
        if not state then
            context.router:Print("Server failed to start.", "error")
            return false
        end

        if state.distribution == "PARTY" or state.distribution == "RAID" then
            context.router:Print("Server started on channel %s and broadcast to %s", nil, tostring(state.channelName or "unknown"), tostring(state.distribution))
        else
            context.router:Print("Server started on channel %s without party or raid broadcast", nil, tostring(state.channelName or "unknown"))
        end
        return true
    end, "Start the server and broadcast the session channel.")

    register({ "server", "stop" }, function(context)
        if not Server.StopServer then
            context.router:Print("Server stop is not available.", "warn")
            return false
        end

        if not Server:StopServer("slash-command") then
            context.router:Print("Server is not active.", "warn")
            return false
        end

        context.router:Print("Server stopped.")
        return true
    end, "Stop the server and broadcast the channel shutdown.")

    register({ "server", "status" }, function(context)
        local state = Server.GetState and Server:GetState() or nil
        if not state then
            context.router:Print("Server is inactive.")
            return true
        end

        context.router:Print(
            "Server active: channel=%s group=%s startedAt=%s",
            nil,
            tostring(state.channelName or "none"),
            tostring(state.distribution or "none"),
            tostring(state.startedAt or 0)
        )
        return true
    end, "Show server status.")

    register({ "server", "event", "start" }, function(context)
        if not Server.StartEvent then
            context.router:Print("Server event start is not available.", "warn")
            return false
        end

        local state = Server:StartEvent({
            name = joinArgs(context.args, 1),
        })
        if not state then
            context.router:Print("Server event failed to start. Start the server first.", "warn")
            return false
        end

        context.router:Print(
            "Server event started: id=%s name=%s channel=%s",
            nil,
            tostring(state.id or "none"),
            tostring(state.name ~= "" and state.name or "unnamed"),
            tostring(state.channelName or "none")
        )
        return true
    end, "Start an event on the active server session. Remaining text becomes the event name.")

    register({ "server", "event", "stop" }, function(context)
        if not Server.EndEvent then
            context.router:Print("Server event stop is not available.", "warn")
            return false
        end

        if not Server:EndEvent("slash-command") then
            context.router:Print("Server event is not active.", "warn")
            return false
        end

        context.router:Print("Server event stopped.")
        return true
    end, "Stop the active server event.")

    register({ "server", "event", "status" }, function(context)
        local state = Server.GetEventState and Server:GetEventState() or nil
        if not state then
            context.router:Print("Server event is inactive.")
            return true
        end

        context.router:Print(
            "Server event active: id=%s name=%s channel=%s startedAt=%s",
            nil,
            tostring(state.id or "none"),
            tostring(state.name ~= "" and state.name or "unnamed"),
            tostring(state.channelName or "none"),
            tostring(state.startedAt or 0)
        )
        return true
    end, "Show server event status.")
end

ServerCommands:RegisterSlashCommands()
